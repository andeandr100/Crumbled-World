#version 150
in vec4 position;
in vec3 normal;

uniform mat4 projModelViewMat, modelMat;

out vec4 pos;
out vec3 lifeBarValues;
out float value;

void main( void )
{
	value = position.w;
	lifeBarValues = normal;
	pos = projModelViewMat*modelMat*vec4(position.xyz,1.0);
	gl_Position = pos;
}
