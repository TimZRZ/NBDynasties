using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class Toggle_Terrain : MonoBehaviour
{
    public Toggle toggle;

    // Start is called before the first frame update
    void Start()
    {
        toggle.onValueChanged.AddListener(delegate
            {
                toggleValueChanged(toggle);
            }
        );
    }

    void toggleValueChanged(Toggle toggle)
    {
        var material = GetComponent<Renderer>().material;
        material.SetInt("_ShowTerrain", toggle.isOn == true? 1 : 0);
    }
}
