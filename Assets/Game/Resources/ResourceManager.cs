using UnityEngine;

public class ResourceManager
{

    private ResourceManager instance;
    public ResourceManager Instance
    {
        get
        {
            if (instance == null)
            {
                return instance = new ResourceManager();
            }
            return instance;
        }
    }
    
    public void Init()
    {
        
    }


    public void Load()
    {
        
    }
}
