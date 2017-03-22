#version 330 core

uniform sampler2D gPosition;
uniform vec4 coverColor;
uniform vec2 ScreenSize;
uniform vec3 CenterPosition;
uniform float Radius;
uniform int	NumExtraRange;
uniform float ExtraRange[3];
uniform vec4 ExtraRangeColor[3];

uniform vec3 LineStart;
uniform vec3 LineEnd;

uniform vec3 AtVec;
uniform float Angle;
uniform vec3 AtVecLeft;
uniform vec3 AtVecRight;


//in vec3 worldPos0; 

out vec4 Frag_Color;

float lineSegmentPointLength(in vec3 start, in vec3 end, in vec3 P1){
	vec3 v = end - start;
	vec3 addDir = (v * (dot((P1 - start), v) / dot(v,v)));
	vec3 CollPos = start + addDir;

	vec3 Center = start + v * 0.5f;
	if ( dot(Center - start,Center - start) < dot(Center - CollPos,Center - CollPos)){
		CollPos = (dot(v, addDir) > 0) ? end : start;
	}
	return length(CollPos - P1);
}

void main()
{
	vec2 screenCoord = gl_FragCoord.xy / ScreenSize;
	vec3 FragPos = texture(gPosition, screenCoord).rgb;


	float yValue = (0.2-min(0.2,abs(FragPos.y-CenterPosition.y)))/0.2;
	
#if defined(SPHERE)
	float distance = length(CenterPosition-FragPos);
#endif
#if defined(LINE)
	float distance = lineSegmentPointLength(LineStart, LineEnd, FragPos);
#endif
	float alpha = 0;
	vec3 color = vec3(0.2,1,0.2);

	if( distance < Radius ){
		alpha = ((Radius*0.5) - min((Radius*0.5),abs( Radius - distance) ) ) / (Radius*0.5) * 0.2;
	}else{
		alpha = (0.05 - min(0.05,abs( Radius - distance) ) ) * 22.0;

		float currentRange = Radius;
		for( int i=0; i<NumExtraRange; i++ ){
			float addRange = ExtraRange[i];
			currentRange += addRange;

			float curentAlpha = 0.0;
			if( distance < currentRange ){
				curentAlpha = (addRange - min((addRange), abs( currentRange - distance) ) ) / (addRange) * 0.2 * ExtraRangeColor[i].a;
			}else{
				curentAlpha = (0.05 - min(0.05, abs( currentRange - distance) ) ) * 22 * ExtraRangeColor[i].a;
			}
			
			if(curentAlpha >= alpha){
				color = ExtraRangeColor[i].rgb;
				alpha = max(alpha, curentAlpha);
			}
			
		}
	}

	

#if defined(CONE)
	float pointAngle = acos( dot(AtVec, normalize(FragPos - CenterPosition)) ); 
	
	float lineDist1 = lineSegmentPointLength(CenterPosition, AtVecLeft, FragPos);
	float lineDist2 = lineSegmentPointLength(CenterPosition, AtVecRight, FragPos);
	
#ifdef NOANGLERESTRICTION
	if(distance < Radius){
		alpha = max(alpha, max( max(0,(1-lineDist1)), max(0,(1-lineDist2)) ) * 0.2 );
	}
	alpha = max(alpha, (0.05-min(min(lineDist1,lineDist2),0.05))/0.05);
#else
	if( pointAngle > Angle ){
		alpha = 0;
	}else if(distance < Radius){
		alpha = max(alpha, max( max(0,(1-lineDist1)), max(0,(1-lineDist2)) ) * 0.2 );
	}
	alpha = max(alpha, (0.05-min(min(lineDist1,lineDist2),0.05))/0.05);
#endif 
	


	
	float currentRange = Radius;
	vec3 leftVec = normalize(AtVecLeft-CenterPosition);
	vec3 rightVec = normalize(AtVecRight-CenterPosition);
	for( int i=0; i<NumExtraRange; i++ ){
		float addRange = ExtraRange[i];
		currentRange += addRange;
			
		if( distance > (currentRange-addRange) ){
#ifdef NOANGLERESTRICTION
			if(distance < currentRange ){
#else
			if(distance < currentRange && pointAngle <= Angle){
#endif
				lineDist1 = lineSegmentPointLength(CenterPosition + leftVec * (currentRange-addRange), CenterPosition + leftVec * currentRange, FragPos);
				lineDist2 = lineSegmentPointLength(CenterPosition + rightVec * (currentRange-addRange), CenterPosition + rightVec * currentRange, FragPos);
				float curentAlpha = max( max(0,(1-lineDist1)), max(0,(1-lineDist2)) ) * 0.2 * ExtraRangeColor[i].a;

				if(curentAlpha >= alpha){
					color = ExtraRangeColor[i].rgb;
					alpha = max(alpha, curentAlpha);
				}
			}

			float curentAlpha;

			lineDist1 = lineSegmentPointLength(CenterPosition + leftVec * (currentRange-addRange), CenterPosition + leftVec * currentRange, FragPos);
			lineDist2 = lineSegmentPointLength(CenterPosition + rightVec * (currentRange-addRange), CenterPosition + rightVec * currentRange, FragPos);
			curentAlpha = (0.05-min(min(lineDist1,lineDist2),0.05))/0.05* ExtraRangeColor[i].a;

			if(curentAlpha >= alpha){
				color = ExtraRangeColor[i].rgb;
				alpha = max(alpha, curentAlpha);
			}
		}
	}
	
#endif

	Frag_Color = vec4(color,alpha * yValue);
}
