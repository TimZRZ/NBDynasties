using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraController : MonoBehaviour
{
    public float speedX = 60f;
    public float speedY = 40f;
    public float boardThicknessX = 10f;
    public float boardThicknessY = 10f;
    public float scrollSpeed = 5000f;
    public Vector2 scrollLimit;

    Vector3 initPos;

    private void Start()
    {
        initPos = transform.position;
    }

    // Update is called once per frame
    void Update()
    {
        Vector3 pos = transform.position;

        if (Input.mousePosition.x >= Screen.width - boardThicknessX)
        {
            pos.x += speedX * Time.deltaTime;
        }
        else if (Input.mousePosition.x <= boardThicknessX)
        {
            pos.x -= speedX * Time.deltaTime;
        }
        if (Input.mousePosition.y >= Screen.height - boardThicknessY)
        {
            pos.y += speedY * Time.deltaTime;
        }
        else if (Input.mousePosition.y <= boardThicknessY)
        {
            pos.y -= speedY * Time.deltaTime;
        }

        float scroll = Input.GetAxis("Mouse ScrollWheel");
        pos.z -= scroll * scrollSpeed * Time.deltaTime;

        float deltaScroll = pos.z - initPos.z;
        if (deltaScroll > 100)
        {
            float angle = 45f * (deltaScroll - 100f) / 100f;
            transform.rotation = Quaternion.AngleAxis(angle, -Vector3.right);
        }
        else
        {
            transform.rotation = Quaternion.AngleAxis(0, -Vector3.right);
        }

        float boardLimitX = deltaScroll;
        float boardLimitY = 0.6f * deltaScroll;
        pos.x = Mathf.Clamp(pos.x, initPos.x - boardLimitX, initPos.x + boardLimitX);
        pos.y = Mathf.Clamp(pos.y, initPos.y - boardLimitY, initPos.y + boardLimitY);
        pos.z = Mathf.Clamp(pos.z, scrollLimit.x, scrollLimit.y);

        transform.position = pos;
    }
}
