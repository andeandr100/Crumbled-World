#version 150

uniform vec4 coverColor;
uniform sampler2D diffuseMap;

in vec2 TextCord;
in vec4 VertexColor;

out vec4 FragColor; 

void main()
{
	vec4 diffuseColor = vec4( coverColor.rgb * VertexColor.rgb, texture2D(diffuseMap, TextCord).a);

	FragColor = diffuseColor;

}
