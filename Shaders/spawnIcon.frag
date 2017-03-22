#version 150

uniform vec4 coverColor;
uniform sampler2D diffuseMap;
uniform vec3 lightDir;

in vec2 TextCord;
in vec4 VertexColor;

out vec4 FragColor; 

void main()
{
	vec3 color = coverColor.rgb * VertexColor.rgb;
	vec4 textColor = texture2D(diffuseMap, TextCord);
	float alpha = textColor.a * VertexColor.a;

	FragColor = vec4( textColor.rgb*alpha + color * (1.0-alpha), 1.0);
}
