#version 150

uniform sampler2D diffuseMap;
uniform vec4 coverColor;
uniform vec3 lightDir;

in vec2 TextCord;
in vec4 vertexColor;

out vec4 FragColor;

void main()
{
	FragColor = texture2D(diffuseMap, TextCord) * vertexColor * coverColor;
}
