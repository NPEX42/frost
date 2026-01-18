package frost

import "core:slice"
import "core:strings"
import "core:c"
import "vendor:wgpu"
import "core:log"
import stbi "vendor:stb/image"

Texture :: struct {
    handle: wgpu.Texture,
    size: wgpu.Extent3D,
    view: wgpu.TextureView,
    sampler: wgpu.Sampler
}

CreateSurfaceDepthTexture :: proc() -> Texture {
    g := gfx

    size := wgpu.Extent3D {
        width = g.config.width,
        height = g.config.height,
        depthOrArrayLayers = 1
    }

    desc := wgpu.TextureDescriptor {
        dimension = ._2D,
        format = .Depth32Float,
        size = size,
        mipLevelCount = 1,
        sampleCount = 1,
        usage = {.RenderAttachment, .TextureBinding}
    }

    texture := wgpu.DeviceCreateTexture(g.device, &desc)

    view := wgpu.TextureCreateView(texture)

    sampler := wgpu.DeviceCreateSampler(g.device, &wgpu.SamplerDescriptor {
        addressModeU = .ClampToEdge,
        addressModeV = .ClampToEdge,
        addressModeW = .ClampToEdge,
        compare = .LessEqual,
        magFilter = .Linear,
        minFilter = .Nearest,
        mipmapFilter = .Nearest,
        lodMaxClamp = 100,
        lodMinClamp = 0,
        label = "DepthSampler",
        maxAnisotropy = 1
    })

    return Texture {
        handle = texture,
        sampler = sampler,
        size = size,
        view = view
    }

}

ReleaseTexture :: proc(tex: Texture) {
    if tex.handle != nil do wgpu.TextureRelease(tex.handle)
    if tex.sampler != nil do wgpu.SamplerRelease(tex.sampler)
    if tex.view != nil do wgpu.TextureViewRelease(tex.view)
}

TextureInfo :: struct {
    format: wgpu.TextureFormat,
    minFilter: wgpu.FilterMode,
    magFilter: wgpu.FilterMode
}


CreateTexture :: proc(width, height: u32, info: TextureInfo) -> Texture {
    g := gfx

    size := wgpu.Extent3D {
        width = width,
        height = height,
        depthOrArrayLayers = 1
    }

    desc := wgpu.TextureDescriptor {
        dimension = ._2D,
        format = info.format,
        size = size,
        mipLevelCount = 1,
        sampleCount = 1,
        usage = {.TextureBinding, .CopyDst}
    }

    texture := wgpu.DeviceCreateTexture(g.device, &desc)

    view := wgpu.TextureCreateView(texture)

    sampler := wgpu.DeviceCreateSampler(g.device, &wgpu.SamplerDescriptor {
        addressModeU = .ClampToEdge,
        addressModeV = .ClampToEdge,
        addressModeW = .ClampToEdge,
        compare = .Undefined,
        magFilter = info.magFilter,
        minFilter = info.minFilter,
        mipmapFilter = .Linear,
        lodMaxClamp = 100,
        lodMinClamp = 0,
        label = "TextureSampler",
        maxAnisotropy = 1
    })

    return Texture {
        handle = texture,
        sampler = sampler,
        size = size,
        view = view
    }

}


SetTextureData_RGBA8 :: proc(tex: ^Texture, pixels: []u8) {
    g := gfx
    wgpu.QueueWriteTexture(
        g.queue, 
        &wgpu.TexelCopyTextureInfo {
            aspect = .All,
            mipLevel = 0,
            origin = {x = 0, y = 0, z = 0},
            texture = tex.handle
        },
        raw_data(pixels),
        size_of(u8) * len(pixels),
        &wgpu.TexelCopyBufferLayout {
            bytesPerRow = tex.size.width * 4,
            offset = 0,
            rowsPerImage = tex.size.height
        },
        &tex.size
    )

}


LoadTexture :: proc(filepath: string) -> Texture {
    w: c.int = 0
    h: c.int = 0
    channels: c.int = 0
    data := stbi.load(strings.clone_to_cstring(filepath, context.temp_allocator), &w, &h, &channels, 4)
    defer stbi.image_free(data)

    tex := CreateTexture(u32(w), u32(h), {
        format = .RGBA8Unorm,
        magFilter = .Nearest,
        minFilter = .Nearest
    })
    SetTextureData_RGBA8(&tex, slice.from_ptr(data, int(w * h * channels)))

    return tex
}