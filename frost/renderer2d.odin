package frost

import "vendor:wgpu"
Vec2f :: #type [2]f32
Color3f :: #type [3]f32

Vertex2D :: struct {
    position: Vec2f,
    UV0: Vec2f,
    Color: Color3f
}

MAX_QUADS   :: 16384
MAX_VERTS   :: MAX_QUADS * 4
MAX_INDICES :: MAX_QUADS * 6

Renderer2D :: struct {

    vertices: [MAX_VERTS]Vertex2D,
    indices: [MAX_INDICES]u16,

    vertexCount: u16,
    indexCount: u16,

    pipeline: ^RenderPipeline,
    vbo: Vertex2DBuffer,
    ibo: IndexBufferU16,
}

r2d: Renderer2D

InitR2D :: proc() {

    spec := &MaterialSpec {
        fs_entry = "fs_main",
        name = "R2D",
        vs_entry = "vs_main",
        sourcePath = "res/shaders/r2d.wgsl",
        topology = .TriangleList,
        layout_desc = nil
    }

    r2d.pipeline = CreateRenderPipeline(spec, Vertex2D)

    r2d.ibo = CreateIndexBufferU16(MAX_INDICES)
    r2d.vbo = CreateVertex2DBuffer(MAX_VERTS)

    r2d.indexCount = 0
    r2d.vertexCount = 0
}

FlushR2D :: proc() {
    if r2d.vertexCount == 0 {
        return
    }


    SetIndexBufferU16Data(&r2d.ibo, r2d.indices[:])
    SetVertex2DBufferData(&r2d.vbo, r2d.vertices[:])

    UploadIndexBufferU16Data(&r2d.ibo)
    UploadVertex2DBufferData(&r2d.vbo)

    BindIndexBufferU16(&r2d.ibo)
    BindVertex2DBuffer(&r2d.vbo)
    wgpu.RenderPassEncoderDrawIndexed(gfx.render_pass, u32(r2d.indexCount), 1, 0, 0, 0)

    r2d.indexCount = 0
    r2d.vertexCount = 0
}

PushQuad :: proc(pos: Vec2f, size: Vec2f, color: Color3f = {1, 1, 1}) {
    
} 