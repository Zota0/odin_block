package camera

import "core:math"
import "core:math/big"
import "core:math/bits"
import "core:math/cmplx"
import "core:math/ease"
import "core:math/fixed"
import "core:math/linalg"
import "core:math/noise"
import "core:math/rand"

import "../../config/const"

Vec2 :: const.Vec2
Vec3 :: const.Vec3
Vec4 :: const.Vec4
Vec2I :: const.Vec2I
Vec3I :: const.Vec3I
Vec4I :: const.Vec4I
Mat4 :: const.Mat4

DEBUG_MODE :: const.DEBUG_MODE
VSYNC_MODE :: const.VSYNC_MODE

// MARK: camera Structure
Camera :: struct {
    position: Vec3,
    target: Vec3,
    up: Vec3,
    fov: f32,
    aspect: f32,
    near: f32,
    far: f32,
}

// Initialize camera with default values
Camera_Init :: proc(windowSize: Vec2I) -> Camera {
    return Camera{
        position = Vec3{0, 0, 3},  // Camera position
        target = Vec3{0, 0, 0},    // Looking at origin
        up = Vec3{0, 1, 0},        // Up vector
        fov = 88,                  // 88 degree field of view
        aspect = f32(windowSize.x) / f32(windowSize.y),
        near = 1,
        far = 1000.0,
    }
}

// Calculate view matrix
Get_View_Matrix :: proc(camera: ^Camera) -> Mat4 {
    return linalg.matrix4_look_at_f32(
        camera.position,
        camera.target,
        camera.up,
    )
}

// Calculate projection matrix
Get_Projection_Matrix :: proc(camera: ^Camera) -> Mat4 {
    return linalg.matrix4_perspective_f32(
        math.to_radians_f32(camera.fov),
        camera.aspect,
        camera.near,
        camera.far,
    )
}