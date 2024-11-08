package input

import glfw "vendor:glfw"

import "core:fmt"
import "core:math"
import "base:runtime"

import "../../config/const"
Vec2f64 :: const.Vec2f64

// Input state tracking
Key_State :: enum {
    Up,         // Key is not pressed
    Pressed,    // Key was just pressed this frame
    Held,       // Key is being held down
    Released,   // Key was just released this frame
    Tapped,     // Key was pressed and released within tap threshold
}

Mouse_State :: enum {
    Up,
    Pressed,
    Held,
    Released,
}

KEY :: uint

Mouse_Button :: enum {
    Left,
    Right,
    Middle,
}

Input_Manager :: struct {
    // Keyboard state
    key_states: map[KEY]Key_State,
    key_press_times: map[KEY]f64,
    
    // Mouse state
    mouse_states: map[Mouse_Button]Mouse_State,
    mouse_position: Vec2f64,
    mouse_previous: Vec2f64,
    mouse_delta: Vec2f64,
    scroll_offset: Vec2f64,
    
    // Configuration
    tap_threshold: f64,
    double_click_threshold: f64,
    
    // Window reference for input context
    window: glfw.WindowHandle,
}

// Initialize input manager
InputInit :: proc(window: glfw.WindowHandle) -> ^Input_Manager {
    input := new(Input_Manager)
    input.window = window
    input.tap_threshold = 0.2  // 200ms tap threshold
    input.double_click_threshold = 0.3  // 300ms double click threshold
    
    // Initialize maps
    input.key_states = make(map[KEY]Key_State)
    input.key_press_times = make(map[KEY]f64)
    input.mouse_states = make(map[Mouse_Button]Mouse_State)
    
    // Set up GLFW callbacks
    glfw.SetKeyCallback(window, KeyCallback)
    glfw.SetMouseButtonCallback(window, MouseButtonCallback)
    glfw.SetCursorPosCallback(window, CursorPositionCallback)
    glfw.SetScrollCallback(window, ScrollCallback)
    
    return input
}

// Cleanup
InputDestroy :: proc(input: ^Input_Manager) {
    delete(input.key_states)
    delete(input.key_press_times)
    delete(input.mouse_states)
    free(input)
}

// Update input states
InputUpdate :: proc(input: ^Input_Manager) {
    // Update mouse delta
    x, y := glfw.GetCursorPos(input.window)
    input.mouse_delta = {
        x - input.mouse_previous[0],
        y - input.mouse_previous[1],
    }
    input.mouse_previous = {x, y}
    input.mouse_position = {x, y}
    
    // Update key states
    current_time := glfw.GetTime()
    for key, state in &input.key_states {
        #partial switch state {
        case .Pressed:
            input.key_states[key] = .Held
        case .Released:
            input.key_states[key] = .Up
        case .Tapped:
            input.key_states[key] = .Up
        }
    }
    
    // Update mouse states
    for button, state in &input.mouse_states {
        #partial switch state {
        case .Pressed:
            input.mouse_states[button] = .Held
        case .Released:
            input.mouse_states[button] = .Up
        }
    }
    
    // Reset scroll offset
    input.scroll_offset = {0, 0}
}

// Keyboard input checking
IsKeyPressed :: proc(input: ^Input_Manager, key: KEY) -> bool {
    return input.key_states[key] == .Pressed
}

IsKeyHeld :: proc(input: ^Input_Manager, key: KEY) -> bool {
    return input.key_states[key] == .Held
}

IsKeyReleased :: proc(input: ^Input_Manager, key: KEY) -> bool {
    return input.key_states[key] == .Released
}

IsKeyTapped :: proc(input: ^Input_Manager, key: KEY) -> bool {
    return input.key_states[key] == .Tapped
}

IsKeyDown :: proc(input: ^Input_Manager, key: KEY) -> bool {
    state := input.key_states[key]
    return state == .Pressed || state == .Held
}

// Mouse input checking
IsMouseButtonPressed :: proc(input: ^Input_Manager, button: Mouse_Button) -> bool {
    return input.mouse_states[button] == .Pressed
}

IsMouseButtonHeld :: proc(input: ^Input_Manager, button: Mouse_Button) -> bool {
    return input.mouse_states[button] == .Held
}

IsMouseButtonReleased :: proc(input: ^Input_Manager, button: Mouse_Button) -> bool {
    return input.mouse_states[button] == .Released
}

IsMouseButtonDown :: proc(input: ^Input_Manager, button: Mouse_Button) -> bool {
    state := input.mouse_states[button]
    return state == .Pressed || state == .Held
}

GetMousePosition :: proc(input: ^Input_Manager) -> Vec2f64 {
    return input.mouse_position
}

GetMouseDelta :: proc(input: ^Input_Manager) -> Vec2f64 {
    return input.mouse_delta
}

GetScrollOffset :: proc(input: ^Input_Manager) -> Vec2f64 {
    return input.scroll_offset
}

// GLFW Callbacks
@(private)
KeyCallback :: proc "c" (window: glfw.WindowHandle, key: i32, scancode: i32, action: i32, mods: i32) {
    context = runtime.default_context()
    input := cast(^Input_Manager)glfw.GetWindowUserPointer(window)
    if input == nil do return
    
    current_time := glfw.GetTime()
    
    switch action {
    case glfw.PRESS:
        input.key_states[KEY(key)] = .Pressed
        input.key_press_times[KEY(key)] = current_time
    case glfw.RELEASE:
        // Check for tap
        if press_time, ok := input.key_press_times[KEY(key)]; ok {
            if current_time - press_time < input.tap_threshold {
                input.key_states[KEY(key)] = .Tapped
            } else {
                input.key_states[KEY(key)] = .Released
            }
        }
    }
}

@(private)
MouseButtonCallback :: proc "c" (window: glfw.WindowHandle, button: i32, action: i32, mods: i32) {
    context = runtime.default_context()
    input := cast(^Input_Manager)glfw.GetWindowUserPointer(window)
    if input == nil do return
    
    mouse_button := Mouse_Button(button)
    
    switch action {
    case glfw.PRESS:
        input.mouse_states[mouse_button] = .Pressed
    case glfw.RELEASE:
        input.mouse_states[mouse_button] = .Released
    }
}

@(private)
CursorPositionCallback :: proc "c" (window: glfw.WindowHandle, x: f64, y: f64) {
    context = runtime.default_context()
    input := cast(^Input_Manager)glfw.GetWindowUserPointer(window)
    if input == nil do return
    
    input.mouse_position = {x, y}
}

@(private)
ScrollCallback :: proc "c" (window: glfw.WindowHandle, x_offset: f64, y_offset: f64) {
    context = runtime.default_context()
    input := cast(^Input_Manager)glfw.GetWindowUserPointer(window)
    if input == nil do return
    
    input.scroll_offset = {x_offset, y_offset}
}