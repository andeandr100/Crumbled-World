#version 330 
uniform mat4 projModelViewMat;


layout (location = 0) in vec3 position; 
layout (location = 1) in vec3 normal; 
layout (location = 4) in vec3 color; 

out vec3 color0; 
out vec3 WorldPos0;
out vec3 normal0;

void main()
{ 
    gl_Position = projModelViewMat * vec4(position, 1.0);
    color0 = color;  
    WorldPos0 = position;
	normal0 = normal;
}