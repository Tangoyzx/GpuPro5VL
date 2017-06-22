using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class VLPoint : MonoBehaviour {
	public Shader vlShader;
	public int sampleCount = 5;
	public float scatterFactor = 0.5f;
	public float g = 0.5f;
	private Light _light;
	private Material _mat;
	private CommandBuffer _commandBuffer;

	private Mesh _pointLightMesh;
	
	void Start() {
		_light = GetComponent<Light>();
		_mat = new Material(vlShader);

		if (_pointLightMesh == null)
        {
            GameObject go = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            _pointLightMesh = go.GetComponent<MeshFilter>().sharedMesh;
            Destroy(go);
        }

		_commandBuffer = new CommandBuffer();
		_commandBuffer.name = "VolumetricLight";

		_light.AddCommandBuffer(LightEvent.AfterShadowMap, _commandBuffer);
		
		VLRenderer.instance.preRender += OnLightPreRender;
	}

	void Update() {
		_commandBuffer.Clear();
	}

	void OnLightPreRender(VLRenderer renderer, Matrix4x4 vp) {
		_mat.SetPass(0);

		
		var radius = _light.range;
		var scale = radius + radius;
		var world = Matrix4x4.TRS(transform.position, transform.rotation, new Vector3(scale, scale, scale));

		_mat.SetVector("_VolumetricLight", new Vector4(0, 0, _light.range, 0));

		_mat.SetMatrix("_WorldViewProj", vp * world);
		_mat.SetVector("_VLightPos", transform.position);
		_mat.SetVector("_VLightParams", new Vector4(radius, radius * radius, 1 / (radius * radius), 5));
		_mat.SetVector("_Params", new Vector4(sampleCount, scatterFactor, 0, 0));
		_mat.SetVector("_CameraForward", renderer.vCamera.transform.forward);
		_mat.SetVector("_MieG", new Vector4(1 - (g * g), 1 + (g * g), 2 * g, 1.0f / (4.0f * Mathf.PI)));

		_mat.EnableKeyword("POINT");
		_mat.EnableKeyword("SHADOWS_CUBE");

		_commandBuffer.Clear();

		_commandBuffer.SetGlobalTexture("_ShadowMapTexture", BuiltinRenderTextureType.CurrentActive);

		_commandBuffer.SetRenderTarget(renderer.vlRT);

		_commandBuffer.DrawMesh(_pointLightMesh, world, _mat, 0, 0);
	}
}
