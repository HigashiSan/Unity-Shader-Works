using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SnowNoise : MonoBehaviour
{
    public Shader snowingShader;
    private Material snowMaterial;
    private MeshRenderer meshRenderer;

    [Range(0.001f,0.1f)]
    public float _flakeAmount;
    [Range(0,1)]
    public float _flakeOpacity;

    private void Start() {
        meshRenderer = GetComponent<MeshRenderer>();
        snowMaterial = new Material(snowingShader);
    }

    private void Update() {
        snowMaterial.SetFloat("_FlakeAmount",_flakeAmount);
        snowMaterial.SetFloat("_FlakeOpacity",_flakeOpacity);

        RenderTexture snow = (RenderTexture)meshRenderer.material.GetTexture("_Splat");
        RenderTexture temp = RenderTexture.GetTemporary(snow.width,snow.height,0,RenderTextureFormat.ARGBFloat);
        Graphics.Blit(snow, temp, snowMaterial);
        Graphics.Blit(temp, snow);
        meshRenderer.material.SetTexture("_Splat",snow);
        RenderTexture.ReleaseTemporary(temp);
    }
}
