using System;
using System.Linq;
using UnityEditor;
using UnityEditor.Animations;
using UnityEngine;

public static class PlayerAnimatorBuilder
{
    const string GeneralFbx = "Assets/Artist/Adventurers/Animations/Rig_Medium_General.fbx";
    const string MovementFbx = "Assets/Artist/Adventurers/Animations/Rig_Medium_MovementBasic.fbx";
    public const string ControllerPath = "Assets/Artist/Adventurers/Player.controller";

    // 速度超过这个值就算在移动，PlayerController 往 Speed 参数里写的是米/秒
    const float MoveThreshold = 0.1f;

    [MenuItem("Tools/Dungeon/RebuildPlayerAnimator")]
    public static void Rebuild()
    {
        AssetDatabase.DeleteAsset(ControllerPath);
        GetOrCreate();
    }

    public static AnimatorController GetOrCreate()
    {
        var existing = AssetDatabase.LoadAssetAtPath<AnimatorController>(ControllerPath);
        if (existing != null) return existing;

        // 片段默认不循环，先打开待机和奔跑的循环
        SetLoop(GeneralFbx, "Idle_A");
        SetLoop(MovementFbx, "Running_A");

        var idleClip = FindClip(GeneralFbx, "Idle_A");
        var runClip = FindClip(MovementFbx, "Running_A");
        if (idleClip == null || runClip == null)
        {
            Debug.LogError("[Dungeon] 找不到 Idle_A 或 Running_A，请确认 Assets/Artist/Adventurers/Animations 已导入完成");
            return null;
        }

        var controller = AnimatorController.CreateAnimatorControllerAtPath(ControllerPath);
        controller.AddParameter("Speed", AnimatorControllerParameterType.Float);

        var sm = controller.layers[0].stateMachine;
        var idle = sm.AddState("Idle");
        idle.motion = idleClip;
        var run = sm.AddState("Run");
        run.motion = runClip;
        sm.defaultState = idle;

        var toRun = idle.AddTransition(run);
        toRun.hasExitTime = false;
        toRun.duration = 0.15f;
        toRun.AddCondition(AnimatorConditionMode.Greater, MoveThreshold, "Speed");

        var toIdle = run.AddTransition(idle);
        toIdle.hasExitTime = false;
        toIdle.duration = 0.15f;
        toIdle.AddCondition(AnimatorConditionMode.Less, MoveThreshold, "Speed");

        EditorUtility.SetDirty(controller);
        AssetDatabase.SaveAssets();
        Debug.Log($"[Dungeon] Animator Controller 已生成：{ControllerPath}");
        return controller;
    }

    static AnimationClip FindClip(string fbxPath, string clipName)
    {
        var clips = AssetDatabase.LoadAllAssetsAtPath(fbxPath)
            .OfType<AnimationClip>()
            .Where(c => !c.name.StartsWith("__preview__"))
            .ToArray();

        // 片段名可能带前缀，例如 "Rig_Medium_General|Idle_A"
        return clips.FirstOrDefault(c => c.name == clipName)
               ?? clips.FirstOrDefault(c => c.name.EndsWith("|" + clipName));
    }

    static void SetLoop(string fbxPath, string clipName)
    {
        var importer = AssetImporter.GetAtPath(fbxPath) as ModelImporter;
        if (importer == null) return;

        var clips = importer.clipAnimations;
        if (clips == null || clips.Length == 0) clips = importer.defaultClipAnimations;

        var changed = false;
        foreach (var c in clips)
        {
            var match = c.name == clipName || c.name.EndsWith("|" + clipName, StringComparison.Ordinal);
            if (match && !c.loopTime)
            {
                c.loopTime = true;
                changed = true;
            }
        }

        if (!changed) return;

        importer.clipAnimations = clips;
        importer.SaveAndReimport();
    }
}
