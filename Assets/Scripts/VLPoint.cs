using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class VLPoint : MonoBehaviour {
	[RangeAttribute(0, 1)]
	public float g;
	public Shader shader;
	public Texture2D fallOff;
	private Light _light;
	private Material _mat;
	private CommandBuffer _command;
	private Mesh _sphereMesh;

	// Use this for initialization
	void Start () {
		_mat = new Material(shader);


		GameObject go = GameObject.CreatePrimitive(PrimitiveType.Sphere);
		_sphereMesh = go.GetComponent<MeshFilter>().sharedMesh;
		Destroy(go);

		_command = new CommandBuffer();
		_command.name = "Volumetric Lighting";
		_light = gameObject.GetComponent<Light>();
		_light.AddCommandBuffer(LightEvent.AfterShadowMap, _command);
		// VLRenderer.instance.camera.AddCommandBuffer(CameraEvent.AfterForwardOpaque, _command);

		VLRenderer.instance.preRender += SetupVolumetricLight;

		_mat.SetTexture("_FallOffTex", fallOff);
	}
	

	void SetupVolumetricLight(VLRenderer renderer, Matrix4x4 matrix) {
		_command.Clear();
		_command.SetRenderTarget(renderer.vlRT);
		_command.ClearRenderTarget(false, true, new Color(0, 0, 0, 0));

		var MieG = new Vector4(1 - (g * g), 1 + (g * g), 2 * g, 1.0f / (4.0f * Mathf.PI));

		var radius = _light.range;
		var world = Matrix4x4.TRS(transform.position, transform.rotation, new Vector3(radius * 2, radius * 2, radius * 2));
		var lightParams = new Vector4(radius, radius * radius, 1.0f / (radius * radius), 5);
		_mat.SetVector("_MieG", MieG);
		_mat.SetVector("_VLightParams", lightParams);
		_mat.SetVector("_VLightPos", transform.position);
		_mat.SetColor("_VLightColor", _light.color);
		_mat.SetVector("_CameraForward", renderer.camera.transform.forward);

		_command.DrawMesh(_sphereMesh, world, _mat, 0, 0);
	}
}