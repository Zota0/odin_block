package shaders

import "core:time"
import "core:fmt"
import "core:mem"
import "core:strings"
import "core:os"
import "core:path/filepath"
import "base:runtime"
import gl "vendor:OpenGL"

verify_shader_files :: proc(vertex_path: string, fragment_path: string) -> bool {
    if !os.exists(vertex_path) {
        fmt.eprintln("ERROR: Vertex shader file does not exist:", vertex_path)
        return false
    }
    
    if !os.exists(fragment_path) {
        fmt.eprintln("ERROR: Fragment shader file does not exist:", fragment_path)
        return false
    }
    
    return true
}

ShaderProgram :: proc(vertex_path: string, fragment_path: string) -> (program: u32, ok: bool) {
    
    fmt.println("\n=== Creating Shader Program ===")
    fmt.println("Checking shader files...")
    
    if !verify_shader_files(vertex_path, fragment_path) {
        return 0, false
    }
    
    program, ok = create_shader_program(vertex_path, fragment_path)
    
    return
}

create_shader_program :: proc(vertex_path: string, fragment_path: string) -> (program: u32, ok: bool) {
    fmt.println("Creating vertex shader...")
    vertex_shader, vertex_ok := compile_shader(vertex_path, gl.VERTEX_SHADER)
    if !vertex_ok {
        return 0, false
    }
    defer gl.DeleteShader(vertex_shader)
    
    fmt.println("Creating fragment shader...")
    fragment_shader, fragment_ok := compile_shader(fragment_path, gl.FRAGMENT_SHADER)
    if !fragment_ok {
        return 0, false
    }
    defer gl.DeleteShader(fragment_shader)
    
    fmt.println("Creating program object...")
    program = gl.CreateProgram()
    if program == 0 {
        fmt.eprintln("ERROR: Failed to create program object")
        return 0, false
    }
    
    fmt.println("Attaching vertex shader...")
    gl.AttachShader(program, vertex_shader)
    if !check_gl_error("AttachShader (vertex)") {
        gl.DeleteProgram(program)
        return 0, false
    }
    
    fmt.println("Attaching fragment shader...")
    gl.AttachShader(program, fragment_shader)
    if !check_gl_error("AttachShader (fragment)") {
        gl.DeleteProgram(program)
        return 0, false
    }
    
    fmt.println("Linking program...")
    gl.LinkProgram(program)
    
    link_status: i32
    gl.GetProgramiv(program, gl.LINK_STATUS, &link_status)
    
    log_length: i32
    gl.GetProgramiv(program, gl.INFO_LOG_LENGTH, &log_length)
    
    if log_length > 0 {
        log := make([]u8, log_length)
        defer delete(log)
        gl.GetProgramInfoLog(program, log_length, nil, raw_data(log))
        log_str := string(log[:log_length-1])
        
        if link_status == 0 {
            fmt.eprintln("ERROR: Program linking failed:")
            fmt.eprintln(log_str)
            gl.DeleteProgram(program)
            return 0, false
        } else if len(log_str) > 0 {
            fmt.println("Program linking warnings:")
            fmt.println(log_str)
        }
    }
    
    if link_status == 0 {
        fmt.eprintln("ERROR: Program linking failed with no error log")
        gl.DeleteProgram(program)
        return 0, false
    }
    
    fmt.println("Shader program created successfully")
    return program, true
}

compile_shader :: proc(path: string, shader_type: u32) -> (shader: u32, ok: bool) {
    shader_type_str := shader_type == gl.VERTEX_SHADER ? "vertex" : "fragment"
    fmt.printf("Reading %s shader from: %s\n", shader_type_str, path)
    
    data, read_ok := os.read_entire_file(path)
    if !read_ok {
        fmt.eprintln("ERROR: Failed to read shader file:", path)
        return 0, false
    }
    defer delete(data)
    
    source := string(data)
    if len(source) == 0 {
        fmt.eprintln("ERROR: Shader file is empty:", path)
        return 0, false
    }
    
    fmt.printf("Creating %s shader object...\n", shader_type_str)
    shader = gl.CreateShader(shader_type)
    if shader == 0 {
        fmt.eprintln("ERROR: Failed to create shader object")
        return 0, false
    }
    
    fmt.println("Setting shader source...")
    source_str := strings.clone_to_cstring(source)
    defer delete(source_str)
    
    gl.ShaderSource(shader, 1, &source_str, nil)
    if !check_gl_error("ShaderSource") {
        gl.DeleteShader(shader)
        return 0, false
    }
    
    fmt.printf("Compiling %s shader...\n", shader_type_str)
    gl.CompileShader(shader)
    
    compile_status: i32
    gl.GetShaderiv(shader, gl.COMPILE_STATUS, &compile_status)
    
    log_length: i32
    gl.GetShaderiv(shader, gl.INFO_LOG_LENGTH, &log_length)
    
    if log_length > 0 {
        log := make([]u8, log_length)
        defer delete(log)
        gl.GetShaderInfoLog(shader, log_length, nil, raw_data(log))
        log_str := string(log[:log_length-1])
        
        if compile_status == 0 {
            fmt.eprintln("ERROR: Shader compilation failed:")
            fmt.eprintln(log_str)
            gl.DeleteShader(shader)
            return 0, false
        } else if len(log_str) > 0 {
            fmt.println("Shader compilation warnings:")
            fmt.println(log_str)
        }
    }
    
    if compile_status == 0 {
        fmt.eprintln("ERROR: Shader compilation failed with no error log")
        gl.DeleteShader(shader)
        return 0, false
    }
    
    fmt.printf("%s shader compiled successfully\n", shader_type_str)
    return shader, true
}

check_gl_error :: proc(location: string) -> bool {
    error := gl.GetError()
    if error != gl.NO_ERROR {
        fmt.eprintln("OpenGL error at", location, ":", error)
        return false
    }
    return true
}

log_handler :: proc(data: rawptr, level: runtime.Logger_Level, text: string, location := #caller_location) {
    fmt.eprintf("[%v] %v\n", level, text)
}