#version 330
uniform mat4 projModelViewMat, modelMat;


layout (location = 0) in vec4 position; 
layout (location = 2) in vec2 uvCoord; 
layout (location = 4) in vec4 color;

out vec2 textCoord;
out vec4 outColor;
	
void main()
{
	outColor = color;
	textCoord = uvCoord;
	gl_Position = projModelViewMat * modelMat * position;
}
