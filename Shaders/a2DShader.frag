#version 330 core
in vec2 TexCoords;

uniform sampler2D diffuseMap;
uniform sampler2D gGlow;

out vec4 FragColor;

void main()
{             
	FragColor = texture(diffuseMap, TexCoords);
}  





