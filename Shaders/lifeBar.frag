#version 150
uniform sampler2D diffuseMap;

in vec4 spriteColor;
in vec2 tc;

out vec4 FragColor; 

void main( void )
{
	FragColor = spriteColor + texture2D(diffuseMap, tc);
}

