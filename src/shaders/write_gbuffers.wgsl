struct SceneUniforms {
	perspective: mat4x4<f32>,
    view: mat4x4<f32>,
    inverse_perspective_view: mat4x4<f32>,
	camera_pos: vec4<f32>
}

@group(0) @binding(0) var<uniform> scene: SceneUniforms;

struct MaterialUniforms {
    ambient: vec4<f32>,
    diffuse: vec4<f32>,
    specular: vec4<f32>,
} 

@group(1) @binding(0) var<uniform> material: MaterialUniforms;
@group(1) @binding(1) var diffuse_texture: texture_2d<f32>;
@group(1) @binding(2) var diffuse_texture_sampler: sampler;
@group(1) @binding(3) var normal_texture: texture_2d<f32>;
@group(1) @binding(4) var normal_texture_sampler: sampler;
@group(1) @binding(5) var metal_roughness_texture: texture_2d<f32>;
@group(1) @binding(6) var metal_roughness_texture_sampler: sampler;

struct MeshUniforms {
    model: mat4x4<f32>,
}

@group(2) @binding(0) var<uniform> mesh: MeshUniforms;

struct VertexInput {
    @builtin(vertex_index) index: u32,
    @location(0) position: vec3<f32>,
    @location(1) normal: vec3<f32>,
    @location(2) uv: vec2<f32>,
    @location(3) tangent: vec3<f32>,
}

struct VertexOutput {
    @builtin(position) clip_space_position: vec4<f32>,
    @location(0) world_position: vec3<f32>,
    @location(1) normal: vec3<f32>,
    @location(2) uv: vec2<f32>,
    @location(3) tangent: vec3<f32>,
}


@vertex
fn vs_main(in: VertexInput) -> VertexOutput {
    var out: VertexOutput;
    out.clip_space_position = scene.perspective * scene.view * mesh.model * vec4<f32>(in.position, 1.0);
    out.world_position = (mesh.model * vec4<f32>(in.position, 1.0)).xyz;
    out.normal = (mesh.model * vec4<f32>(in.normal, 0.0)).xyz;    
    out.uv = in.uv;
    out.tangent = (mesh.model * vec4<f32>(in.tangent, 0.0)).xyz;
    return out;
}

struct FragmentOutput {
	@location(0) albedo: vec4<f32>,
	@location(1) normal: vec4<f32>,
	@location(2) material: vec4<f32>,
}


@fragment
fn fs_main(in: VertexOutput) -> FragmentOutput {
	var output: FragmentOutput;

    // Diffuse texture is stored in rgba8unormsrgb, so srgb->linear conversion happens automatically 
    output.albedo = vec4<f32>(textureSample(diffuse_texture, diffuse_texture_sampler, in.uv).rgb, 1.0);
    
	var normal = 
        textureSample(normal_texture, normal_texture_sampler, in.uv).rgb;
    normal = normal - 0.5;
    var rotation = mat3x3<f32>(
        normalize(in.tangent),
        normalize(cross(in.tangent, in.normal)),
        normalize(in.normal)
    );
	normal = (normalize(rotation * normalize(normal)) * 0.5) + 0.5;
	output.normal = vec4<f32>(normal, 1.0);

    // red -> metal, green -> roughness
	output.material = vec4<f32>(textureSample(metal_roughness_texture, metal_roughness_texture_sampler, in.uv).bg, 1.0, 1.0);
	
	return output;	
}