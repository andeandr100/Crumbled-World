#version 330 core
in vec2 TexCoords;

uniform vec4 coverColor;
uniform sampler2D diffuseMap;
uniform sampler2D gGlow;

out vec4 FragColor;

void main()
{             
	FragColor = texture(diffuseMap, TexCoords) * coverColor;

	if( dot(FragColor,FragColor) < 1.005 )
		discard;
}  





