using UnityEngine;

public class TopDownCamera : MonoBehaviour
{
    public Transform target;
    public Vector3 offset = new Vector3(0f, 22f, -11f);
    public float smooth = 8f;

    void LateUpdate()
    {
        if (target == null) return;

        var targetPos = target.position + offset;
        // 位置和朝向用同一个系数平滑，从总览镜头切过来时不会突然转向
        var k = 1f - Mathf.Exp(-smooth * Time.deltaTime);
        transform.position = Vector3.Lerp(transform.position, targetPos, k);
        transform.rotation = Quaternion.Slerp(transform.rotation, Quaternion.LookRotation(-offset), k);
    }
}
