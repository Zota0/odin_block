package objects

import gl "vendor:OpenGL"
import "core:fmt"

CreateTriangle :: proc() -> (u32, u32) {
    fmt.println("## Creating triangle... ##")

    vertices := []f32{
        0.0, 0.5, 0.0,      /* Top */
        -0.5, -0.366, 0.0, /* Left */
        0.5, -0.366, 0.0,  /* Right */
    }

    fmt.println("Vertices array created.")

    // Using slices for vao and vbo
    vaoArray := []u32{0} // Creating a slice with one element
    vboArray := []u32{0} // Creating a slice with one element

    fmt.println("Generating Vertex Arrays...")
    gl.GenVertexArrays(1, vaoArray)

    fmt.println("Generating Buffers...")
    gl.GenBuffers(1, vboArray)

    vao := vaoArray[0]
    vbo := vboArray[0]

    if vao == 0 || vbo == 0 {
        fmt.eprintln("Failed to generate VAO or VBO")
        return 0, 0
    }

    fmt.println("Binding Vertex Array and Buffer...")
    gl.BindVertexArray(vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)

    // Ensure size calculation is correct
    gl.BufferData(gl.ARRAY_BUFFER, len(vertices) * size_of(f32), &vertices[0], gl.STATIC_DRAW)

    fmt.println("Setting Vertex Attrib Pointer for position...")
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 6 * size_of(f32), 0)
    gl.EnableVertexAttribArray(0)

    fmt.println("Setting Vertex Attrib Pointer for color...")
    gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 6 * size_of(f32), 3 * size_of(f32))
    gl.EnableVertexAttribArray(1)

    fmt.println("Unbinding buffers...")
    gl.BindBuffer(gl.ARRAY_BUFFER, 0)
    gl.BindVertexArray(0)

    fmt.println("## Triangle creation complete. ##")

    return vao, vbo
}

