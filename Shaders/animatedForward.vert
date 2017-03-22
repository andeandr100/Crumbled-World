#version 330
uniform mat4 projModelViewMat, modelMat;
uniform mat4 boneMatrix[60];

layout (location = 0) in vec4 position; 
layout (location = 1) in vec3 normal; 
layout (location = 2) in vec2 uvCoord; 
layout (location = 3) in vec3 tagent; 
layout (location = 5) in uvec3 boneId;
layout (location = 6) in vec3 weight;

out vec2 textCoord;
out vec3 worldPos0;

out vec3 outNormal;
out vec3 outTagent;
out vec3 outBinormal;
	
void main()
{
	mat4 transformMatrix = weight.x * boneMatrix[boneId[0]];
		transformMatrix += weight.y * boneMatrix[boneId[1]];
		transformMatrix += weight.z * boneMatrix[boneId[2]];

	vec3 finalNormal =	(transformMatrix * vec4(normal,0)).xyz;
	mat3 normalMatrix = transpose(inverse(mat3(modelMat )));
	outNormal	= normalize( normalMatrix * finalNormal );
	outTagent	= normalize( normalMatrix * tagent );
	outBinormal = normalize( normalMatrix * cross(finalNormal, tagent ) );

	vec4 worldPos =	modelMat * transformMatrix * position;

	textCoord = uvCoord;
	worldPos0 = worldPos.xyz;
	gl_Position = projModelViewMat * worldPos;

}
