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
import ll "mod/lua"
import obj "mod/objects"
import shaders "mod/shaders"
import camera "mod/camera"
import const "config/const"
import win "config/win"

Vec2 :: const.Vec2
Vec3 :: const.Vec3
Vec4 :: const.Vec4
Vec2I :: const.Vec2I
Vec3I :: const.Vec3I
Vec4I :: const.Vec4I
Mat4 :: const.Mat4

DEBUG_MODE :: const.DEBUG_MODE
VSYNC_MODE :: const.VSYNC_MODE

// MARK: Variables
ctx: runtime.Context
window: win.Window
cam: camera.Camera

GLFW_Init :: proc() -> bool {
    if !glfw.Init() {
        fmt.eprintln("Failed to initialize GLFW")
        return false
    }
    fmt.println("GLFW initialized successfully")
    return true
}

// MARK: Main
main :: proc() {
    ctx = context

    // MARK: Window config
    windowSize := Vec2I{}
    windowSize.x = 800
    windowSize.y = 600
    bgColor := Vec4{0.2, 0.3, 0.3, 1.0}

    // MARK: GLFW Init
    if !GLFW_Init() {
        return
    }
    defer glfw.Terminate()
    
    windowConfig := win.Config{
        size = windowSize,
        title = "Odin Block",
        gl_major = 4,
        gl_minor = 6,
        resizable = true,
        vsync = const.VSYNC_MODE,
        samples = 8,
        fullscreen = false,
    }

    window, windowOk := win.WindowInit(windowConfig)
    if !windowOk {
        return
    }
    defer win.WinDestroy(&window)
    

    // Initialize cam
    cam = camera.Camera_Init(windowSize)
    
    fmt.println("Initializing triangle")
    TriangleShaderProgram, triangle_ok := shaders.ShaderProgram("shaders/vertex.glsl", "shaders/fragment.glsl")
    if !triangle_ok {
        fmt.eprintln("Failed to initialize triangle")
    }
    defer gl.DeleteProgram(TriangleShaderProgram)

    
    CircleShaderProgram, circle_ok := shaders.ShaderProgram("shaders/vertex.glsl", "shaders/fragment.glsl")
    if !circle_ok {
        fmt.eprintln("Failed to initialize circle")
    }
    defer gl.DeleteProgram(CircleShaderProgram)

    RectShaderProgram, rect_ok := shaders.ShaderProgram("shaders/vertex.glsl", "shaders/fragment.glsl")
    if !rect_ok {
        fmt.eprintln("Failed to initialize rectangle")
    }
    defer gl.DeleteProgram(RectShaderProgram)


    TriangleVao, TriangleVbo := obj.CreateTexturedTriangle()
    CircleVao, CircleVbo := obj.CreateCircle(1, 32)
    RectVao, RectVbo := obj.CreateRectangle(3, 3) 


    texture: u32
    gl.GenTextures(1, &texture)
    gl.BindTexture(gl.TEXTURE_2D, texture)

    // Set texture wrapping/filtering options
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

    // Load texture image using stb_image
    width, height, channels: i32
    data := img.load("texture.png", &width, &height, &channels, 4)
    if data != nil {
        gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, data)
        gl.GenerateMipmap(gl.TEXTURE_2D)
        img.image_free(data)
    } else {
        fmt.eprintln("Failed to load texture")
    }

    // Get uniform locations
    viewLocTriangle := gl.GetUniformLocation(TriangleShaderProgram, "view")
    projectionLocTriangle := gl.GetUniformLocation(TriangleShaderProgram, "projection")
    modelLocTriangle  := gl.GetUniformLocation(TriangleShaderProgram, "model")

    viewLocCircle := gl.GetUniformLocation(CircleShaderProgram, "view")
    projectionLocCircle := gl.GetUniformLocation(CircleShaderProgram, "projection")
    modelLocCircle := gl.GetUniformLocation(CircleShaderProgram, "model")
    
    viewLocRect, projectionLocRect, modelLocRect := shaders.GetAllUniforms(RectShaderProgram)

    // Create model matrix (identity for now)
    model := linalg.MATRIX4F32_IDENTITY

    // MARK: Clear color
    fmt.println("Setting clear color")
    gl.ClearColor(bgColor[0], bgColor[1], bgColor[2], bgColor[3])
    
    // MARK: Game loop
    fmt.println("Entering game loop")
    for !glfw.WindowShouldClose(window.handle) {
        gl.Clear(gl.COLOR_BUFFER_BIT)

        // Update view and projection matrices
        view := camera.Get_View_Matrix(&cam)
        projection := camera.Get_Projection_Matrix(&cam)

        shaders.Apply(
            TriangleShaderProgram,
            &view,
            &projection,
            &model,
            TriangleVao,
            TriangleVbo,
            viewLocTriangle,
            projectionLocTriangle,
            modelLocTriangle,
            0,
            3,
        )

        shaders.Apply(
            CircleShaderProgram,
            &view,
            &projection,
            &model,
            CircleVao,
            CircleVbo,
            viewLocCircle,
            projectionLocCircle,
            modelLocCircle,
            0,
            512,
        )

        shaders.Apply(
            RectShaderProgram,
            &view,
            &projection,
            &model,
            RectVao,
            RectVbo,
            viewLocRect,
            projectionLocRect,
            modelLocRect,
            0,
            6,
        )

        // // Use shader and set uniforms
        // gl.UseProgram(TriangleShaderProgram)
        
        // // Set matrices in shader
        // gl.UniformMatrix4fv(viewLocTriangle, 1, gl.FALSE, &view[0, 0])
        // gl.UniformMatrix4fv(projectionLocTriangle, 1, gl.FALSE, &projection[0, 0])
        // gl.UniformMatrix4fv(modelLocTriangle, 1, gl.FALSE, &model[0, 0])

        // // Draw triangle
        // gl.BindVertexArray(TriangleVao)
        // gl.DrawArrays(gl.TRIANGLES, 0, 3)

        // gl.UseProgram(CircleShaderProgram)
        // gl.UniformMatrix4fv(viewLocCircle, 1, gl.FALSE, &view[0, 0])
        // gl.UniformMatrix4fv(projectionLocCircle, 1, gl.FALSE, &projection[0, 0])
        // gl.UniformMatrix4fv(modelLocCircle, 1, gl.FALSE, &model[0, 0])

        // gl.BindVertexArray(CircleVao)
        // gl.DrawArrays(gl.TRIANGLES, 0, 512)

        // Displaying on the screen
        glfw.SwapBuffers(window.handle)
        
        // Key inputs
        glfw.PollEvents()
    }
    fmt.println("Game loop exited")
}