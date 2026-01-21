/// Frost Main
package main

import "core:math/linalg"
import "core:math"
import "core:fmt"
import "vendor:wgpu"
import "core:log"
import "frost"
import "core:mem"



pipeline: ^frost.RenderPipeline;


vertices := []frost.Vertex3D {
    {position = {-1,  1, 0}, color = {1, 0, 0}, UV0 = {0, 1}},
    {position = {-1, -1, 0}, color = {0, 1, 0}, UV0 = {0, 0}},
    {position = { 1, -1, 0}, color = {0, 0, 1}, UV0 = {1, 0}},
    {position = { 1,  1, 0}, color = {1, 0, 1}, UV0 = {1, 1}},
}

indices := []u16 {
    0, 1, 2,
    2, 3, 0
}

mesh: frost.StaticMesh



FrameData :: struct #align(16) {
    time: f32,
    gamma: f32,
}

CameraData :: struct #align(16) {
    proj: frost.mat4f,
    view: frost.mat4f,
}

ModelData :: struct #align(16) {
    model: frost.mat4f
}

uniformBuffer: ^frost.UniformBuffer(FrameData)
cameraBuffer: ^frost.UniformBuffer(CameraData)
modelBuffer: ^frost.UniformBuffer(ModelData)

bindGroup: wgpu.BindGroup
cameraGroup: wgpu.BindGroup

shaderMat: frost.BindingGroup

textureGroup: frost.BindingGroup

cameraPos: [3]f32 = {0, 1, 5}

main :: proc() {

    when #config(LOGGING, false) {
        context.logger = log.create_console_logger()
    }

    attribs := frost.VertexLayout(frost.Vertex3D)

    for a in attribs {
        fmt.printfln("Attrib: %v", a)
    }

    

    

    app := frost.Application {
        width = 1080,
        height = 720,
        title = "Sandbox App",
        
        on_create = create,
        on_update = update,
        on_render = render,
        on_shutdown = shutdown,
        on_resize = resize
    }

    frost.init(&app)
}

create :: proc() {

    mesh = frost.CreateStaticMeshFromSlices(vertices, indices)

    tex := frost.LoadTexture("res/materials/Atlas.png")

    frost.gfx.clear_color = {0.1, 0.2, 0.3, 1.0}

    spec := frost.materialspec_load("res/materials/red.json")
    fmt.println(spec.name)
    fmt.println(spec.sourcePath)
    fmt.printfln("Topology: %v", spec.topology)


    uniformBuffer = frost.CreateUniformBufferWithData(FrameData, &FrameData {time = 0, gamma = 2.4})
    cameraBuffer = frost.CreateUniformBufferWithData(CameraData, &CameraData {
        proj = linalg.matrix4_perspective(math.to_radians_f32(70.0), f32(frost.application.width) / f32(frost.application.height), 0.1, 1000.0),
        view = linalg.inverse(
            linalg.matrix4_translate_f32(cameraPos)
        )
    })

    modelBuffer = frost.CreateUniformBufferWithData(ModelData, &ModelData {
        model = linalg.identity(frost.mat4f)
    })

    shaderMat = frost.CreateBindingGroup(0, 
        []frost.UniformInfo {
            uniformBuffer.info,
            cameraBuffer.info,
            modelBuffer.info
        },
            {.Vertex, .Fragment}
    )

    textureGroup = frost.CreateTextureBindingGroup(1,
        {tex},
        {.Vertex, .Fragment}
    )
    
    layouts := []wgpu.BindGroupLayout {
        shaderMat.layout,
        textureGroup.layout
    }

    spec.layout_desc = &wgpu.PipelineLayoutDescriptor {
        bindGroupLayoutCount = 2,
        bindGroupLayouts = raw_data(layouts),
        label = spec.name
    }

    pipeline = frost.CreateRenderPipeline(spec, frost.Vertex3D)

    frost.matsec_delete(spec)

    
    

    

    log.debugf("BindGroup: %p",shaderMat.bindingGroup);

    
}

accumTime: f32 = 0
angle: f32 = 0

update :: proc(dt: f32) {
    accumTime += dt
    frost.SetUniformData(FrameData, uniformBuffer, &FrameData {
        time = math.sin(accumTime),
        gamma = 2.4
    });

    model := linalg.identity(frost.mat4f)

    model *= linalg.matrix4_rotate_f32(math.to_radians_f32(30), {1, 0, 0})
    model *= linalg.matrix4_rotate_f32(math.to_radians_f32(angle), {0, 1, 0})
    

    frost.SetUniformData(ModelData, modelBuffer, &ModelData {
        model = model
    })

    angle += (360 / 10) * dt;

}

render :: proc(gfx: ^frost.GraphicsContext, render_pass: wgpu.RenderPassEncoder) {
    frost.BindRenderPipeline(pipeline, render_pass)
    frost.BindGroup(&shaderMat)
    frost.BindGroup(&textureGroup)
    frost.DrawStaticMesh(&mesh)
}

shutdown :: proc() {
    frost.ReleaseUniformBuffer(FrameData, uniformBuffer)
    frost.ReleaseUniformBuffer(CameraData, cameraBuffer)
    frost.ReleaseUniformBuffer(ModelData, modelBuffer)
    frost.ReleaseRenderPipeline(pipeline)
}

resize :: proc(width, height: f32) {
    frost.SetUniformData(
        CameraData, cameraBuffer, &CameraData {
            proj = linalg.matrix4_perspective(math.to_radians_f32(70.0), width / height, 0.1, 1000.0),
            view = linalg.inverse(
                linalg.matrix4_translate_f32(cameraPos)
            )
        }
    )
}


