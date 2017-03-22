#version 330
uniform mat4 projModelViewMat, modelMat;

layout (location = 0) in vec3 position; 
layout (location = 1) in vec3 normal; 
layout (location = 2) in vec2 uvCoord; 
layout (location = 4) in vec4 color;

out vec3 outNormal;
out vec2 textCoord;
out vec3 worldPos0;
out vec3 localPosition;
out vec4 outColor;


void main()
{	
	localPosition = position;
	//pulsePos = modelMat[3].xyz + vec3(0,4.25,0);
	vec4 worldPos = vec4( modelMat[3].xyz + position, 1);

	mat3 normalMatrix = transpose(inverse(mat3(modelMat )));
	outNormal = normalMatrix * normal;

	outColor = color;
	textCoord = uvCoord;
    worldPos0 = worldPos.xyz;
	
	gl_Position = projModelViewMat * worldPos;
}
