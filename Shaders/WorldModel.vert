#version 330
uniform mat4 projModelViewMat, modelMat;

layout (location = 0) in vec3 position; 
layout (location = 1) in vec3 normal; 
layout (location = 2) in vec2 uvCoord; 
layout (location = 4) in vec3 color;

out vec2 localTextureCord;
out vec2 textCoord;
out vec3 worldPos0;

out vec3 outNormal;
out vec3 outTagent;
out vec3 outBinormal;

void main()
{
	textCoord = uvCoord;
	localTextureCord = vec2( position.x * 0.25, position.z * 0.25 );

	mat3 normalMatrix = transpose(inverse(mat3(1.0)));
	outNormal	= normalMatrix * normal;
	outTagent	= normalMatrix * vec3(1,0,0);
	outBinormal = normalMatrix * cross(normal, vec3(1,0,0) );

	vec4 worldPosition = modelMat * vec4( position, 1.0 );
	worldPos0 = worldPosition.xyz;
	gl_Position = projModelViewMat *  worldPosition;
}
