package objects

import "core:fmt"
import "core:math"
import gl "vendor:OpenGL"

Vertex_P3 :: struct {
    position: [3]f32,
}

Vertex_P3T2 :: struct {
    position: [3]f32,
    texcoord: [2]f32,
}

// Error checking utility
CheckGlError :: proc(message: string) {
    err := gl.GetError()
    if err != gl.NO_ERROR {
        fmt.printfln("OpenGL error [%s]: %x", message, err)
    }
}

// Generic buffer creation utility
CreateBuffer :: proc(vertices: []$T, attributes: []Attribute_Config) -> (vao: u32, vbo: u32) {
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
    CheckGlError("BufferData")
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
        CheckGlError("Vertex Attribute Setup")
    }
    // Unbind buffers
    gl.BindBuffer(gl.ARRAY_BUFFER, 0)
    gl.BindVertexArray(0)
    fmt.println("## Buffer creation complete. ##")
    return vao, vbo
}

// Enhanced buffer creation utility with index buffer support
CreateBufferIndexed :: proc(vertices: []$T, indices: []u32, attributes: []Attribute_Config) -> (vao: u32,  ebo: u32, vbo: u32) {
    fmt.println("## Creating indexed buffer objects... ##")
    
    // Generate buffers
    gl.GenVertexArrays(1, &vao)
    gl.GenBuffers(1, &vbo)
    gl.GenBuffers(1, &ebo)
    
    if vao == 0 || vbo == 0 || ebo == 0 {
        fmt.eprintln("Failed to generate VAO, VBO, or EBO")
        return 0, 0, 0
    }
    
    // Bind VAO first
    gl.BindVertexArray(vao)
    
    // Bind and fill vertex buffer
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
    gl.BufferData(gl.ARRAY_BUFFER, len(vertices) * size_of(T), &vertices[0], gl.STATIC_DRAW)
    CheckGlError("Vertex BufferData")
    
    // Bind and fill element buffer
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(indices) * size_of(u32), &indices[0], gl.STATIC_DRAW)
    CheckGlError("Index BufferData")
    
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
        CheckGlError("Vertex Attribute Setup")
    }
    
    // Unbind buffers
    gl.BindBuffer(gl.ARRAY_BUFFER, 0)
    gl.BindVertexArray(0)
    // Note: Don't unbind EBO while VAO is active as VAO stores its state
    
    fmt.println("## Indexed buffer creation complete. ##")
    return vao, vbo, ebo
}

Attribute_Config :: struct {
    location: u32,
    size:     i32,
    offset:   int,
}

// Optimized triangle creation
CreateTriangle :: proc() -> (vao: u32,  ebo: u32, vbo: u32) {
    vertices := []Vertex_P3{
        {{0.0, 0.5, 0.0}},    // Top
        {{-0.5, -0.366, 0.0}}, // Left
        {{0.5, -0.366, 0.0}},  // Right
    }
    
    indices := []u32{0, 1, 2}
    
    attributes := []Attribute_Config{
        {location = 0, size = 3, offset = 0}, // position
    }
    
    return CreateBufferIndexed(vertices, indices, attributes)
}

// Optimized rectangle creation
CreateRectangle :: proc(width: f32 = 1.0, height: f32 = 1.0) -> (vao: u32,  ebo: u32, vbo: u32) {
    half_width := width * 0.5
    half_height := height * 0.5
    
    vertices := []Vertex_P3T2{
        {{-half_width, -half_height, 0.0}, {0.0, 0.0}}, // Bottom left
        {{half_width, -half_height, 0.0}, {1.0, 0.0}},  // Bottom right
        {{half_width, half_height, 0.0}, {1.0, 1.0}},   // Top right
        {{-half_width, half_height, 0.0}, {0.0, 1.0}},  // Top left
    }
    
    indices := []u32{
        0, 1, 2,  // First triangle
        0, 2, 3,  // Second triangle
    }
    
    attributes := []Attribute_Config{
        {location = 0, size = 3, offset = 0}, // position
        {location = 1, size = 2, offset = size_of([3]f32)}, // texture coordinates
    }
    
    return CreateBufferIndexed(vertices, indices, attributes)
}

CreateRectangleUnindexed :: proc(width: f32 = 1.0, height: f32 = 1.0) -> (vao: u32, vbo: u32) {
    half_width := width * 0.5
    half_height := height * 0.5
    
    // Create 6 vertices (2 triangles)
    vertices := []Vertex_P3T2{
        // First triangle
        {{-half_width, -half_height, 0.0}, {0.0, 0.0}}, // Bottom left
        {{half_width, -half_height, 0.0}, {1.0, 0.0}},  // Bottom right
        {{half_width, half_height, 0.0}, {1.0, 1.0}},   // Top right
        
        // Second triangle
        {{-half_width, -half_height, 0.0}, {0.0, 0.0}}, // Bottom left
        {{half_width, half_height, 0.0}, {1.0, 1.0}},   // Top right
        {{-half_width, half_height, 0.0}, {0.0, 1.0}},  // Top left
    }
    
    attributes := []Attribute_Config{
        {location = 0, size = 3, offset = 0}, // position
        {location = 1, size = 2, offset = size_of([3]f32)}, // texture coordinates
    }
    
    return CreateBuffer(vertices, attributes)
}

CreateTexturedTriangle :: proc() -> (vao: u32,  ebo: u32, vbo: u32) {
	vertices := []Vertex_P3T2 {
		{{-0.5, -0.5, 0.0}, {0.0, 0.0}},
		{{0.5, -0.5, 0.0}, {1.0, 0.0}},
		{{0.0, 0.5, 0.0}, {0.5, 1.0}},
	}

    indices := []u32{0, 1, 2}


	attributes := []Attribute_Config {
		{location = 0, size = 3, offset = 0}, // position
		{location = 1, size = 2, offset = size_of([3]f32)}, // texcoord
	}

	return CreateBufferIndexed(vertices, indices, attributes)
}

CreateColoredTriangle :: proc() -> (u32, u32, u32) {
	vertices := []Vertex_P3T2 {
		{{-0.5, -0.5, 0.0}, {0.0, 0.0}},
		{{0.5, -0.5, 0.0}, {1.0, 0.0}},
		{{0.0, 0.5, 0.0}, {0.5, 1.0}},
	}

    indices := []u32{0, 1, 2}


	attributes := []Attribute_Config {
		{location = 0, size = 3, offset = 0}, // position
		{location = 1, size = 2, offset = size_of([3]f32)}, // uv coordinates
	}

	return CreateBufferIndexed(vertices, indices, attributes)
}

CreateCircle :: proc(radius: f32 = 0.5, segments: int = 32) -> (vao: u32,  ebo: u32, vbo: u32) {
    // Calculate vertices and indices
    vertex_count := segments + 1  // Center vertex + vertices on circumference
    index_count := segments * 3   // Each segment is still a triangle
    
    // Allocate memory for vertices and indices
    vertices := make([]Vertex_P3T2, vertex_count)
    indices := make([]u32, index_count)
    defer delete(vertices)
    defer delete(indices)
    
    // Set center vertex
    vertices[0] = Vertex_P3T2{{0.0, 0.0, 0.0}, {0.5, 0.5}}
    
    // Calculate segment angle
    segment_angle := 2.0 * math.PI / f32(segments)
    
    // Generate vertices on the circumference
    for i := 0; i < segments; i += 1 {
        angle := f32(i) * segment_angle
        
        // Calculate position
        x := math.cos(angle) * radius
        y := math.sin(angle) * radius
        
        // Calculate texture coordinates
        u := (math.cos(angle) + 1.0) * 0.5
        v := (math.sin(angle) + 1.0) * 0.5
        
        // Set vertex
        vertices[i + 1] = Vertex_P3T2{{x, y, 0.0}, {u, v}}
        
        // Set indices for this triangle
        idx := i * 3
        indices[idx] = 0                          // Center vertex
        indices[idx + 1] = u32(i + 1)            // Current point on circumference
        indices[idx + 2] = u32((i + 1) % segments + 1) // Next point on circumference
    }
    
    attributes := []Attribute_Config{
        {location = 0, size = 3, offset = 0}, // position
        {location = 1, size = 2, offset = size_of([3]f32)}, // texture coordinates
    }
    
    return CreateBufferIndexed(vertices, indices, attributes)
}

CreateCube :: proc(size: f32 = 1.0) -> (vao: u32, ebo: u32, vbo: u32) {
    half_size := size * 0.5
    
    // 8 vertices for a cube (each corner)
    vertices := []Vertex_P3T2{
        // Front face
        {{-half_size, -half_size,  half_size}, {0.0, 0.0}},  // bottom-left  0
        {{ half_size, -half_size,  half_size}, {1.0, 0.0}},  // bottom-right 1
        {{ half_size,  half_size,  half_size}, {1.0, 1.0}},  // top-right    2
        {{-half_size,  half_size,  half_size}, {0.0, 1.0}},  // top-left     3
        
        // Back face
        {{-half_size, -half_size, -half_size}, {1.0, 0.0}},  // bottom-left  4
        {{ half_size, -half_size, -half_size}, {0.0, 0.0}},  // bottom-right 5
        {{ half_size,  half_size, -half_size}, {0.0, 1.0}},  // top-right    6
        {{-half_size,  half_size, -half_size}, {1.0, 1.0}},  // top-left     7
    }

    // Indices for drawing the triangles
    indices := []u32{
        // Front face
        0, 1, 2,
        0, 2, 3,
        // Right face
        1, 5, 6,
        1, 6, 2,
        // Back face
        5, 4, 7,
        5, 7, 6,
        // Left face
        4, 0, 3,
        4, 3, 7,
        // Top face
        3, 2, 6,
        3, 6, 7,
        // Bottom face
        4, 5, 1,
        4, 1, 0,
    }
    
    attributes := []Attribute_Config{
        {location = 0, size = 3, offset = 0}, // position
        {location = 1, size = 2, offset = size_of([3]f32)}, // texture coordinates
    }
    
    return CreateBufferIndexed(vertices, indices, attributes)
}

