using System;

namespace Ported
{
    // 登录和游戏之间传递选中的角色。
    // 只有 Boot 一个场景，登录和游戏都是 prefab，切换由热更层的 GameFlow 负责：它启动时填上下面两个回调。
    // 这里是 AOT 程序集，不能直接引用热更代码，所以用回调
    public static class PortedSession
    {
        public static int HeroIndex;

        public static Action EnterGame;
        public static Action BackToLogin;
    }
}
