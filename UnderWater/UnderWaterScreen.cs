using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class UnderWaterScreen : MonoBehaviour
{
    public Material underWaterMat;
    public Material waterDimMat;

    [Header("====== Water Noise ======")]
    [Range(0,10)]
    public float NoiseScale = 3;
    [Range(0,300)]
    public float NoiseAmount = 4;
    [Range(0,30)]
    public float NoiseSpeed = 10;
    [Range(0.0f,0.003f)]
    public float OffsetScale = 0.001f;
    [Range(-10,10)]
    public float waterWaveStart;
    [Range(0,50)]
    public float waterWaveDistance;

    [Header("====== Water Fog =======")]
    [Range(-15,10)]
    public float fogStart;
    [Range(1,40)]
    public float fogIntensity;
    public Color waterColor = Color.black;

    private void Update() {
        underWaterMat.SetFloat("_NoiseScale", NoiseScale);
        underWaterMat.SetFloat("_NoiseAmount",NoiseAmount);
        underWaterMat.SetFloat("_NoiseSpeed", NoiseSpeed);
        underWaterMat.SetFloat("_OffsetScale", OffsetScale);
        underWaterMat.SetFloat("_WaterWaveDistance",waterWaveDistance);
        underWaterMat.SetFloat("_WaterWaveStart",waterWaveStart);
        waterDimMat.SetColor("_FogColor", waterColor);
        waterDimMat.SetFloat("_FogStart", fogStart);
        waterDimMat.SetFloat("_FogIntensity", fogIntensity);
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dest) {

        RenderTexture temp = RenderTexture.GetTemporary(src.width,src.height,0,RenderTextureFormat.ARGBFloat);
        Graphics.Blit(src, temp, underWaterMat);
        Graphics.Blit(temp, dest, waterDimMat);
        RenderTexture.ReleaseTemporary(temp);
    }
}
