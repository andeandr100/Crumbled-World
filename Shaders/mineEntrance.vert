#version 330
uniform mat4 projModelViewMat, modelMat;

layout (location = 0) in vec4 position; 


out vec3 worldPos0;



void main()
{	
	vec4 worldPos = modelMat * position;


    worldPos0 = worldPos.xyz;
	
	gl_Position = projModelViewMat * worldPos;
}
