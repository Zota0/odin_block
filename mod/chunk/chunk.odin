package chunk

import "core:fmt"
import "core:strings"
import "core:math/linalg"
import gl "vendor:OpenGL"
import obj "../objects"
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

CHUNK_SIZE_X :: const.CHUNK_SIZE_X    // 16
CHUNK_SIZE_Y :: const.CHUNK_SIZE_Y    // 256
CHUNK_SIZE_Z :: const.CHUNK_SIZE_Z    // 16
SUBCHUNK_HEIGHT :: const.SUBCHUNK_Y   // 32

BLOCK_TYPE :: enum {
    EMPTY = 0,
    SOLID = 1,
    LIQUID = 2,
    MODIFIER = 3,
}

BLOCK_ID :: enum {
    AIR = 0,
    DIRT = 1,
}

BLOCK_NAME := []string{
    "air",
    "dirt",
}

Block :: struct {
    position: Vec3I,            // block position within chunk
    chunkID: i32,              // ID of the chunk this block belongs to
    block_type: BLOCK_TYPE,
    id: BLOCK_ID,
    vao: u32,                  // Vertex Array Object
    vbo: u32,                  // Vertex Buffer Object
    ebo: u32,                  // Element Buffer Object
    model_matrix: matrix[4, 4]f32,
}

Chunk :: struct {
    x: i8,
    y: i8,
    z: i8,
    subChunks: []SubChunk,
}

SubChunk :: struct {
    id: u8,
    blocks: []Block,
}

CreateChunk :: proc(x: i8, y: i8, z: i8) -> Chunk {
    return Chunk{
        x = x,
        y = y,
        z = z,
        subChunks = make([]SubChunk, (CHUNK_SIZE_Y / SUBCHUNK_HEIGHT)),
    }
}

CreateSubChunk :: proc(x: i8, y: i8, z: i8) -> SubChunk {
    blocks := make([]Block, (CHUNK_SIZE_X * SUBCHUNK_HEIGHT * CHUNK_SIZE_Z))
    return SubChunk{
        id = 0,
        blocks = blocks,
    }
}

GetSubChunk :: proc(chunk: ^Chunk, x: i8, y: i8, z: i8) -> SubChunk {
    subchunk_index := y / SUBCHUNK_HEIGHT
    return chunk.subChunks[subchunk_index]
}

GetBlockFromChunk :: proc(chunk: ^Chunk, x: i8, y: i8, z: i8) -> Block {
    subchunk_index := y / SUBCHUNK_HEIGHT
    local_y := y % SUBCHUNK_HEIGHT
    return GetBlock(&chunk.subChunks[subchunk_index], x, local_y, z)
}

GetBlock :: proc(subChunk: ^SubChunk, x: i8, y: i8, z: i8) -> Block {
    index := int(x) + int(y) * CHUNK_SIZE_X + int(z) * CHUNK_SIZE_X * SUBCHUNK_HEIGHT
    return subChunk.blocks[index]
}

SetBlock :: proc(subChunk: ^SubChunk, x: i8, y: i8, z: i8, block: Block) {
    index := int(x) + int(y) * CHUNK_SIZE_X + int(z) * CHUNK_SIZE_X * SUBCHUNK_HEIGHT
    subChunk.blocks[index] = block
}

GetBlockTex :: proc(block: Block) -> string {
    return fmt.tprintf("assets/%v.png", BLOCK_NAME[block.id])
}

CreateBlock :: proc(x: i8, y: i8, z: i8, chunk_id: i32, block_type: BLOCK_TYPE, block_id: BLOCK_ID) -> Block {
    // Create OpenGL buffers for the block
    vao, ebo, vbo := obj.CreateCube(1.0)  // 1.0 is the size of the block
    
    // Create model matrix for the block's position
    model_matrix := linalg.MATRIX4F32_IDENTITY
    model_matrix = linalg.matrix4_translate_f32({f32(x), f32(y), f32(z)})
    
    return Block{
        position = {x, y, z},
        chunkID = chunk_id,
        block_type = block_type,
        id = block_id,
        vao = vao,
        vbo = vbo,
        ebo = ebo,
        model_matrix = model_matrix,
    }
}
