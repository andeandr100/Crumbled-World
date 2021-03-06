#version 150

in vec4 pos[];
in vec3 lifeBarValues[];
in float value[];

layout (points) in;
layout (triangle_strip, max_vertices = 20) out;

out vec4 spriteColor;
out vec2 tc;
uniform mat4 projMat;

void main( void )
{

	const float h = 0.06;
	const float w = 0.4;

	//background
	spriteColor = vec4(0,0,0,1);
	tc = vec2(0,0);
	float xOffset = h * 0.2;
	if(value[0] != 1.0 || lifeBarValues[0].z > 0.5 )
	{
		xOffset += w;
		gl_Position = pos[0].xyzw+projMat*vec4(w,h,0.0,0.0);
		EmitVertex();

		gl_Position = pos[0].xyzw+projMat*vec4(w,-h,0.0,0.0);
		EmitVertex();

		gl_Position = pos[0].xyzw+projMat*vec4(-w,h,0.0,0.0);
		EmitVertex();

		gl_Position = pos[0].xyzw+projMat*vec4(-w,-h,0.0,0.0);
		EmitVertex();

		EndPrimitive();

		float life = min( 1.0, value[0]);
	



		const vec3 red = vec3(0.75, 0.1, 0.1);
		const vec3 orange = vec3(0.75, 0.75, 0.1);
		const vec3 green = vec3(0.1, 0.75, 0.1);

		vec3 color = green;
		if( life > 0.4 )
			color = mix(orange, green, clamp((life-0.4)/0.25, 0, 1));
		else
			color = mix(red, orange, clamp((life-0.15)/0.15, 0, 1));

		vec4 topColor = vec4(color,1);
		vec4 bottomColor = vec4(color * 0.15,1);

		const vec2 healthBarSize = vec2(w-h*0.3, h-h*0.3);
		float barSize = healthBarSize.x * 2 * life;


	
	


		//Health bar
		spriteColor = topColor;
		gl_Position = pos[0].xyzw+projMat*vec4(-healthBarSize.x + barSize,healthBarSize.y,0.0,0.0);
		EmitVertex();

		spriteColor = bottomColor;
		gl_Position = pos[0].xyzw+projMat*vec4(-healthBarSize.x + barSize,-healthBarSize.y,0.0,0.0);
		EmitVertex();

		spriteColor = topColor;
		gl_Position = pos[0].xyzw+projMat*vec4(-healthBarSize.x,healthBarSize.y,0.0,0.0);
		EmitVertex();

		spriteColor = bottomColor;
		gl_Position = pos[0].xyzw+projMat*vec4(-healthBarSize.x,-healthBarSize.y,0.0,0.0);
		EmitVertex();
		EndPrimitive();

		//Health bar background

		const vec4 hBgTopColor = vec4(0.2,0.2,0.2,1);
		const vec4 hBgBottomColor = vec4(0.05,0.05,0.05,1);

		spriteColor = hBgTopColor;
		gl_Position = pos[0].xyzw+projMat*vec4(healthBarSize.x,healthBarSize.y,0.0,0.0);
		EmitVertex();

		spriteColor = hBgBottomColor;
		gl_Position = pos[0].xyzw+projMat*vec4(healthBarSize.x,-healthBarSize.y,0.0,0.0);
		EmitVertex();

		spriteColor = hBgTopColor;
		gl_Position = pos[0].xyzw+projMat*vec4(-healthBarSize.x + barSize,healthBarSize.y,0.0,0.0);
		EmitVertex();

		spriteColor = hBgBottomColor;
		gl_Position = pos[0].xyzw+projMat*vec4(-healthBarSize.x + barSize,-healthBarSize.y,0.0,0.0);
		EmitVertex();

		EndPrimitive();


		if( value[0] > 1.0 )
		{
			float extraLife = value[0] - 1.0;
			barSize = healthBarSize.x * 2.0 * extraLife;

			const vec4 ExtraTopColor = vec4(0.6,0.68,0.6,1);
			const vec4 ExtraBottomColor = vec4(0.1,0.1,0.1,1);

			spriteColor = ExtraTopColor;
			gl_Position = pos[0].xyzw+projMat*vec4(-healthBarSize.x + clamp(barSize - h*2.0,0,healthBarSize.x*2),healthBarSize.y,0.0,0.0);
			EmitVertex();

			spriteColor = ExtraBottomColor;
			gl_Position = pos[0].xyzw+projMat*vec4(-healthBarSize.x + clamp(barSize,0,healthBarSize.x*2),-healthBarSize.y,0.0,0.0);
			EmitVertex();

			spriteColor = ExtraTopColor;
			gl_Position = pos[0].xyzw+projMat*vec4(-healthBarSize.x,healthBarSize.y,0.0,0.0);
			EmitVertex();

			spriteColor = ExtraBottomColor;
			gl_Position = pos[0].xyzw+projMat*vec4(-healthBarSize.x,-healthBarSize.y,0.0,0.0);
			EmitVertex();

			EndPrimitive();
		}
	}else{
		xOffset = -h * 2.0;
	}
	if(lifeBarValues[0].x > 0.5)
	{
		//background
		spriteColor = vec4(0,0,0,0);
		
		tc = vec2(0.625,0.0625);
		gl_Position = pos[0].xyzw+projMat*vec4(xOffset + h*4.0,h * 2.0,0.0,0.0);
		EmitVertex();

		tc = vec2(0.625,0);
		gl_Position = pos[0].xyzw+projMat*vec4(xOffset + h*4.0,-h * 2.0,0.0,0.0);
		EmitVertex();

		tc = vec2(0.5,0.0625);
		gl_Position = pos[0].xyzw+projMat*vec4(xOffset,h * 2.0,0.0,0.0);
		EmitVertex();

		tc = vec2(0.5,0);
		gl_Position = pos[0].xyzw+projMat*vec4(xOffset,-h * 2.0,0.0,0.0);
		EmitVertex();

		EndPrimitive();
	}
	else if(lifeBarValues[0].y > 0.5)
	{
		//background
		spriteColor = vec4(0,0,0,0);

		tc = vec2(0.75,0.5);
		gl_Position = pos[0].xyzw+projMat*vec4(xOffset + h*4.0,h * 2.0,0.0,0.0);
		EmitVertex();

		tc = vec2(0.75,0.4375);
		gl_Position = pos[0].xyzw+projMat*vec4(xOffset + h*4.0,-h * 2.0,0.0,0.0);
		EmitVertex();

		tc = vec2(0.625,0.5);
		gl_Position = pos[0].xyzw+projMat*vec4(xOffset,h * 2.0,0.0,0.0);
		EmitVertex();

		tc = vec2(0.625,0.4375);
		gl_Position = pos[0].xyzw+projMat*vec4(xOffset,-h * 2.0,0.0,0.0);
		EmitVertex();

		EndPrimitive();
	}
}
