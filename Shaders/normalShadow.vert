#version 330

uniform mat4 projModelViewMat, modelMat;

layout (location = 0) in vec4 position; 
layout (location = 2) in vec2 uvCoord; 
//layout (location = 7) in mat4 modelMatrix; 

out vec2 TextCord;
	
void main()
{	
	TextCord = uvCoord;
	gl_Position = projModelViewMat * modelMat * position;
}
