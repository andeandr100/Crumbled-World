#version 330
uniform mat4 projModelViewMat, modelMat;
uniform float time;

layout (location = 0) in vec4 position;
layout (location = 1) in vec3 normal;
layout (location = 2) in vec2 uvCoord;
layout (location = 3) in vec3 tagent;

out vec2 textCoord;
out vec3 worldPos0;

out vec3 outNormal;
out vec3 outTagent;
out vec3 outBinormal;


void main()
{
	float timeDist = (time + modelMat[3][0] * 0.1 + modelMat[3][2]*0.2) * 0.75;
	vec2 addVec = vec2( sin(timeDist*0.5 + 0.5*cos(time*0.1)) * position.z*0.02, cos(timeDist) * position.z*0.02 );
	vec4 worldPos = modelMat * position + vec4(addVec.xy, (cos(length(addVec) * 0.2243994) - 1.0) * 6.0, 0.0);

	mat3 normalMatrix = mat3(modelMat);
	outNormal	= normalize(normalMatrix * normal);
    outTagent	= normalize(normalMatrix * tagent);
	// Example: outBinormal = cross(outNormal, outTagent);
    outBinormal = cross(outNormal, outTagent);


	textCoord = uvCoord;
    worldPos0 = worldPos.xyz;
	gl_Position = projModelViewMat * worldPos;

}
