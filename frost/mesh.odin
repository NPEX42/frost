package frost

import "core:os"
import "core:log"
import "core:fmt"
import "core:strings"
import "vendor:cgltf"
import "vendor:wgpu"

import "tinyobj"

import "core:math/rand"

StaticMesh :: struct {
    vertices: []Vertex3D,
    indices: []u16,

    ibo: IndexBufferU16,
    vbo: VertexBuffer
}

CreateStaticMeshFromSlices :: proc(vertices: []Vertex3D, indices: []u16) -> StaticMesh {
    mesh := StaticMesh {
        indices = indices,
        vertices = vertices,
        ibo = CreateIndexBufferU16(len(indices)),
        vbo = CreateVertexBuffer(len(vertices))
    }

    SetVertexBufferData(&mesh.vbo, vertices)
    SetIndexBufferU16Data(&mesh.ibo, indices)

    UploadVertexBufferData(&mesh.vbo)
    UploadIndexBufferU16Data(&mesh.ibo)

    return mesh
}

DrawStaticMesh :: proc(mesh: ^StaticMesh, instances: u32 = 1) {
    BindVertexBuffer(&mesh.vbo)
    BindIndexBufferU16(&mesh.ibo)
    wgpu.RenderPassEncoderDrawIndexed(gfx.render_pass, u32(len(mesh.indices)), instances, 0, 0, 0);
}

LoadStaticMesh_OBJ :: proc(filepath: string, base_dir: string = "") -> (mesh: StaticMesh, success: bool) {
    
    data, ok := os.read_entire_file(filepath)
	if !ok {
		fmt.println("Failed to read file")
        success = false
		return
	}
	defer delete(data)

    obj := tinyobj.parse_obj(string(data), base_dir)
    defer tinyobj.destroy(&obj)

    if !obj.success {
        success = false
        log.fatalf("Failed to Parse OBJ File '%v'", filepath)
        return
    }

    fmt.printf("# of vertices  = %d\n", len(obj.attrib.vertices) / 3)
	fmt.printf("# of normals   = %d\n", len(obj.attrib.normals) / 3)
	fmt.printf("# of texcoords = %d\n", len(obj.attrib.texcoords) / 2)
	fmt.printf("# of shapes    = %d\n", len(obj.shapes))
	fmt.printf("# of materials = %d\n", len(obj.materials))

    indices := make([]u16, len(obj.attrib.faces), context.temp_allocator)
    uv_indices := make([]u16, len(obj.attrib.faces), context.temp_allocator)
    verts := make([]Vertex3D, len(obj.attrib.vertices) / 3, context.temp_allocator)

    for shape in obj.shapes {
		fmt.printf("Shape: %s\n", shape.name)
		
		// Iterate over faces in this shape
		index_offset := 0
		for f := 0; f < shape.length; f += 1 {
			current_face_idx := shape.face_offset + f
			num_verts := obj.attrib.face_num_verts[current_face_idx]
			mat_id := obj.attrib.material_ids[current_face_idx]

			fmt.printf("  Face %d (Material ID: %d): ", f, mat_id)
			
			// Print vertex indices for this face
			for v := 0; v < num_verts; v += 1 {
				idx := obj.attrib.faces[index_offset + v]
				fmt.printf("%d/%d/%d ", idx.v_idx, idx.vt_idx, idx.vn_idx)

                indices[index_offset + v] = u16(idx.v_idx)

                uv_indices[index_offset + v] = u16(idx.vt_idx)
			}
			fmt.println("")
			
			index_offset += num_verts
		}
    }

    for _, i in verts {
        verts[i] = Vertex3D {
            position = {
                obj.attrib.vertices[i * 3 + 0],
                obj.attrib.vertices[i * 3 + 1],
                obj.attrib.vertices[i * 3 + 2]
            },
            color = {
                rand.float32(),
                rand.float32(),
                rand.float32()
            },
            UV0 = {
                obj.attrib.texcoords[uv_indices[i] * 2 + 0],
                obj.attrib.texcoords[uv_indices[i] * 2 + 1],
            }
        }
    }

    success = true;
    return CreateStaticMeshFromSlices(verts, indices ), true
}