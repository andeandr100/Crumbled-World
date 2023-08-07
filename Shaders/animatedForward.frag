#version 330
uniform vec4 coverColor;

uniform sampler2D normalMap;
uniform sampler2D diffuseMap;
uniform sampler2D specularMap;
uniform sampler2DShadow shadowMap;

uniform mat4 lighProjCamView;
uniform vec3 camPos;
uniform vec3 lightDir;
uniform vec3 lightDirColor;
uniform vec3 ambientColor;

in vec2 textCoord; 
in vec3 worldPos0; 

in vec3 outNormal;
in vec3 outTagent;
in vec3 outBinormal;

out vec4 FragColor;


vec3 ApplyLight( vec3 worlPos, vec3 surfaceColor, vec3 normal, float Specular, vec3 surfaceToCamera) {
    vec3 surfaceToLight = lightDir;
    float attenuation = 1.0;

	vec3 ambient = surfaceColor.rgb * ambientColor;

	//Shadow
	float bias = 0.001;
	float shadowFactor=1.0;
	vec4 lightSpace_pos = lighProjCamView * vec4(worlPos,1);
	vec4 lightPos = lightSpace_pos-vec4(0,0,bias,0);
	if( lightSpace_pos.w > 0.0 ){

		shadowFactor += textureProjOffset(shadowMap, lightPos, ivec2(-1, 1));
        shadowFactor += textureProjOffset(shadowMap, lightPos, ivec2(1, 1));
        shadowFactor += textureProjOffset(shadowMap, lightPos, ivec2(1, -1));
        shadowFactor += textureProjOffset(shadowMap, lightPos, ivec2(-1, -1));

		shadowFactor *= 0.25f;
	}
    //diffuse
    float diffuseCoefficient = max(0.0, dot(normal, surfaceToLight));
    vec3 diffuse = diffuseCoefficient * surfaceColor.rgb * lightDirColor;
    
    //specular
    float specularCoefficient = 0.0;
    if(diffuseCoefficient > 0.0)
        specularCoefficient = pow(max(0.0, dot(surfaceToCamera, reflect(-surfaceToLight, normal))), 1);
    float specular = specularCoefficient * Specular * 0.2;

    //linear color (color before gamma correction)
    return ambient + attenuation*(diffuse + specular) * shadowFactor;
}

// a simple random generator (taken from a post on StackOverflow). co is seed. 
float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void main()
{             
    // Retrieve data from G-buffer
    vec4 color = texture(diffuseMap, textCoord) * coverColor;
	mat3 TBN = mat3( outTagent, outBinormal, outNormal );
    vec3 Normal = normalize( TBN * (texture2D(normalMap, textCoord).rgb * 2.0 - 1.0) );
	float Specular = texture2D(specularMap, textCoord).g;

	if( color.a < 0.9*coverColor.a )
		discard;

	vec3 linearColor = ApplyLight(worldPos0, color.rgb, Normal, Specular, normalize(camPos-worldPos0));

	FragColor = vec4(linearColor, color.a);
}  

