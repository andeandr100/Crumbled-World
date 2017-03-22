#version 150

uniform sampler2D diffuseMap;

in vec4 SpriteColor;
in vec2 tc;

out vec4 FragColor;

void main( void )
{
   FragColor = texture2D(diffuseMap, tc) * SpriteColor;
}

