package win

import "core:fmt"
import gl "vendor:OpenGL"
import "vendor:glfw"
import "core:strings"
import c "core:c"
import "base:runtime"

import "../../config/const"

DEBUG_MODE :: const.DEBUG_MODE
Vec2I :: const.Vec2I

Window :: struct {
    handle: glfw.WindowHandle,
    size: Vec2I,
    config: Config,
}

Config :: struct {
    size: Vec2I,
    title: string,
    // Optional configurations with defaults
    gl_major: int,
    gl_minor: int,
    resizable: bool,
    vsync: bool,
    samples: int,  // MSAA samples (0 = disabled)
    fullscreen: bool,
}

DEFAULT_CONFIG :: Config {
    size = Vec2I{1280, 720},
    title = "Odin Application",
}

// Window property modification procedures
WinSetTitle :: proc(window: ^Window, title: string) {
    if window.handle == nil do return
    title_cstring := strings.clone_to_cstring(title)
    defer delete(title_cstring)
    glfw.SetWindowTitle(window.handle, title_cstring)
    window.config.title = strings.clone(title)
}

WinSetSize :: proc(window: ^Window, size: Vec2I) {
    if window.handle == nil do return
    glfw.SetWindowSize(window.handle, c.int(size.x), c.int(size.y))
    window.size = size
    window.config.size = size
}

WinGetSize :: proc(window: ^Window) -> Vec2I {
    if window.handle == nil do return Vec2I{}
    width, height: c.int
    width, height = glfw.GetWindowSize(window.handle)
    return Vec2I{i32(width), i32(height)}
}

WinSetPos :: proc(window: ^Window, x, y: int) {
    if window.handle == nil do return
    glfw.SetWindowPos(window.handle, c.int(x), c.int(y))
}

WinGetPos :: proc(window: ^Window) -> Vec2I {
    if window.handle == nil do return Vec2I{}
    x, y: c.int
    x, y = glfw.GetWindowPos(window.handle)
    return Vec2I{i32(x), i32(y)}
}

WinSetFullscreen :: proc(window: ^Window, fullscreen: bool) {
    if window.handle == nil do return
    if fullscreen == window.config.fullscreen do return

    monitor := glfw.GetPrimaryMonitor()
    mode := glfw.GetVideoMode(monitor)
    if mode == nil do return

    if fullscreen {
        // Store window properties before going fullscreen
        pos := WinGetPos(window)
        size := WinGetSize(window)
        
        glfw.SetWindowMonitor(
            window.handle,
            monitor,
            0, 0,
            mode.width,
            mode.height,
            mode.refresh_rate,
        )
    } else {
        // Return to windowed mode with previous size
        glfw.SetWindowMonitor(
            window.handle,
            nil,
            100, 100, // Default windowed position
            c.int(window.config.size.x),
            c.int(window.config.size.y),
            0, // Let the system decide refresh rate
        )
    }
    window.config.fullscreen = fullscreen
}

WinSetVSync :: proc(window: ^Window, vsync: bool) {
    if window.handle == nil do return
    glfw.MakeContextCurrent(window.handle)
    glfw.SwapInterval(vsync ? 1 : 0)
    window.config.vsync = vsync
}

WinSetSamples :: proc(window: ^Window, samples: int) -> bool {
    if window.handle == nil do return false
    // Note: Changing MSAA requires window recreation
    // Store current config
    config := window.config
    config.samples = samples
    
    // Destroy current window
    WinDestroy(window)
    
    // Create new window with updated config
    new_window, ok := WindowInit(config)
    if !ok do return false
    
    // Update window
    window^ = new_window
    return true
}

WinSetResizable :: proc(window: ^Window, resizable: bool) {
    if window.handle == nil do return
    glfw.SetWindowAttrib(window.handle, glfw.RESIZABLE, i32(resizable ? 1 : 0))
    window.config.resizable = resizable
}

WinMinimize :: proc(window: ^Window) {
    if window.handle == nil do return
    glfw.IconifyWindow(window.handle)
}

WinMaximize :: proc(window: ^Window) {
    if window.handle == nil do return
    glfw.MaximizeWindow(window.handle)
}

WinRestore :: proc(window: ^Window) {
    if window.handle == nil do return
    glfw.RestoreWindow(window.handle)
}

WinFocus :: proc(window: ^Window) {
    if window.handle == nil do return
    glfw.FocusWindow(window.handle)
}

WinShouldClose :: proc(window: ^Window) -> bool {
    if window.handle == nil do return true
    return bool(glfw.WindowShouldClose(window.handle))
}

WinSetShouldClose :: proc(window: ^Window, should_close: bool) {
    if window.handle == nil do return
    glfw.SetWindowShouldClose(window.handle, should_close ? glfw.TRUE : glfw.FALSE)
}

// Window state queries
WinIsFocused :: proc(window: ^Window) -> bool {
    if window.handle == nil do return false
    return bool(glfw.GetWindowAttrib(window.handle, glfw.FOCUSED))
}

WinIsMinimized :: proc(window: ^Window) -> bool {
    if window.handle == nil do return false
    return bool(glfw.GetWindowAttrib(window.handle, glfw.ICONIFIED))
}

WinIsMaximized :: proc(window: ^Window) -> bool {
    if window.handle == nil do return false
    return bool(glfw.GetWindowAttrib(window.handle, glfw.MAXIMIZED))
}

WinIsVisible :: proc(window: ^Window) -> bool {
    if window.handle == nil do return false
    return bool(glfw.GetWindowAttrib(window.handle, glfw.VISIBLE))
}

// Window Events
WinSwapBuffers :: proc(window: ^Window) {
    if window.handle == nil do return
    glfw.SwapBuffers(window.handle)
}

WinPollEvents :: proc() {
    glfw.PollEvents()
}

WinWaitEvents :: proc() {
    glfw.WaitEvents()
}

// Example usage of error callback
glfw_error_callback :: proc "c" (error: c.int, description: cstring) {
    context = runtime.default_context()  // Create a context for the callback
    fmt.eprintf("GLFW Error (%d): %s\n", error, description)
}

WindowInit :: proc(config: Config = DEFAULT_CONFIG) -> (window: Window, ok: bool) {
    fmt.println("Setting GLFW window hints")
    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, c.int(config.gl_major))
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, c.int(config.gl_minor))
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
    glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, glfw.TRUE)
    glfw.WindowHint(glfw.RESIZABLE, config.resizable ? glfw.TRUE : glfw.FALSE)
    
    fmt.println("Setting GLFW sampling")
    if config.samples > 0 {
        glfw.WindowHint(glfw.SAMPLES, c.int(config.samples))
    }
    
    fmt.println("Setting GLFW debug")
    when DEBUG_MODE { 
        glfw.WindowHint(glfw.OPENGL_DEBUG_CONTEXT, glfw.TRUE)
    }
    
    fmt.println("Creating window")
    monitor := config.fullscreen ? glfw.GetPrimaryMonitor() : nil
    
    fmt.println("Setting up title")
    title_cstring := strings.clone_to_cstring(config.title)
    defer delete(title_cstring)
    
    fmt.printf("Creating window: %dx%d, title: %s\n", config.size.x, config.size.y, config.title)
    handle := glfw.CreateWindow(
        c.int(config.size.x), 
        c.int(config.size.y), 
        title_cstring, 
        monitor, 
        nil,
    )
    
    if handle == nil {
        fmt.eprintln("Failed to create window")
        return Window{}, false
    }
    
    fmt.println("Making context current")
    glfw.MakeContextCurrent(handle)
    
    if config.vsync {
        glfw.SwapInterval(1)
    } else {
        glfw.SwapInterval(0)
    }
    
    fmt.println("Loading OpenGL functions")
    gl.load_up_to(config.gl_major, config.gl_minor, glfw.gl_set_proc_address)
    
    window = Window{
        handle = handle,
        size = config.size,
        config = config,
    }
    return window, true
}

WinDestroy :: proc(window: ^Window) {
    if window.handle != nil {
        glfw.DestroyWindow(window.handle)
        window.handle = nil
    }
}