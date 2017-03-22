#version 330

uniform sampler2D diffuseMap;

in vec3 worldNor0;
in vec3 worldPos0; 
in vec4 SpriteColor;
in vec2 tc;


layout (location = 0) out vec3 WorldPosOut; 
layout (location = 1) out vec3 NormalOut; 
layout (location = 2) out vec4 DiffuseOut;
layout (location = 3) out vec4 GlowOut;

#if defined(SELECTED)
	const float selected = 1.0;
#else
	const float selected = 0.0;
#endif

void main( void )
{
    WorldPosOut = worldPos0; 
    DiffuseOut = vec4(texture2D(diffuseMap, tc).rgb * SpriteColor.rgb, 0.3); 
	NormalOut = worldNor0;
	GlowOut = vec4(0,0,0,selected);
}

