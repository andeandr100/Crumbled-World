#version 330
uniform mat4 projModelViewMat, modelMat;
in vec4 position;
in vec2 uvCoord;
out vec2 TexCoords;

void main()
{
	TexCoords = uvCoord;
	gl_Position = projModelViewMat * modelMat * position;
}

