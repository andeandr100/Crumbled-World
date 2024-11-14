#version 330
uniform vec4 coverColor;
uniform sampler2D diffuseMap;
uniform float time;
in vec2 TextCord;
in vec4 vertexColor;
out vec4 Frag_Color;
void main()
{
	Frag_Color = (vertexColor * 0.5 + vertexColor * texture2D(diffuseMap, TextCord) * 0.35 + texture2D(diffuseMap, TextCord) * 0.15) * coverColor;
}

