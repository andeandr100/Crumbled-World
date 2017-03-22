#version 150
#extension GL_ARB_explicit_attrib_location : enable
#extension GL_ARB_separate_shader_objects : enable


in vec3 worldNor0;
in vec3 worldPos0; 
in vec3 color;


layout (location = 0) out vec3 WorldPosOut; 
layout (location = 1) out vec3 NormalOut; 
layout (location = 2) out vec4 DiffuseOut;
layout (location = 3) out vec4 GlowOut;

void main( void )
{
    WorldPosOut = worldPos0; 
    DiffuseOut = vec4( color.rgb, 0.3); 
	NormalOut = worldNor0;
	GlowOut = vec4(0,0,0,0);
}