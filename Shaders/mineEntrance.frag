#version 330 core

uniform sampler2D gPosition;
uniform vec2 ScreenSize;

in vec3 worldPos0; 

out vec4 FragColor;

void main()
{           
	vec2 screenCoord = gl_FragCoord.xy / ScreenSize;
	vec3 FragPos = texture(gPosition, screenCoord).rgb;

	float alpha = min(1,length(FragPos-worldPos0)*0.5);

	FragColor = vec4(0,0,0,alpha);
}

