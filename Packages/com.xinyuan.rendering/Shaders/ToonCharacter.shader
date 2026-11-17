Shader "XinYuan/Character/ToonCharacter"
{
    Properties
    {
        // [about naming]
        // All properties will try to follow URP Lit shader's naming convention,
        // so switching your URP lit material's shader to this toon lit shader will preserve most of the original properties if defined in this shader.
        // For URP Lit shader's naming convention, see URP's Lit.shader (search "Lit t:shader" in the project window, use "Search: In Packages")

        // [about HDR color picker]
        // All color properties in this shader are HDR, because we don't want to limit user's creativity, even if HDR color makes no sense at all.
        // If user want to make a 100% non-sense color choice, for example, an emissive shadow, just let them do it! 
        // because why not? It is NPR, unlike PBR, there is no right or wrong, everything is permitted and valid if it looks good.
        // Adding [HDR] will force unity to treat the color as linear, be careful.

        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Base
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        [Header(Base Color)]
        [MainTexture]_MainTex("基础贴图", 2D) = "white" {} // Not using [Tex] to preserve tiling and offset GUI
        [HDR][MainColor]_MainColor("基础颜色", Color) = (1,1,1,1)
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Render States (can't use LWGUI's group, because of using [Enum(UnityEngine.Rendering.XXX)])
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////               
        [Header(Polygon Face Culling)]
        // https://docs.unity3d.com/ScriptReference/Rendering.CullMode.html
//        [Enum(UnityEngine.Rendering.CullMode)]_Cull("_Cull (Default Back)", Float) = 2
        [Enum(UnityEngine.Rendering.CullMode)]_Cull("裁剪面", Float) = 2
        
        [HideInInspector][Header(Blending state)]
        // https://docs.unity3d.com/ScriptReference/Rendering.BlendMode.html
        // this section will only affect ForwardLit pass
        
        [HideInInspector][Enum(UnityEngine.Rendering.BlendMode)]_SrcBlend("源像素混合值", Float) = 1
        [HideInInspector][Enum(UnityEngine.Rendering.BlendMode)]_DstBlend("目标像素混合值", Float) = 0

        [Header(ZWrite)]
        [ToggleUI]_ZWrite("是否深度写入 (默认开启) ", Float) = 1

        // Not expose ZTest to avoid confusion because in 99.9% of situations custom ZTest is not useful. (ZTest default is LEqual)
        [HideInInspector][Enum(UnityEngine.Rendering.CompareFunction)]_ZTestComp("深度测试操作 (默认 LEqual)", Float) = 4

        [Header(Stencil)]
        _StencilRef("蒙板引用 (默认0)", Range(0,255)) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)]_ForwardStencilComp("主色蒙板比较操作", Float) = 0
        [Enum(UnityEngine.Rendering.StencilOp)]_ForwardStencilOp("主色蒙板通过操作", Float) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)]_OutlineStencilComp("描边蒙板比较操作", Float) = 0
        [Enum(UnityEngine.Rendering.StencilOp)]_OutlineStencilOp("描边蒙板通过操作", Float) = 0

        
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // RMAO Map （ r : Roughness , g : Metallic , b : Ambient Occlusion , a : specular area) 
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        [Main(_RMAOMAP)] _UseRMAO("多通道图支持", Float) = 1
        [SubHelper(_RMAOMAP, r) Specular #g) Ambient Occlusion(AO) #b) Emission #a) RampUVY)]
        [SubHeader(_RMAOMAP, Define)]
        [Tex(_RMAOMAP)][NoScaleOffset]_RMAOMap("多通道图", 2D) = "white" {}
        [SubEnum(_RMAOMAP,N,0,R,1,G,2,B,3)]_showVertColorChannel("显示顶点色",Float) = 0
        [Main(_DecalTex)]_UseDetailMap("细节贴图", Float) = 1
        [SubEnum(_DecalTex,UV1,0,UV2,1)]_DetailMapUV("细节贴图UV", Float) = 0
        [Tex(_DecalTex)][NoScaleOffset]_DecalTex("细节贴图", 2D) = "black" {}
        [Sub(_DecalTex)]_DecalTexAlpha("透明度", Range(0,1)) = 1
        
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Face
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Group name added extra spaces to line up (Default XXX) in material GUI 
        [Main(_ISFACE,_ISFACE)]_IsFace("是否脸部", Float) = 0

        // SubHeader used as a note
        // TODO: turn this into a good looking infobox 
       // [SubHelper(_ISFACE, Please turn on this group for all face materials #so face area can use a better set of lighting and outline settings automatically # If the model combined face and other parts into 1 mesh #can enable mask texture to select valid face area only)]

        [SubHeader(_ISFACE, Optional Mask Texture)]
        [Tex(_ISFACE)][NoScaleOffset]_FaceAoMap("SDF阴影图", 2D) = "white" {}
        [Sub(_ISFACE)]_FaceAoOffset("SDF阴影偏移 (Default 0)", Range(-1,1)) = 0.0

        [SubHeader(_ISFACE, HairShadow)]
        [Sub(_ISFACE)]_DepthTexRimLightAndShadowWidthMultiplier("刘海阴影偏移", Range(0,2)) = 1
        [Sub(_ISFACE)]_DepthTexShadowThresholdOffset("刘海阴影阈值偏移", Range(-0.1,0.1)) = 0
        [Sub(_ISFACE)][HDR]_DepthTexShadowTintColor("刘海阴影色调 ", Color) = (1,1,1)
        
        [SubHeader(_ISFACE, Blush)]
        [Tex(_ISFACE)][NoScaleOffset]_BlushMap("腮红通道图", 2D) = "white" {}
        
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Lighting Style
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        [Main(_ShadowSettings)]_ShadowSettings("阴影设置", Float) = 1
        
        [SubHeader(_ShadowSettings, SphereNormal Control)]
        [SubNumToggle(_ShadowSettings)]_UseSphereNormal("使用球形法线平滑阴影", Float) = 0
        [SubNumToggle(_ShadowSettings)]_ShowSphereNormal("显示球形法线", Float) = 0
        [Sub(_ShadowSettings)]_HeadBonePosOffset("模拟球体中心位置偏移", Vector) = (0,0,0,0)
        
        [SubHeader(_ShadowSettings, CelShadow Control)]
        [Sub(_ShadowSettings)]_CelShadowIntensity("阴影强度",Range(0,1)) = 1
        [Sub(_ShadowSettings)]_CelShadeMidPoint("阴影区域偏移 (Default 0)", Range(-1,1)) = 0
        [Sub(_ShadowSettings)]_CelShadeSoftnessx("阴影边缘平滑", Range(0,1)) = 0.01
        [Sub(_ShadowSettings)]_OcclusionStrength("AO强度", Range(0, 1)) = 1
 
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Ramp Texture lighting
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Group name added extra spaces to line up (Default XXX) in material GUI
        [Main(_RAMP_LIGHTING,_RAMP_LIGHTING)]_UseRampLightingTex("Ramp阴影颜色", Float) = 0 
        [Tex(_RAMP_LIGHTING)][NoScaleOffset]_RampLightingTex("Ramp贴图", 2D) = "white" {}
        
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // FresnelRim
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        [Main(_FRESNELRIM, _FRESNELRIM)]_FresnelRim_ON("边缘光", Float) = 0
        [SubNumToggle(_FRESNELRIM)]_FresnelRimMainLightEffect("开启主光颜色影响", Float) = 1
        [HDR][Sub(_FRESNELRIM)]_FresnelRimColor("边缘光颜色", Color) = (1,1,1,1)
        [Sub(_FRESNELRIM)]_FresnelRimParams("x 宽度; y 平滑; z 强度; w 阴影遮罩范围", Vector) = (0.2, 0.2, 1, 0)
        
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // FresnelRim(战斗特效用)
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        [HideInInspector][Main(_FXFRESNELRIM, _FXFRESNELRIM)]_FXFresnelRim_ON("边缘光", Float) = 0
        [HideInInspector][HDR][Sub(_FXFRESNELRIM)]_FXFresnelRimColor("边缘光颜色", Color) = (1,1,1,1)
        [HideInInspector][Sub(_FXFRESNELRIM)]_FXFresnelRimParams("x 宽度; y 平滑; z 强度;", Vector) = (0.2, 0.2, 1, 0)

        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // HSV lighting
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        [Main(_HSVLighting)]_HSVLighting("自定义阴影颜色", Float) = 0
        [SubHeader(_HSVLighting, ShowColorMask)]
        [SubEnum(_HSVLighting,N,0,LightCol,2,LowSatCol,1,DarkCol,3)]_ShowLightColorMask("显示固有色遮罩",Float) = 0
        [Sub(_HSVLighting)]_lightColorThreshold("亮度区分阈值",Range(0, 1)) = 0
        [Sub(_HSVLighting)]_LowSaturationThreshold("饱和度区分阈值", Range(0, 0.5)) = 0
        
        [SubHeader(_HSVLighting, LowSatColor)]
        [Sub(_HSVLighting)][HDR]_LowSaturationFallbackColor("低饱和度区域颜色(对应遮罩LowSatCol", Color) = (0.4,0.4,0.4)
        [Sub(_HSVLighting)][HDR]_CelShadowOcclusionColorSV("AO颜色", Color) = (1,1,1)
        
        [SubHeader(_HSVLighting, LightColor)]
        [Sub(_HSVLighting)]_SelfShadowAreaHueOffset_light("亮色阴影色相 (对应遮罩LightCol", Range(-1,1)) = 0
        [Sub(_HSVLighting)]_SelfShadowAreaSaturationBoost_light("亮色阴影饱和度", Range(0,1)) = 0
        [Sub(_HSVLighting)]_SelfShadowAreaValueMul_light("亮色阴影亮度", Range(0,1)) = 0.5
        [Sub(_HSVLighting)][HDR]_SelfShadowTintColor_light("亮色阴影叠加颜色", Color) = (1,1,1)
        [Sub(_HSVLighting)][HDR]_CelShadowOcclusionColorV("AO颜色", Color) = (1,1,1)
        
        [SubHeader(_HSVLighting, DarkColor)]
        [Sub(_HSVLighting)]_SelfShadowAreaHueOffset_dark("暗色阴影色相 (对应遮罩DarkCol", Range(-1,1)) = 0
        [Sub(_HSVLighting)]_SelfShadowAreaSaturationBoost_dark("暗色阴影饱和度", Range(0,1)) = 0
        [Sub(_HSVLighting)]_SelfShadowAreaValueMul_dark("暗色阴影亮度", Range(0,1)) = 0.5
        [Sub(_HSVLighting)][HDR]_SelfShadowTintColor_dark("暗色阴影叠加颜色 ", Color) = (1,1,1)
        [Sub(_HSVLighting)][HDR]_CelShadowOcclusionColorD("AO颜色", Color) = (1,1,1)
        
        
        [SubHeader(_HSVLighting, Shadow RimLight)]
        [Sub(_HSVLighting)]_CelShadowReflectIntensity("阴影反光强度", Range(0,1)) = 0
        [Sub(_HSVLighting)]_CelShadowReflectIntensityLightMulty("亮色区域反光增强", Range(1,10)) = 1
        [Sub(_HSVLighting)]_CelShadowReflectWidthx("阴影反光范围", Range(0,1)) = 0
        [Sub(_HSVLighting)]_CelShadowReflectSmooth("阴影反光边缘柔和", Range(0,1)) = 0
        [Sub(_HSVLighting)][HDR]_CelShadowReflectColor("阴影反光色调", Color) = (0.5,0.7,1)
        
        
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Depth Texture Rim Light And Shadow
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//        [Main(_TOON_ENABLE_DEPTH_TEXTURE_RIMLIGHT_AND_SHADOW)]_TOON_ENABLE_DEPTH_TEXTURE_RIMLIGHT_AND_SHADOW("屏幕空间深度边缘光", Float) = 1
//        
//        [SubHeader(_TOON_ENABLE_DEPTH_TEXTURE_RIMLIGHT_AND_SHADOW, Fresnel RimLight)]
//        [SubNumToggle(_TOON_ENABLE_DEPTH_TEXTURE_RIMLIGHT_AND_SHADOW)]_useNoVRimLight("使用菲涅尔边缘光（默认关闭）",float) = 0
//        [Sub(_TOON_ENABLE_DEPTH_TEXTURE_RIMLIGHT_AND_SHADOW)]_FresnelPoint("菲涅尔边缘光宽度",Range(0,0.9)) = 0.2
//        [Sub(_TOON_ENABLE_DEPTH_TEXTURE_RIMLIGHT_AND_SHADOW)]_FresnelSoft("菲涅尔边缘光柔和",Range(0,1)) = 0.02
//        
//        [SubHeader(_TOON_ENABLE_DEPTH_TEXTURE_RIMLIGHT_AND_SHADOW, Depth Texture Rim Light and Shadow Shape)]
//        [Sub(_TOON_ENABLE_DEPTH_TEXTURE_RIMLIGHT_AND_SHADOW)]_DepthTexRimLightAndShadowWidthMultiplier("屏幕空间深度边缘光-阴影宽度乘子 (默认: 1)", Range(0,4)) = 0.5
//          
//
//        [SubHeader(_TOON_ENABLE_DEPTH_TEXTURE_RIMLIGHT_AND_SHADOW, Depth Texture Rim Light)]
//        [Sub(_TOON_ENABLE_DEPTH_TEXTURE_RIMLIGHT_AND_SHADOW)]_DepthTexRimLightUsage("屏幕深度边缘光强度 (默认: 0.5)", Range(0,1)) = 0.5       
//        [Sub(_TOON_ENABLE_DEPTH_TEXTURE_RIMLIGHT_AND_SHADOW)][HDR]_DepthTexRimLightTintColor("屏幕深度边缘光色调 (默认:白色)", Color) = (1,1,1)
//        [Sub(_TOON_ENABLE_DEPTH_TEXTURE_RIMLIGHT_AND_SHADOW)]_DepthTexRimFadeoutRange("屏幕空间深度边缘光渐变范围 (默认: 1)", Range(0.01,10)) = 0.01
//        [Sub(_TOON_ENABLE_DEPTH_TEXTURE_RIMLIGHT_AND_SHADOW)]_DepthTexRimThresholdOffset("屏幕深度边缘光阈值偏移 (默认: 0)", Range(-1,1)) = 0  
//
//        [SubHeader(_TOON_ENABLE_DEPTH_TEXTURE_RIMLIGHT_AND_SHADOW, Depth Texture Shadow)]
//        [HideInInspector][Sub(_TOON_ENABLE_DEPTH_TEXTURE_RIMLIGHT_AND_SHADOW)]_DepthTexShadowThresholdOffset("屏幕深度阴影阈值偏移 (默认: 0)",  Range(-1,1)) = 0
//        [HideInInspector][Sub(_TOON_ENABLE_DEPTH_TEXTURE_RIMLIGHT_AND_SHADOW)]_DepthTexShadowFadeoutRange("屏幕深度阴影渐变范围 (默认: 0.01)", Range(0.01,10)) = 0.01 
        
        
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Outline
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Group name added extra spaces to line up (Default XXX) in material GUI
        [Main(_RENDER_OUTLINE)]_RenderOutline("轮廓支持", Float) = 1
        
        [SubHeader(_RENDER_OUTLINE, Smooth outline Mode)]
        [SubNumToggle(_RENDER_OUTLINE)]_OutlineUseBakedSmoothNormal("使用平滑法线(Default On)", Float) = 1

        [SubHeader(_RENDER_OUTLINE, Color)]
        [Sub(_RENDER_OUTLINE)][HDR]_OutlineTintColor("描边叠加颜色 (默认 linear 0.25)", Color) = (0.4,0.4,0.4,1)
        [Sub(_RENDER_OUTLINE)][HDR]_OutlineEmissionCol("描边自发光", Color) = (0,0,0)
        [Sub(_RENDER_OUTLINE)][HDR]_OutlineReplace("描边色替换", Range(0,1)) = 0
        [Sub(_RENDER_OUTLINE)]_OutlinePixelWidth("描边宽度 (默认 1)", Range(0,32)) = 1
        [SubNumToggle(_RENDER_OUTLINE)]_useVertColorR("使用顶点色控制宽度", Float) = 1

        
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Specular
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Group name added extra spaces to line up (Default XXX) in material GUI
        [Main(_SPECULARHIGHLIGHTS,_SPECULARHIGHLIGHTS)]_UseSpecular("高光支持 (默认关闭)", Float) = 0

        [SubHeader(_SPECULARHIGHLIGHTS,Define GGX specular)]
        [SubToggle(_SPECULARHIGHLIGHTS, _)]_UseGGXDirectSpecular("使用GGX计算高光 (Default On)", Float) = 1
        [Sub(_SPECULARHIGHLIGHTS)]_GGXDirectSpecularSmoothnessMultiplier("GGX光滑度乘数 (Default 0.5)", Range(0,1.9)) = 0.5
        [Sub(_SPECULARHIGHLIGHTS)]_SpecularFadeDistance("高光在阴影消失距离(默认0.2)",Range(0,0.5)) = 0.1

        [SubHeader(_SPECULARHIGHLIGHTS,Define Specular Area)]
        [Sub(_SPECULARHIGHLIGHTS)]_SpecularIntensity("高光强度 (默认 1)", Range(0,20)) = 1
        [Sub(_SPECULARHIGHLIGHTS)]_MultiplyBaseColorToSpecularColor("颜色贴图影响程度 (Default 0)", Range(0,1)) = 0  
        [Sub(_SPECULARHIGHLIGHTS)][HDR]_SpecularColor("高光颜色 (默认 White)", Color) = (1,1,1) // URP Lit.shader use _SpecColor, we ignore it and use our own name to avoid confusion
        
        
        [SubHeader(_SPECULARHIGHLIGHTS,Define Specular Area Remap)]
        [Sub(_SPECULARHIGHLIGHTS)]_SpecularAreaRemapUsage("使用裁边 (Default 0)", Range(0,1)) = 0.0
        [Sub(_SPECULARHIGHLIGHTS)]_SpecularAreaRemapMidPoint("裁边位置 (Default 0.1)", Range(0,1)) = 0.1
        [Sub(_SPECULARHIGHLIGHTS)]_SpecularAreaRemapRange("边缘过渡 (Default 0.05)", Range(0,1)) = 0.05

        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Emission
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Group name added extra spaces to line up (Default XXX) in material GUI
        [Main(_EMISSION,_EMISSION)]_UseEmission("自发光支持(默认关闭)", Float) = 0 

        // SubHeader used as a note
        // TODO: turn this into a good looking infobox 
        [SubHelper(_EMISSION, Besides regular emission use case #You can also enable it for eye highlight and let bloom postprocess do the diffusion filter)] 
        [Sub(_EMISSION)][HDR]_EmissionColor("自发光颜色 (默认 White)", Color) = (1,1,1) // same as URP's Lit.shader

        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // VAT
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        [Main(_VAT_ON,_VAT_ON)] _VAT_ON("顶点动画", Float) = 0
        [SubNumToggle(_VAT_ON)] _offsetX("X方向偏移(上下)",float) = 0
        [SubNumToggle(_VAT_ON)] _offsetY("Y方向偏移(前后)",float) = 1
        [SubNumToggle(_VAT_ON)] _offsetZ("Z方向偏移(左右)",float) = 1

        [SubHeader(_VAT_ON, Sin Control)]
        //[SubNumToggle(_VAT_ON)] _usesin("使用sin控制动画",float) = 1
        [Sub(_VAT_ON)] _sinoffset("Sin偏移值", Range(-0.02, 0.02)) = 0.006  
        [Sub(_VAT_ON)] _sinpinlv("Sin频率", Range(1, 40)) = 20  
        [Sub(_VAT_ON)] _speedsin("Sin速度", Range(0.01, 1)) = 0.3        
        
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Dissolve by Height or by Distance
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        [Main(_DISSOLVE)]_DISSOLVE("方向溶解支持", Float) = 0
        [SubHeader(_DISSOLVE, Texture Control)]
        [Sub(_DISSOLVE)]_DissNoiseScale1("消融噪声强度1", Float) = 1
	    [Sub(_DISSOLVE)]_DissNoiseScale2("消融噪声强度2", Float) = 5
        [Sub(_DISSOLVE)]_DissSpeed1("消融噪声速度1",Float) = 0.5
	    [Sub(_DISSOLVE)]_DissSpeed2("消融噪声速度2", Float) = 2
        
        [SubHeader(_DISSOLVE, Progress Control)]
        [SubEnum(_DISSOLVE,N,0,X,1,Y,2,Z,3)]_DissDirect("消融方向",Float) = 0
        [SubNumToggle(_DISSOLVE)]_DissDirectInvert("消融方向反转", Float) = 0
        [Sub(_DISSOLVE)]_DissDirProgress ("消融进度", Range(0,1)) = 0
        [Sub(_DISSOLVE)]_DissClipWidth ("消融宽度", Float) = 5
        [Sub(_DISSOLVE)]_DissClipRemapMin ("消融进度0偏移", Float) = 0
        [Sub(_DISSOLVE)]_DissClipRemapMax ("消融进度1偏移", Float) = 0
        
        [SubHeader(_DISSOLVE, VertAnim)]
        [Sub(_DISSOLVE)]_DissAnimDelay ("顶点动画延迟", Float) = 2
        [Sub(_DISSOLVE)]_DissAnimPow ("顶点动画平滑", Range(0, 1)) = 0.3    
        [Sub(_DISSOLVE)]_DissAnimStren ("顶点位移强度", Float) = 2
        [Sub(_DISSOLVE)]_DissAnimNormalStren ("顶点散开强度", Float) = 1
        
        [SubHeader(_DISSOLVE, Edge)]
        [Sub(_DISSOLVE)][HDR]_DissDirEdgeColor ("消融边缘颜色 (默认:white)", Color) = (1, 1, 1, 1)

        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Dissolve by Height or by Distance
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		[Main(_DISSOLVE_STAGE, _DISSOLVE_STAGE)]_DISSOLVE_STAGE("二阶段溶解支持  (默认关闭)", Float) = 0
        [SubNumToggle(_DISSOLVE_STAGE)]_DISSOLVE_ON ("启用溶解效果", Float) = 0
        
        [SubHeader(_DISSOLVE_STAGE, Texture Control)]
        [SubEnum(_DISSOLVE_STAGE,ProcedureNoise,0,CustomTex,1)]_DissNoiseSelect("消融噪声选择",Float) = 0
        [Sub(_DISSOLVE_STAGE)]_DissNoiseScalex("程序噪声强度", Float) = 1
        [Sub(_DISSOLVE_STAGE)]_DissCustomTex(" 自定义贴图", 2D) = "White" {}
        [SubEnum(_DISSOLVE_STAGE,UV1,0,UV2,1,Position,2)]_DissNoiseUV("消融噪声UV",Float) = 2
        [Sub(_DISSOLVE_STAGE)]_DissSpeed("UV速度",Vector) = (0,0,0,0)
        
        [SubHeader(_DISSOLVE_STAGE, Progress Control)]
        [Sub(_DISSOLVE_STAGE)]_DissProgress ("消融进度", Range(0,1)) = 0
        [Sub(_DISSOLVE_STAGE)]_DissFirstStageEnd ("一阶段结束节点", Range(0,1)) = 0.5
        [Sub(_DISSOLVE_STAGE)]_DissSecondStageStart ("二阶段开始节点", Range(0,1)) = 0.5
        
        [SubHeader(_DISSOLVE_STAGE, Edge)]
        [Sub(_DISSOLVE_STAGE)]_DissEdgeWidthx("边缘宽度", Range(0,1)) = 0.1
        [Sub(_DISSOLVE_STAGE)]_DissEdgeSmooth("边缘软化", Range(0,1)) = 0
        [Sub(_DISSOLVE_STAGE)][HDR]_DissEdgeColor ("边缘颜色 (默认:white)", Color) = (1, 1, 1, 1)
        [Sub(_DISSOLVE_STAGE)]_DissEdgeBloomSten("发光强度", Float) = 1
        
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Energy Field
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        [Main(_EnergyField)] _EnergyField("能量气场", Float) = 0
        [Sub(_EnergyField)]_EFSize("气场大小", Float) = 0        // Filed Size and Color
        [Sub(_EnergyField)]_EFEdgeThreshold("颜色边界阀值", Range(0,1)) = 0.5
        [Sub(_EnergyField)]_EFEdgeSmooth("颜色边界平滑度", Range(0, 1)) = 0.1
        [SubNumToggle(_EnergyField)]_EFZWrite("深度写入", Float) = 0
        
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Flow Map
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        [Main(_FLOWMAP_ON, _FLOWMAP_ON)] _FLOWMAP_ON("法线流动", Float) = 0
		[Tex(_FLOWMAP_ON)][NoScaleOffset]_FlowMap("流动贴图", 2D) = "white" {}
        [Tex(_FLOWMAP_ON)][NoScaleOffset]_BumpMap("法线贴图", 2D) = "white" {}
        [Sub(_FLOWMAP_ON)]_BumpScale("法线强度", Float) = 1
		[Sub(_FLOWMAP_ON)]_FlowOffsetSpeed("法线流动速度(x:X方向偏移值 y:Y方向偏移值 z:流动速度)", Vector) = (0,0,0,0)
        [SubNumToggle(_FLOWMAP_ON)]_applyColorFlow("开启颜色流动", Float) = 1
        [Sub(_FLOWMAP_ON)]_ColorFlowOffsetSpeed("颜色流动速度(x:X方向偏移值 y:Y方向偏移值 z:流动速度)", Vector) = (0,0,0,0)
        [SubNumToggle(_FLOWMAP_ON)]_applyVertFlow("开启顶点流动", Float) = 1
        [SubNumToggle(_FLOWMAP_ON)]_useVertColB("使用顶点色G遮罩", Float) = 1
        [Sub(_FLOWMAP_ON)]_VertFlowTex("顶点贴图", 2D) = "white" {}
        [SubNumToggle(_FLOWMAP_ON)]_showFlowVert("显示顶点动画", Float) = 0
        [Sub(_FLOWMAP_ON)]_FlowVert(" 顶点流动速度(x:X方向偏移值 y:Y方向偏移值 z:流动速度 w:顶点偏移值)", Vector) = (0,0,0,0)
        
        
        
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // FresnelRamp
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        [Main(_FRESNELRAMP, _FRESNELRAMP)]_FRESNELRAMP_ON("菲涅尔渐变", Float) = 0
        [Tex(_FRESNELRAMP)][NoScaleOffset]_FresnelRampTex("Ramp", 2d) =  "white" {}
        [SubNumToggle(_FRESNELRAMP)]_FresnelRampInvert("Ramp反向", Float) = 0
        [Sub(_FRESNELRAMP)]_FresnelRampParams("Fresnel：xy ramp; zw lerp", Vector) = (0, 1, 0, 1)
        [Tex(_FRESNELRAMP)][NoScaleOffset]_FresnelRampNoise("Noise", 2d) =  "white" {}
        [Sub(_FRESNELRAMP)]_FresnelNoiseUV("Noise：xy uv速度; z scale; w 强度", Vector) = (0, 0, 1, 0)
        
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        //AlphaOverride
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
        [Main(_RenderType)] _RenderType("材质渲染设置", Float) = 0
        [Surface(_RenderType,_Blend,_SrcBlend,_DstBlend,_CharacterZWrite)] _RenderType_PARAM("渲染状态", Float) = 0
        [HideInInspector]_Blend("Blend", Float) = 0
        [SubEnum(_RenderType,RGBA,15,RGB,14)]_ColorWriteMask("ColorMask写入",Float) = 15
        
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Alpha Clipping
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Group name added extra spaces to line up (Default XXX) in material GUI 
        [HideInInspector][Main(_ALPHATEST_ON,_ALPHATEST_ON)]_AlphaClip("透贴支持 ", Float) = 0
        [HideInInspector]_Cutoff("_Cutoff (Default 0.5)", Range(0.0, 1.0)) = 0.01

        
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Set by script
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // everything inside your CBUFFER_START(UnityPerMaterial) must exist in this Properties{} section in order to make SRP batcher works
        // even properties that are only set by script and [HideInInspector]!
        // You can try comment out any line here and reimport the shader,
        // doing this will make SRP batching fail, you can check it by viewing .shader in the inspector

        //dither
        [HideInInspector]_DitherFadeoutAmount("_DitherFadeoutAmount", Range(0,1)) = 0
        [HideInInspector]_DITHERFADEOUT_ON("_DITHERFADEOUT_ON", Float) = 0

        // average shadow mapping
        [HideInInspector]_AverageShadowMapRTSampleIndex("_AverageShadowMapRTSampleIndex", Float) = -1
        
        // face
        [HideInInspector]_FaceForwardDirection("_FaceForwardDirection", Vector) = (0,1,0)
        [HideInInspector]_FixFaceNormalAmount("_FixFaceNormalAmount", Range(0,1)) = 1
        [HideInInspector]_FaceUpDirection("_FaceUpDirection", Vector) = (0,1,0)
        
        // per char
        [HideInInspector]_CharacterHeight("消融高度", Float) = 2
        [HideInInspector]_PovitPosWS("根节点坐标", Vector) = (0,0,0,0)
        [HideInInspector]_PovitPosWSForward("根节点坐标", Vector) = (0,0,0,0)
        [HideInInspector]_PovitPosWSUp("根节点坐标", Vector) = (0,0,0,0)
        [HideInInspector]_PovitPosOffset("模型根位置偏移", Vector) = (0,0,0,0)
        [HideInInspector]_CharacterBoundCenterPosWS("_CharacterBoundCenterPosWS", Vector) = (0,0,0)
        
        // perspective removal
        [HideInInspector]_PerspectiveRemovalAmount("_PerspectiveRemovalAmount", Range(0,1)) = 0
        [HideInInspector]_PerspectiveRemovalRadius("_PerspectiveRemovalRadius", Float) = 1
        [HideInInspector]_HeadBonePositionWS("_HeadBonePositionWS", Vector) = (0,0,0)

        
        [HideInInspector]_CameraLightPosWS("_characterLightPos",Vector) = (1,0,0)
        [HideInInspector]_CameraLightPosVS("_characterLightPosVS",Vector) = (1,0,0)
        [HideInInspector]_UseCameraLight("_UseCameraLight",Float) = 0
        [HideInInspector]LOADING_DEPTH_ON("LOADING_DEPTH_ON",Float) = 1
        [HideInInspector]_DISSOLVE_ON("方向溶解支持", Float) = 0
        [HideInInspector]_DISSOLVEE_ON("方向溶解支持", Float) = 0


        
    }
    SubShader
    {       
        Tags 
        {
            // SRP introduced a new "RenderPipeline" tag in Subshader. This allows you to create shaders
            // that can match multiple render pipelines. If a RenderPipeline tag is not set it will match
            // any render pipeline. In case you want your SubShader to only run in URP, set the tag to
            // "UniversalPipeline"

            // here "UniversalPipeline" tag is written because we only want this shader to run in URP.
            // If Universal render pipeline is not set in the graphics settings, this SubShader will fail.

            // One can add a SubShader below or fallback to Standard built-in to make this
            // material work with both Universal Render Pipeline and Builtin Unity Pipeline

            // the tag value is "UniversalPipeline", not "UniversalRenderPipeline", be careful!
            // see -> https://github.com/Unity-Technologies/Graphics/pull/1431/
            "RenderPipeline" = "UniversalPipeline"

            // [need ShaderModel 4.5 because of SRP-batcher]
            // URP's Lit.shader also require ShaderModel 4.5
            // ShaderModel 4.5 = OpenGL ES 3.1 capabilities (DX11 SM5.0 on D3D platforms, just without tessellation shaders)
            // Not supported on DX11 before SM5.0, OpenGL before 4.3 (i.e. Mac), OpenGL ES 2.0/3.0.
            // Supported on DX11+ SM5.0, OpenGL 4.3+, OpenGL ES 3.1, Metal, Vulkan, PS4/XB1 consoles.
            // Has compute shaders, random access texture writes, atomics and so on. No geometry or tessellation shaders.
            // https://docs.unity3d.com/Manual/SL-ShaderCompileTargets.html
            "ShaderModel"="4.5" 

            // explicit SubShader tag to avoid confusion
            "RenderType"="Opaque"
            "UniversalMaterialType" = "Lit"
            "IgnoreProjector" = "True"
            "Queue"="Geometry"
        }

        

        // No LOD defined
        //LOD 300
    
        // We can extract duplicated hlsl code from all passes into this HLSLINCLUDE section. Less duplicated code = Less error
        HLSLINCLUDE

        // overdraw检测，打包阶段会剔除对应变体
        #pragma multi_compile_fragment _ DEBUG_DISPLAY
        
        #pragma multi_compile_local _ _DISSOLVE_STAGE
        

        ENDHLSL

        // [#0 Pass - ForwardLit]
        // Shades GI, all lights, emission, and fog in a single pass.
        // Compared to the Builtin pipeline forward renderer, URP forward renderer will
        // render a scene with multiple lights(additional light) with fewer draw calls and less overdraw.
        Pass
        {               
            Name "ForwardLit"
            Tags
            {
                // "Lightmode" matches the "ShaderPassName" set in UniversalRenderPipeline.cs. 
                // SRPDefaultUnlit and passes with no LightMode tag are also rendered by Universal Render Pipeline

                // In this pass, 
                // "Lightmode" tag must be "UniversalForward" in order to render lit objects by URP's ForwardRenderer by default.
                "LightMode" = "UniversalForward"
                
            }

           // render state
            Cull [_Cull]
            ZTest [_ZTestComp] // early exit at Early-Z stage if possible (possible if _AlphaClip is off)            
            ZWrite [_ZWrite]
            Blend [_SrcBlend] [_DstBlend]
            ColorMask [_ColorWriteMask]
            // write the value [_ExtraThickOutlineStencilID] whenever the depth test passes. The stencil test is set to always pass.
            // the stencil write value will be used by extra thick outline pass later
            // https://docs.unity3d.com/Manual/SL-Stencil.html
            Stencil 
            {
                Ref [_StencilRef]
                Comp [_ForwardStencilComp] // passing depth test = passing stencil
                Pass [_ForwardStencilOp] // replace means write
            }

            HLSLPROGRAM

            //#pragma exclude_renderers ... // no need to exclude renderers, all platforms will run the same Pass
            #pragma target 4.5 // need ShaderModel 4.5 (= OpenGL ES 3.1 capabilities) because of SRP-batcher

            //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            // Our Material Keywords (try to match URP's material keywords)
            //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            #pragma shader_feature_local _FLOWMAP_ON // need tangentWS from vertex shader also, so shader_feature_local_fragment is not enough
            #pragma shader_feature_local_fragment _FRESNELRAMP
            
            #pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS // URP Lit.shader use _SPECULARHIGHLIGHTS_OFF, here we use a inverted keyword
            #pragma shader_feature_local _ISFACE
            #pragma shader_feature_local _RAMP_LIGHTING
            
            // #pragma multi_compile _TOON_ADDITIONAL_LIGHTS // multi_compile_vertex is not enough, because we still need to apply vertex light result in frag
            #define _TOON_ADDITIONAL_LIGHTS 1
            // #pragma multi_compile_fragment _ _MAIN_LIGHT_SHADOWS_CASCADE
            #define _MAIN_LIGHT_SHADOWS_CASCADE 1
            
            #define FOG_HEIGHT_PASS_APPLY 1
            #define FOG_LINEAR 1
            
            #define _TOON_RECEIVE_SELF_SHADOW 1
            #pragma multi_compile _ _DITHER_FADEOUT
            #define _DISSOLVE 1
            
            #define _DISSOLVE_BRANCH 1
            
            #pragma vertex VertexShaderAllWork
            #pragma fragment FragmentShaderAllWork

            // because this pass is just a ForwardLit pass
            // define "ToonForwardLitPass" to inject code into VertexShaderAllWork()
            #define ToonForwardLitPass 1
            #define TRANPARENTBLOOM 0
            // all shader logic written inside this .hlsl, remember to write all #define BEFORE writing #include
            #include "Packages/com.xinyuan.rendering/Shaders/ToonCharacter_HLSL/ToonCharacter_Shared.hlsl"

            ENDHLSL
        }

        // [#1 Pass - Outline]
        // Same as the above "ForwardLit" pass, but 
        // -vertex position are pushed(extrude) out a bit base on lighting normal / smoothed normal direction
        // -also color is tinted
        // -Cull Front instead of Cull Back because Cull Front is a must for all extrude mesh outline method
        Pass 
        {
            Name "Outline"
            Tags 
            {
                "LightMode" = "NiloToonOutline" // here we set "NiloToonOutline" as custom pass's "LightMode" value, but it can be any string, just pick one you like
            }

            // TODO: we should find a way to flip Cull from the first pass, instead of hardcode "Cull Front"
            Cull Front // Cull Front is a must for the extra pass extrude mesh outline method. 
            ZTest [_ZTestComp] // early exit at Early-Z stage if possible (possible if _AlphaClip is off)            
            ZWrite [_ZWrite]
            Blend [_SrcBlend] [_DstBlend]
            ColorMask [_ColorWriteMask]
           
            Stencil 
            {
                Ref [_StencilRef]
                Comp [_OutlineStencilComp] // passing depth test = passing stencil
                Pass [_OutlineStencilOp] // replace means write
            }
            
            HLSLPROGRAM

            //#pragma exclude_renderers ... // no need to exclude renderers, all platforms will run the same Pass
            #pragma target 4.5 // need ShaderModel 4.5 (= OpenGL ES 3.1 capabilities) because of SRP-batcher
            
            
            #pragma shader_feature_local _FLOWMAP_ON
            #pragma multi_compile _ _DITHER_FADEOUT
            #define _DISSOLVE 1
            #define _DISSOLVE_BRANCH 1
            #define FOG_HEIGHT_PASS_APPLY 1
            #define FOG_LINEAR 1

            #pragma vertex VertexShaderAllWork
            #pragma fragment FragmentShaderAllWork

            #define ToonSelfOutlinePass 1

            // all shader logic written inside this .hlsl, remember to write all #define BEFORE writing #include
            #include "Packages/com.xinyuan.rendering/Shaders/ToonCharacter_HLSL/ToonCharacter_Shared.hlsl"


            ENDHLSL
        }

        // DepthOnly pass. Used for rendering URP's offscreen depth prepass (you can search DepthOnlyPass.cs in URP package)
        // When URP's depth texture is on, and if CopyDepthPass is not possible due to MSAA for example, 
        // URP will perform this offscreen depth prepass for this toon shader to draw depth into _CameraDepthTexture
        
        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            // more explicit render state to avoid confusion
            ZWrite On // the only goal of this pass is to write depth!
            ZTest LEqual // early exit at Early-Z stage if possible (possible if _AlphaClip is off)            
            ColorMask 0 // we don't care about color, we just want to write depth, ColorMask 0 will save some write bandwidth
            Cull [_Cull]
            
            HLSLPROGRAM
            //#pragma exclude_renderers ... // no need to exclude renderers, all platforms will run the same Pass
            #pragma target 4.5 // need ShaderModel 4.5 (= OpenGL ES 3.1 capabilities) because of SRP-batcher
            
            // #pragma shader_feature_local _FLOWMAP_ON
            // #pragma multi_compile_local _DITHER_FADEOUT
            // #pragma multi_compile_local _DISSOLVE 
            // #define _DITHER_FADEOUT_BRANCH 1
            // #define _DISSOLVE_BRANCH 1
            
            #pragma vertex VertexShaderAllWork
            #pragma fragment BaseColorAlphaClipTest // we only need to do Clip(), no need color shading
            
            #define ToonDepthOnlyOrDepthNormalPass 1

            #include "Packages/com.xinyuan.rendering/Shaders/ToonCharacter_HLSL/ToonCharacter_Shared.hlsl"
              
            
            ENDHLSL
            
        }
        
    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "XYRendering.Editor.XYRendingBaseGUI" 
}
