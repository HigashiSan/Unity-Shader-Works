using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[RequireComponent(typeof(Camera))]
[ExecuteInEditMode]
public class CamGrab : MonoBehaviour 
{
    public Shader nightVisionShader;

    [Range(0,2)] public float _Distortion = 0.5f;
    [Range(0.01f, 1)] public float _Scale = 0.5f;
    [Range(0, 3f)] public float _Brightness = 1.0f;
    [Range(0, 2)] public float _Saturation = 1;
    [Range(0, 2)] public float _Contrast = 1;
    [Range(0, 10)] public float _VignetteFalloff = 1;
    [Range(0, 100)] public float _VignetteIntensity = 1;

    public Color _VisionColor = Color.black;

    [Header("====== Noise Settings ======")]
    public Texture2D _NoiseMap;
    [Range(0, 10)] public float _NoiseAmount = 1;
    private float _RandomValue;

    public float noiseScale;
    private int textureWidth;
    private int textureHeight;
    private Texture2D generatedTexture;

    private Material myMaterial;
    Material nightVisionMat
    {
        get
        {
            if (myMaterial == null)
            {
                myMaterial = new Material(nightVisionShader)
                {
                    hideFlags = HideFlags.HideAndDontSave
                };
            }
            return myMaterial;
        }
    }

    private Color[] GenerateNoiseTexture(int mapHeight, int mapWidth, float noiseScale)
    {
        float[,] noiseMap = new float[mapWidth, mapHeight];

        if (noiseScale <= 0) noiseScale = 0.001f;

        for (int x = 0; x < mapWidth; x++)
        {
            for (int y = 0; y < mapHeight; y++)
            {
                float sampleX = x / noiseScale;
                float sampleY = y / noiseScale;

                float perlinValue = Mathf.PerlinNoise(sampleX, sampleY);
                noiseMap[x, y] = perlinValue;
            }
        }

        Color[] colorMap = new Color[mapWidth * mapHeight];
        for (int x = 0; x < mapWidth; x++)
        {
            for (int y = 0; y < mapHeight; y++)
            {
                colorMap[y * mapWidth + x] = Color.Lerp(Color.black, Color.white, noiseMap[x, y]);
            }
        }
        return colorMap;
    }

    public void GenerateTexture()
    {
        Color[] colorMap = new Color[textureHeight * textureWidth];
        colorMap = GenerateNoiseTexture(textureWidth, textureHeight, noiseScale);

        generatedTexture = new Texture2D(textureWidth, textureHeight);
        generatedTexture.filterMode = FilterMode.Bilinear;
        generatedTexture.wrapMode = TextureWrapMode.Repeat;
        generatedTexture.SetPixels(colorMap);
        generatedTexture.Apply();
    }


    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (nightVisionMat != null)
        {
            nightVisionMat.SetFloat("_Distortion", _Distortion);
            nightVisionMat.SetFloat("_Scale", _Scale);
            nightVisionMat.SetFloat("_Brightness", _Brightness);
            nightVisionMat.SetFloat("_Saturation", _Saturation);
            nightVisionMat.SetFloat("_Contrast", _Contrast);
            nightVisionMat.SetFloat("_VignetteFalloff", _VignetteFalloff);
            nightVisionMat.SetFloat("_VignetteIntensity", _VignetteIntensity);

            nightVisionMat.SetColor("_VisionColor", _VisionColor);

            if (_NoiseMap != null)
            {
                nightVisionMat.SetTexture("_NoiseMap", _NoiseMap);
                nightVisionMat.SetFloat("_NoiseAmount", _NoiseAmount);
                nightVisionMat.SetFloat("_RandomValue", _RandomValue);
            }
            Graphics.Blit(source, destination, nightVisionMat);
        }
        else Graphics.Blit(source, destination);
    }

    private void Start()
    {
        textureWidth = Screen.width;
        textureHeight = Screen.height;
        GenerateTexture();
    }

    private void Update()
    {
        _RandomValue = Random.Range(-3.14f, 3.14f);
    }
}
