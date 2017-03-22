#version 330
uniform mat4 projModelViewMat, modelMat;


layout (location = 0) in vec4 position; 
layout (location = 1) in vec3 normal; 
layout (location = 2) in vec2 uvCoord; 
layout (location = 3) in vec3 tagent; 
//layout (location = 7) in mat4 modelMatrix; 

out vec2 textCoord;
out vec3 worldPos0;

out vec3 outNormal;
out vec3 outTagent;
out vec3 outBinormal;
	
void main()
{
	mat3 normalMatrix = transpose(inverse(mat3(modelMat)));
	outNormal	= normalMatrix * normal;
	outTagent	= normalMatrix * tagent;
	outBinormal = normalMatrix * cross(normal, tagent );


	textCoord = uvCoord;
    worldPos0 = (modelMat * position).xyz;
	
	vec4 worldPos = modelMat * position;
	gl_Position = projModelViewMat * worldPos;
}
