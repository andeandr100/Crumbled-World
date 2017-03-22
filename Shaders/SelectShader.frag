#version 330 core
precision mediump float;

uniform sampler2D gGlow;
uniform vec2 offset;

in vec2 v_texCoord;

out vec4 FragColor;

void main()
{   
	FragColor = vec4(0.0);
	if(texture2D(gGlow, v_texCoord).a < 0.1)
	{
		float value = texture2D(gGlow, v_texCoord + vec2(-offset.x*2,0)).a + texture2D(gGlow, v_texCoord + vec2(offset.x*2,0)).a + 
						texture2D(gGlow, v_texCoord + vec2(0,-offset.y*2)).a + texture2D(gGlow, v_texCoord + vec2(0,offset.y*2)).a;
		if( value > 0 ){
			FragColor = vec4(1.0,1.0,1.0,0.75);
		}
	}
}  
 



