/// Frost Engine Core
package frost

import "core:time"
import "core:thread"
import "core:os"
import "core:mem"
import "base:runtime"
import "core:fmt"
import "core:log"

import "vendor:glfw"
import "vendor:wgpu"
import "vendor:wgpu/glfwglue"





GraphicsContext :: struct {
    ctx:                runtime.Context,
    window:             glfw.WindowHandle,
    instance:           wgpu.Instance,
	surface:            wgpu.Surface,
	adapter:            wgpu.Adapter,
	device:             wgpu.Device,
	config:             wgpu.SurfaceConfiguration,
	queue:              wgpu.Queue,
	module:             wgpu.ShaderModule,
	pipeline_layout:    wgpu.PipelineLayout,
	pipeline:           wgpu.RenderPipeline,


    clear_color: [4]f64,

    render_pass: wgpu.RenderPassEncoder,

    depth: Texture
}

gfx: GraphicsContext

application: ^Application = nil

track: mem.Tracking_Allocator

MEM_POLL_TIME :: 5.0


init :: proc(app: ^Application) {

    

    when ODIN_DEBUG {
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {

            //log.destroy_console_logger(context.logger)
    

            fmt.println("=== Memory Stats ===")
            fmt.printfln("Peak Usage: %v Bytes ", track.peak_memory_allocated)

			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

    application = app;

    log.info("Initializing Frost Engine.")

    

    gfx.ctx = context;


    if !glfw.Init() {
        log.panic("Failed To Initialize GLFW.")
    }
    glfw.WindowHint(glfw.CLIENT_API, glfw.NO_API)
    gfx.window = glfw.CreateWindow(1080, 720, "Frost Engine", nil, nil);

    gfx.instance = wgpu.CreateInstance(nil)
    if gfx.instance == nil {
        log.panic("Failed To Create WGPU Instance.")
    }

    gfx.surface = glfwglue.GetSurface(gfx.instance, gfx.window);

    log.info("Creating Adapter")

    wgpu.InstanceRequestAdapter(gfx.instance, &{compatibleSurface = gfx.surface}, {callback = on_adapter})


    on_adapter :: proc "c" (status: wgpu.RequestAdapterStatus, adapter: wgpu.Adapter, message: string, userdata1: rawptr, userdata2: rawptr) {
        context = gfx.ctx;

        if status != .Success || adapter == nil {
            log.panic("Failed To Get Adapter.")
        }

        gfx.adapter = adapter;

        log.info("Created Adapter")

        wgpu.AdapterRequestDevice(adapter, nil, {callback = on_device})

    }

    on_device :: proc "c" (status: wgpu.RequestDeviceStatus, device: wgpu.Device, message: string, _u1: rawptr, _u2: rawptr) {
        context = gfx.ctx
        if status != .Success || device == nil {
            log.panic("Failed To Get Device.")
        }

        log.info("Created Device")

        gfx.device = device;


        width, height := framebuffer_size()


        log.debugf("Surface %p", gfx.surface)
        caps, status := wgpu.SurfaceGetCapabilities(gfx.surface, gfx.adapter)

        for i: uint = 0; i < caps.formatCount; i += 1 {
            log.debugf("Surface Formats: %v", caps.formats[i])
        }


        gfx.config = wgpu.SurfaceConfiguration {
            device = gfx.device,
            usage = {.RenderAttachment},
            format = caps.formats[0],
            width = width,
            height = height,
            presentMode = .Fifo,
            alphaMode = .Opaque,
        }

        log.info("Configuring Surface (", width, ",", height, ")")


        wgpu.SurfaceConfigure(gfx.surface, &gfx.config);

        gfx.depth = CreateSurfaceDepthTexture()

        gfx.queue = wgpu.DeviceGetQueue(gfx.device)



    


        


        run();
    }
}



framebuffer_size :: proc() -> (u32, u32) {
    iw, ih := glfw.GetFramebufferSize(gfx.window)
	return u32(iw), u32(ih)
}

pollEvents :: proc() {
    glfw.PollEvents()
}

run :: proc() {



    application.on_create();
    dt, accumTime: f32 = 0.0, 0
    memTimer: f32 = 0
    for !glfw.WindowShouldClose(gfx.window) {
        timeStart := f32(glfw.GetTime());
        pollEvents()
        w, h := framebuffer_size();
        if w == 0 || h == 0 { 
            time.sleep(time.Millisecond * 10)
            log.info("sleeping")
        }
        application.on_update(dt);
        render()

        timeEnd := f32(glfw.GetTime());

        dt = timeEnd - timeStart
        accumTime += dt
        memTimer += dt
        if memTimer >= MEM_POLL_TIME {
            memTimer -= MEM_POLL_TIME
            log.infof("Memory Usage: %v bytes", track.current_memory_allocated)
        }
        free_all(context.temp_allocator)


    }
    application.on_shutdown();
    finish();
}


render :: proc() {
    surface_tex := wgpu.SurfaceGetCurrentTexture(gfx.surface)
    switch surface_tex.status {
        case .SuccessOptimal, .SuccessSuboptimal:

        case .Timeout, .Outdated, .Lost:
            if surface_tex.texture != nil {
                wgpu.TextureRelease(surface_tex.texture)
            }
            resize()
            return;

        case .OutOfMemory, .DeviceLost, .Error:
            // Fatal error
            log.panicf("[triangle] get_current_texture status=%v", surface_tex.status)
    }

    defer wgpu.TextureRelease(surface_tex.texture)

    frame := wgpu.TextureCreateView(surface_tex.texture, nil)
    defer wgpu.TextureViewRelease(frame)

    command_encoder := wgpu.DeviceCreateCommandEncoder(gfx.device, nil)
    defer wgpu.CommandEncoderRelease(command_encoder)

    render_pass_enc := wgpu.CommandEncoderBeginRenderPass(command_encoder, &{
        colorAttachmentCount = 1,
        colorAttachments = &wgpu.RenderPassColorAttachment {
            view = frame, 
            loadOp = .Clear,
            storeOp = .Store,
            depthSlice = wgpu.DEPTH_SLICE_UNDEFINED,
            clearValue = gfx.clear_color
        },
        depthStencilAttachment = &wgpu.RenderPassDepthStencilAttachment {
            view = gfx.depth.view,
            depthLoadOp = .Clear,
            depthStoreOp = .Store,
            depthClearValue = 1.0
        }
    })

    gfx.render_pass = render_pass_enc

    

    application.on_render(&gfx, render_pass_enc);

    wgpu.RenderPassEncoderEnd(render_pass_enc)
    wgpu.RenderPassEncoderRelease(render_pass_enc)

    command_buffer := wgpu.CommandEncoderFinish(command_encoder, nil)
    defer wgpu.CommandBufferRelease(command_buffer)

    wgpu.QueueSubmit(gfx.queue, {command_buffer})

    wgpu.SurfacePresent(gfx.surface)


}

finish :: proc() {

}

resize :: proc() {
    gfx.config.width, gfx.config.height = framebuffer_size()
	wgpu.SurfaceConfigure(gfx.surface, &gfx.config)
    ReleaseTexture(gfx.depth)
    gfx.depth = CreateSurfaceDepthTexture()
    w, h := framebuffer_size()
    application.on_resize(f32(w), f32(h))
}
