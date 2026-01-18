struct PerFrameData {
    time: f32,
    gamma: f32,
}

struct Camera {
    proj: mat4x4f,
    view: mat4x4f
}

struct Model {
    trans: mat4x4f
}

struct VertexInput {
    @location(0) position: vec3<f32>,
    @location(1) color: vec3<f32>,
    @location(2) uv0: vec2<f32>
};

struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
    @location(0) color: vec3<f32>,
    @location(1) uv0: vec2<f32> 
};

struct FragOut {
    @location(0) color: vec4<f32>
}

@group(0) @binding(0) var<uniform> frame: PerFrameData;
@group(0) @binding(1) var<uniform> camera: Camera;
@group(0) @binding(2) var<uniform> modelMat: Model;


@group(1) @binding(0) var t_diffuse: texture_2d<f32>;
@group(1) @binding(1) var s_diffuse: sampler;

@vertex
fn vs_main(model: VertexInput) -> VertexOutput {
    var out: VertexOutput;
    out.clip_position = camera.proj * camera.view * modelMat.trans * vec4<f32>(model.position, 1.0);
    out.color = model.color;
    out.uv0 = model.uv0;
    return out;
}

// Fragment shader

fn gammaCorrection(in: vec3<f32>) -> vec3<f32> {
    var out: vec3<f32>;

    out.r = pow((in.r + 0.055) / 1.055, frame.gamma);
    out.g = pow((in.g + 0.055) / 1.055, frame.gamma);
    out.b = pow((in.b + 0.055) / 1.055, frame.gamma);

    return out;
}


@fragment
fn fs_main(in: VertexOutput) -> FragOut {
    var pixel: FragOut;
    var color = textureSample(t_diffuse, s_diffuse, in.uv0).xyz;
    if (color.r == 1 && color.g == 0 && color.b == 1) {
        discard;
    }
    pixel.color = vec4<f32>(gammaCorrection(textureSample(t_diffuse, s_diffuse, in.uv0).xyz), 1.0);
    //pixel.color = vec4<f32>(in.uv0, 0, 1);
    return pixel;
}

