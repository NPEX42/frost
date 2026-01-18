package frost

import "vendor:wgpu"

CreateFn :: #type proc();
RenderFn :: #type proc(gfx: ^GraphicsContext, render_pass: wgpu.RenderPassEncoder);
UpdateFn :: #type proc(dt: f32);
ShutdownFn :: #type proc();
ResizeFn :: #type proc(width: f32, height: f32)

Application :: struct {
    on_create: CreateFn,
    on_render: RenderFn,
    on_update: UpdateFn,
    on_shutdown: ShutdownFn,
    on_resize: ResizeFn
}