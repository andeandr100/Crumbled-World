#version 330

uniform sampler2D diffuseMap;

in vec2 TextCord;

out vec4 Frag_Color;

void main()
{
    if( texture2D(diffuseMap, TextCord).a < 0.9 )
		discard;

	Frag_Color = vec4( 0, 0, 0, 1 );
}
