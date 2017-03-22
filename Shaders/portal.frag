#version 330
uniform vec4 coverColor;
uniform float time;

uniform sampler2D diffuseMap;

in vec2 textCoord; 
in vec4 outColor;

out vec4 FragColor;



void main()
{             
    // Retrieve data from G-buffer
    float color1 = texture(diffuseMap, textCoord - vec2(0,time*0.2)).r;
	FragColor = vec4( outColor.rgb * color1, outColor.a * color1 * 1.5);

}  

