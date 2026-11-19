using UnityEngine;
using UnityEngine.Rendering;

namespace Ported
{
    // 环境光、雾、天空盒、主光源这些设置存在场景文件里，prefab 带不走。
    // 编辑器导出 prefab 时调用 Capture 记下当时场景的设置，prefab 实例化时在 Awake 里设回去
    public class PortedRenderSettings : MonoBehaviour
    {
        public AmbientMode ambientMode = AmbientMode.Trilight;
        public Color ambientSkyColor = Color.gray;
        public Color ambientEquatorColor = Color.gray;
        public Color ambientGroundColor = Color.gray;
        public float ambientIntensity = 1f;

        public Material skybox;
        public Light sun;

        public DefaultReflectionMode reflectionMode = DefaultReflectionMode.Skybox;
        public Texture customReflection;
        public float reflectionIntensity = 1f;

        public bool fog;
        public FogMode fogMode = FogMode.Linear;
        public Color fogColor = Color.gray;
        public float fogDensity = 0.01f;
        public float fogStartDistance;
        public float fogEndDistance = 300f;

        void Awake()
        {
            Apply();
        }

        public void Capture()
        {
            ambientMode = RenderSettings.ambientMode;
            ambientSkyColor = RenderSettings.ambientSkyColor;
            ambientEquatorColor = RenderSettings.ambientEquatorColor;
            ambientGroundColor = RenderSettings.ambientGroundColor;
            ambientIntensity = RenderSettings.ambientIntensity;
            skybox = RenderSettings.skybox;
            sun = RenderSettings.sun;
            reflectionMode = RenderSettings.defaultReflectionMode;
            customReflection = RenderSettings.customReflectionTexture;
            reflectionIntensity = RenderSettings.reflectionIntensity;
            fog = RenderSettings.fog;
            fogMode = RenderSettings.fogMode;
            fogColor = RenderSettings.fogColor;
            fogDensity = RenderSettings.fogDensity;
            fogStartDistance = RenderSettings.fogStartDistance;
            fogEndDistance = RenderSettings.fogEndDistance;
        }

        public void Apply()
        {
            RenderSettings.ambientMode = ambientMode;
            RenderSettings.ambientSkyColor = ambientSkyColor;
            RenderSettings.ambientEquatorColor = ambientEquatorColor;
            RenderSettings.ambientGroundColor = ambientGroundColor;
            RenderSettings.ambientIntensity = ambientIntensity;
            RenderSettings.skybox = skybox;
            RenderSettings.sun = sun;
            RenderSettings.defaultReflectionMode = reflectionMode;
            RenderSettings.customReflectionTexture = customReflection;
            RenderSettings.reflectionIntensity = reflectionIntensity;
            RenderSettings.fog = fog;
            RenderSettings.fogMode = fogMode;
            RenderSettings.fogColor = fogColor;
            RenderSettings.fogDensity = fogDensity;
            RenderSettings.fogStartDistance = fogStartDistance;
            RenderSettings.fogEndDistance = fogEndDistance;
            // 换了天空盒后环境光要重新算
            DynamicGI.UpdateEnvironment();
        }
    }
}
