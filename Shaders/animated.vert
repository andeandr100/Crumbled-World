#version 330
uniform mat4 projModelViewMat, modelMat;
uniform mat4 boneMatrix[60];

layout (location = 0) in vec4 position;
layout (location = 1) in vec3 normal;
layout (location = 2) in vec2 uvCoord;
layout (location = 3) in vec3 tagent;
layout (location = 4) in vec4 color;
layout (location = 5) in uvec3 boneId;
layout (location = 6) in vec3 weight;

out vec2 textCoord;
out vec3 worldPos0;
out vec4 outColor;

out vec3 outNormal;
out vec3 outTagent;
out vec3 outBinormal;
	
void main()
{
	outColor = color;
	mat4 transformMatrix = weight.x * boneMatrix[boneId[0]] +
                           weight.y * boneMatrix[boneId[1]] +
                           weight.z * boneMatrix[boneId[2]];

	mat3 normalMatrix = mat3(modelMat);

    vec3 finalNormal = (transformMatrix * vec4(normal, 0.0)).xyz;
    outNormal = normalize(normalMatrix * finalNormal);

    vec3 finalTangent = (transformMatrix * vec4(tagent, 0.0)).xyz;
    outTagent = normalize(normalMatrix * finalTangent);
    
    outBinormal = cross(outNormal, outTagent);

    vec4 worldPos =	modelMat * transformMatrix * position;

    textCoord = uvCoord;
    worldPos0 = worldPos.xyz;
    gl_Position = projModelViewMat * worldPos;

}
