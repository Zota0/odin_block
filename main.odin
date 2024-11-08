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
import ui "vendor:microui"
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
import draw "mod/draw"
import input "mod/input"
import ll "mod/lua"
import obj "mod/objects"
import shaders "mod/shaders"
import binds "config/binds"
import chunk "mod/chunk"

Vec2 :: const.Vec2
Vec3 :: const.Vec3
Vec4 :: const.Vec4
Vec2I :: const.Vec2I
Vec3I :: const.Vec3I
Vec4I :: const.Vec4I
Mat4 :: const.Mat4

DEBUG_MODE :: const.DEBUG_MODE
VSYNC_MODE :: const.VSYNC_MODE
FPS_UPDATE_RATE :: const.FPS_UPDATE_RATE
MOUSE_SENSITIVITY :: Vec2{0.5, 0.5}

// MARK: Variables
ctx: runtime.Context
window: win.Window
inputManager: input.InputManager
cam: camera.Camera
deltaTime: f32

GLFW_Init :: proc() -> bool {
	if !glfw.Init() {
		fmt.println("Failed to initialize GLFW")
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
	samples    = 2,
	fullscreen = false,
}

RoundToDec :: proc(value: f32, decimals: int) -> f32 {
	multiplier := math.pow(10.0, f32(decimals))
	return math.round(value * multiplier) / multiplier
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

	// MARK: Input manager Init
	inputManager = input.InputInit(window.handle)^
	glfw.SetWindowUserPointer(window.handle, &inputManager)
	defer input.InputDestroy(&inputManager)

	// MARK: Init camera
	fmt.println("Initializing camera")
	cam = camera.CameraInit(windowSize)

	// MARK: Initialize shaders
	fmt.println("Initializing rectangle")
	cubeShaderProgram, cubeShaderOk := shaders.ShaderProgram(
		"shaders/vertex.glsl",
		"shaders/fragment.glsl",
	)
	defer gl.DeleteProgram(cubeShaderProgram)
	if !cubeShaderOk {
		fmt.println("Failed to initialize rectangle")
	}

	CubeVao, CubeEbo, CubeVbo := obj.CreateCube(1)
	CubeModelMat := linalg.MATRIX4F32_IDENTITY
	CubeView, CubeProj, CubeModel := shaders.GetAllUniforms(cubeShaderProgram)

    {
        // // MARK: Create texture params
        // texture: u32
        // gl.GenTextures(1, &texture)
        // gl.BindTexture(gl.TEXTURE_2D, texture)

        // // MARK: Set wrap, filter options
        // gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
        // gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
        // gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
        // gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

        // // MARK: Load texture
        // width, height, channels: i32
        // data := img.load("texture.png", &width, &height, &channels, 4)
        // if data != nil {
        // 	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, data)
        // 	gl.GenerateMipmap(gl.TEXTURE_2D)
        // 	img.image_free(data)
        // } else {
        // 	fmt.println("Failed to load texture")
        // }
        // gl.BindTexture(gl.TEXTURE_2D, 0)
    }

	// MARK: Clear color
	fmt.println("Setting clear color")
	gl.ClearColor(bgColor[0], bgColor[1], bgColor[2], bgColor[3])

	// MARK: Enable depth test
	draw.EnableDepthTest()
	draw.EnableCullFace()
	draw.EnableCullFaceBack()
	draw.EnableCullFaceCCW()


	// MARK: variables for fps, delta time
	currentFrameTime: f32 = f32(glfw.GetTime())
	lastFrameTime: f32 = f32(glfw.GetTime())
	lastFPSUpdate: f32 = lastFrameTime
	currentFPS: u8 = 0

	glfw.SetInputMode(window.handle, glfw.CURSOR, glfw.CURSOR_DISABLED)

	// MARK: Game loop
	fmt.println("Entering game loop")
	for !glfw.WindowShouldClose(window.handle) {
		// MARK: Clear buffers
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		// MARK: Calculate delta time
		currentFrameTime := f32(glfw.GetTime())
		deltaTime = RoundToDec(currentFrameTime - lastFrameTime, 4)
		lastFrameTime = currentFrameTime

		// MARK: Calculate FPS
		if currentFrameTime - lastFPSUpdate >= 1.0 {
			currentFPS = u8(1.0 / deltaTime)
			lastFPSUpdate = currentFrameTime

			title := fmt.tprintf(
				"%s | FPS: %v | Frame Time: %v ms",
				windowConfig.title,
				currentFPS,
				u8(deltaTime * 1000),
			)

			win.WinSetTitle(&window, title)
		}


		// MARK: Update view and projection matrices
		view := camera.GetViewMatrix(&cam)
		projection := camera.GetProjectionMatrix(&cam)

		shaders.Draw(
			cubeShaderProgram,
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
			36,
		)
		// MARK: Display on the screen
		glfw.SwapBuffers(window.handle)

		binds.GetInputs(&inputManager, &cam, &window, deltaTime, MOUSE_SENSITIVITY)


		// MARK: Input update
		input.InputUpdate(&inputManager)

		// Key inputs
		glfw.PollEvents()
	}
	// MARK: Exit program
	fmt.println("Exit")
}
