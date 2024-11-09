package const

import "core:math/linalg"

// MARK: const
DEBUG_MODE :: #config(DEBUG_MODE, true)
VSYNC_MODE :: #config(VSYNC_MODE, true)
FPS_UPDATE_RATE :: #config(FPS_UPDATE_RATE, 1) // For displaying fps
CHUNK_SIZE_X :: #config(CHUNK_SIZE_X, 16)
CHUNK_SIZE_Z :: #config(CHUNK_SIZE_Z, 16)
CHUNK_SIZE_Y :: #config(CHUNK_SIZE_Y, 256)
SUBCHUNK_Y :: #config(SUBCHUNK_Y, 32)
WORLD_SIZE_CHUNKS :: #config(WORLD_SIZE_CHUNKS, 1)

Mat4 :: linalg.Matrix4x4f32

Vec2 :: [2]f32
Vec3 :: [3]f32
Vec4 :: [4]f32

Vec2I :: [2]i32
Vec3I :: [3]i32
Vec4I :: [4]i32

Vec2f64 :: [2]f64
Vec3f64 :: [3]f64
Vec4f64 :: [4]f64

Vec2i64 :: [2]i64
Vec3i64 :: [3]i64
Vec4i64 :: [4]i64
