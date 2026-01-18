/// Frost Main
package main

import "core:math/linalg"
import "core:math"
import "core:fmt"
import "vendor:wgpu"
import "core:log"
import "frost"
import "core:mem"



import frostGfx "frost/graphics"
import frostMaths "frost/maths"


pipeline: ^frostGfx.RenderPipeline;


vertices := []frostGfx.Vertex3D {
    {position = {-1,  1, 0}, color = {1, 0, 0}, UV0 = {0, 1}},
    {position = {-1, -1, 0}, color = {0, 1, 0}, UV0 = {0, 0}},
    {position = { 1, -1, 0}, color = {0, 0, 1}, UV0 = {1, 0}},
    {position = { 1,  1, 0}, color = {1, 0, 1}, UV0 = {1, 1}},
}

indices := []u16 {
    0, 1, 2,
    2, 3, 0
}

mesh: frostGfx.StaticMesh



FrameData :: struct #align(16) {
    time: f32,
    gamma: f32,
}

CameraData :: struct #align(16) {
    proj: frostMaths.mat4f,
    view: frostMaths.mat4f,
}

ModelData :: struct #align(16) {
    model: frostMaths.mat4f
}

uniformBuffer: ^frostGfx.UniformBuffer(FrameData)
cameraBuffer: ^frostGfx.UniformBuffer(CameraData)
modelBuffer: ^frostGfx.UniformBuffer(ModelData)

bindGroup: wgpu.BindGroup
cameraGroup: wgpu.BindGroup

shaderMat: frostGfx.BindingGroup

textureGroup: frostGfx.BindingGroup

cameraPos: [3]f32 = {0, 1, 5}

main :: proc() {

    when #config(LOGGING, false) {
        context.logger = log.create_console_logger()
    }

    attribs := frost.VertexLayout(frostGfx.Vertex3D)

    for a in attribs {
        fmt.printfln("Attrib: %v", a)
    }

    

    

    app := frost.Application {
        on_create = create,
        on_update = update,
        on_render = render,
        on_shutdown = shutdown,
        on_resize = resize
    }

    frost.init(&app)
}

create :: proc() {

    mesh = frostGfx.CreateStaticMeshFromSlices(vertices, indices)

    tex := frost.LoadTexture("res/materials/Atlas.png")

    frost.gfx.clear_color = {0.1, 0.2, 0.3, 1.0}

    spec := frostGfx.materialspec_load("res/materials/red.json")
    fmt.println(spec.name)
    fmt.println(spec.sourcePath)
    fmt.printfln("Topology: %v", spec.topology)


    uniformBuffer = frostGfx.CreateUniformBufferWithData(FrameData, &FrameData {time = 0, gamma = 2.4})
    cameraBuffer = frostGfx.CreateUniformBufferWithData(CameraData, &CameraData {
        proj = linalg.matrix4_perspective(math.to_radians_f32(70.0), 1080.0 / 720.0, 0.1, 1000.0),
        view = linalg.inverse(
            linalg.matrix4_translate_f32(cameraPos)
        )
    })

    modelBuffer = frostGfx.CreateUniformBufferWithData(ModelData, &ModelData {
        model = linalg.identity(frostMaths.mat4f)
    })

    shaderMat = frostGfx.CreateBindingGroup(0, 
        []frostGfx.UniformInfo {
            uniformBuffer.info,
            cameraBuffer.info,
            modelBuffer.info
        },
            {.Vertex, .Fragment}
    )

    textureGroup = frostGfx.CreateTextureBindingGroup(1,
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

    pipeline = frostGfx.CreateRenderPipeline(spec)

    frostGfx.matsec_delete(spec)

    
    

    

    log.debugf("BindGroup: %p",shaderMat.bindingGroup);

    
}

accumTime: f32 = 0
angle: f32 = 0

update :: proc(dt: f32) {
    accumTime += dt
    frostGfx.SetUniformData(FrameData, uniformBuffer, &FrameData {
        time = math.sin(accumTime),
        gamma = 2.4
    });

    model := linalg.identity(frostMaths.mat4f)

    model *= linalg.matrix4_rotate_f32(math.to_radians_f32(30), {1, 0, 0})
    model *= linalg.matrix4_rotate_f32(math.to_radians_f32(angle), {0, 1, 0})
    

    frostGfx.SetUniformData(ModelData, modelBuffer, &ModelData {
        model = model
    })

    angle += (360 / 10) * dt;

}

render :: proc(gfx: ^frost.GraphicsContext, render_pass: wgpu.RenderPassEncoder) {
    frostGfx.BindRenderPipeline(pipeline, render_pass)
    frostGfx.BindGroup(&shaderMat)
    frostGfx.BindGroup(&textureGroup)
    frostGfx.DrawStaticMesh(&mesh)
}

shutdown :: proc() {
    frostGfx.ReleaseUniformBuffer(FrameData, uniformBuffer)
    frostGfx.ReleaseUniformBuffer(CameraData, cameraBuffer)
    frostGfx.ReleaseUniformBuffer(ModelData, modelBuffer)
    frostGfx.ReleaseRenderPipeline(pipeline)
}

resize :: proc(width, height: f32) {
    frostGfx.SetUniformData(
        CameraData, cameraBuffer, &CameraData {
            proj = linalg.matrix4_perspective(math.to_radians_f32(70.0), width / height, 0.1, 1000.0),
            view = linalg.inverse(
                linalg.matrix4_translate_f32(cameraPos)
            )
        }
    )
}


