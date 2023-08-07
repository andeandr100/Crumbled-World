#version 330 core

uniform mat4 projModelViewMat, modelMat;

in vec3 position;


void main()
{
	gl_Position = vec4( position, 1.0 );
}
