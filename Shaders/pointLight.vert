#version 330
uniform mat4 projModelViewMat, modelMat;


layout (location = 0) in vec4 position; 

	
void main()
{
	gl_Position = projModelViewMat * modelMat * position;
}
