#version 330
uniform sampler2D diffuseMap;

in vec2 textCoord; 
out vec4 FragColor;

void main()
{             
    // Retrieve data from G-buffer
    vec4 color = texture(diffuseMap, textCoord);
	
	if( color.a < 0.9 )
		discard;

	FragColor = vec4(0,0,0,1);
}  

