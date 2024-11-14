#version 150
uniform mat4 projModelViewMat;
in vec3 position;

void main()
{
	gl_Position = projModelViewMat * vec4( position, 1.0 );
}
