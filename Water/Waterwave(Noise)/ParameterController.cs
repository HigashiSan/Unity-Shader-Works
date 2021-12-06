using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class ParameterController : MonoBehaviour
{
    public Slider distortionS;
    public Slider speedXS;
    public Slider speedYS;

    public Material waterWaveMat;

    private void Start() {
        distortionS.value = 50;
        speedXS.value = 0.05f;
        speedYS.value = 0.07f;
    }

    private void Update() {
        waterWaveMat.SetFloat("_Distortion", distortionS.value);
        waterWaveMat.SetFloat("_WaveXSpeed",speedXS.value);
        waterWaveMat.SetFloat("_WaveYSpeed",speedYS.value);
    }
}
