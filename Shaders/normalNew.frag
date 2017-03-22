#version 330
uniform vec4 coverColor;

uniform sampler2D normalMap;
uniform sampler2D diffuseMap;
uniform sampler2D specularMap;
uniform sampler2D glowMap;

in vec2 textCoord; 
in vec3 worldPos0; 

in vec3 outNormal;
in vec3 outTagent;
in vec3 outBinormal;

layout (location = 0) out vec3 WorldPosOut; 
layout (location = 1) out vec3 NormalOut; 
layout (location = 2) out vec4 DiffuseOut;
layout (location = 3) out vec3 GlowOut;

void main() 
{ 
	vec4 diffuseColor = texture2D(diffuseMap, textCoord);
	if( diffuseColor.a < 0.9 )
		discard;

	mat3 TBN = mat3( outTagent, outBinormal, outNormal );
	vec3 normal = normalize( TBN * (texture2D(normalMap, textCoord).rgb * 2.0 - 1.0) );

    WorldPosOut = worldPos0; 
    DiffuseOut = vec4(diffuseColor.rgb * coverColor.rgb, texture2D(specularMap, textCoord).r); 
	NormalOut = normal;
	GlowOut = texture2D(glowMap, textCoord).rgb;

}
