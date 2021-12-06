using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

[RequireComponent(typeof(Camera))]
[ExecuteInEditMode]
public class RayMarchCam : SceneViewFilter
{
    [SerializeField]
    private Shader _myShader;
    public Material rayMarchMaterial
    {
        get
        {
            if (!rayMarchMat && _myShader)
            {
                rayMarchMat = new Material(_myShader);
                rayMarchMat.hideFlags = HideFlags.HideAndDontSave;
            }
            return rayMarchMat;
        }
    }
    private Material rayMarchMat;

    public Camera myCamera
    {
        get
        {
            if (!cam)
            {
                cam = GetComponent<Camera>();
            }
            return cam;
        }
    }
    private Camera cam;
    public float _maxDst;
    [Range(1,600)]
    public int _MaxIteration;
    [Range(0.1f,0.001f)]
    public float _Accuracy; 

    [Header("===== Light Settings =====")]
    public Transform _directionalLight;
    public Color _LightCol;
    public float _LightIntensity;

    [Header("===== Shadow =====")]
    [Range(0,8)]
    public float _ShadowIntensity;
    public Vector2 _ShadowDst;

    [Header("===== Signed Distance Field =====")]
    public Vector4 _sphere1;
    public Vector4 _box1;
    public Vector3 _BoxSize;
    public Vector3 _BoxPos;
    public float _box1Round;
    public float _boxSphereSmooth;
    public Vector4 _sphere2;
    public float _sphereIntersectSmooth;

    [Header("===== Ambient Occlusion =====")]
    [Range(0.01f,10.0f)]
    public float _AoStepSize;

    public Color _mainColor;

    public Slider aoIntensitySlider;
    public Slider aoIterationsSlider;
    public Slider softShadowSlider;

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (!rayMarchMaterial)
        {
            Graphics.Blit(source, destination);
            return;
        }

        rayMarchMaterial.SetVector("_LightDir", _directionalLight ? _directionalLight.forward : Vector3.down);
        rayMarchMaterial.SetColor("_LightCol", _LightCol);
        rayMarchMaterial.SetFloat("_LightIntensity", _LightIntensity);

        rayMarchMaterial.SetMatrix("_CamFrustum", CamFrustum(myCamera));
        rayMarchMaterial.SetMatrix("_CamToWorldMatrix", myCamera.cameraToWorldMatrix);
        rayMarchMaterial.SetFloat("_maxDst", _maxDst);
        rayMarchMaterial.SetInt("_MaxIterations", _MaxIteration);
        rayMarchMaterial.SetFloat("_Accuracy", _Accuracy);

        rayMarchMaterial.SetFloat("_Box1round", _box1Round);
        rayMarchMaterial.SetFloat("_BoxSphereSmooth", _boxSphereSmooth);
        rayMarchMaterial.SetFloat("_SphereIntersectSmooth", _sphereIntersectSmooth);

        rayMarchMaterial.SetVector("_Sphere1", _sphere1);
        rayMarchMaterial.SetVector("_Sphere2", _sphere2);
        rayMarchMaterial.SetVector("_Box1", _box1);
        rayMarchMaterial.SetVector("_BoxPos", _BoxPos);
        rayMarchMaterial.SetVector("_BoxSize", _BoxSize);

        rayMarchMaterial.SetFloat("_ShadowIntensity", _ShadowIntensity);
        rayMarchMaterial.SetVector("_ShadowDst", _ShadowDst);
        rayMarchMaterial.SetFloat("_ShadowSoft", softShadowSlider.value);

        rayMarchMaterial.SetFloat("_AoStepSize", _AoStepSize);
        rayMarchMaterial.SetFloat("_AoIntensity", aoIntensitySlider.value);
        rayMarchMaterial.SetInt("_AoIterations", (int)aoIterationsSlider.value);

        rayMarchMaterial.SetColor("_MainColor", _mainColor);

        RenderTexture.active = destination;
        rayMarchMaterial.SetTexture("_MainTex", source);
        GL.PushMatrix();
        GL.LoadOrtho();
        rayMarchMaterial.SetPass(0);
        GL.Begin(GL.QUADS);

        GL.MultiTexCoord2(0, 0.0f, 0.0f);
        GL.Vertex3(0.0f, 0.0f, 3.0f);
        GL.MultiTexCoord2(0, 1.0f, 0.0f);
        GL.Vertex3(1.0f, 0.0f, 2.0f);
        GL.MultiTexCoord2(0, 1.0f, 1.0f);
        GL.Vertex3(1.0f, 1.0f, 1.0f);
        GL.MultiTexCoord2(0, 0.0f, 1.0f);
        GL.Vertex3(0.0f, 1.0f, 0.0f);

        GL.End();
        GL.PopMatrix();
    }

    //Calculate Camera Frustum
    private Matrix4x4 CamFrustum(Camera cam)
    {
        Matrix4x4 frustum = Matrix4x4.identity;
        float halfHeight = Mathf.Tan((cam.fieldOfView * 0.5f) * Mathf.Deg2Rad);

        Vector3 goUp = Vector3.up * halfHeight;
        Vector3 goRight = Vector3.right * halfHeight * cam.aspect;

        Vector3 TL = (-Vector3.forward - goRight + goUp);
        Vector3 TR = (-Vector3.forward + goRight + goUp);
        Vector3 BR = (-Vector3.forward + goRight - goUp);
        Vector3 BL = (-Vector3.forward - goRight - goUp);

        frustum.SetRow(0, TL);
        frustum.SetRow(1, TR);
        frustum.SetRow(2, BR);
        frustum.SetRow(3, BL);

        return frustum;
    }
}
