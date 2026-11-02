using UnityEngine;

public class TopDownCamera : MonoBehaviour
{
    public Transform target;
    public Vector3 offset = new Vector3(0f, 16f, -8f);
    public float smooth = 8f;

    void LateUpdate()
    {
        if (target == null) return;

        var targetPos = target.position + offset;
        transform.position = Vector3.Lerp(transform.position, targetPos, 1f - Mathf.Exp(-smooth * Time.deltaTime));
        transform.rotation = Quaternion.LookRotation(-offset);
    }
}
