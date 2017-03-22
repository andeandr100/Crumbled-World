#version 330
uniform mat4 projModelViewMat, modelMat;
in vec3 position;

void main()
{
	gl_Position = projModelViewMat * modelMat * vec4( position, 1.0 );
}
