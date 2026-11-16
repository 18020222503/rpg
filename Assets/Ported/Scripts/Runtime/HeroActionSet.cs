using System;
using UnityEngine;

namespace Ported
{
    // 一个角色的全部技能数据。ScriptableObject 必须放在同名文件里，Unity 才能找到它的脚本
    public class HeroActionSet : ScriptableObject
    {
        public string heroId;
        public SocketData[] sockets = Array.Empty<SocketData>();
        public ActionData[] combo = Array.Empty<ActionData>();
        public ActionData heavy;
        public ActionData skill1;
        public ActionData skill2;
        public ActionData ultimate;
        public EmitterData[] emitters = Array.Empty<EmitterData>();

        public ActionData FindCombo(int id)
        {
            foreach (var a in combo)
                if (a != null && a.id == id) return a;
            return null;
        }

        public EmitterData FindEmitter(int id)
        {
            foreach (var e in emitters)
                if (e != null && e.id == id) return e;
            return null;
        }
    }
}
