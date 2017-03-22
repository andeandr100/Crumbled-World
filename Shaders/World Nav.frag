#version 150
out vec4 Frag_Color;

uniform vec4 coverColor;

void main()
{
	Frag_Color = coverColor;
}
