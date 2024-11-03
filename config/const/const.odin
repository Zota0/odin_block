package const

import "core:math/linalg"

// MARK: const
DEBUG_MODE :: #config(DEBUG_MODE, true)
VSYNC_MODE :: #config(VSYNC_MODE, true)

Mat4 :: linalg.Matrix4x4f32

Vec2 :: [2]f32
Vec3 :: [3]f32
Vec4 :: [4]f32
Vec2I :: [2]i32
Vec3I :: [3]i32
Vec4I :: [4]i32