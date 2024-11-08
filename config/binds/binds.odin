package binds

import glfw "vendor:glfw"
import fmt "core:fmt"

import "../../mod/input"
import import_camera "../../mod/camera"
import "../win"
import const "../const"

Vec2 :: const.Vec2

// MARK: Key and Mouse binds
keyBinds: map[string]input.KEY = {
	"GO_FORWARD"   = glfw.KEY_W,
	"GO_BACKWARD"  = glfw.KEY_S,
	"GO_LEFT"      = glfw.KEY_A,
	"GO_RIGHT"     = glfw.KEY_D,
	"GO_UP"        = glfw.KEY_SPACE,
	"GO_DOWN"      = glfw.KEY_LEFT_SHIFT,
	"TOGGLE_INV"   = glfw.KEY_E,
	"TOGGLE_MOUSE" = glfw.KEY_LEFT_CONTROL,
	"CAMERA_RESET" = glfw.KEY_ESCAPE,
}
mouseBinds: map[string]input.MouseButton = {
	"LEFT"        = glfw.MOUSE_BUTTON_LEFT,
	"RIGHT"       = glfw.MOUSE_BUTTON_RIGHT,
	"MIDDLE"      = glfw.MOUSE_BUTTON_MIDDLE,
	"MOUSE1"      = glfw.MOUSE_BUTTON_1,
	"MOUSE2"      = glfw.MOUSE_BUTTON_2,
	"MOUSE3"      = glfw.MOUSE_BUTTON_3,
	"MOUSE4"      = glfw.MOUSE_BUTTON_4,
	"MOUSE5"      = glfw.MOUSE_BUTTON_5,
	"MOUSE6"      = glfw.MOUSE_BUTTON_6,
	"MOUSE7"      = glfw.MOUSE_BUTTON_7,
	"MOUSE8"      = glfw.MOUSE_BUTTON_8,
	"LAST_BUTTON" = glfw.MOUSE_BUTTON_LAST,
}

// MARK: Getting inputs
GetInputs :: proc(input_manager: ^input.InputManager, camera: ^import_camera.Camera, window: ^win.Window, deltaTime: f32, mouse_sensitivity: Vec2) {
	// MARK: Inputs
	if input.IsKeyDown(input_manager, keyBinds["camera_RESET"]) {
		import_camera.CameraReset(camera)
	}

	if input.IsKeyDown(input_manager, keyBinds["GO_FORWARD"]) {
		import_camera.CameraMoveForward(camera, deltaTime * 10)
	}
	if input.IsKeyDown(input_manager, keyBinds["GO_BACKWARD"]) {
		import_camera.CameraMoveBackward(camera, deltaTime * 10)
	}
	if input.IsKeyDown(input_manager, keyBinds["GO_LEFT"]) {
		import_camera.CameraMoveLeft(camera, deltaTime * 10)
	}
	if input.IsKeyDown(input_manager, keyBinds["GO_RIGHT"]) {
		import_camera.CameraMoveRight(camera, deltaTime * 10)
	}
	if input.IsKeyDown(input_manager, keyBinds["GO_UP"]) {
		import_camera.CameraMoveUp(camera, deltaTime * 10)
	}
	if input.IsKeyDown(input_manager, keyBinds["GO_DOWN"]) {
		import_camera.CameraMoveDown(camera, deltaTime * 10)
	}
	if input.IsKeyTapped(input_manager, keyBinds["TOGGLE_MOUSE"]) {
		if glfw.GetInputMode(window.handle, glfw.CURSOR) == glfw.CURSOR_DISABLED {
			glfw.SetInputMode(window.handle, glfw.CURSOR, glfw.CURSOR_NORMAL)
		} else {
			glfw.SetInputMode(window.handle, glfw.CURSOR, glfw.CURSOR_DISABLED)
		}
	}
	if input.IsMouseButtonPressed(input_manager, glfw.MOUSE_BUTTON_LEFT) {
		fmt.println("shoot")
	}

	mouseDelta := input.GetMouseDelta(input_manager) * 0.001
	if mouseDelta.x != 0 || mouseDelta.y != 0 {
		import_camera.CameraRotate(
			camera,
			-(f32(mouseDelta.x) * mouse_sensitivity.x),
			-(f32(mouseDelta.y) * mouse_sensitivity.y),
		)
	}
}
