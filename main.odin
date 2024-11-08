package main

// MARK: Named imports
import ansi "core:encoding/ansi"
import base32 "core:encoding/base32"
import base64 "core:encoding/base64"
import csv "core:encoding/csv"
import hex "core:encoding/hex"
import ini "core:encoding/ini"
import json "core:encoding/json"
import xml "core:encoding/xml"
import net "vendor:ENet"
import gl "vendor:OpenGL"
import glfw "vendor:glfw"
import lua "vendor:lua/5.4"
import gui "vendor:microui"
import font "vendor:stb/easy_font"
import img "vendor:stb/image"

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
import "base:runtime"
import "core:bufio"
import "core:crypto"
import "core:debug/trace"
import "core:fmt"
import "core:hash"
import "core:io"
import "core:log"
import "core:math"
import "core:os"
import "core:reflect"
import "core:strconv"
import "core:strings"
import "core:thread"
import "core:time"

// MARK: Custom modules
import const "config/const"
import win "config/win"
import camera "mod/camera"
import input "mod/input"
import ll "mod/lua"
import obj "mod/objects"
import shaders "mod/shaders"

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
inputManager: input.Input_Manager
cam: camera.Camera

GLFW_Init :: proc() -> bool {
	if !glfw.Init() {
		fmt.eprintln("Failed to initialize GLFW")
		return false
	}
	fmt.println("GLFW initialized successfully")
	return true
}

// MARK: Window config
windowSize := Vec2I{800, 600}
bgColor := Vec4{0.2, 0.3, 0.3, 1.0}
windowConfig := win.Config {
    size       = windowSize,
    title      = "Odin Block",
    gl_major   = 4,
    gl_minor   = 6,
    resizable  = true,
    vsync      = const.VSYNC_MODE,
    samples    = 8,
    fullscreen = false,
}

// MARK: Main
main :: proc() {
    // MARK: Setting up context
	ctx = context

	// MARK: GLFW Init
	if !GLFW_Init() {
		return
	}
	defer glfw.Terminate()

	// MARK: Window Init
	window, windowOk := win.WindowInit(windowConfig)
	if !windowOk {
		return
	}
	defer win.WinDestroy(&window)

	inputManager = input.InputInit(window.handle)^
    defer input.InputDestroy(&inputManager)

	// MARK: Init camera
    fmt.println("Initializing camera")
	cam = camera.Camera_Init(windowSize)

    // MARK: Initialize shaders
    fmt.println("Initializing rectangle")
	RectShaderProgram, rect_ok := shaders.ShaderProgram(
		"shaders/vertex.glsl",
		"shaders/fragment.glsl",
	)
    defer gl.DeleteProgram(RectShaderProgram)
	if !rect_ok {
		fmt.eprintln("Failed to initialize rectangle")
	}

	RectVao, RectVbo := obj.CreateRectangleUnindexed(1, 3)
    RectIdVao, ReactIdEbo, RectIdVbo := obj.CreateRectangle(3, 1);
    
    CubeVao, CubeEbo, CubeVbo := obj.CreateCube(1)
    CubeModelMat := linalg.MATRIX4F32_IDENTITY
    CubeView, CubeProj, CubeModel := shaders.GetAllUniforms(RectShaderProgram)

    // MARK: Create texture params
	texture: u32
	gl.GenTextures(1, &texture)
	gl.BindTexture(gl.TEXTURE_2D, texture)

	// MARK: Set wrap, filter options
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

	// MARK: Load texture
	width, height, channels: i32
	data := img.load("texture.png", &width, &height, &channels, 4)
	if data != nil {
		gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, data)
		gl.GenerateMipmap(gl.TEXTURE_2D)
		img.image_free(data)
	} else {
		fmt.eprintln("Failed to load texture")
	}

	// MARK: Get uniform locations
    fmt.println("Getting uniform locations")
	RectView, RectProj, RectModel := shaders.GetAllUniforms(RectShaderProgram)

	// MARK: Create model matrix
    fmt.println("Creating model matrix")
	model := linalg.MATRIX4F32_IDENTITY

	// MARK: Clear color
	fmt.println("Setting clear color")
	gl.ClearColor(bgColor[0], bgColor[1], bgColor[2], bgColor[3])

    // MARK: Enable depth test
	gl.Enable(gl.DEPTH_TEST)
    gl.Enable(gl.CULL_FACE)
    gl.CullFace(gl.BACK)
    gl.CullFace(gl.CCW)

	// MARK: Game loop
	fmt.println("Entering game loop")

    rotation :f32 = 0.0

	for !glfw.WindowShouldClose(window.handle) {
		
        // MARK: Clear buffers
        gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		// MARK: Update view and projection matrices
		view := camera.Get_View_Matrix(&cam)
		projection := camera.Get_Projection_Matrix(&cam)
        
        rotation = f32(glfw.GetTime() * 0.5)
        CubeModelMat = linalg.matrix4_rotate_f32(rotation, {0.5, 1.0, 0.0})

        shaders.Draw(
            RectShaderProgram,
            &view,
            &projection,
            &CubeModelMat,
            CubeVao,
            CubeVbo,
            nil,
            CubeView,
            CubeProj,
            CubeModel,
            0,
            36
        )

        // MARK: Update model matrix
		// shaders.Apply(
		// 	RectShaderProgram,// Use Apply instead of Draw since it's simpler
		// 	&view,
		// 	&projection,
		// 	&model,
		// 	RectVao,
		// 	RectVbo,
		// 	RectView,
		// 	RectProj,
		// 	RectModel,
		// 	0,
		// 	6,
		// )
        shaders.Draw(
			RectShaderProgram,
			&view,
			&projection,
			&model,
			RectIdVao,
			RectIdVbo,
			nil,
			RectView,
			RectProj,
			RectModel,
			0,
			6,
        )

		// MARK: Display on the screen
		glfw.SwapBuffers(window.handle)

        // MARK: Input update
		input.InputUpdate(&inputManager)

		// Key inputs
		glfw.PollEvents()
	}
    // MARK: Exit
	fmt.println("Exit")
}
