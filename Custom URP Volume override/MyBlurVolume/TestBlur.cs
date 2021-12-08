using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class TestBlur : VolumeComponent,IPostProcessComponent
{
    [Range(0f, 100f)]
    public FloatParameter BiurRadius = new FloatParameter(0f);

    [Range(0, 10)]
    public IntParameter Iteration = new IntParameter(5);

    [Range(1, 10)]
    public FloatParameter downSample = new FloatParameter(0f);

    public bool IsActive() => downSample.value > 0f;

    public bool IsTileCompatible() => false;
}
