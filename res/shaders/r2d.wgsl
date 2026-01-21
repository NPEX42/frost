struct VertexInput {
    @location(0) position: vec2<f32>,
    @location(1) uv0: vec2<f32>,
    @location(2) color: vec3<f32>
};

struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
    @location(0) color: vec3<f32>,
    @location(1) uv0: vec2<f32> 
};

struct FragOut {
    @location(0) color: vec4<f32>
}

//@group(1) @binding(0) var t_diffuse: texture_2d<f32>;
//@group(1) @binding(1) var s_diffuse: sampler;

@vertex
fn vs_main(model: VertexInput) -> VertexOutput {
    var out: VertexOutput;
    out.clip_position = vec4<f32>(model.position, 0.0, 1.0);
    out.color = model.color;
    out.uv0 = model.uv0;
    return out;
}

// Fragment shader

fn gammaCorrection(in: vec3<f32>) -> vec3<f32> {
    var out: vec3<f32>;

    out.r = pow((in.r + 0.055) / 1.055, 2.4);
    out.g = pow((in.g + 0.055) / 1.055, 2.4);
    out.b = pow((in.b + 0.055) / 1.055, 2.4);

    return out;
}


@fragment
fn fs_main(in: VertexOutput) -> FragOut {
    var pixel: FragOut;
    pixel.color = vec4<f32>(in.color, 1.0);
    //pixel.color = vec4<f32>(in.uv0, 0, 1);
    return pixel;
}

