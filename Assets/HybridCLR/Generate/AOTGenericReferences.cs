using System.Collections.Generic;
public class AOTGenericReferences : UnityEngine.MonoBehaviour
{

    // {{ AOT assemblies
    public static readonly IReadOnlyList<string> PatchedAOTAssemblyList = new List<string>
    {
        "UnityEngine.AssetBundleModule.dll",
        "UnityEngine.CoreModule.dll",
        "mscorlib.dll",
    };
    // }}

    // {{ constraint implement type
    // }} 

    // {{ AOT generic types
    // System.ByReference<ushort>
    // System.Collections.Generic.Dictionary.Enumerator<int,object>
    // System.Collections.Generic.Dictionary.Enumerator<object,object>
    // System.Collections.Generic.Dictionary.KeyCollection.Enumerator<int,object>
    // System.Collections.Generic.Dictionary.KeyCollection.Enumerator<object,object>
    // System.Collections.Generic.Dictionary.KeyCollection<int,object>
    // System.Collections.Generic.Dictionary.KeyCollection<object,object>
    // System.Collections.Generic.Dictionary.ValueCollection.Enumerator<int,object>
    // System.Collections.Generic.Dictionary.ValueCollection.Enumerator<object,object>
    // System.Collections.Generic.Dictionary.ValueCollection<int,object>
    // System.Collections.Generic.Dictionary.ValueCollection<object,object>
    // System.Collections.Generic.Dictionary<int,object>
    // System.Collections.Generic.Dictionary<object,object>
    // System.Collections.Generic.EqualityComparer<int>
    // System.Collections.Generic.EqualityComparer<object>
    // System.Collections.Generic.ICollection<System.Collections.Generic.KeyValuePair<int,object>>
    // System.Collections.Generic.ICollection<System.Collections.Generic.KeyValuePair<object,object>>
    // System.Collections.Generic.IEnumerable<System.Collections.Generic.KeyValuePair<int,object>>
    // System.Collections.Generic.IEnumerable<System.Collections.Generic.KeyValuePair<object,object>>
    // System.Collections.Generic.IEnumerator<System.Collections.Generic.KeyValuePair<int,object>>
    // System.Collections.Generic.IEnumerator<System.Collections.Generic.KeyValuePair<object,object>>
    // System.Collections.Generic.IEnumerator<object>
    // System.Collections.Generic.IEqualityComparer<int>
    // System.Collections.Generic.IEqualityComparer<object>
    // System.Collections.Generic.KeyValuePair<int,object>
    // System.Collections.Generic.KeyValuePair<object,object>
    // System.Collections.Generic.ObjectEqualityComparer<int>
    // System.Collections.Generic.ObjectEqualityComparer<object>
    // System.ReadOnlySpan<ushort>
    // System.Span<ushort>
    // }}

    public void RefMethods()
    {
        // object& System.Runtime.CompilerServices.Unsafe.As<object,object>(object&)
        // System.Void* System.Runtime.CompilerServices.Unsafe.AsPointer<object>(object&)
        // object UnityEngine.AssetBundle.LoadAsset<object>(string)
        // object UnityEngine.Component.GetComponent<object>()
        // object UnityEngine.Component.GetComponentInChildren<object>()
        // object[] UnityEngine.Component.GetComponentsInChildren<object>(bool)
        // object UnityEngine.GameObject.AddComponent<object>()
        // object[] UnityEngine.GameObject.GetComponentsInChildren<object>(bool)
        // object UnityEngine.Object.Instantiate<object>(object)
    }
}
