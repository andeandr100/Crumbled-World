#version 330
uniform vec4 coverColor;

uniform sampler2D diffuseMap;
uniform sampler2D normalMap;
uniform sampler2D specularMap;
uniform sampler2D glowMap;

in vec2 textCoord; 
in vec3 worldPos0; 
in vec4 vertexColor;
in vec3 worldNormal;

layout (location = 0) out vec3 WorldPosOut; 
layout (location = 1) out vec3 NormalOut; 
layout (location = 2) out vec4 DiffuseOut;
layout (location = 3) out vec4 GlowOut;

#if defined(SELECTED)
	const float selected = 1.0;
#else
	const float selected = 0.0;
#endif

void main() 
{ 
	vec4 diffuseColor = texture2D(diffuseMap, textCoord);
	if( diffuseColor.a < 0.9 )
		discard;


    WorldPosOut = worldPos0; 
    DiffuseOut = vec4( diffuseColor.rgb*coverColor.rgb, 0.4)*vertexColor; 
	NormalOut = worldNormal;
	GlowOut = vec4(0,0,0,selected);
}
