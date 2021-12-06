using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent (typeof(Camera))]
[ExecuteInEditMode, ImageEffectAllowedInSceneView]
public class ImageTest : MonoBehaviour
{
    public Shader shader;
    public Transform container;

    public int numSteps = 10;
    public float cloudScale;

    public float densityMultiplier;
    [Range(0, 1)]
    public float densityThreshold;

    public Vector3 offset;

    [Header("Lighting Settings")]
    public int numStepsLight;
    public float rayOffsetStrength;

    public float lightAbsorptionThroughCloud = 1;
    public float lightAbsorptionTowardSun = 1;
    [Range(0, 1)]
    public float darknessThreshold = .2f;

    Material myMaterial;

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (myMaterial == null)
        {
            myMaterial = new Material(shader);
        }

        myMaterial.SetVector("BoundsMin", container.position - container.localScale / 2);
        myMaterial.SetVector("BoundsMax", container.position + container.localScale / 2);

        myMaterial.SetFloat("CloudScale", cloudScale);
        myMaterial.SetFloat("DensityThreshold", densityThreshold);
        myMaterial.SetFloat("DensityMultiplier", densityMultiplier);
        myMaterial.SetInt("NumSteps", numSteps);
        myMaterial.SetFloat("lightAbsorptionTowardSun", lightAbsorptionThroughCloud);
        myMaterial.SetFloat("lightAbsorptionThroughCloud", lightAbsorptionThroughCloud);
        myMaterial.SetFloat("darknessThreshold", darknessThreshold);
        myMaterial.SetInt("numStepsLight", numStepsLight);
        myMaterial.SetFloat("rayOffsetStrength", rayOffsetStrength);

        var noise = FindObjectOfType<NoiseGenerator>();
        myMaterial.SetTexture("ShapeNoise", noise.shapeTexture);
        myMaterial.SetTexture("BlueNoise", noise.blueNoise);

        Graphics.Blit(source, destination, myMaterial);
    }
}
