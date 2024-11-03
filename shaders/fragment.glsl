#version 460 core

in vec2 TexCoord;

out vec4 FragColor;

void main(){
    vec3 yellow=vec3(0.9, 1.0, 0.0);
    vec3 green=vec3(0.0, 1.0, 0.0);
    
    // Mix between yellow and green based on UV coordinates
    // Using the V coordinate for the interpolation
    vec3 finalColor=mix(yellow,green,TexCoord.y * TexCoord.x);
    
    FragColor=vec4(finalColor,1.);
}