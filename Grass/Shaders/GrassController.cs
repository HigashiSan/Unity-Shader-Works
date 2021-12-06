using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class GrassController : MonoBehaviour
{
    public Material grassMat;

    [Header("====== Grass Settings ======")]
    [Range(0,2)]
    public float BendAngle = 0.267f;
    [Range(0.01f, 0.1f)]
    public float GrassWidth = 0.05f;
    [Range(1, 20)]
    public float GrassDensity = 6.5f;


    private void Start()
    {
        if (grassMat == null)
        {
            Debug.Log("Error");
        }
    }

    private void Update()
    {
        grassMat.SetFloat("_BladeWidth", GrassWidth);
        grassMat.SetFloat("_BendRotationRandom", BendAngle);
        grassMat.SetFloat("_TessellationUniform", GrassDensity);
    }
}
