using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class SSAOControl : MonoBehaviour
{
    public bool EnableAO = true;
    public bool ShowAoTexture = false;

    [Header("====== SSAO Settings ======")]
    [Range(0f, 1f)]
    public float AOStrength = 0.5f;
    [Range(4, 128)]
    public int SampleTimes = 64;
    [Range(0.0001f, 10f)]
    public float HalfSphereRadius = 0.01f;
    [Range(0.0001f, 1f)]
    public float GenAoDistance = 0.001f;
    [Range(0.00001f,0.0003f)]
    public float DepthOffset = 0.00005f;
    public Texture noiseTexture;

    [Header("====== Blur Settings ======")]
    [Range(1,5)]
    public int BlurRadius = 2;
    [Range(0, 0.2f)]
    public float bilaterFilterStrength = 0.1f;

    private List<Vector4> SampleArrays = new List<Vector4>();

    private Camera myCamera;
    [SerializeField]
    private Material SSAOMat;

    private void Awake()
    {
        var shader = Shader.Find("SS/SSAO");
        SSAOMat = new Material(shader);
    }

    private void Start()
    {
        myCamera = GetComponent<Camera>();
        myCamera.depthTextureMode = myCamera.depthTextureMode | DepthTextureMode.DepthNormals;
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        GenRandomSampleArraay();

        int width = source.width;
        int height = source.height;

        RenderTexture AOtexture = RenderTexture.GetTemporary(width, height, 0);
        SSAOMat.SetVectorArray("_SampleArray", SampleArrays.ToArray());
        SSAOMat.SetFloat("_SampleTimes", SampleArrays.Count);
        SSAOMat.SetFloat("_HalfSphereRadius", HalfSphereRadius);
        SSAOMat.SetFloat("_AOStrength", AOStrength);
        SSAOMat.SetTexture("_NoiseTexture", noiseTexture);
        SSAOMat.SetFloat("_GenAoDistance", GenAoDistance);
        SSAOMat.SetFloat("_DepthOffset", DepthOffset);
        Graphics.Blit(source, AOtexture, SSAOMat, 0);

        RenderTexture Blurtexture = RenderTexture.GetTemporary(width, height, 0);
        SSAOMat.SetFloat("_BilaterFilterFactor", 1 - bilaterFilterStrength);
        SSAOMat.SetVector("_BlurRadius", new Vector4(BlurRadius, 0, 0, 0));
        Graphics.Blit(AOtexture, Blurtexture, SSAOMat, 1);

        if (EnableAO == true)
        {
            if (ShowAoTexture == true)
            {
                Graphics.Blit(Blurtexture, destination);
            }
            else
            { 
                Graphics.Blit(Blurtexture, AOtexture);
                SSAOMat.SetTexture("_AoTexture", AOtexture);
                Graphics.Blit(source, destination, SSAOMat, 2);
            }
        }
        else
        {
            Graphics.Blit(source, destination);
        }

        RenderTexture.ReleaseTemporary(AOtexture);
        RenderTexture.ReleaseTemporary(Blurtexture);
    }

    public void GenRandomSampleArraay()
    {
        if (SampleTimes == SampleArrays.Count)
            return;
        SampleArrays.Clear();
        for (int i = 0; i < SampleTimes; i++)
        {
            var vec = new Vector4(Random.Range(-1.0f, 1.0f), Random.Range(-1.0f, 1.0f), Random.Range(0, 1.0f), 1.0f);
            vec.Normalize();
            var scale = (float)i / SampleTimes;
            
            scale = Mathf.Lerp(0.01f, 1.0f, scale * scale);
            vec *= scale;
            SampleArrays.Add(vec);
        }
    }
}
