package camera

import "core:math"
import "core:math/linalg"

// Move camera along its local axes
Camera_Move_Forward :: proc(camera: ^Camera, distance: f32) {
    direction := linalg.normalize(camera.target - camera.position)
    camera.position += direction * distance
    camera.target += direction * distance
}

Camera_Move_Right :: proc(camera: ^Camera, distance: f32) {
    direction := linalg.normalize(camera.target - camera.position)
    right := linalg.normalize(linalg.cross(direction, camera.up))
    camera.position += right * distance
    camera.target += right * distance
}

Camera_Move_Up :: proc(camera: ^Camera, distance: f32) {
    camera.position += camera.up * distance
    camera.target += camera.up * distance
}

// Rotate camera around its local axes
Camera_Rotate :: proc(camera: ^Camera, yaw, pitch: f32) {
    // Calculate the direction vector from position to target
    direction := linalg.normalize(camera.target - camera.position)
    
    // Create rotation quaternions for yaw and pitch
    yaw_quat := linalg.quaternion_angle_axis_f32(yaw, camera.up)
    right := linalg.normalize(linalg.cross(direction, camera.up))
    pitch_quat := linalg.quaternion_angle_axis_f32(pitch, right)
    
    // Combine rotations and apply to direction
    rotation := linalg.quaternion_mul_quaternion(pitch_quat, yaw_quat)
    new_direction := linalg.quaternion_mul_vector3(rotation, direction)
    
    // Update target position based on rotated direction
    camera.target = camera.position + new_direction
}

// Orbit camera around target point
Camera_Orbit :: proc(camera: ^Camera, yaw, pitch: f32) {
    // Calculate current spherical coordinates
    offset := camera.position - camera.target
    radius := linalg.length(offset)
    current_pitch := math.asin(offset.y / radius)
    current_yaw := math.atan2(offset.z, offset.x)
    
    // Update angles
    new_pitch := clamp(current_pitch + pitch, -math.PI/2 + 0.1, math.PI/2 - 0.1)
    new_yaw := current_yaw + yaw
    
    // Convert back to Cartesian coordinates
    camera.position = {
        camera.target.x + radius * math.cos(new_pitch) * math.cos(new_yaw),
        camera.target.y + radius * math.sin(new_pitch),
        camera.target.z + radius * math.cos(new_pitch) * math.sin(new_yaw),
    }
}

// Zoom camera (change distance to target)
Camera_Zoom :: proc(camera: ^Camera, factor: f32) {
    direction := linalg.normalize(camera.target - camera.position)
    distance := linalg.length(camera.target - camera.position)
    new_distance := clamp(distance * factor, 0.1, 100.0)
    camera.position = camera.target - direction * new_distance
}

// Utility functions
clamp :: proc(value, min, max: f32) -> f32 {
    if value < min do return min
    if value > max do return max
    return value
}

// Update camera field of view
Camera_Set_FOV :: proc(camera: ^Camera, fov: f32) {
    camera.fov = clamp(fov, 10.0, 120.0)
}

// Reset camera to default position
Camera_Reset :: proc(camera: ^Camera) {
    camera.position = Vec3{0, 0, 3}
    camera.target = Vec3{0, 0, 0}
    camera.up = Vec3{0, 1, 0}
    camera.fov = 88
}