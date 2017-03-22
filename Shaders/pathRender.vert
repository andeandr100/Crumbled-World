#version 150
uniform mat4 projModelViewMat;
uniform vec3 camPos;
in vec3 pos1;
in vec3 pos2;

out vec3 Pos1;
out vec3 Pos2;

void main( void )
{
	Pos1 = pos1;
	Pos2 = pos2;

	gl_Position = projModelViewMat * vec4((pos1+pos2)*0.5,1);
}
