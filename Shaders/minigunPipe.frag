#version 330
uniform vec4 coverColor;
#if defined(GLOW)
uniform vec3 glowColor;
#endif

uniform sampler2D normalMap;
uniform sampler2D diffuseMap;
uniform sampler2D specularMap;
uniform sampler2D glowMap;

uniform vec2  heatUvCoordOffset;
uniform float heat;

in vec2 textCoord; 
in vec3 worldPos0; 

in vec3 outNormal;
in vec3 outTagent;
in vec3 outBinormal;

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
	vec4 diffuseColorOverHeat = texture2D(diffuseMap, textCoord+heatUvCoordOffset);
	vec4 diffuseColorOverHeatGlow = texture2D(glowMap, textCoord+heatUvCoordOffset);

	//if( diffuseColor.a < 0.9 )
	//	discard;

	mat3 TBN = mat3( outTagent, outBinormal, outNormal );
	vec3 normal = normalize( TBN * (texture2D(normalMap, textCoord).rgb * 2.0 - 1.0) );

	WorldPosOut = worldPos0; 
	DiffuseOut = vec4((diffuseColor.rgb * coverColor.rgb * (1-heat)) + (diffuseColorOverHeat.rgb * heat), texture2D(specularMap, textCoord).r); 
	NormalOut = normal;
	

#if defined(GLOW)
	GlowOut = vec4((texture2D(glowMap, textCoord).rgb*(1-heat)*0.75) + (diffuseColorOverHeatGlow.rgb * heat * 0.25) + glowColor, selected);
#else
	GlowOut = vec4((texture2D(glowMap, textCoord).rgb*(1-heat)*0.75) + (diffuseColorOverHeatGlow.rgb * heat * 0.25), selected);
#endif
}
