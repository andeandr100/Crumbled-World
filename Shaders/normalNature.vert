#version 330
uniform mat4 projModelViewMat, modelMat;
uniform float time;

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
	//Position
	vec4 worldPos = modelMat * position;
	float timeDist = (time + modelMat[3][0] * 0.1 + modelMat[3][2]*0.2) * 0.75;
	vec2 addVec = vec2( sin(timeDist*0.5 + 0.5*cos(time*0.1)) * position.z*0.02, cos(timeDist) * position.z*0.02 );
	worldPos.x += addVec.x;
	worldPos.z += addVec.y;
	worldPos.y -= (1.0 - sin( 1.570796 + ( length( addVec ) / 7 ) * 1.570796 )) * 6.0;

	//Normal
	mat3 normalMatrix = transpose(inverse(mat3(modelMat )));
	outNormal	= normalMatrix * normal;
	outTagent	= normalMatrix * tagent;
	outBinormal = normalMatrix * cross(normal, tagent );


	textCoord = uvCoord;
    worldPos0 = worldPos.xyz;
	gl_Position = projModelViewMat * worldPos;

}