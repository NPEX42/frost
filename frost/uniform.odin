package frost

import "vendor:glfw/bindings"
import "core:log"
import "core:os"
import "vendor:wgpu"


UniformInfo :: struct {
    elemSize: u32,
    buffer: wgpu.Buffer
}

UniformBuffer :: struct($T: typeid) {
    using info: UniformInfo,
}

CreateUniformBufferWithData :: proc($T: typeid, data: ^T) -> ^UniformBuffer(T) {

    buff := new(UniformBuffer(T))

    buff.info.elemSize = size_of(T)

    // Create buffer with correct size
    buff.buffer = wgpu.DeviceCreateBuffer(gfx.device, &{
        label = "",
        size = u64(size_of(T)),  // <- Must be large enough!
        usage = {.Uniform, .CopyDst},
        mappedAtCreation = false,
    })

    // Write data to buffer
    wgpu.QueueWriteBuffer(
        wgpu.DeviceGetQueue(gfx.device),
        buff.buffer,
        0,  // offset
        data,
        size_of(T),  // size in bytes
    )

    return buff
}
SetUniformData :: proc($T: typeid, uniform: ^UniformBuffer(T), data: ^T) {
    // Write data to buffer
    wgpu.QueueWriteBuffer(
        wgpu.DeviceGetQueue(gfx.device),
        uniform.buffer,
        0,  // offset
        data,
        size_of(T),  // size in bytes
    )
}

ReleaseUniformBuffer :: proc($T: typeid, uniform: ^UniformBuffer(T)) {
    wgpu.BufferRelease(uniform.buffer)
    free(uniform)
}

BindingGroup :: struct {
    bindingGroup: wgpu.BindGroup,
    layout: wgpu.BindGroupLayout,
    index: u32
}

CreateBindingGroup :: proc(index: u32, buffers: []UniformInfo, stages: bit_set[wgpu.ShaderStage; u64], name: string = "BindingGroup") -> BindingGroup {
    entrys := make_slice([]wgpu.BindGroupLayoutEntry, len(buffers))


    for _, i in entrys {
        entrys[i].binding = u32(i)
        entrys[i].buffer = {
            hasDynamicOffset = false,
            type = .Uniform
        }
        entrys[i].visibility = stages
    }

    bind_group_layout_desc := wgpu.BindGroupLayoutDescriptor {
        entryCount = len(entrys),
        entries = raw_data(entrys),
    }

    bind_group_layout := wgpu.DeviceCreateBindGroupLayout(gfx.device, &bind_group_layout_desc)

    bindings := make([]wgpu.BindGroupEntry, len(buffers))


    for _, i in bindings {
        bindings[i].binding = u32(i)
        bindings[i].buffer = buffers[i].buffer
        bindings[i].size = u64(buffers[i].elemSize)
    }
    


    group := BindingGroup {
        index = index,
        layout = wgpu.DeviceCreateBindGroupLayout(gfx.device, &bind_group_layout_desc),
        bindingGroup = wgpu.DeviceCreateBindGroup(gfx.device, &wgpu.BindGroupDescriptor {
            layout = bind_group_layout,
            entryCount = len(bindings),
            entries = raw_data(bindings),
            label = name
        })
    }

    delete(entrys)
    delete(bindings)

    return group
}

BindGroup :: proc(group: ^BindingGroup) {
    wgpu.RenderPassEncoderSetBindGroup(gfx.render_pass, group.index, group.bindingGroup)
}

CreateTextureBindingGroup :: proc(index: u32, textures: []Texture, stages: bit_set[wgpu.ShaderStage; u64], name: string = "TexBindingGroup") -> BindingGroup {
    entrys := make_slice([]wgpu.BindGroupLayoutEntry, len(textures) * 2)


    for _, i in entrys {
        entrys[i].binding = u32(i)
        entrys[i].visibility = stages

        if i % 2 == 0 { // Texture View Binding
            entrys[i].texture = {
                multisampled = false,
                sampleType = .Float,
                viewDimension = ._2D
            }
        } else {
            entrys[i].sampler = {
                type = .Filtering
            }
        }

    }

    bind_group_layout_desc := wgpu.BindGroupLayoutDescriptor {
        entryCount = len(entrys),
        entries = raw_data(entrys),
    }

    bind_group_layout := wgpu.DeviceCreateBindGroupLayout(gfx.device, &bind_group_layout_desc)

    bindings := make([]wgpu.BindGroupEntry, len(textures) * 2)


    for _, i in bindings {
        bindings[i].binding = u32(i)
        
        
        if i % 2 == 0 { // Texture View Binding
            bindings[i].textureView = textures[i/2].view
        } else {
            bindings[i].sampler = textures[i/2].sampler
        }

    }
    


    group := BindingGroup {
        index = index,
        layout = bind_group_layout,
        bindingGroup = wgpu.DeviceCreateBindGroup(gfx.device, &wgpu.BindGroupDescriptor {
            layout = bind_group_layout,
            entryCount = len(bindings),
            entries = raw_data(bindings),
            label = name
        })
    }

    delete(entrys)
    delete(bindings)

    return group
}

