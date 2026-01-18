package frost

import "base:runtime"
import "vendor:wgpu"
import "core:fmt"
import "core:reflect"
PrintStructFields :: proc($T: typeid) {
    typeinfo := type_info_of(T)
    fmt.printfln("Size: %v", typeinfo.size)
    fmt.printfln("Align: %v", typeinfo.align)

    fmt.println("=== Fields ===")
    field_names := reflect.struct_field_names(T)
    field_types := reflect.struct_field_types(T)
    field_offsets := reflect.struct_field_offsets(T)
    for i: uint = 0; i < len(field_names); i += 1 {
        fmt.printfln("Field #%v: %v - %v (+%v)", i, field_names[i], field_types[i], field_offsets[i])
    }
}

VertexLayout :: proc($T: typeid) -> []wgpu.VertexAttribute {
    field_types := reflect.struct_field_types(T)
    field_offsets := reflect.struct_field_offsets(T)

    attribs := make([dynamic]wgpu.VertexAttribute, context.temp_allocator)

    for i: uint = 0; i < len(field_types); i += 1 {
        format := TypeToVertexFormat(field_types[i])
        append(&attribs, wgpu.VertexAttribute {
            format = format,
            offset = u64(field_offsets[i]),
            shaderLocation = u32(i)
        })
    }

    return attribs[:]
}


TypeToVertexFormat :: proc(type: ^runtime.Type_Info) -> wgpu.VertexFormat {
    switch type.id {
        case typeid_of(u16): return .Uint16
        case typeid_of(f32): return .Float32
        case typeid_of([2]f32): return .Float32x2
        case typeid_of([3]f32): return .Float32x3
    }

    return .Uint8
}