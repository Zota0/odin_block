package shaders

import "core:strings"
import gl "vendor:OpenGL"
import file "../files"

ShaderProgram :: proc(vertex_path, fragment_path: string) -> u32 {
    shaderCode_vertex := strings.clone_to_cstring(file.ReadFile(vertex_path))
    shaderCode_fragment := strings.clone_to_cstring(file.ReadFile(fragment_path))

    vertex := gl.CreateShader(gl.VERTEX_SHADER)
    gl.ShaderSource(vertex, 1, &shaderCode_vertex, nil)
    gl.CompileShader(vertex)

    fragment := gl.CreateShader(gl.FRAGMENT_SHADER)
    gl.ShaderSource(fragment, 1, &shaderCode_fragment, nil)
    gl.CompileShader(fragment)

    program := gl.CreateProgram()
    gl.AttachShader(program, vertex)
    gl.AttachShader(program, fragment)
    gl.LinkProgram(program)

    gl.DeleteShader(vertex)
    gl.DeleteShader(fragment)

    return program
}
