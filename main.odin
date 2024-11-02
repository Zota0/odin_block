package main

// Named imports
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

// Maths
import "core:math/big"
import "core:math/bits"
import "core:math/cmplx"
import "core:math/ease"
import "core:math/fixed"
import "core:math/linalg"
import "core:math/noise"
import "core:math/rand"

// Other imports
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

// Custom modules
import ll "modules/lua"
import file "modules/files"
import obj "modules/objects"
import shaders "modules/shaders"


// Constants
DEBUG_MODE :: #config(DEBUG_MODE, true)
VSYNC_MODE :: #config(VSYNC_MODE, true)

Vec2 :: distinct [2]f32
Vec3 :: distinct [3]f32
Vec4 :: distinct [4]f32
Vec2I :: distinct [2]i32
Vec3I :: distinct [3]i32
Vec4I :: distinct [4]i32

// Variables
ctx: runtime.Context
window: glfw.WindowHandle

GLFW_Init :: proc() -> bool {
    if !glfw.Init() {
        fmt.eprintln("Failed to initialize GLFW")
        return false
    }
    fmt.println("GLFW initialized successfully")
    return true
}

Window_Init :: proc(win_size: Vec2I) -> bool {
    fmt.println("Setting GLFW window hints")
    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
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

main :: proc() {
    // MARK: CONTEXT
    ctx = context

    // MARK: WINDOW DEFAULT CONFIG
    windowSize := Vec2I{800, 600}
    bgColor := Vec4{0.2, 0.3, 0.3, 1.0}

    // MARK: INIT
    if !GLFW_Init() {
        return
    }
    defer glfw.Terminate()
    
    if !Window_Init(windowSize) {
        return
    }
    
    fmt.println("Initializing triangle")
    TriangleShaderProgram := shaders.ShaderProgram("vertex.glsl", "fragment.glsl")
    defer gl.DeleteProgram(TriangleShaderProgram)
    
    TriangleVao, TriangleVbo := obj.CreateTriangle()
    
    // MARK: CLEAR COLOR
    fmt.println("Setting clear color")
    gl.ClearColor(bgColor[0], bgColor[1], bgColor[2], bgColor[3])
    
    // MARK: GAME LOOP
    fmt.println("Entering game loop")
    for !glfw.WindowShouldClose(window) {
        gl.Clear(gl.COLOR_BUFFER_BIT)

        // triangle
        gl.UseProgram(TriangleShaderProgram)
        gl.BindVertexArray(TriangleVao)
        gl.DrawArrays(gl.TRIANGLES, 0, 3)

        // Displaying on the screen
        glfw.SwapBuffers(window)
        
        // Key inputs
        glfw.PollEvents()
    }
    fmt.println("Game loop exited")
}