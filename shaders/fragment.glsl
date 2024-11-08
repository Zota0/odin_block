#version 460 core

in vec2 TexCoord;
out vec4 FragColor;

// Constants for color definitions
const vec3 YELLOW=vec3(.9,1.,0.);
const vec3 GREEN=vec3(0.,1.,0.);
const vec3 RED=vec3(1.,0.,0.);
const vec3 BLUE=vec3(0.,0.,1.);

// Function to create a smooth transition
float smoothTransition(float value,float edge0,float edge1){
    float t=clamp((value-edge0)/(edge1-edge0),0.,1.);
    return t*t*(3.-2.*t);// Smooth interpolation using smoothstep algorithm
}

void main(){
    // Create more interesting patterns using both coordinates
    float angle=atan(TexCoord.y-.5,TexCoord.x-.5);
    float distance=length(TexCoord-vec2(.5));
    
    // Create a radial gradient with smooth transitions
    float delta=smoothTransition(distance*2.,0.,1.);
    
    // Add some circular wave patterns
    delta+=sin(distance*15.)*.1;
    delta+=cos(angle*6.)*.1;
    
    // Ensure delta stays in valid range after modifications
    delta=clamp(delta,0.,1.);
    
    // Create primary and secondary color mixes
    vec3 primaryMix=mix(YELLOW,GREEN,delta);
    vec3 secondaryMix=mix(RED,BLUE,delta);
    
    // Create final color with smooth transition
    float blendFactor=smoothTransition(sin(distance*10.+angle*3.)*.5+.5,0.,1.);
    vec3 finalColor=mix(primaryMix,secondaryMix,blendFactor);
    
    // Add subtle vignette effect
    float vignette=smoothTransition(1.-distance*1.2,0.,1.);
    finalColor*=vignette;
    
    FragColor=vec4(finalColor,1.);
}