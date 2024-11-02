package objects

import "core:fmt"
import gl "vendor:OpenGL"

check_gl_error :: proc(message: string) {
	err := gl.GetError()
	if err != gl.NO_ERROR {
		fmt.printfln("OpenGL error [%s]: %x", message, err)
	}
}

CreateTriangle :: proc() -> (u32, u32) {
	fmt.println("## Creating triangle... ##")

	vertices := []f32 {
		0.0, 0.5, 0.0, /* Top */
		-0.5, -0.366, 0.0, /* Left */
		0.5, -0.366, 0.0, /* Right */
	}

	fmt.println("Vertices array created.")

	vboArray: [1]u32 // Allocate space for 1 buffer.
	vaoArray: [1]u32 // Allocate space for 1 vertex array.

	fmt.println("Generating Buffers...")
	gl.GenBuffers(1, &vboArray[0])
	check_gl_error("GenBuffers")

	fmt.println("Generating Vertex Arrays...")
	gl.GenVertexArrays(1, &vaoArray[0])
	check_gl_error("GenVertexArrays")

	fmt.printfln("vao: %d", vaoArray[0])
	fmt.printfln("vbo: %d", vboArray[0])

	vao := vaoArray[0]
	vbo := vboArray[0]

	if vao == 0 || vbo == 0 {
		fmt.eprintln("Failed to generate VAO or VBO")
		return 0, 0
	}

	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	check_gl_error("BindBuffer")

	fmt.println("Binding Vertex Array and Buffer...")
	gl.BindVertexArray(vao)
	check_gl_error("BindVertexArray")

	gl.BufferData(gl.ARRAY_BUFFER, len(vertices) * size_of(f32), &vertices[0], gl.STATIC_DRAW)
	check_gl_error("BufferData")

	fmt.println("Setting Vertex Attrib Pointer for position...")
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), 0)
	check_gl_error("VertexAttribPointer for position")

	gl.EnableVertexAttribArray(0)
	check_gl_error("EnableVertexAttribArray for position")

	fmt.println("Unbinding buffers...")
	gl.BindBuffer(gl.ARRAY_BUFFER, 0)
	gl.BindVertexArray(0)

	fmt.println("## Triangle creation complete. ##")

	return vao, vbo
}