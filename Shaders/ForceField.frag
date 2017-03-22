#version 330 core

uniform sampler2D gPosition;
uniform sampler2D glowMap;
uniform float time;
uniform vec2 ScreenSize;
uniform vec3 camPos;
uniform vec3 positions[20];
uniform float spawnTime[20];
uniform float lifeTime[20];
uniform int numHit;

in vec2 textCoord; 
in vec3 worldPos0; 
in vec3 localPosition;
in vec3 outNormal;
in vec4 outColor;
//in vec3 pulsePos;

out vec4 FragColor;

void main()
{           
	vec2 screenCoord = gl_FragCoord.xy / ScreenSize;
	vec3 FragPos = texture(gPosition, screenCoord).rgb;

	vec3 viewDir  = normalize(camPos - FragPos);
	float viewAlpha = max(0,1-abs(dot(viewDir, normalize(outNormal)))-0.5)*2;

	vec4 d1 = texture2D(glowMap, vec2(textCoord.x*3+time*0.05, textCoord.y*2+time*0.2));
	vec4 d2 = texture2D(glowMap, vec2(textCoord.y*2+time*0.05, textCoord.x*2+time*0.2));

	float alpha = min(1,length(FragPos-worldPos0)*0.5);
	float alpha2 = min(0.4,length(FragPos-worldPos0)*0.2);

	float textureAlpha = (d1.a + d2.a)*min(textCoord.y*3,1);
	vec3 textureColor = vec3(max(d1.r,d2.r), max(d1.g,d2.g), max(d1.b,d2.b)) * vec3(0.3,0.5,1.0) * textureAlpha;
	vec3 blueColor = vec3(0,0,1)*alpha2;

	float colorDist = 0.0;
	for(int i=0; i<numHit; i++){
		float currentTime = (time - spawnTime[i]);
		float fadeOutTime = lifeTime[i] * 0.5;
		
		colorDist += min(abs(length(localPosition-positions[i])-currentTime)-0.05,0)*-20.0 * (1.0 - max(currentTime+fadeOutTime-lifeTime[i],0.0)*(1.0/fadeOutTime));
	}
	colorDist = min(colorDist, 1.0);

	
	textureAlpha = textureAlpha * 0.5;
	float totalAlpha = textureAlpha + viewAlpha + alpha2;
	float maxAlpha = max(textureAlpha, max(viewAlpha, alpha2));
	FragColor = vec4( textureColor*(textureAlpha/totalAlpha), maxAlpha*alpha*0.5 );
	FragColor.rgb += vec3(0,0,1)*(alpha2/totalAlpha);
    FragColor.rgb += vec3(0.7,0.7,1)*(viewAlpha/totalAlpha);
	FragColor += vec4( 0.6,0.6,0.9,1.0) * colorDist;
	FragColor *= outColor;
}

