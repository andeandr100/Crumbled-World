#version 330 core
in vec2 TexCoords;

uniform sampler2D diffuseMap;
uniform sampler2D gGlow;

out vec4 FragColor;

void main()
{             
	FragColor = texture(diffuseMap, TexCoords);
	float grayColor = (FragColor.x * 0.299 + FragColor.y*0.587 + FragColor.z*0.114);
	FragColor = vec4(grayColor,grayColor,grayColor,1.0);

	if( dot(FragColor,FragColor) < 1.005 )
		discard;
}  





