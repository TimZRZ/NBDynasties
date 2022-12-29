using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public struct Province
{
    public string id;
    public string name;
    public Color32 color;

    public Province(string[] rawData)
    {
        this.id = rawData[0];
        this.name = rawData[1];
        Color32 newColor = new Color32(
            (byte)Int32.Parse(rawData[3]),
            (byte)Int32.Parse(rawData[4]),
            (byte)Int32.Parse(rawData[5]),
            (byte)Int32.Parse(rawData[6]));
        this.color = newColor;
    }
}

public class MapShower : MonoBehaviour
{
    public GameEvent onProvinceUpdated; 

    int width;
    int height;

    Dictionary<Color32, Province> mapData = new Dictionary<Color32, Province>();
    Dictionary<Color32, Color32> colorDict = new Dictionary<Color32, Color32>();

    Color32[] remapTexArr;
    Texture2D paletteTex;

    bool selected;
    Color32 prevColor;

    // Start is called before the first frame update
    void Start()
    {
        ReadMapData();

        var material = GetComponent<Renderer>().material;
        Texture2D mainTex = material.GetTexture("_MainTex") as Texture2D;
        var mainTexArr = mainTex.GetPixels32();

        width = mainTex.width;
        height = mainTex.height;

        var remapColorDict = new Dictionary<Color32, Color32>();
        int idx = 0;
        remapTexArr = new Color32[mainTexArr.Length];
        for (int i = 0; i < mainTexArr.Length; i++)
        {
            var mainColor = mainTexArr[i];
            if (!remapColorDict.ContainsKey(mainColor))
            {
                var low = (byte)(idx % 256);
                var high = (byte)(idx / 256);
                Color32 newColor = new Color32(low, high, 0, 255);

                remapColorDict[mainColor] = newColor;

                // Store reference from remapped color to origin color.
                colorDict[newColor] = mainColor;

                idx++;
            }
            var remapColor = remapColorDict[mainColor];

            remapTexArr[i] = remapColor;
        }

        print(idx + " " + mainTexArr.Length);

        var paletteTexArr = new Color32[256 * 256];
        for (int i = 0; i < paletteTexArr.Length; i++)
        {
            paletteTexArr[i] = new Color32(255, 255, 255, 255);
        }

        var remapTex = new Texture2D(width, height, TextureFormat.RGBA32, false);
        remapTex.filterMode = FilterMode.Point;
        remapTex.SetPixels32(remapTexArr);
        remapTex.Apply(false);
        material.SetTexture("_RemapTex", remapTex);

        paletteTex = new Texture2D(256, 256, TextureFormat.RGBA32, false);
        paletteTex.filterMode = FilterMode.Point;
        paletteTex.SetPixels32(paletteTexArr);
        paletteTex.Apply(false);
        material.SetTexture("_PaletteTex", paletteTex);
    }

    // Update is called once per frame
    void Update()
    {
        var mousePos = Input.mousePosition;
        var ray = Camera.main.ScreenPointToRay(mousePos);
        RaycastHit hitInfo;
        if (Physics.Raycast(ray, out hitInfo))
        {
            var p = hitInfo.point;
            int scale = (int)(width / GetComponent<MeshGenerator>().numX / GetComponent<MeshGenerator>().tileSize);
            int x = (int)Mathf.Floor(p.x) * scale;
            int y = (int)Mathf.Floor(p.y) * scale + height;

            var remapColor = remapTexArr[x + y * width];

            if (!selected || !prevColor.Equals(remapColor))
            {
                if (selected)
                {
                    updateColor(prevColor, new Color32(255, 255, 255, 255));
                }
                selected = true;
                prevColor = remapColor;
                updateColor(remapColor, new Color32(255, 200, 0, 255));
                paletteTex.Apply(false);
                
                if (colorDict.ContainsKey(remapColor) && mapData.ContainsKey(colorDict[remapColor]))
                {
                    Province provinceData = mapData[colorDict[remapColor]];
                    onProvinceUpdated.Raise(this, provinceData.name);
                }
            }
        }
    }

    void ReadMapData()
    {
        var data = Resources.Load<TextAsset>("Data/MapColorData");
        var lines = data.text.Split('\n');

        for (int i = 1; i < lines.Length; i++)
        {
            var datum = lines[i].Split(',');
            Province province = new Province(datum);
            mapData[province.color] = province;
        }
    }

    void updateColor(Color32 remapColor, Color32 color)
    {
        int xp = remapColor[0];
        int yp = remapColor[1];

        paletteTex.SetPixel(xp, yp, color);
    }

}
