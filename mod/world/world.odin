package world

import "core:fmt"
import "core:math/linalg"
import chunks "../chunk"
import draw "../draw"
import obj "../objects"
import sha "../shaders"
import gl "vendor:OpenGL"
import "../../config/const"

Vec2    :: const.Vec2
Vec3    :: const.Vec3
Vec4    :: const.Vec4
Vec2I   :: const.Vec2I
Vec3I   :: const.Vec3I
Vec4I   :: const.Vec4I
Vec2f64 :: const.Vec2f64
Vec3f64 :: const.Vec3f64
Vec4f64 :: const.Vec4f64
Vec2i64 :: const.Vec2i64
Vec3i64 :: const.Vec3i64
Vec4i64 :: const.Vec4i64
V
Vec3i8

CHUNK_SIZE_X :: const.CHUNK_SIZE_X        // 16
CHUNK_SIZE_Y :: const.CHUNK_SIZE_Y        // 256
CHUNK_SIZE_Z :: const.CHUNK_SIZE_Z        // 16
SUBCHUNK_HEIGHT :: const.SUBCHUNK_Y       // 32
WORLD_SIZE_CHUNKS :: const.WORLD_SIZE_CHUNKS // 1

World :: struct {
    chunks: []chunks.Chunk,
    shader_program: u32,
    view_loc: i32,
    proj_loc: i32,
    model_loc: i32,
}

CreateWorld :: proc() -> (world: World, ok: bool) {
    program, shader_ok := shaderProgram()
    if !shader_ok {
        return World{}, false
    }
    
    view_loc, proj_loc, model_loc := sha.GetAllUniforms(program)
    
    return World{
        chunks = make([]chunks.Chunk, WORLD_SIZE_CHUNKS),
        shader_program = program,
        view_loc = view_loc,
        proj_loc = proj_loc,
        model_loc = model_loc,
    }, true
}

MakeWorldDirt :: proc(world: ^World) {
    for i := 0; i < WORLD_SIZE_CHUNKS; i += 1 {
        world.chunks[i] = chunks.CreateChunk(i8(i), 0, 0)
        
        for j := 0; j < CHUNK_SIZE_Y / SUBCHUNK_HEIGHT; j += 1 {
            subchunk := chunks.CreateSubChunk(i8(i), i8(j), 0)
            world.chunks[i].subChunks[j] = subchunk
            
            for x := 0; x < CHUNK_SIZE_X; x += 1 {
                for y := 0; y < SUBCHUNK_HEIGHT; y += 1 {
                    for z := 0; z < CHUNK_SIZE_Z; z += 1 {
                        block := NewBlock(
                            i8(x), 
                            i8(y + j * SUBCHUNK_HEIGHT), 
                            i8(z),
                            chunks.BLOCK_TYPE.SOLID,
                            chunks.BLOCK_ID.DIRT,
                            i32(i), // chunk ID
                        )
                        chunks.SetBlock(&subchunk, i8(x), i8(y), i8(z), block)
                    }
                }
            }
        }
    }
}

shaderProgram :: proc() -> (program: u32, ok: bool) {
    program, ok = sha.ShaderProgram("shaders/vertex.glsl", "shaders/fragment.glsl")
    if !ok {
        fmt.println("Failed to initialize shader program")
        return 0, false
    }
    return program, true
}

NewBlock :: proc(
    x: i8,
    y: i8,
    z: i8,
    block_type: chunks.BLOCK_TYPE,
    id: chunks.BLOCK_ID,
    chunk_id: i32,
) -> chunks.Block {
    // Create block mesh and get buffer handles
    vao, ebo, vbo := obj.CreateCube(1.0)
    
    // Create and set up model matrix for block position
    model_matrix := linalg.MATRIX4F32_IDENTITY
    model_matrix = linalg.matrix4_translate_f32(Vec3i8{x, y, z})
    
    return chunks.Block{
        position = {x, y, z},
        chunkID = chunk_id,
        block_type = block_type,
        id = id,
        vao = vao,
        vbo = vbo,
        ebo = ebo,
        model_matrix = model_matrix,
    }
}

DrawWorld :: proc(world: ^World, view_matrix: matrix[4, 4]f32, proj_matrix: matrix[4, 4]f32, camera_pos: Vec3) {
    draw.EnableDepthTest()
    draw.EnableCullFace()
    draw.EnableCullFaceBack()
    draw.EnableCullFaceCCW()
    
    gl.UseProgram(world.shader_program)
    
    // Use the provided view and projection matrices
    gl.UniformMatrix4fv(world.view_loc, 1, false, &view_matrix[0, 0])
    gl.UniformMatrix4fv(world.proj_loc, 1, false, &proj_matrix[0, 0])
    
    for i := 0; i < WORLD_SIZE_CHUNKS; i += 1 {
        chunk := &world.chunks[i]
        
        // Basic frustum culling check for chunk
        chunk_pos := Vec3{
            f32(chunk.x) * f32(CHUNK_SIZE_X), 
            f32(chunk.y), 
            f32(chunk.z) * f32(CHUNK_SIZE_Z),
        }
        if !IsChunkVisible(chunk_pos, camera_pos) {
            continue
        }
        
        for j := 0; j < CHUNK_SIZE_Y / SUBCHUNK_HEIGHT; j += 1 {
            subchunk := &chunk.subChunks[j]
            
            for k := 0; k < CHUNK_SIZE_X * SUBCHUNK_HEIGHT * CHUNK_SIZE_Z; k += 1 {
                x := k % CHUNK_SIZE_X
                y := (k / CHUNK_SIZE_X) % SUBCHUNK_HEIGHT
                z := k / (CHUNK_SIZE_X * SUBCHUNK_HEIGHT)
                
                block := chunks.GetBlock(subchunk, i8(x), i8(y), i8(z))
                
                if block.block_type == chunks.BLOCK_TYPE.SOLID {
                    gl.UniformMatrix4fv(world.model_loc, 1, false, &block.model_matrix[0, 0])
                    gl.BindVertexArray(block.vao)
                    gl.DrawElements(gl.TRIANGLES, 36, gl.UNSIGNED_INT, nil)
                }
            }
        }
    }
    
    gl.BindVertexArray(0)
    gl.UseProgram(0)
}

// Basic frustum culling check
IsChunkVisible :: proc(chunk_pos: Vec3, camera_pos: Vec3) -> bool {
    // Simple distance-based culling
    MAX_RENDER_DISTANCE :: 256.0  // Adjust as needed
    dist := linalg.distance(chunk_pos, camera_pos)
    return dist < MAX_RENDER_DISTANCE
}

DestroyWorld :: proc(world: ^World) {
    // Clean up shader program
    if world.shader_program != 0 {
        gl.DeleteProgram(world.shader_program)
    }
    
    // Clean up chunks and blocks
    for chunk in world.chunks {
        for subchunk in chunk.subChunks {
            for block in subchunk.blocks {
                // Clean up OpenGL resources for each block
                if block.vao != 0 do gl.DeleteVertexArrays(1, &block.vao)
                if block.vbo != 0 do gl.DeleteBuffers(1, &block.vbo)
                if block.ebo != 0 do gl.DeleteBuffers(1, &block.ebo)
            }
            delete(subchunk.blocks)
        }
        delete(chunk.subChunks)
    }
    delete(world.chunks)
}