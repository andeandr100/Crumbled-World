#version 330

uniform sampler2D myTextureLvl;//5
uniform sampler2D myTexture1D;//6
uniform sampler2D myTexture2D;
uniform sampler2D myTexture3D;
uniform sampler2D myTexture1N;//9
uniform sampler2D myTexture2N;
uniform sampler2D myTexture3N;
uniform sampler2D myTexture1S;//12
uniform sampler2D myTexture2S;
uniform sampler2D myTexture3S;


uniform vec3 lightDir;

in vec2 localTextureCord;
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

void getSampel( in vec3 useColorLvl, out vec4 sample )
{
	sample = texture2D(myTexture1D, localTextureCord) * useColorLvl.r
		+ texture2D(myTexture2D, localTextureCord) * useColorLvl.g
		+ texture2D(myTexture3D, localTextureCord) * useColorLvl.b;
}


void getNormal( in vec3 useColorLvl, out vec3 normal )
{
	mat3 TBN = mat3( outTagent, outBinormal, outNormal );
	normal = texture2D(myTexture1N, localTextureCord).rgb * useColorLvl.r
		+ texture2D(myTexture2N, localTextureCord).rgb * useColorLvl.g
		+ texture2D(myTexture3N, localTextureCord).rgb * useColorLvl.b;

	normal = normalize( TBN * (normalize(normal) - 0.5) );
}

void main()
{
	vec3 useColorLvl = texture2D( myTextureLvl, textCoord ).rgb;

	vec4 outColor;
	getSampel(useColorLvl, outColor);
	outColor.a = texture2D(myTexture1S, localTextureCord).r * 0.5;

	WorldPosOut = worldPos0; 
    DiffuseOut = outColor;
	getNormal( useColorLvl, NormalOut );
	
	GlowOut = vec4(0,0,0,selected);
}
