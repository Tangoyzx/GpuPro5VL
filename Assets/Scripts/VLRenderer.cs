using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class VLRenderer : MonoBehaviour {
	public static VLRenderer instance;
	public Action<VLRenderer, Matrix4x4> preRender;
	public Camera vCamera;
	public RenderTexture vlRT;
	public Shader blurShader;
	private Material _blurMat;
	private CommandBuffer _commandBuffer;

	public Texture2D _ditheringTexture;

	void Awake() {
		instance = this;

		vlRT = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGB32);
		vlRT.name = "VolumetricLightRT";
		vlRT.filterMode = FilterMode.Bilinear;

		GenerateDitherTexture();
		_blurMat = new Material(blurShader);

		_commandBuffer = new CommandBuffer();
		_commandBuffer.name = "Pre Light Pass";

		vCamera = GetComponent<Camera>();
		vCamera.depthTextureMode = DepthTextureMode.Depth;
		vCamera.AddCommandBuffer(CameraEvent.AfterDepthTexture, _commandBuffer);
	}

	void OnPreRender() {
		_commandBuffer.Clear();
		_commandBuffer.SetRenderTarget(vlRT);

		_commandBuffer.ClearRenderTarget(false, true, new Color(0, 0, 0, 0));

		Shader.SetGlobalTexture("_DitherTexture", _ditheringTexture);

		var vp = GL.GetGPUProjectionMatrix(vCamera.projectionMatrix, true) * vCamera.worldToCameraMatrix;

		preRender(this, vp);
	}

	void OnRenderImage(RenderTexture source, RenderTexture destination) {
		var tmp = RenderTexture.GetTemporary(vlRT.width, vlRT.height, 0, vlRT.format);
		Graphics.Blit(vlRT, tmp, _blurMat, 0);
		Graphics.Blit(tmp, vlRT, _blurMat, 1);
		Graphics.Blit(vlRT, destination);
		RenderTexture.ReleaseTemporary(tmp);
	}

	private void GenerateDitherTexture()
    {
        if (_ditheringTexture != null)
        {
            return;
        }

        var size = 4;
        _ditheringTexture = new Texture2D(size, size, TextureFormat.Alpha8, false, true);
        _ditheringTexture.filterMode = FilterMode.Point;
        Color32[] c = new Color32[size * size];

        byte b;
        b = (byte)(0.0f / 16.0f * 255); c[0] = new Color32(b, b, b, b);
        b = (byte)(8.0f / 16.0f * 255); c[1] = new Color32(b, b, b, b);
        b = (byte)(2.0f / 16.0f * 255); c[2] = new Color32(b, b, b, b);
        b = (byte)(10.0f / 16.0f * 255); c[3] = new Color32(b, b, b, b);

        b = (byte)(12.0f / 16.0f * 255); c[4] = new Color32(b, b, b, b);
        b = (byte)(4.0f / 16.0f * 255); c[5] = new Color32(b, b, b, b);
        b = (byte)(14.0f / 16.0f * 255); c[6] = new Color32(b, b, b, b);
        b = (byte)(6.0f / 16.0f * 255); c[7] = new Color32(b, b, b, b);

        b = (byte)(3.0f / 16.0f * 255); c[8] = new Color32(b, b, b, b);
        b = (byte)(11.0f / 16.0f * 255); c[9] = new Color32(b, b, b, b);
        b = (byte)(1.0f / 16.0f * 255); c[10] = new Color32(b, b, b, b);
        b = (byte)(9.0f / 16.0f * 255); c[11] = new Color32(b, b, b, b);

        b = (byte)(15.0f / 16.0f * 255); c[12] = new Color32(b, b, b, b);
        b = (byte)(7.0f / 16.0f * 255); c[13] = new Color32(b, b, b, b);
        b = (byte)(13.0f / 16.0f * 255); c[14] = new Color32(b, b, b, b);
        b = (byte)(5.0f / 16.0f * 255); c[15] = new Color32(b, b, b, b);

        _ditheringTexture.SetPixels32(c);
        _ditheringTexture.Apply();
    }
}
