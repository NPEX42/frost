package frostGfx

import "core:encoding/json"
import "core:log"
import "core:os"
import "vendor:wgpu"

import ".."

MaterialSpec :: struct {
    name: string,
    sourcePath: string,

    fs_entry: string,
    vs_entry: string,

    topology: wgpu.PrimitiveTopology,

    layout_desc: ^wgpu.PipelineLayoutDescriptor,


    json_data: json.Value
}

RenderPipeline :: struct {
    layout: wgpu.PipelineLayout,
    pipeline: wgpu.RenderPipeline,
    module: wgpu.ShaderModule,
}

materialspec_load :: proc(filepath: string) -> ^MaterialSpec {
    data, ok := os.read_entire_file_from_filename(filepath)
    if !ok { 
        log.fatalf("Failed To Read Material Spec '%v'", filepath); 
    }
    defer delete(data)

    json_data, err := json.parse(data)
    if err != .None {
        log.fatalf("Failed to parse spec, '%s'", err)
    }

    //defer json.destroy_value(json_data)

    root := json_data.(json.Object)

    spec := new(MaterialSpec, context.temp_allocator)

    spec.name = root["name"].(json.String)
    spec.sourcePath = root["sourcePath"].(json.String)
    spec.fs_entry = root["fs_entry"].(json.String)
    spec.vs_entry = root["vs_entry"].(json.String)

    switch root["topology"].(json.String) {
        case "TriangleList": spec.topology = .TriangleList
        case "TriangleStrip": spec.topology = .TriangleStrip
        case "PointList": spec.topology = .PointList
        case "LineList": spec.topology = .LineList
        case "LineStrip": spec.topology = .LineStrip
        case: log.fatal("Unknown Topology:", root["topology"].(json.String))
    }


    spec.json_data = json_data

    return spec
}

matsec_delete :: proc(spec: ^MaterialSpec) {
    json.destroy_value(spec.json_data)
}

CreateRenderPipeline :: proc(spec: ^MaterialSpec) -> ^RenderPipeline {
    rp := new(RenderPipeline)
    gfx := frost.gfx

    shader_src, ok := os.read_entire_file_from_filename(spec.sourcePath)
    defer delete(shader_src)

    if !ok {
        log.panicf("Failed To Load Shader Source '%s'\n", spec.sourcePath)
    }

    rp.module = wgpu.DeviceCreateShaderModule(gfx.device, &{
        nextInChain = &wgpu.ShaderSourceWGSL{
            sType = .ShaderSourceWGSL,
            code  = string(shader_src),
        }
    })

    if spec.layout_desc == nil {
        rp.layout = wgpu.DeviceCreatePipelineLayout(gfx.device, &{
            

        });
    } else {
        rp.layout = wgpu.DeviceCreatePipelineLayout(gfx.device, spec.layout_desc)
    }

    vertex_attribs := frost.VertexLayout(Vertex3D)

    vertex_input := wgpu.VertexBufferLayout {
        arrayStride = size_of(Vertex3D),
        attributeCount = uint(len(vertex_attribs)),
        attributes = raw_data(vertex_attribs),
        stepMode = .Vertex
    }




    rp.pipeline = wgpu.DeviceCreateRenderPipeline(gfx.device, &{
        layout = rp.layout,
        vertex = {
            module     = rp.module,
            entryPoint = spec.vs_entry,

            buffers = &vertex_input,
            bufferCount = 1

        },
        fragment = &{
            module      = rp.module,
            entryPoint  = spec.fs_entry,
            targetCount = 1,
            targets     = &wgpu.ColorTargetState{
                format    = gfx.config.format,
                writeMask = wgpu.ColorWriteMaskFlags_All,
            },
        },
        primitive = {
            topology = spec.topology,

        },
        multisample = {
            count = 1,
            mask  = 0xFFFFFFFF,
        },
        depthStencil = &{
            format = .Depth32Float,
            depthWriteEnabled = .True,
            depthCompare = .LessEqual
        },

        label = spec.name

    })



    return rp
}


BindRenderPipeline :: proc(rp: ^RenderPipeline, pass: wgpu.RenderPassEncoder) {
    gfx := frost.gfx
    if rp.pipeline != nil {
        wgpu.RenderPassEncoderSetPipeline(pass, rp.pipeline)
    } else {
        log.fatalf("Failed To Bind RenderPipeline")
    }
}

ReleaseRenderPipeline :: proc(rp: ^RenderPipeline) {
    gfx := frost.gfx
    
    wgpu.ShaderModuleRelease(rp.module)
    wgpu.PipelineLayoutRelease(rp.layout)
    wgpu.RenderPipelineRelease(rp.pipeline)

    free(rp)
}



