#version 330 core
in vec2 TexCoords;

uniform sampler2D diffuseMap;
uniform sampler2D gGlow;

out vec4 FragColor;

void main()
{
    vec3 Color = texture(diffuseMap, TexCoords).rgb;
    vec3 Glow = texture(gGlow, TexCoords).rgb;
    
    FragColor = vec4(Glow, 1.0);

    // Add the base color if its brightness is above a threshold.
    // Using dot(Color, Color) is faster than length(Color) as it avoids a square root.
    // 1.5 * 1.5 = 2.25
    if(dot(Color, Color) > 2.25)
    {
        FragColor.rgb += Color;
    }
}





