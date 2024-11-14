#version 150 core
uniform vec4 coverColor;
uniform sampler2D diffuseMap;
uniform float time;
in vec2 TextCord;
out vec4 Frag_Color;
void main()
{
	Frag_Color = coverColor * texture2D(diffuseMap, TextCord);
}