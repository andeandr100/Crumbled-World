#version 330 core

uniform sampler2D diffuseMap;
uniform sampler2D gPosition;
uniform vec3 effectColor;
uniform vec2 ScreenSize;
uniform vec3 CenterPosition;
uniform float Radius;
uniform float time;


out vec4 Frag_Color;


void main()
{
	
	vec2 screenCoord = gl_FragCoord.xy / ScreenSize;
	vec3 FragPos = texture(gPosition, screenCoord).rgb;

	vec2 uvCoord = vec2(FragPos.x - CenterPosition.x, FragPos.z - CenterPosition.z) * 0.5;
	float alphaColor = texture(diffuseMap, uvCoord).r;

	//vec2 uvCoord1 = vec2(FragPos.x - CenterPosition.x, FragPos.z - CenterPosition.z) + vec2(time, time) * 0.3;
	//vec2 uvCoord2 = vec2(FragPos.x - CenterPosition.x, FragPos.z - CenterPosition.z) + vec2(time, -time) * 0.3;
	//float alphaColor = ( texture(diffuseMap, uvCoord1).r + texture(diffuseMap, uvCoord2).r ) * 0.5;

	float yValue = (0.2-min(0.2,abs(FragPos.y-CenterPosition.y)))/0.2;
	

	float distance = length(CenterPosition-FragPos);
	float alpha = 0;


	float alphaBasedOnDistanceToEdge = ((Radius*0.5) - min((Radius*0.5),abs( Radius - distance) ) ) / (Radius*0.5) * 0.5 + 0.15;
	alpha = alphaBasedOnDistanceToEdge * ( 1 - sin(time*4+distance*9)*0.35) * alphaColor;

	if( distance > Radius ){
		//alpha = (0.05 - min(0.05,abs( Radius - distance) ) ) * 22.0;

		float distToRadius = distance - Radius;
		alpha = alpha * max(0, 1 - (distToRadius / 0.3)  );
	}

	Frag_Color = vec4(effectColor,alpha * yValue);
}
