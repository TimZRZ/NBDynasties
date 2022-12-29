using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;

public class CanvasUI : MonoBehaviour
{
    public TextMeshProUGUI provinceName;

    public void ProvinceNameUpdate(Component sender, object data)
    {
        provinceName.SetText(data.ToString());
    }
}
