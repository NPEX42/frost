package frostGfx

import "vendor:wgpu"
import "core:log"
import "core:os"

import ".."

Buffer :: struct($T: typeid) {
    inner: wgpu.Buffer,
    data: []T
}

CreateBuffer :: proc($T: typeid, length: int, usage: wgpu.BufferUsageFlags, label: string = "DataBuffer") -> Buffer(T) {
    buff := Buffer(T) {}
    g := frost.gfx

    buff.inner = wgpu.DeviceCreateBuffer(g.device, &wgpu.BufferDescriptor {
        label = label,
        mappedAtCreation = false,
        size = u64(size_of(T) * length),
        usage = usage
    })

    buff.data = nil

    return buff
}

UploadBufferData :: proc($T: typeid, buffer: ^Buffer(T)) {
    g := frost.gfx
    wgpu.QueueWriteBuffer(g.queue, buffer.inner, 0, raw_data(buffer.data), size_of(T) * len(buffer.data))
}

SetBufferData :: proc($T: typeid, buffer: ^Buffer(T), data: []T) {
    buffer.data = data
}

VertexBuffer :: Buffer(Vertex3D)

CreateVertexBuffer :: proc(length: int, label: string = "VertexBuffer") -> VertexBuffer {
    return CreateBuffer(Vertex3D, length, {.CopyDst, .Vertex}, label)
}

UploadVertexBufferData :: proc(buffer: ^VertexBuffer) {
    UploadBufferData(Vertex3D, buffer)
} 

SetVertexBufferData :: proc(buffer: ^VertexBuffer, data: []Vertex3D) {
    SetBufferData(Vertex3D, buffer, data)
}

BindVertexBuffer :: proc(buffer: ^VertexBuffer) {
    g := frost.gfx
    wgpu.RenderPassEncoderSetVertexBuffer(g.render_pass, 0, buffer.inner, 0, u64(len(buffer.data) * size_of(Vertex3D)))
}




IndexBufferU16 :: Buffer(u16)

CreateIndexBufferU16 :: proc(length: int, label: string = "IndexBuffer_u16") -> IndexBufferU16 {
    return CreateBuffer(u16, length, {.CopyDst, .Index}, label)
}

UploadIndexBufferU16Data :: proc(buffer: ^IndexBufferU16) {
    UploadBufferData(u16, buffer)
} 

SetIndexBufferU16Data :: proc(buffer: ^IndexBufferU16, data: []u16) {
    SetBufferData(u16, buffer, data)
}

BindIndexBufferU16 :: proc(buffer: ^IndexBufferU16) {
    g := frost.gfx
    wgpu.RenderPassEncoderSetIndexBuffer(g.render_pass, buffer.inner, .Uint16, 0, u64(len(buffer.data) * size_of(u16)))
}


IndexBufferU32 :: Buffer(u32)

CreateIndexBufferU32 :: proc(length: int, label: string = "IndexBuffer_u32") -> IndexBufferU32 {
    return CreateBuffer(u32, length, {.CopyDst, .Index}, label)
}

UploadIndexBufferU32Data :: proc(buffer: ^IndexBufferU32) {
    UploadBufferData(u32, buffer)
} 

SetIndexBufferU32Data :: proc(buffer: ^IndexBufferU32, data: []u32) {
    SetBufferData(u32, buffer, data)
}

BindIndexBufferU32 :: proc(buffer: ^IndexBufferU32) {
    g := frost.gfx
    wgpu.RenderPassEncoderSetIndexBuffer(g.render_pass, buffer.inner, .Uint32, 0, u64(len(buffer.data) * size_of(u32)))
}