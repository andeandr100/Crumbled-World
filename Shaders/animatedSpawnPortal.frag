#version 330
uniform vec4 coverColor;

uniform sampler2D normalMap;
uniform sampler2D diffuseMap;
uniform sampler2D specularMap;
uniform sampler2D glowMap;


uniform vec3 portalPosition;
uniform vec3 portalAtVec;
uniform vec3 portalColor;

in vec2 textCoord; 
in vec3 worldPos0; 

in vec3 outNormal;
in vec3 outTagent;
in vec3 outBinormal;
in vec4 outColor;

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
	
	float alphaValue = floor(dot(portalAtVec, normalize(worldPos0.xyz-portalPosition))+1.2);
	
	vec4 diffuseColor = texture2D(diffuseMap, textCoord);
	if( diffuseColor.a * alphaValue < 0.9 )
		discard;



	const vec3 v = vec3(0,1,0);
	vec3 collPos = portalPosition + (v * (dot((worldPos0 - portalPosition), v) / dot(v, v)));
	float len = clamp(length(collPos - worldPos0),0,1);




	mat3 TBN = mat3( outTagent, outBinormal, outNormal );
	vec3 normal = normalize( TBN * (texture2D(normalMap, textCoord).rgb * 2.0 - 1.0) );

	WorldPosOut = worldPos0;
	DiffuseOut = vec4(diffuseColor.rgb * coverColor.rgb * outColor.rgb * len + portalColor * (1-len), texture2D(specularMap, textCoord).r);
	NormalOut = normal;
	GlowOut = vec4(texture2D(glowMap, textCoord).rgb,selected);
}
