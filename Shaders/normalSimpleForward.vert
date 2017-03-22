#version 330
uniform mat4 projModelViewMat, modelMat;

layout (location = 0) in vec4 position; 
layout (location = 4) in vec4 color;

out vec4 outColor;

void main()
{
	outColor = color;
	gl_Position = projModelViewMat * modelMat * position;
}
