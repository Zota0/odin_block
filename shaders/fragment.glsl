#version 330 core

in vec3 Normal;
out vec4 FragColor;

void main() {
    // Normalize the normal vector to ensure correct color representation
    vec3 newNormal=normalize(Normal);
    
    // Directly assign the normalized normal components to RGB
    FragColor=vec4(newNormal,1.);
}