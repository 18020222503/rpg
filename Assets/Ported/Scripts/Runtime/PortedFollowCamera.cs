using UnityEngine;
using UnityEngine.InputSystem;

namespace Ported
{
    // 第三人称跟随相机：按住鼠标右键或 Q/E 转动视角，滚轮缩放
    public class PortedFollowCamera : MonoBehaviour
    {
        public Transform target;
        public float distance = 6f;
        public float height = 1.6f;
        public float pitch = 18f;
        public float yaw;
        public float smooth = 10f;

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
                    pitch = Mathf.Clamp(pitch - d.y * 0.15f, -5f, 70f);
                }

                var scroll = mouse.scroll.ReadValue().y;
                if (Mathf.Abs(scroll) > 0.01f) distance = Mathf.Clamp(distance - Mathf.Sign(scroll) * 0.6f, 2.5f, 14f);
            }

            var focus = target.position + Vector3.up * height;
            var rot = Quaternion.Euler(pitch, yaw, 0f);
            var wanted = focus - rot * Vector3.forward * distance;

            var k = 1f - Mathf.Exp(-smooth * Time.deltaTime);
            transform.position = Vector3.Lerp(transform.position, wanted, k);
            transform.rotation = Quaternion.LookRotation(focus - transform.position);
        }
    }
}
