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

	vec2 uvCoord = vec2(FragPos.x - CenterPosition.x, FragPos.z - CenterPosition.z) * 0.333;
	float alphaColor = texture(diffuseMap, uvCoord).r;

	float yValue = (0.2-min(0.2,abs(FragPos.y-CenterPosition.y)))/0.2;
	

	float distance = length(CenterPosition-FragPos);
	float alpha = 0;

	if( distance < Radius ){
		if(sin(-time*5+distance*9) > 0.92){
			alpha = max(0,(Radius-distance)/Radius) * 1.0 * (0.4+alphaColor*0.6);
		}
	}

	Frag_Color = vec4(effectColor,alpha * yValue);
}
