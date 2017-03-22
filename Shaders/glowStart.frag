#version 330 core
in vec2 TexCoords;

uniform sampler2D diffuseMap;
uniform sampler2D gGlow;

out vec4 FragColor;

void main()
{             

    vec3 Color = texture(diffuseMap, TexCoords).rgb;
	vec3 Glow = texture(gGlow, TexCoords).rgb;
	
	FragColor = vec4(Glow,1);

	if(length(Color) > 1.5)
		FragColor.rgb += Color;

}  





