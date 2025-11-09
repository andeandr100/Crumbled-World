#version 330
uniform mat4 projModelViewMat, modelMat;
uniform mat4 boneMatrix[60];

layout (location = 0) in vec4 position;
layout (location = 5) in uvec3 boneId;
layout (location = 6) in vec3 weight;

void main()
{
	mat4 transformMatrix = weight.x * boneMatrix[boneId[0]] +
                           weight.y * boneMatrix[boneId[1]] +
                           weight.z * boneMatrix[boneId[2]];

	vec4 worldPos =	modelMat * transformMatrix * position;

	gl_Position = projModelViewMat * worldPos;

}
