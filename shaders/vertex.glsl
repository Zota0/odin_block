#version 330 core
layout(location=0)in vec3 aPos;
layout(location=1)in vec3 aNormal;

uniform mat4 projection;// Changed from projectionMatrix
uniform mat4 view;// Changed from viewMatrix
uniform mat4 model;// Changed from modelMatrix

out vec3 Normal;

void main(){
    gl_Position=projection*view*model*vec4(aPos,1.);
    Normal=aNormal;
}