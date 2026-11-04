using System;
using System.IO;
using UnityEngine;

public static class BootConfig
{
   public const string CDN = "127.0.0.1:8080";

   //编辑器下是否走本地 bundle 的完整下载流程，由菜单 Tools/Hotdate/EditorUseLocalBundle 切换
   public const string EditorUseLocalBundleKey = "HotUpdate.EditorUseLocalBundle";

   //是否从 bundle 加载资源：真机固定为 true，编辑器默认直读工程资源
   public static bool UseBundle
   {
      get
      {
#if UNITY_EDITOR
         return UnityEditor.EditorPrefs.GetBool(EditorUseLocalBundleKey, false);
#else
         return true;
#endif
      }
   }

   //不走 bundle 时也不需要下载
   public static bool SkipDownload => !UseBundle;

   //下载源：真机是 CDN，编辑器是打包工具输出的 AssetBundle/{平台} 目录
   public static string BaseUrl
   {
      get
      {
#if UNITY_EDITOR
         string dir = Path.Combine(ProjectRoot, "AssetBundle", UnityEditor.EditorUserBuildSettings.activeBuildTarget.ToString());
         return new Uri(dir).AbsoluteUri;
#else
         return $"http://{CDN}";
#endif
      }
   }

   //下载缓存目录。编辑器和 Windows 包的 persistentDataPath 是同一个目录，编辑器单独放到 Library 下避免互相覆盖
   public static string CacheDir
   {
      get
      {
#if UNITY_EDITOR
         return Path.Combine(ProjectRoot, "Library", "HotUpdateCache");
#else
         return Application.persistentDataPath;
#endif
      }
   }

#if UNITY_EDITOR
   static string ProjectRoot => Path.GetDirectoryName(Application.dataPath);
#endif
}
