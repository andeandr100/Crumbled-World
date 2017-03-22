#version 330 core

uniform mat4 projModelViewMat, modelMat;

in vec3 position;

	
//out vec3 worldPos0;

void main()
{

	//vec4 worldPos = modelMat * vec4( position, 1.0 );

    //worldPos0 = worldPos.xyz;

	//gl_Position = projModelViewMat * worldPos;

	gl_Position = vec4( position, 1.0 );
}
