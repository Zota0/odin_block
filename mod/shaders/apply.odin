package shaders

import const "../../config/const"
import gl "vendor:OpenGL"

Vec2 :: const.Vec2
Vec3 :: const.Vec3
Vec4 :: const.Vec4
Vec2I :: const.Vec2I
Vec3I :: const.Vec3I
Vec4I :: const.Vec4I
Mat4 :: const.Mat4

DEBUG_MODE :: const.DEBUG_MODE
VSYNC_MODE :: const.VSYNC_MODE

Apply :: proc(
	program: u32,
	view, projection, model: ^Mat4,
	vao, vbo: u32,
	view_loc, projection_loc, model_loc, first, arr_count: i32,
) {
	gl.UseProgram(program)

	// Set matrices in shader
	gl.UniformMatrix4fv(view_loc, 1, gl.FALSE, &view[0, 0])
	gl.UniformMatrix4fv(projection_loc, 1, gl.FALSE, &projection[0, 0])
	gl.UniformMatrix4fv(model_loc, 1, gl.FALSE, &model[0, 0])

	// Draw 
	gl.BindVertexArray(vao)
	gl.DrawArrays(gl.TRIANGLES, first, arr_count)
}

GetUniform :: proc(
	program: u32,
	name: cstring,
) -> i32 {
	loc := gl.GetUniformLocation(program, name)
	return loc
}

GetAllUniforms :: proc(
	program: u32,
) -> (view, projection, model: i32) {
    view = GetUniform(program, "view")
    projection = GetUniform(program, "projection")
    model = GetUniform(program, "model")

    return view, projection, model
}