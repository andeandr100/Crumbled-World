#version 330 core

in vec2 TexCoords;

uniform sampler2D gPosition;
uniform sampler2D gNormal;
uniform sampler2D gColor;
uniform sampler2D gGlow;
uniform sampler2D gRandNormal;
uniform sampler2DShadow shadowMap;

uniform mat4 lighProjCamView;

uniform vec3 camPos;
uniform vec3 lightDir;
uniform vec3 lightDirColor;
uniform vec3 ambientColor;

out vec4 FragColor;

vec3 ApplyLight( in vec3 worlPos, in vec3 surfaceColor, in vec3 normal, in float Specular, in vec3 surfaceToCamera) {
    vec3 surfaceToLight = lightDir;
    const float attenuation = 1.0;

	//Shadow
#if defined(SOFT_SHADOW) || defined(SHADOW)
	const float bias = 0.002;
	float shadowFactor = 1.0;
	vec4 lightSpace_pos = lighProjCamView * vec4(worlPos,1);
	vec4 lightPos = lightSpace_pos-vec4(0,0,bias,0);

	if( lightSpace_pos.w > 0.0 ){
#if defined(SOFT_SHADOW)

#if defined(SHADOW_HIGH)

		shadowFactor = textureProjOffset(shadowMap, lightPos, ivec2(0, 0));
		shadowFactor += textureProjOffset(shadowMap, lightPos, ivec2(-2, 2));
        shadowFactor += textureProjOffset(shadowMap, lightPos, ivec2(2, 2));
        shadowFactor += textureProjOffset(shadowMap, lightPos, ivec2(2, -2));
        shadowFactor += textureProjOffset(shadowMap, lightPos, ivec2(-2, -2));
		shadowFactor += textureProjOffset(shadowMap, lightPos, ivec2(4, 0));
        shadowFactor += textureProjOffset(shadowMap, lightPos, ivec2(-4, 0));
        shadowFactor += textureProjOffset(shadowMap, lightPos, ivec2(0, 4));
        shadowFactor += textureProjOffset(shadowMap, lightPos, ivec2(0, -4));
		shadowFactor *= 0.1111111;
#else
	#if defined(SHADOW_NORMAL)
		shadowFactor = textureProjOffset(shadowMap, lightPos, ivec2(-1, 1));
        shadowFactor += textureProjOffset(shadowMap, lightPos, ivec2(1, 1));
        shadowFactor += textureProjOffset(shadowMap, lightPos, ivec2(1, -1));
        shadowFactor += textureProjOffset(shadowMap, lightPos, ivec2(-1, -1));
		shadowFactor += textureProjOffset(shadowMap, lightPos, ivec2(2, 0));
        shadowFactor += textureProjOffset(shadowMap, lightPos, ivec2(-2, 0));
        shadowFactor += textureProjOffset(shadowMap, lightPos, ivec2(0, 2));
        shadowFactor += textureProjOffset(shadowMap, lightPos, ivec2(0, -2));
		shadowFactor *= 0.125;
	#else
		shadowFactor = textureProjOffset(shadowMap, lightPos, ivec2(0, 0))*2.0;
		shadowFactor += textureProjOffset(shadowMap, lightPos, ivec2(-1, 1));
        shadowFactor += textureProjOffset(shadowMap, lightPos, ivec2(1, 1));
        shadowFactor += textureProjOffset(shadowMap, lightPos, ivec2(1, -1));
        shadowFactor += textureProjOffset(shadowMap, lightPos, ivec2(-1, -1));
		shadowFactor *= 0.1666667;
	#endif
#endif
#else
		shadowFactor = textureProjOffset(shadowMap, lightPos, ivec2(0, 0));
#endif
	}
#endif
    //diffuse
    float diffuseCoefficient = max(0.0, dot(normal, surfaceToLight));
    vec3 diffuse = diffuseCoefficient * surfaceColor.rgb * lightDirColor;
    
    //specular
    float specularCoefficient = 0.0;
    if(diffuseCoefficient > 0.0)
        specularCoefficient = pow(max(0.0, dot(surfaceToCamera, reflect(-surfaceToLight, normal))), 1);
    float specular = specularCoefficient * Specular * 0.2;

    //linear color (color before gamma correction)
#if defined(SOFT_SHADOW) || defined(SHADOW)
    return (surfaceColor.rgb * ambientColor) + attenuation*(diffuse + specular) * shadowFactor;
#else
	return (surfaceColor.rgb * ambientColor) + attenuation*(diffuse + specular);
#endif
}

// a simple random generator (taken from a post on StackOverflow). co is seed. 
float rand(in vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

//g_scale: scales distance between occluders and occludee.
//g_bias: controls the width of the occlusion cone considered by the occludee.
//g_sample_rad: the sampling radius.
//g_intensity: the ao intensity.

float doAmbientOcclusion(in vec2 tcoord, in vec2 uv, in vec3 p, in vec3 cnorm)
{
    const float scale = 0.4;
	const float bias = 0.05;
	const float intensity = 1.9; 
    vec3 diff = texture(gPosition, tcoord + uv).rgb - p;
    vec3 v = normalize(diff);
    float d = length(diff) * scale;
    return max(0.0,dot(cnorm,v)-bias)*(1.0/(1.0+d))* intensity;
}

float ambientOcclusionSSAO(){
    vec2 texCoord = TexCoords; 
    vec3 p = texture(gPosition, texCoord.xy).xyz;
    vec3 n = texture(gNormal, texCoord.xy).xyz;
    vec2 rnd = normalize(vec2(rand(p.xy), rand(n.xy)));

    float ao = 0.0f;
	float depth = length(p-camPos);
    float rad = 0.20/depth;
    const vec2 vec[4] = vec2[4](
		vec2(1.0,0.0), 
		vec2(-1.0,0.0), 
		vec2(0.0,1.0), 
		vec2(0.0,-1.0)
	);

    const int iterations = 4;
    for (int j = 0; j < iterations; ++j)
    {
      vec2 coord1 = reflect(vec[j],rnd)*rad;
      vec2 coord2 = vec2(coord1.x - coord1.y, coord1.x + coord1.y) *0.707;
      
      ao += doAmbientOcclusion(texCoord.xy,coord1*0.25, p, n);
      ao += doAmbientOcclusion(texCoord.xy,coord2*0.5, p, n);
      ao += doAmbientOcclusion(texCoord.xy,coord1*0.75, p, n);
      ao += doAmbientOcclusion(texCoord.xy,coord2, p, n);
    }
	const float numIteration = float(iterations)*4.0;
  
    return 1.0 - ao / numIteration; 
}

void main()
{             
    // Retrieve data from G-buffer
   
	/*if(TexCoords.y < 0.5)
	{
		if( TexCoords.x < 0.5)
		{
			FragColor = vec4(texture(gColor, TexCoords * 2).rgb, 1.0);
		}
		else
		{
			FragColor = vec4(texture(gNormal, (TexCoords-vec2(0.5,0)) * 2).rgb, 1.0);
		}
	}else{
		if( TexCoords.x < 0.5)
		{
			FragColor = vec4(texture(gGlow, (TexCoords-vec2(0,0.5)) * 2).rgb, 1.0);
		}
		else
		{
			FragColor = vec4(texture(gPosition, (TexCoords-vec2(0.5,0.5)) * 2).rgb, 1.0);
		}		
	}*/

	vec3 FragPos = texture(gPosition, TexCoords).rgb;
	if(length(FragPos) > 0.01)
	{
		vec3 Normal = texture(gNormal, TexCoords).rgb;
		vec3 Color = texture(gColor, TexCoords).rgb;
		float Specular = texture(gColor, TexCoords).a;

		vec3 linearColor = ApplyLight(FragPos, Color, Normal, Specular, normalize(camPos-FragPos));
#if defined(AMBIENT_OCCLUSION)
		float ao = ambientOcclusionSSAO();
		FragColor = vec4(linearColor * ao, 1.0);
#else
		FragColor = vec4(linearColor * 0.85, 1.0);
#endif

	}
	else{
		FragColor = vec4(0,0,0,0);
	}
	
}  





