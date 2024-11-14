#version 330
uniform mat4 projModelViewMat, modelMat;
in vec4 position;
in vec2 uvCoord;
in vec4 color;

out vec4 vertexColor;
out vec2 TextCord;

void main()
{
	vertexColor = color;
	TextCord = uvCoord;
	gl_Position = projModelViewMat * modelMat * position;
}
