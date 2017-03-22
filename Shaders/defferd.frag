#version 330

in vec3 color0; 
in vec3 WorldPos0; 
in vec3 normal0;

layout (location = 0) out vec3 WorldPosOut; 
layout (location = 1) out vec3 NormalOut; 
layout (location = 2) out vec3 DiffuseOut;


void main() 
{ 
    WorldPosOut = WorldPos0; 
    DiffuseOut = color0; 
	NormalOut = normal0;
}