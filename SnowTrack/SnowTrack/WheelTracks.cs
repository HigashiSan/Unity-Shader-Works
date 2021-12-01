using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WheelTracks : MonoBehaviour
{
    public Shader drawShader;
    public GameObject snowTerrain;
    public Transform[] wheels;

    [Range(0,5)]
    public float trackWeight;

    private Material drawMaterial;
    private Material snowMaterial;
    private RenderTexture splatMap;

    RaycastHit groundHit;
    private int layerMask;

    private Vector3[] lastWheelPos =new Vector3[4];

    private void Start() {
        layerMask = LayerMask.GetMask("Ground");
        drawMaterial = new Material(drawShader);
             
        snowMaterial = snowTerrain.GetComponent<MeshRenderer>().material;
        snowMaterial.SetTexture("_Splat", splatMap = new RenderTexture(1024,1024,0,RenderTextureFormat.ARGBFloat));
    }

    private void Update() {
        for(int i=0; i < wheels.Length; i++){
            if(Physics.Raycast(wheels[i].position, -Vector3.up, out groundHit, 1f, layerMask)){
                if(lastWheelPos[i] == wheels[i].position) return;
                drawMaterial.SetVector("_Coordinate",new Vector4(groundHit.textureCoord.x,groundHit.textureCoord.y,0,0));
                RenderTexture temp = RenderTexture.GetTemporary(splatMap.width,splatMap.height,0,RenderTextureFormat.ARGBFloat);

                drawMaterial.SetFloat("_TrackWidth", wheels[i].GetComponent<MeshRenderer>().bounds.size.z);
                drawMaterial.SetFloat("_TrackWeight", trackWeight);

                Graphics.Blit(splatMap,temp);
                Graphics.Blit(temp,splatMap,drawMaterial);
                RenderTexture.ReleaseTemporary(temp);

                lastWheelPos[i] = wheels[i].position;
            }
        }
    }
}
