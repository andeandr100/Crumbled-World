#version 330
uniform sampler2D diffuseMap;

in vec2 textCoord;
in vec3 worldPos0; 

uniform vec3 portalPosition;
uniform vec3 portalAtVec;

 
out vec4 FragColor;

void main()
{             
    // Retrieve data from G-buffer
    vec4 color = texture(diffuseMap, textCoord);
	
	float alphaValue = floor(dot(portalAtVec, normalize(worldPos0.xyz-portalPosition))+1.0);

	if( color.a * alphaValue< 0.9 )
		discard;

	FragColor = vec4(0,0,0,1);
}  

