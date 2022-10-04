using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BasicRotation : MonoBehaviour
{
    // Use this for initialization
    public float speed = 1;
    public float RotAngleY = 22.5f;

     
    // Update is called once per frame
    void Update () {
        float rY = Mathf.SmoothStep(-RotAngleY,RotAngleY,Mathf.PingPong(Time.time * speed + 0.5f,1));
        transform.rotation = Quaternion.Euler(0,rY,0);
    }
}
