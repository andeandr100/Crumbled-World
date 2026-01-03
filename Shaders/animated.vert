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

	// Compute bone transformation matrix using weights
	mat4 transformMatrix = weight.x * boneMatrix[boneId[0]] +
                           weight.y * boneMatrix[boneId[1]] +
                           weight.z * boneMatrix[boneId[2]];

	// Extract upper 3x3 for normal transformation (no translation needed for normals)
	mat3 normalMatrix = mat3(modelMat);
	
	// Transform normal, tangent and compute binormal in one pass
	// Apply bone transformation first, then model transformation
	vec3 finalNormal = mat3(transformMatrix) * normal;
	vec3 finalTangent = mat3(transformMatrix) * tagent;
	
	// Transform to world space and normalize once at the end
	outNormal = normalize(normalMatrix * finalNormal);
	outTagent = normalize(normalMatrix * finalTangent);
	
	// Cross product to get binormal (already normalized since inputs are normalized)
	outBinormal = cross(outNormal, outTagent);

	// Compute world position: modelMat * transformMatrix * position
	// This is more efficient than separate multiplications
	vec4 worldPos = modelMat * (transformMatrix * position);

	textCoord = uvCoord;
	worldPos0 = worldPos.xyz;
	
	// Final projection
	gl_Position = projModelViewMat * worldPos;
}
