#version 330 core

uniform sampler2D gPosition;
uniform sampler2D gNormal;

uniform sampler2D diffuseMap;

uniform vec2 offset;
uniform vec3 camPos;

in vec2 TexCoords;

out vec4 FragColor;

const vec2 offsetArray[4] = vec2[](
    vec2(1.0, 0.0),
    vec2(-1.0, 0.0),
    vec2(0.0, 1.0),
    vec2(0.0, -1.0)
);

void main()
{
    vec3 currentPos = texture(gPosition, TexCoords).xyz;
    vec3 originalColor = texture(diffuseMap, TexCoords).rgb;

    // Edge detection based on depth buffer
    float maxDepthDiff = 0.0;
    for(int i = 0; i < 4; i++)
    {
        vec3 neighborPos = texture(gPosition, TexCoords + offset * offsetArray[i]).xyz;
        maxDepthDiff = max(maxDepthDiff, length(neighborPos - currentPos));
    }

    // If a significant depth difference is found, it's an edge, so we blur.
    if(maxDepthDiff > 0.2)
    {
        vec3 blurredColor = originalColor;
        for(int i = 0; i < 4; i++)
        {
            blurredColor += texture(diffuseMap, TexCoords + offset * offsetArray[i]).rgb;
        }
        FragColor = vec4(blurredColor / 5.0, 1.0);
    }
    else
    {
        FragColor = vec4(originalColor, 1.0);
    }
}
