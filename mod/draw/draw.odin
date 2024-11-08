package draw

import gl "vendor:OpenGL"

// MARK: Depth test
EnableDepthTest :: proc() {
	gl.Enable(gl.DEPTH_TEST)
}
DisableDepthTest :: proc() {
    gl.Disable(gl.DEPTH_TEST)
}
ToggleDepthTest :: proc() {
	if gl.IsEnabled(gl.DEPTH_TEST) {
		DisableDepthTest()
	} else {
		EnableDepthTest()
	}
}

// MARK: Cull face
EnableCullFace :: proc() {
	gl.Enable(gl.CULL_FACE)
}
DisableCullFace :: proc() {
	gl.Disable(gl.CULL_FACE)
}

// MARK: Cull faces
EnableCullFaceBack :: proc() {
	gl.CullFace(gl.BACK)
}
EnableCullFaceFront :: proc() {
	gl.CullFace(gl.FRONT)
}
EnableCullFaceFrontAndBack :: proc() {
	gl.CullFace(gl.FRONT_AND_BACK)
}
EnableCullFaceFrontLeft :: proc() {
    gl.CullFace(gl.FRONT_LEFT)
}
EnableCullFaceFrontRight :: proc() {
    gl.CullFace(gl.FRONT_RIGHT)
}
EnableCullFaceBackLeft :: proc() {
    gl.CullFace(gl.BACK_LEFT)
}
EnableCullFaceBackRight :: proc() {
    gl.CullFace(gl.BACK_RIGHT)
}
EnableCullFaceNone :: proc() {
	gl.CullFace(gl.NONE)
}

// MARK: CCW && CW
EnableCullFaceCCW :: proc() {
    gl.CullFace(gl.CCW)
}

EnableCullFaceCW :: proc() {
    gl.CullFace(gl.CW)
}
