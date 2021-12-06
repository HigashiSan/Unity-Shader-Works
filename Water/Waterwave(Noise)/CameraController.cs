using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraController : MonoBehaviour
{
    public GameObject waterPlane;
    private Transform myCamera;

    private void Start() {
        myCamera = this.GetComponent<Transform>();
    }

    private void Update() {
        if(myCamera.transform.position.y < waterPlane.transform.position.y){
            Debug.Log("Is under the sea");
        }
    }
}
