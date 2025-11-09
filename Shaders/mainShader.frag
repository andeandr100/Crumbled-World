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
    float shadowFactor = 1.0;

#if defined(SOFT_SHADOW) || defined(SHADOW)
    // --- Shadow Bias: Tweak these values to fix shadow acne ---
    const float BIAS_CONSTANT = 0.001;
    const float BIAS_SLOPE = 0.007;
    // ---------------------------------------------------------

    vec4 lightSpace_pos = lighProjCamView * vec4(worlPos, 1.0);
    
    // Perform perspective divide manually
    vec3 projCoords = lightSpace_pos.xyz / lightSpace_pos.w;
    
    // Check if the fragment is within the light's frustum
    if (projCoords.z < 1.0) {
        // Calculate slope-scaled bias to prevent shadow acne
        float bias = max(BIAS_SLOPE * (1.0 - dot(normal, surfaceToLight)), BIAS_CONSTANT);
        
        // Apply bias to the shadow coordinate before comparison
        vec4 biasedLightSpacePos = lightSpace_pos;
        biasedLightSpacePos.z -= bias * biasedLightSpacePos.w;

#if defined(SOFT_SHADOW)
        shadowFactor = 0.0;
        vec2 texelSize = 1.0 / vec2(textureSize(shadowMap, 0));
        // Compute base shadow coordinate (with perspective divide)
        vec3 shadowCoord = biasedLightSpacePos.xyz / biasedLightSpacePos.w;
        
#if defined(SHADOW_HIGH)
        // 9-tap Poisson-like sampling for high quality soft shadows
        shadowFactor += texture(shadowMap, shadowCoord);
        shadowFactor += texture(shadowMap, shadowCoord + vec3(texelSize * vec2(-2,  2), 0.0));
        shadowFactor += texture(shadowMap, shadowCoord + vec3(texelSize * vec2( 2,  2), 0.0));
        shadowFactor += texture(shadowMap, shadowCoord + vec3(texelSize * vec2( 2, -2), 0.0));
        shadowFactor += texture(shadowMap, shadowCoord + vec3(texelSize * vec2(-2, -2), 0.0));
        shadowFactor += texture(shadowMap, shadowCoord + vec3(texelSize * vec2( 4,  0), 0.0));
        shadowFactor += texture(shadowMap, shadowCoord + vec3(texelSize * vec2(-4,  0), 0.0));
        shadowFactor += texture(shadowMap, shadowCoord + vec3(texelSize * vec2( 0,  4), 0.0));
        shadowFactor += texture(shadowMap, shadowCoord + vec3(texelSize * vec2( 0, -4), 0.0));
        shadowFactor *= 0.1111111; // 1.0 / 9
#elif defined(SHADOW_NORMAL)
        // 8-tap sampling for normal quality
        shadowFactor += texture(shadowMap, shadowCoord + vec3(texelSize * vec2(-1,  1), 0.0));
        shadowFactor += texture(shadowMap, shadowCoord + vec3(texelSize * vec2( 1,  1), 0.0));
        shadowFactor += texture(shadowMap, shadowCoord + vec3(texelSize * vec2( 1, -1), 0.0));
        shadowFactor += texture(shadowMap, shadowCoord + vec3(texelSize * vec2(-1, -1), 0.0));
        shadowFactor += texture(shadowMap, shadowCoord + vec3(texelSize * vec2( 2,  0), 0.0));
        shadowFactor += texture(shadowMap, shadowCoord + vec3(texelSize * vec2(-2,  0), 0.0));
        shadowFactor += texture(shadowMap, shadowCoord + vec3(texelSize * vec2( 0,  2), 0.0));
        shadowFactor += texture(shadowMap, shadowCoord + vec3(texelSize * vec2( 0, -2), 0.0));
        shadowFactor *= 0.125; // 1.0 / 8
#else // Low quality soft shadow
        // 5-tap sampling (center weighted)
        shadowFactor += texture(shadowMap, shadowCoord) * 2.0;
        shadowFactor += texture(shadowMap, shadowCoord + vec3(texelSize * vec2(-1,  1), 0.0));
        shadowFactor += texture(shadowMap, shadowCoord + vec3(texelSize * vec2( 1,  1), 0.0));
        shadowFactor += texture(shadowMap, shadowCoord + vec3(texelSize * vec2( 1, -1), 0.0));
        shadowFactor += texture(shadowMap, shadowCoord + vec3(texelSize * vec2(-1, -1), 0.0));
        shadowFactor *= 0.1666667; // 1.0 / 6
#endif
#else // Hard shadow
        shadowFactor = textureProj(shadowMap, biasedLightSpacePos);
#endif
    }
#endif
    //diffuse
    float diffuseCoefficient = max(0.0, dot(normal, surfaceToLight));
    vec3 diffuse = diffuseCoefficient * surfaceColor.rgb * lightDirColor;
    
    //specular
    float specularCoefficient = 0.0;
    if(diffuseCoefficient > 0.0) {
        // Simplified specular calculation, pow(x, 1) is just x
        specularCoefficient = max(0.0, dot(surfaceToCamera, reflect(-surfaceToLight, normal)));
    }
    vec3 specular = specularCoefficient * Specular * 0.2 * lightDirColor; // Specular should also be colored by light

    //linear color (color before gamma correction)
    vec3 ambient = surfaceColor.rgb * ambientColor;
#if defined(SOFT_SHADOW) || defined(SHADOW)
    return ambient + (diffuse + specular) * attenuation * shadowFactor;
#else
    return ambient + (diffuse + specular) * attenuation;
#endif
}

// a simple random generator (taken from a post on StackOverflow). co is seed. 
float rand(in vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}


// ...existing code...
//g_scale: scales distance between occluders and occludee.
//g_bias: controls the width of the occlusion cone considered by the occludee.
//g_sample_rad: the sampling radius.
//g_intensity: the ao intensity.

float doAmbientOcclusion(in vec2 tcoord, in vec2 uv, in vec3 p, in vec3 cnorm)
{
    const float scale = 0.4;
    const float bias = 0.05;
    const float intensity = 1.9;
    // Get neighbour pixel's position and calculate difference vector
    vec3 diff = texture(gPosition, tcoord + uv).rgb - p;
    vec3 v = normalize(diff);
    float d = length(diff) * scale;
    // Attenuate occlusion factor by distance
    return max(0.0, dot(cnorm, v) - bias) * (1.0 / (1.0 + d)) * intensity;
}

float ambientOcclusionSSAO()
{
    vec3 p = texture(gPosition, TexCoords).xyz;
    vec3 n = texture(gNormal, TexCoords).rgb;
    // Use a random vector from a texture instead of rand() function
    vec2 rnd = normalize(vec2(rand(p.xy), rand(n.xy)));

    float ao = 0.0f;
    // Calculate sampling radius based on depth
    float depth = length(p - camPos);
    float rad = 0.20 / depth;

    const vec2 vec[4] = vec2[](
        vec2(1.0, 0.0),
        vec2(-1.0, 0.0),
        vec2(0.0, 1.0),
        vec2(0.0, -1.0)
    );

    const int iterations = 4;
    for (int j = 0; j < iterations; ++j)
    {
      // Rotate sampling vector by random angle - faster than reflect()
      vec2 coord1 = vec2(dot(vec[j], rnd), dot(vec[j], vec2(-rnd.y, rnd.x))) * rad;
      vec2 coord2 = vec2(coord1.x - coord1.y, coord1.x + coord1.y) * 0.707; // Rotated by 45 degrees
      
      ao += doAmbientOcclusion(TexCoords, coord1 * 0.25, p, n);
      ao += doAmbientOcclusion(TexCoords, coord2 * 0.5, p, n);
      ao += doAmbientOcclusion(TexCoords, coord1 * 0.75, p, n);
      ao += doAmbientOcclusion(TexCoords, coord2, p, n);
    }
    const float numIteration = float(iterations) * 4.0;
  
    return 1.0 - ao / numIteration;
}

void main()
{
    vec3 FragPos = texture(gPosition, TexCoords).rgb;
    // Use dot product for squared length check to avoid sqrt
    if(dot(FragPos, FragPos) > 0.0001) // 0.01 * 0.01
    {
        vec3 Normal = texture(gNormal, TexCoords).rgb;
        // Single texture fetch for color and specular
        vec4 ColorAndSpecular = texture(gColor, TexCoords);
        vec3 Color = ColorAndSpecular.rgb;
        float Specular = ColorAndSpecular.a;

        vec3 linearColor = ApplyLight(FragPos, Color, Normal, Specular, normalize(camPos - FragPos));
#if defined(AMBIENT_OCCLUSION)
        float ao = ambientOcclusionSSAO();
        FragColor = vec4(linearColor * ao, 1.0);
#else
        FragColor = vec4(linearColor * 0.85, 1.0);
#endif
    }
    else {
        discard; // Discard fragment if it's part of the background
    }
}
