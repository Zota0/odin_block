#version 330 core

in vec3 Normal;
out vec4 FragColor;

void main(){
    // Normalize the normal vector
    vec3 normalizedNormal=normalize(Normal);
    
    // Map the normal components to RGB color (0-1 range)
    vec3 color=(normalizedNormal+1.)/2.;// Shift and scale to 0-1
    
    FragColor=vec4(color,1.);// Add alpha (1.0 for opaque)
}