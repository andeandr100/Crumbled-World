#version 330 core

uniform sampler2D gPosition;
uniform sampler2D gNormal;
uniform sampler2D gColor;

uniform vec2 ScreenSize;
uniform vec3 camPos;
uniform vec3 LightPos;
uniform vec3 LightColor;
uniform float LightQuadratic;
uniform float LightLinear;
uniform float LightRadius;
uniform float LightIntensity;
uniform float CutOfLumen;

out vec4 FragColor;

void main()
{           
	vec2 texcoord = gl_FragCoord.xy / ScreenSize;
  
    // Retrieve data from gbuffer
    vec3 FragPos = texture(gPosition, texcoord).rgb;
    vec3 Normal = texture(gNormal, texcoord).rgb;
    vec3 Diffuse = texture(gColor, texcoord).rgb;
    float Specular = texture(gColor, texcoord).a;
    
    // Then calculate lighting as usual
    vec3 viewDir  = normalize(camPos - FragPos);

    // Calculate distance between light source and current fragment
    float distance = length(LightPos - FragPos);
    //if(distance < LightRadius)
    //{
        // Diffuse
        vec3 lightDir = normalize(LightPos - FragPos);
        vec3 diffuse = max(dot(Normal, lightDir), 0.17) * Diffuse * LightColor;
        
		// Specular
        vec3 halfwayDir = normalize(lightDir + viewDir);  
        float spec = pow(max(dot(Normal, halfwayDir), 0.0), 16.0);
        vec3 specular = LightColor * spec * Specular;
        
		// Attenuation
        float attenuation = (LightIntensity / (1.0 + LightLinear * distance + LightQuadratic * distance * distance))-CutOfLumen;
        diffuse *= attenuation;
        specular *= attenuation;
        FragColor = vec4((diffuse + specular),1);
    //}
}
