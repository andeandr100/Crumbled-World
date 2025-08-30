#version 330
uniform vec4 coverColor;

uniform sampler2D diffuseMap;
uniform sampler2D normalMap;
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
layout (location = 3) out vec4 GlowOut;

#if defined(SELECTED)
	const float selected = 1.0;
#else
	const float selected = 0.0;
#endif

void main()
{
    vec4 diffuseColor = texture(diffuseMap, textCoord);
    if( diffuseColor.a < 0.9 )
        discard;

    // Suggestion: To reduce texture fetches, which can be a performance bottleneck,
    // you could pack multiple maps into a single texture. For example, the single-channel
    // specular map and a single channel from the glow map could be stored in the R and G 
    // channels of a single texture. This would reduce the number of texture lookups.
    float specular = texture(specularMap, textCoord).r;
    vec3 glow = texture(glowMap, textCoord).rgb;

    // Unpack the normal from the normal map.
    vec3 tangentSpaceNormal = texture(normalMap, textCoord).rgb * 2.0 - 1.0;

    // Construct the TBN matrix and transform the normal to world space.
    mat3 TBN = mat3( outTagent, outBinormal, outNormal );
    vec3 WorldNormal = normalize( TBN * tangentSpaceNormal );

    WorldPosOut = worldPos0;
    DiffuseOut = vec4( diffuseColor.rgb*coverColor.rgb, specular);
    NormalOut = WorldNormal;
    GlowOut = vec4(glow, selected);
}