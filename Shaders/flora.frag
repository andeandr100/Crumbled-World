#version 150

uniform sampler2D diffuseMap;
uniform sampler2D normalMap;
uniform sampler2D specularMap;
uniform sampler2DShadow shadowMap;

in vec3 outNormal;
in vec3 outTagent;
in vec3 outBinormal;

smooth in vec4 lightSpace_pos;

in vec2 TextCord;
in vec3 lDir;
in vec3 outEye;
in vec3 outColor;
uniform int numPointLight;
in vec4 outPLightDir[6];
uniform vec3 pointLightColor[6];
uniform vec3 lightDirColor;
uniform vec3 ambientColor;

out vec4 Frag_Color;
void main()
{
	vec4 texColor = texture2D(diffuseMap, TextCord) * vec4( outColor, 1.0 );
	if( texColor.a < 0.9 )
		discard;
	vec4 SpectularColor = texture2D(specularMap, TextCord);

	float bias = 0.005;
	float shadowFactor=1.0;
	vec4 lightPos = lightSpace_pos-vec4(0,0,bias,0);
	if( lightSpace_pos.w > 0.0 )
		shadowFactor = textureProj( shadowMap, lightPos );

	mat3 TBN = mat3( normalize(outTagent), normalize(outBinormal), normalize(outNormal) );
	float factor;
	vec3 n = normalize( TBN * (texture2D(normalMap, TextCord).rgb * 2.0 - 1.0) );
	factor = max( dot( normalize(lDir), n ), 0.0 );

	vec3 halfVector = normalize( outEye + lDir );
	float specularLightDir = 0.0;
	if (factor > 0.05)
		specularLightDir = pow( max( dot(n, halfVector), 0.0 ) * 0.99, 64.0);


	vec3 colorPointLight = vec3(0.0,0.0,0.0);
	for( int i=0; i<numPointLight; i++ ){
		float attenuation = max( 0.0, 1.0 - min( 1.0, dot( outPLightDir[i].xyz/outPLightDir[i].a, outPLightDir[i].xyz/outPLightDir[i].a ) ) );
		//float pointFactor = max(dot(n,normalize(outPLightDir[i].xyz)),0.0) * attenuation;
		colorPointLight += texColor.rgb * pointLightColor[i] * attenuation;
		
		colorPointLight += SpectularColor.rgb * pow( max( dot(n, halfVector), 0.0 ) * 0.99, 64.0) * pointLightColor[i] * attenuation;
		halfVector = normalize( outEye + normalize(outPLightDir[i].xyz) );		
	}
	
	Frag_Color = vec4( ( texColor.rgb*ambientColor + SpectularColor.rgb * specularLightDir * lightDirColor * shadowFactor + (0.5f+factor*0.3f) * shadowFactor * texColor.rgb * lightDirColor ) + colorPointLight, texColor.a );
}
