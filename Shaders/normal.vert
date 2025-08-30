#version 330
uniform mat4 projModelViewMat, modelMat;

layout (location = 0) in vec4 position;
layout (location = 1) in vec3 normal;
layout (location = 2) in vec2 uvCoord;
layout (location = 3) in vec3 tagent;
layout (location = 4) in vec4 color;

out vec2 textCoord;
out vec3 worldPos0;
out vec4 outColor;

out vec3 outNormal;
out vec3 outTagent;
out vec3 outBinormal;

void main()
{
    outColor = color;
    mat3 normalMatrix = mat3(modelMat);
    outNormal	= normalize(normalMatrix * normal);
    outTagent	= normalize(normalMatrix * tagent);
    outBinormal = cross(outNormal, outTagent);


    textCoord = uvCoord;
    vec4 worldPos = modelMat * position;
    worldPos0 = worldPos.xyz;
    
    gl_Position = projModelViewMat * worldPos;
}
