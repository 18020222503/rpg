using System;
using UnityEngine;

namespace Ported
{
    // qq13 动作配置（DataSettings/roleAction/Role_*.lua、Emitter_*.lua）里技能用到的部分。
    // 由 port_tools/export_actions.py 导出成 JSON，PortedBuilder 读进来并把路径解析成预制体引用。
    // 时间单位都是秒，位置/旋转都是相对角色或挂点的局部坐标。

    [Serializable]
    public class SocketData
    {
        public string name;
        public string bone;
        public Vector3 pos;
        public Vector3 rot;
    }

    [Serializable]
    public class FxEvent
    {
        public string path;
        public GameObject prefab;
        public string socket;
        public Vector3 pos;
        public Vector3 rot;
        public Vector3 scale = Vector3.one;
        public float start;
        public float end;
        [Tooltip("true：跟着挂点走；false：生成后留在世界里")]
        public bool follow;
        [Tooltip("动作切换时：0/3 淡出，1 立即删除，2 不管")]
        public int disappear;
        public float softDel;
        public float speed = 1f;
    }

    [Serializable]
    public class HitEvent
    {
        public float start;
        public float end;
        [Tooltip("1 立方体，3 胶囊")]
        public int shape = 1;
        public Vector3 pos;
        public Vector3 rot;
        public Vector3 size = Vector3.one;
        public float radius = 0.5f;
        public float height = 1f;
        public float damageMul = 1f;
        public int maxHits = 1;
        public float interval;
        public string hitFx;
        public GameObject hitFxPrefab;
        public float hitFxScale = 1f;
    }

    [Serializable]
    public class BulletEvent
    {
        public float start;
        public int emitter;
    }

    [Serializable]
    public class MoveEvent
    {
        public float start;
        public Vector3 dir;
        public float time = 0.1f;
    }

    [Serializable]
    public class SpeedEvent
    {
        public float start;
        public float end;
        public float speed = 1f;
    }

    [Serializable]
    public class ActionData
    {
        public int id;
        public string clip;
        public float duration;
        [Tooltip("从这个时间点起可以被移动或其他技能打断")]
        public float breakTime;
        [Tooltip("连招下一段的 id，0 表示没有")]
        public int nextId;
        public float comboStart;
        public float comboEnd;
        public FxEvent[] fx = Array.Empty<FxEvent>();
        public HitEvent[] hits = Array.Empty<HitEvent>();
        public BulletEvent[] bullets = Array.Empty<BulletEvent>();
        public MoveEvent[] moves = Array.Empty<MoveEvent>();
        public SpeedEvent[] speeds = Array.Empty<SpeedEvent>();

        public bool IsValid => id != 0 && !string.IsNullOrEmpty(clip);
    }

    [Serializable]
    public class EmitterChild
    {
        [Tooltip("1 时间到，2 命中，6 销毁")]
        public int trigger;
        public int emitter;
    }

    [Serializable]
    public class EmitterData
    {
        public int id;
        public Vector3 pos;
        public Vector3 rot;
        public int mouths = 1;
        public float range;
        public float speed;
        public float accel;
        public float minSpeed;
        public float maxSpeed = 999f;
        public float life;
        public bool penetrate;
        public string asset;
        public GameObject assetPrefab;
        public float assetScale = 1f;
        public Vector3 assetPos;
        public Vector3 assetRot;
        public string hurtFx;
        public GameObject hurtFxPrefab;
        public float hurtFxScale = 1f;
        public EmitterChild[] children = Array.Empty<EmitterChild>();
    }
}
