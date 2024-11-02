package main

// MARK: Named imports
import gl "vendor:OpenGL"
import lua "vendor:lua/5.4"
import glfw "vendor:glfw"
import net "vendor:ENet"
import img "vendor:stb/image"
import font "vendor:stb/easy_font"
import gui "vendor:microui"
import json "core:encoding/json"
import base64 "core:encoding/base64"
import base32 "core:encoding/base32"
import xml "core:encoding/xml"
import hex "core:encoding/hex"
import ansi "core:encoding/ansi"
import csv "core:encoding/csv"
import ini "core:encoding/ini"

// MARK: Maths
import "core:math/big"
import "core:math/bits"
import "core:math/cmplx"
import "core:math/ease"
import "core:math/fixed"
import "core:math/linalg"
import "core:math/noise"
import "core:math/rand"

// MARK: Other imports
import "core:thread"
import "core:time"
import "core:io"
import "core:fmt"
import "core:reflect"
import "core:hash"
import "core:crypto"
import "core:os"
import "core:log"
import "core:debug/trace"
import "core:math"
import "core:strings"
import "core:strconv"
import "base:runtime"
import "core:bufio"

// MARK: Custom modules
import ll "modules/lua"
import obj "modules/objects"
import shaders "modules/shaders"

// MARK: Constants
DEBUG_MODE :: #config(DEBUG_MODE, true)
VSYNC_MODE :: #config(VSYNC_MODE, true)

Mat4 :: linalg.Matrix4x4f32

Vec2 :: [2]f32
Vec3 :: [3]f32
Vec4 :: [4]f32
Vec2I :: [2]i32
Vec3I :: [3]i32
Vec4I :: [4]i32

// MARK: Camera Structure
Camera :: struct {
    position: Vec3,
    target: Vec3,
    up: Vec3,
    fov: f32,
    aspect: f32,
    near: f32,
    far: f32,
}

// MARK: Variables
ctx: runtime.Context
window: glfw.WindowHandle
camera: Camera

// Initialize camera with default values
Camera_Init :: proc(windowSize: Vec2I) -> Camera {
    return Camera{
        position = Vec3{0, 0, 3},  // Camera position
        target = Vec3{0, 0, 0},    // Looking at origin
        up = Vec3{0, 1, 0},        // Up vector
        fov = 88,                  // 45 degree field of view
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

GLFW_Init :: proc() -> bool {
    if !glfw.Init() {
        fmt.eprintln("Failed to initialize GLFW")
        return false
    }
    fmt.println("GLFW initialized successfully")
    return true
}

// MARK: Window init
Window_Init :: proc(win_size: Vec2I) -> bool {
    fmt.println("Setting GLFW window hints")
    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 4)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 6)
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
    glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, glfw.TRUE)
    
    when DEBUG_MODE { 
        glfw.WindowHint(glfw.CONTEXT_DEBUG, glfw.TRUE)
    }
    
    fmt.println("Creating window")
    window = glfw.CreateWindow(win_size.x, win_size.y, "Odin Block", nil, nil)
    if window == nil {
        fmt.eprintln("Failed to create window")
        return false
    }
    
    fmt.println("Making context current")
    glfw.MakeContextCurrent(window)
    
    fmt.println("Loading OpenGL functions")
    gl.load_up_to(3, 3, glfw.gl_set_proc_address)
    
    return true
}

// MARK: Main
main :: proc() {
    ctx = context

    // MARK: Window config
    windowSize := Vec2I{800, 600}
    bgColor := Vec4{0.2, 0.3, 0.3, 1.0}

    // MARK: GLFW Init
    if !GLFW_Init() {
        return
    }
    defer glfw.Terminate()
    
    if !Window_Init(windowSize) {
        return
    }

    // Initialize camera
    camera = Camera_Init(windowSize)
    
    fmt.println("Initializing triangle")
    TriangleShaderProgram, ok := shaders.ShaderProgram("shaders/vertex.glsl", "shaders/fragment.glsl")
    if !ok {
        fmt.eprintln("Failed to initialize triangle")
        return
    }
    defer gl.DeleteProgram(TriangleShaderProgram)

    TriangleVao, TriangleVbo := obj.CreateTriangle()
    
    // Get uniform locations
    viewLoc := gl.GetUniformLocation(TriangleShaderProgram, "view")
    projectionLoc := gl.GetUniformLocation(TriangleShaderProgram, "projection")
    modelLoc := gl.GetUniformLocation(TriangleShaderProgram, "model")
    
    // Create model matrix (identity for now)
    model := linalg.MATRIX4F32_IDENTITY
    
    // MARK: Clear color
    fmt.println("Setting clear color")
    gl.ClearColor(bgColor[0], bgColor[1], bgColor[2], bgColor[3])
    
    // MARK: Game loop
    fmt.println("Entering game loop")
    for !glfw.WindowShouldClose(window) {
        gl.Clear(gl.COLOR_BUFFER_BIT)

        // Update view and projection matrices
        view := Get_View_Matrix(&camera)
        projection := Get_Projection_Matrix(&camera)

        // Use shader and set uniforms
        gl.UseProgram(TriangleShaderProgram)
        
        // Set matrices in shader
        gl.UniformMatrix4fv(viewLoc, 1, gl.FALSE, &view[0, 0])
        gl.UniformMatrix4fv(projectionLoc, 1, gl.FALSE, &projection[0, 0])
        gl.UniformMatrix4fv(modelLoc, 1, gl.FALSE, &model[0, 0])

        // Draw triangle
        gl.BindVertexArray(TriangleVao)
        gl.DrawArrays(gl.TRIANGLES, 0, 3)

        // Displaying on the screen
        glfw.SwapBuffers(window)
        
        // Key inputs
        glfw.PollEvents()
    }
    fmt.println("Game loop exited")
}