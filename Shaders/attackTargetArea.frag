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

	//Vec2 uvCoord = (FragPos - CenterPosition).xz;
	//vec4 textureColor = texture(diffuseMap, uvCoord);

	float yValue = (0.2-min(0.2,abs(FragPos.y-CenterPosition.y)))/0.2;
	

	float distance = length(CenterPosition-FragPos);
	float alpha = 0;

	if( distance < Radius ){
		alpha = max(0,(Radius-distance)/Radius) * ( 0.7 - sin(-time*5+distance*9)*0.35) * alphaColor;// * textureColor.a * 0.5;
	}

	Frag_Color = vec4(effectColor,alpha * yValue);
}
