#version 330 core

uniform sampler2D gPosition;
uniform sampler2D gNormal;

uniform sampler2D diffuseMap;

uniform vec2 offset;
uniform vec3 camPos;

in vec2 TexCoords;

out vec4 FragColor;


vec2 offsetArray[8];

void main()
{             
	vec2 textCoord=TexCoords.xy;
	vec3 currentPos = texture2D(gPosition, textCoord).xyz;
 
	
	offsetArray[0] = vec2(offset.x, 0.0);
	offsetArray[1] = vec2(0.0, offset.y);
	offsetArray[2] = vec2(0.0, -offset.y);
	offsetArray[3] = vec2(-offset.x, 0.0);
	offsetArray[4] = vec2(offset.x, offset.y);
	offsetArray[5] = vec2(offset.x, -offset.y);
	offsetArray[6] = vec2(-offset.x, offset.y);
	offsetArray[7] = vec2(-offset.x, -offset.y);

     
	//depth
	float maxDiff = length(texture2D(gPosition, textCoord+offsetArray[0]).xyz - currentPos);
	maxDiff = max(maxDiff, length(texture2D(gPosition, textCoord+offsetArray[1]).xyz - currentPos));
	maxDiff = max(maxDiff, length(texture2D(gPosition, textCoord+offsetArray[2]).xyz - currentPos));
	maxDiff = max(maxDiff, length(texture2D(gPosition, textCoord+offsetArray[3]).xyz - currentPos));
	maxDiff = max(maxDiff, length(texture2D(gPosition, textCoord+offsetArray[4]).xyz - currentPos));
	maxDiff = max(maxDiff, length(texture2D(gPosition, textCoord+offsetArray[5]).xyz - currentPos));
	maxDiff = max(maxDiff, length(texture2D(gPosition, textCoord+offsetArray[6]).xyz - currentPos));
	maxDiff = max(maxDiff, length(texture2D(gPosition, textCoord+offsetArray[7]).xyz - currentPos));

 
	if(maxDiff>0.22) {
		vec3 color = texture2D(diffuseMap, textCoord).rgb;
		color += texture2D(diffuseMap, textCoord+offsetArray[0]).rgb;
		color += texture2D(diffuseMap, textCoord+offsetArray[1]).rgb;
		color += texture2D(diffuseMap, textCoord+offsetArray[2]).rgb;
		color += texture2D(diffuseMap, textCoord+offsetArray[3]).rgb;
		color += texture2D(diffuseMap, textCoord+offsetArray[4]).rgb;
		color += texture2D(diffuseMap, textCoord+offsetArray[5]).rgb;
		color += texture2D(diffuseMap, textCoord+offsetArray[6]).rgb;
		color += texture2D(diffuseMap, textCoord+offsetArray[7]).rgb;

		FragColor=vec4(color/8,1.0);
	}
	else {  
		FragColor=vec4(texture2D(diffuseMap, textCoord).rgb,1.0);
	}
}  

