using UnityEngine;
using UnityEngine.InputSystem;

namespace Ported
{
    // 俯视跟随相机：从斜上方看角色，按住鼠标右键或 Q/E 转动视角，滚轮缩放。
    // 角度、距离都是公开字段，播放时可以在 Inspector 里直接调
    public class PortedFollowCamera : MonoBehaviour
    {
        public Transform target;
        [Tooltip("相机离注视点的距离（米）")]
        public float distance = 14f;
        public float minDistance = 6f;
        public float maxDistance = 30f;
        [Tooltip("注视点在角色脚底上方多高")]
        public float height = 1f;
        [Tooltip("俯角，0 是平视，90 是正上方往下看")]
        public float pitch = 55f;
        public float minPitch = 25f;
        public float maxPitch = 85f;
        public float yaw;
        public float smooth = 10f;

        bool placed;

        void LateUpdate()
        {
            if (target == null) return;

            var kb = Keyboard.current;
            var mouse = Mouse.current;
            if (kb != null)
            {
                if (kb.qKey.isPressed) yaw -= 90f * Time.deltaTime;
                if (kb.eKey.isPressed) yaw += 90f * Time.deltaTime;
            }

            if (mouse != null)
            {
                if (mouse.rightButton.isPressed)
                {
                    var d = mouse.delta.ReadValue();
                    yaw += d.x * 0.15f;
                    pitch = Mathf.Clamp(pitch - d.y * 0.15f, minPitch, maxPitch);
                }

                var scroll = mouse.scroll.ReadValue().y;
                if (Mathf.Abs(scroll) > 0.01f) distance *= scroll > 0 ? 0.9f : 1.1f;
            }
            distance = Mathf.Clamp(distance, minDistance, maxDistance);
            pitch = Mathf.Clamp(pitch, minPitch, maxPitch);

            Pose(target.position, out var wantedPos, out var wantedRot);

            // 第一帧直接摆好，不从别处飞过来
            if (!placed)
            {
                transform.SetPositionAndRotation(wantedPos, wantedRot);
                placed = true;
                return;
            }

            var k = 1f - Mathf.Exp(-smooth * Time.deltaTime);
            transform.position = Vector3.Lerp(transform.position, wantedPos, k);
            transform.rotation = Quaternion.LookRotation(target.position + Vector3.up * height - transform.position);
        }

        // 给定角色脚底位置，算出相机该在哪、朝哪看（编辑器截图也用这个）
        public void Pose(Vector3 targetPosition, out Vector3 position, out Quaternion rotation)
        {
            var focus = targetPosition + Vector3.up * height;
            rotation = Quaternion.Euler(pitch, yaw, 0f);
            position = focus - rotation * Vector3.forward * distance;
        }
    }
}
