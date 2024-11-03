package objects

import "core:fmt"
import "core:math"
import gl "vendor:OpenGL"

// Vertex structure definitions
Vertex_P3 :: struct {
	position: [3]f32,
}

Vertex_P3T2 :: struct {
	position: [3]f32,
	texcoord: [2]f32,
}

// Error checking utility
check_gl_error :: proc(message: string) {
	err := gl.GetError()
	if err != gl.NO_ERROR {
		fmt.printfln("OpenGL error [%s]: %x", message, err)
	}
}

// Generic buffer creation utility
create_buffer :: proc(vertices: []$T, attributes: []Attribute_Config) -> (vao: u32, vbo: u32) {
	fmt.println("## Creating buffer objects... ##")

	// Generate and bind buffers
	gl.GenVertexArrays(1, &vao)
	gl.GenBuffers(1, &vbo)

	if vao == 0 || vbo == 0 {
		fmt.eprintln("Failed to generate VAO or VBO")
		return 0, 0
	}

	gl.BindVertexArray(vao)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)

	// Upload vertex data
	gl.BufferData(gl.ARRAY_BUFFER, len(vertices) * size_of(T), &vertices[0], gl.STATIC_DRAW)
	check_gl_error("BufferData")

	// Set up vertex attributes
	stride := size_of(T)
	for attr in attributes {
		gl.VertexAttribPointer(
			attr.location,
			attr.size,
			gl.FLOAT,
			gl.FALSE,
			i32(stride),
			uintptr(attr.offset),
		)
		gl.EnableVertexAttribArray(attr.location)
		check_gl_error("Vertex Attribute Setup")
	}

	// Unbind buffers
	gl.BindBuffer(gl.ARRAY_BUFFER, 0)
	gl.BindVertexArray(0)

	fmt.println("## Buffer creation complete. ##")
	return vao, vbo
}

Attribute_Config :: struct {
	location: u32,
	size:     i32,
	offset:   int,
}

// Specific triangle creation procedures
CreateTriangle :: proc() -> (u32, u32) {
	vertices := []Vertex_P3 {
		{{0.0, 0.5, 0.0}}, /* Top */
		{{-0.5, -0.366, 0.0}}, /* Left */
		{{0.5, -0.366, 0.0}}, /* Right */
	}

	attributes := []Attribute_Config {
		{location = 0, size = 3, offset = 0}, // position
	}

	return create_buffer(vertices, attributes)
}

CreateTexturedTriangle :: proc() -> (u32, u32) {
	vertices := []Vertex_P3T2 {
		{{-0.5, -0.5, 0.0}, {0.0, 0.0}},
		{{0.5, -0.5, 0.0}, {1.0, 0.0}},
		{{0.0, 0.5, 0.0}, {0.5, 1.0}},
	}

	attributes := []Attribute_Config {
		{location = 0, size = 3, offset = 0}, // position
		{location = 1, size = 2, offset = size_of([3]f32)}, // texcoord
	}

	return create_buffer(vertices, attributes)
}

CreateColoredTriangle :: proc() -> (u32, u32) {
	vertices := []Vertex_P3T2 {
		{{-0.5, -0.5, 0.0}, {0.0, 0.0}},
		{{0.5, -0.5, 0.0}, {1.0, 0.0}},
		{{0.0, 0.5, 0.0}, {0.5, 1.0}},
	}

	attributes := []Attribute_Config {
		{location = 0, size = 3, offset = 0}, // position
		{location = 1, size = 2, offset = size_of([3]f32)}, // uv coordinates
	}

	return create_buffer(vertices, attributes)
}

CreateRectangle :: proc(width: f32 = 1.0, height: f32 = 1.0) -> (u32, u32) {
	half_width := width * 0.5
	half_height := height * 0.5

	// Rectangle using two triangles
	vertices := []Vertex_P3T2 {
		// First triangle
		{{-half_width, -half_height, 0.0}, {0.0, 0.0}}, // Bottom left
		{{half_width, -half_height, 0.0}, {1.0, 0.0}}, // Bottom right
		{{half_width, half_height, 0.0}, {1.0, 1.0}}, // Top right

		// Second triangle
		{{-half_width, -half_height, 0.0}, {0.0, 0.0}}, // Bottom left
		{{half_width, half_height, 0.0}, {1.0, 1.0}}, // Top right
		{{-half_width, half_height, 0.0}, {0.0, 1.0}}, // Top left
	}

	attributes := []Attribute_Config {
		{location = 0, size = 3, offset = 0}, // position
		{location = 1, size = 2, offset = size_of([3]f32)}, // texture coordinates
	}

	return create_buffer(vertices, attributes)
}

CreateCircle :: proc(radius: f32 = 0.5, segments: int = 32) -> (u32, u32) {
	// Calculate vertices for the circle
	vertex_count := segments * 3 // Each segment is a triangle
	vertices := make([]Vertex_P3T2, vertex_count)
	defer delete(vertices)

	segment_angle := 2.0 * math.PI / f32(segments)

	for i := 0; i < segments; i += 1 {
		// Calculate the angles for this segment
		angle1 := f32(i) * segment_angle
		angle2 := f32(i + 1) * segment_angle

		// Calculate positions
		x1 := math.cos(angle1) * radius
		y1 := math.sin(angle1) * radius
		x2 := math.cos(angle2) * radius
		y2 := math.sin(angle2) * radius

		// Calculate texture coordinates
		u1 := (math.cos(angle1) + 1.0) * 0.5
		v1 := (math.sin(angle1) + 1.0) * 0.5
		u2 := (math.cos(angle2) + 1.0) * 0.5
		v2 := (math.sin(angle2) + 1.0) * 0.5

		// Set the vertices for this triangle
		idx := i * 3
		vertices[idx] = Vertex_P3T2{{0.0, 0.0, 0.0}, {0.5, 0.5}} // Center
		vertices[idx + 1] = Vertex_P3T2{{x1, y1, 0.0}, {u1, v1}} // First point on circumference
		vertices[idx + 2] = Vertex_P3T2{{x2, y2, 0.0}, {u2, v2}} // Second point on circumference
	}

	attributes := []Attribute_Config {
		{location = 0, size = 3, offset = 0}, // position
		{location = 1, size = 2, offset = size_of([3]f32)}, // texture coordinates
	}

	return create_buffer(vertices, attributes)
}
