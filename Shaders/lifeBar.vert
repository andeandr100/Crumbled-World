#version 150
in vec4 position;
in vec4 color;

uniform mat4 projModelViewMat, modelMat;

out vec4 pos;
out vec4 lifeBarValues;
out float value;

void main( void )
{
	value = position.w;
	lifeBarValues = color;
	pos = projModelViewMat*modelMat*vec4(position.xyz,1.0);
	gl_Position = pos;
}
