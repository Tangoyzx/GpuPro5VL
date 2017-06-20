using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class VLRenderer : MonoBehaviour {
	public static VLRenderer instance;

	public Action<VLRenderer, Matrix4x4> preRender;

	public RenderTexture vlRT;

	public Shader addShader;
	private Material _addMat;

	private CommandBuffer _command;
	public Camera camera;

	void Awake() {
		instance = this;

		_addMat = new Material(addShader);
		

		vlRT = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGB32);

		_command = new CommandBuffer();
		_command.name = "Pre Light";

		camera = gameObject.GetComponent<Camera>();
		camera.AddCommandBuffer(CameraEvent.AfterDepthTexture, _command);
		camera.depthTextureMode = DepthTextureMode.Depth;
	}

	void OnPreRender() {
		_command.Clear();
		var vp = GL.GetGPUProjectionMatrix(camera.projectionMatrix, true) * camera.worldToCameraMatrix;


		if (preRender != null)
			preRender(this, vp);
	}

	void OnRenderImage(RenderTexture source, RenderTexture destination) {
		_addMat.SetTexture("_SecTex", vlRT);		
		Graphics.Blit(source, destination, _addMat);
	}
	
}