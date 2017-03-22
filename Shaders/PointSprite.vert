#version 150
in vec4 position;
in vec2 uvCoord;
in vec4 color;

uniform mat4 projModelViewMat, modelMat;
out vec4 pos;
out float size;
out vec2 uvCord;
out vec4 col;

void main( void )
{
	col = color;
	uvCord = uvCoord;
	size = position.w;
	pos=projModelViewMat*modelMat*vec4(position.xyz,1.0);
	gl_Position= pos;
}
