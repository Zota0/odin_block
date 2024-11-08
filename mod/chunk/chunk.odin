package chunk

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

Chunk :: struct {
    x:         i8,
    y:         i8,
    z:         i8,
    subChunks: []SubChunk,
}

SubChunk :: struct {
    id:     u8,
    blocks: []Block,
}

CreateChunk :: proc(x: i8, y: i8, z: i8) -> Chunk {
    return Chunk{x, y, z, make([]SubChunk, (CHUNK_SIZE_Y / SUBCHUNK_HEIGHT))}
}

CreateSubChunk :: proc(x: i8, y: i8, z: i8) -> SubChunk {
    return SubChunk{0, make([]Block, (CHUNK_SIZE_X * SUBCHUNK_HEIGHT * CHUNK_SIZE_Z))}
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