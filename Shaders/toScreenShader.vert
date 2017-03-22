#version 330
uniform mat4 projModelViewMat, modelMat;

layout (location = 0) in vec4 position;
layout (location = 2) in vec2 uvCoord;

out vec2 TexCoords;

void main()
{
	TexCoords = uvCoord;
	gl_Position = projModelViewMat * modelMat * position;
}
