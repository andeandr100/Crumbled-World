#version 150 core
uniform mat4 projModelViewMat, modelMat;
in vec4 position;
in vec2 uvCoord;
out vec2 TextCord;
void main()
{
	TextCord = uvCoord;
	gl_Position = projModelViewMat * modelMat * position ;
}