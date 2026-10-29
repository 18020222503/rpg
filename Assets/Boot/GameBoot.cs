using UnityEngine;

public class GameBoot : MonoBehaviour
{
    void Start()
    {
        LoadDll.Instance.Load();
    }

}
