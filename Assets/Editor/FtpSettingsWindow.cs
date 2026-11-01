using UnityEditor;
using UnityEngine;

//FTP 配置保存在本机的 EditorPrefs 里，不会提交到 git
public class FtpSettingsWindow : EditorWindow
{
    public const string HostKey = "HotUpdate.FtpHost";
    public const string UserKey = "HotUpdate.FtpUser";
    public const string PasswordKey = "HotUpdate.FtpPassword";
    public const string RemoteDirKey = "HotUpdate.FtpRemoteDir";

    //FTP 账号的根目录是 E:/work/FTP，站点目录 RPG 在它下面
    public const string DefaultRemoteDir = "RPG";

    string host;
    string user;
    string password;
    string remoteDir;

    [MenuItem("Tools/Hotdate/FtpSettings", priority = 100)]
    public static void Open()
    {
        GetWindow<FtpSettingsWindow>("FTP设置");
    }

    void OnEnable()
    {
        host = EditorPrefs.GetString(HostKey, "192.168.1.7:21");
        user = EditorPrefs.GetString(UserKey);
        password = EditorPrefs.GetString(PasswordKey);
        remoteDir = EditorPrefs.GetString(RemoteDirKey, DefaultRemoteDir);
    }

    void OnGUI()
    {
        host = EditorGUILayout.TextField("地址(host:port)", host);
        user = EditorGUILayout.TextField("用户名", user);
        password = EditorGUILayout.PasswordField("密码", password);
        remoteDir = EditorGUILayout.TextField("远端目录", remoteDir);

        if (GUILayout.Button("保存"))
        {
            EditorPrefs.SetString(HostKey, host);
            EditorPrefs.SetString(UserKey, user);
            EditorPrefs.SetString(PasswordKey, password);
            EditorPrefs.SetString(RemoteDirKey, remoteDir);
            Debug.Log("[FTP] 配置已保存");
        }
    }
}
