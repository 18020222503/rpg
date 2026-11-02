using UnityEngine;
using UnityEngine.InputSystem;

[RequireComponent(typeof(CharacterController))]
public class PlayerController : MonoBehaviour
{
    public float moveSpeed = 6f;
    public float turnSpeed = 15f;

    const float Gravity = -20f;

    static readonly int SpeedHash = Animator.StringToHash("Speed");

    CharacterController controller;
    Animator animator;
    float verticalSpeed;

    void Awake()
    {
        controller = GetComponent<CharacterController>();
        animator = GetComponentInChildren<Animator>();
        // 位移由 CharacterController 负责，不用动画里的根运动
        if (animator != null) animator.applyRootMotion = false;
    }

    void Update()
    {
        var move = ReadMoveInput();

        if (move.sqrMagnitude > 0.01f)
        {
            var targetRot = Quaternion.LookRotation(move);
            transform.rotation = Quaternion.Slerp(transform.rotation, targetRot, turnSpeed * Time.deltaTime);
        }

        verticalSpeed = controller.isGrounded ? -1f : verticalSpeed + Gravity * Time.deltaTime;

        var velocity = move * moveSpeed;
        velocity.y = verticalSpeed;
        controller.Move(velocity * Time.deltaTime);

        // 水平速度（米/秒），Animator 用它在待机和奔跑之间切换
        if (animator != null) animator.SetFloat(SpeedHash, move.magnitude * moveSpeed, 0.1f, Time.deltaTime);
    }

    // 俯视角相机朝向世界+Z，所以WASD直接对应世界坐标轴
    static Vector3 ReadMoveInput()
    {
        var kb = Keyboard.current;
        if (kb == null) return Vector3.zero;

        var dir = Vector3.zero;
        if (kb.wKey.isPressed || kb.upArrowKey.isPressed) dir.z += 1f;
        if (kb.sKey.isPressed || kb.downArrowKey.isPressed) dir.z -= 1f;
        if (kb.dKey.isPressed || kb.rightArrowKey.isPressed) dir.x += 1f;
        if (kb.aKey.isPressed || kb.leftArrowKey.isPressed) dir.x -= 1f;
        return dir.normalized;
    }
}
