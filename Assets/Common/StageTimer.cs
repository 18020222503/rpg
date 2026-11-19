using System.Collections.Generic;
using System.Text;
using UnityEngine;

// 启动各阶段耗时统计。放在单独的 AOT 程序集里，Boot（Assembly-CSharp）和热更的 Game 都能调用，
// 从启动到进入界面的各阶段记在同一张表里，进到界面后由 GameFlow 打印。
// 时间用 Time.realtimeSinceStartupAsDouble：从进程启动算起的真实时间，同一帧内多次读取也会变
public static class StageTimer
{
    class Record
    {
        public string name;
        public int depth;
        public double start;
        public double end = -1;
    }

    static readonly List<Record> records = new List<Record>();
    static int openCount;

    static double Now => Time.realtimeSinceStartupAsDouble;

    // 开始一个阶段，返回编号给 End 用。在别的阶段没结束时开始的，打印时缩进显示为子阶段
    public static int Begin(string name)
    {
        records.Add(new Record { name = name, depth = openCount, start = Now });
        openCount++;
        return records.Count - 1;
    }

    // detail 会接在阶段名后面，比如下载了几个 bundle、多大
    public static void End(int id, string detail = null)
    {
        if (id < 0 || id >= records.Count || records[id].end >= 0) return;
        var r = records[id];
        r.end = Now;
        if (!string.IsNullOrEmpty(detail)) r.name += $"（{detail}）";
        openCount--;
    }

    // 记一个已经知道起止时间的阶段，比如进程启动到 Boot 场景跑起来
    public static void Add(string name, double start, double end)
    {
        records.Add(new Record { name = name, depth = openCount, start = start, end = end });
    }

    // 打印目前记下的所有阶段，然后清空，下一次切换界面重新统计
    public static void Report(string title)
    {
        if (records.Count == 0) return;

        double first = records[0].start;
        double last = first;
        foreach (var r in records) last = System.Math.Max(last, r.end >= 0 ? r.end : r.start);

        var sb = new StringBuilder();
        sb.AppendLine($"[StageTimer] {title}，总计 {(last - first) * 1000:0} ms");
        // 开始时间从第一个阶段算起，阶段之间的空档（比如等下一帧）从这一列能看出来
        sb.AppendLine($"{"开始(ms)",10} {"耗时(ms)",10}  阶段");
        foreach (var r in records)
        {
            string cost = r.end >= 0 ? $"{(r.end - r.start) * 1000,10:0.0}" : $"{"未结束",10}";
            sb.AppendLine($"{(r.start - first) * 1000,10:0.0} {cost}  {new string(' ', r.depth * 2)}{r.name}");
        }
        Debug.Log(sb.ToString());

        records.Clear();
        openCount = 0;
    }
}
