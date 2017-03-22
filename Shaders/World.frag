#version 150
uniform sampler2D myTexture0D;
uniform sampler2D myTexture1D;
uniform sampler2D myTexture2D;
uniform sampler2D myTexture3D;
uniform sampler2D myTexture4D;
uniform sampler2D myTextureGN;
uniform sampler2D myTextureGS;
uniform sampler2D myTextureLvl;
uniform sampler2DShadow shadowMap;

in vec2 outTextCord;
in vec3 outNormal;
in vec3 outTagent;
in vec3 outBinormal;
in vec4 outColor1;
in vec4 outColor2;
in vec3 outEye;
in vec3 outlightDir;

smooth in vec4 lightSpace_pos;

uniform vec4 coverColor;
uniform int numPointLight;
in vec4 outPLightDir[16];
uniform vec3 pointLightColor[16];
uniform vec3 lightDirColor;
uniform vec3 ambientColor;
out vec4 Frag_Color;

void getSampel( out vec4 sample )
{
	vec4 useColorLvl = vec4( 1.0, 0.0, 0.0, 0.0);
	sample = texture2D(myTexture0D, outTextCord) * useColorLvl.r
		+ texture2D(myTexture1D, outTextCord) * useColorLvl.g
		+ texture2D(myTexture2D, outTextCord) * useColorLvl.b
		+ texture2D(myTexture3D, outTextCord) * useColorLvl.a;
}

void getNormal( out vec3 normal )
{
	mat3 TBN = mat3( outTagent, outBinormal, outNormal );
	normal = normalize( TBN * (texture2D(myTextureGN, outTextCord).rgb * 2.0 - 1.0) );
}


void main()
{
	
	vec3 n;
	getNormal( n );
	float specularMap = texture2D(myTextureGS, outTextCord).x;
	
	float shadowFactor=1.0;
	if( lightSpace_pos.w > 0.0 )
		shadowFactor = textureProj( shadowMap, lightSpace_pos - vec4(0,0,0.0,0));

	float specular = 0.0;
	float diffuse = max( dot(normalize(outlightDir),n), 0.0 ) * 0.8f;
	vec3 halfVector = normalize( outEye + outlightDir );
	if (diffuse > 0.05)
		specular = pow( max( dot(n, halfVector), 0.0 ) * 0.99, 64.0);
	vec4 texColor;

	getSampel( texColor );
	texColor *= coverColor; 
	if( texColor.a < 0.9 )
		discard;
	texColor *= vec4( outColor.rgb, 1.0);
	float pDiffuse = 0.0;
	vec3 colorPointLight = vec3(0.0,0.0,0.0);
	for( int i=0; i<numPointLight; i++ ){
		float attenuation = max( 0.0, 1.0 - min( 1.0, dot( outPLightDir[i].xyz/outPLightDir[i].a, outPLightDir[i].xyz/outPLightDir[i].a ) ) );
		float pointFactor = max(dot(n,normalize(outPLightDir[i].xyz)),0.0) * attenuation;
		colorPointLight += texColor.rgb * pointLightColor[i] * pointFactor;
		if (pointFactor > 0.05){
			colorPointLight += specularMap * pow( max( dot(n, halfVector), 0.0 ) * 0.99, 64.0) * pointLightColor[i] * attenuation;
			halfVector = normalize( outEye + normalize(outPLightDir[i].xyz) );
		}
	}

	Frag_Color = vec4( texColor.rgb*ambientColor + texColor.rgb *specularMap * specular + texColor.rgb * diffuse * lightDirColor * shadowFactor + colorPointLight, texColor.a );
	
}
