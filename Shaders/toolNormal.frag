#version 330

in vec4 outColor; 

out vec4 FragColor;

void main() 
{ 
    FragColor = vec4(outColor.rgb,1); 
}
