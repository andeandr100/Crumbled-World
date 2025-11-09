#version 150

in vec4 pos[];
in vec4 lifeBarValues[];
in float value[];

layout (points) in;
layout (triangle_strip, max_vertices = 32) out;

out vec4 spriteColor;
out vec2 tc;
uniform mat4 projMat;

// Helper function to create a quad with a solid color
void CreateQuad(vec4 centerPos, vec2 size, vec4 color)
{
    spriteColor = color;
    tc = vec2(0.0, 0.0); // Not used for solid colors

    gl_Position = centerPos + projMat * vec4(size.x, size.y, 0.0, 0.0);
    EmitVertex();
    gl_Position = centerPos + projMat * vec4(size.x, -size.y, 0.0, 0.0);
    EmitVertex();
    gl_Position = centerPos + projMat * vec4(-size.x, size.y, 0.0, 0.0);
    EmitVertex();
    gl_Position = centerPos + projMat * vec4(-size.x, -size.y, 0.0, 0.0);
    EmitVertex();
    EndPrimitive();
}

// Helper function to create a quad with a vertical color gradient
void CreateGradientQuad(vec4 centerPos, vec2 size, float left, float right, vec4 topColor, vec4 bottomColor)
{
    spriteColor = topColor;
    gl_Position = centerPos + projMat * vec4(right, size.y, 0.0, 0.0);
    EmitVertex();

    spriteColor = bottomColor;
    gl_Position = centerPos + projMat * vec4(right, -size.y, 0.0, 0.0);
    EmitVertex();

    spriteColor = topColor;
    gl_Position = centerPos + projMat * vec4(left, size.y, 0.0, 0.0);
    EmitVertex();

    spriteColor = bottomColor;
    gl_Position = centerPos + projMat * vec4(left, -size.y, 0.0, 0.0);
    EmitVertex();
    EndPrimitive();
}

// Helper function to create a textured quad for icons
void CreateIcon(vec4 centerPos, float xOffset, float yOffset, float size, vec2 tc_start, vec2 tc_size)
{
    spriteColor = vec4(0.0, 0.0, 0.0, 0.0); // Use texture, color is irrelevant

    tc = tc_start + vec2(tc_size.x, 0.0);
    gl_Position = centerPos + projMat * vec4(xOffset + size, yOffset + size, 0.0, 0.0);
    EmitVertex();

    tc = tc_start + tc_size;
    gl_Position = centerPos + projMat * vec4(xOffset + size, yOffset, 0.0, 0.0);
    EmitVertex();

    tc = tc_start;
    gl_Position = centerPos + projMat * vec4(xOffset, yOffset + size, 0.0, 0.0);
    EmitVertex();

    tc = tc_start + vec2(0.0, tc_size.y);
    gl_Position = centerPos + projMat * vec4(xOffset, yOffset, 0.0, 0.0);
    EmitVertex();
    EndPrimitive();
}


void main( void )
{
    const float h = 0.06;
    const float w = 0.4;

    // --- Health Bar ---
    if(value[0] != 1.0 || lifeBarValues[0].z > 0.5)
    {
        // Background
        CreateQuad(pos[0], vec2(w, h), vec4(0.0, 0.0, 0.0, 1.0));

        float life = min(1.0, value[0]);
        
        const vec3 red = vec3(0.75, 0.1, 0.1);
        const vec3 orange = vec3(0.75, 0.75, 0.1);
        const vec3 green = vec3(0.1, 0.75, 0.1);

        vec3 color = mix(orange, green, clamp((life - 0.4) / 0.25, 0.0, 1.0));
        color = mix(red, color, step(life, 0.4));
        color = mix(red, orange, clamp((life - 0.15) / 0.15, 0.0, 1.0) * step(life, 0.4));

        vec4 topColor = vec4(color, 1.0);
        vec4 bottomColor = vec4(color * 0.15, 1.0);

        const vec2 healthBarSize = vec2(w - h * 0.3, h - h * 0.3);
        float barEnd = -healthBarSize.x + healthBarSize.x * 2.0 * life;

        // Health bar background (the empty part)
        CreateGradientQuad(pos[0], healthBarSize, barEnd, healthBarSize.x, vec4(0.2, 0.2, 0.2, 1.0), vec4(0.05, 0.05, 0.05, 1.0));
        
        // Health bar (the filled part)
        CreateGradientQuad(pos[0], healthBarSize, -healthBarSize.x, barEnd, topColor, bottomColor);

        // Extra life bar
        if(value[0] > 1.0)
        {
            float extraLife = value[0] - 1.0;
            float extraBarEnd = -healthBarSize.x + healthBarSize.x * 2.0 * extraLife;
            CreateGradientQuad(pos[0], healthBarSize, -healthBarSize.x, extraBarEnd, vec4(0.6, 0.68, 0.6, 1.0), vec4(0.1, 0.1, 0.1, 1.0));
        }
    }

    // --- Status Icons ---
    const float yOffset = -h * 4.0;
    const float iconWidth = h * 3.0;
    float xOffset = -w;
    float iconValue = lifeBarValues[0].w;

    // Decode and draw icons using bitmask-like checks
    if (iconValue >= 512.0) {
        iconValue -= 512.0;
        CreateIcon(pos[0], xOffset, yOffset, iconWidth, vec2(0.0, 0.0), vec2(0.125, 0.0625));
        xOffset += iconWidth + h * 0.5;
    }
    if (iconValue >= 256.0) {
        iconValue -= 256.0;
        CreateIcon(pos[0], xOffset, yOffset, iconWidth, vec2(0.5, 0.0), vec2(0.125, 0.0625));
        xOffset += iconWidth + h * 0.5;
    }
    if (iconValue >= 128.0) {
        iconValue -= 128.0;
        CreateIcon(pos[0], xOffset, yOffset, iconWidth, vec2(0.75, 0.4375), vec2(0.125, 0.0625));
        xOffset += iconWidth + h * 0.5;
    }
    if (iconValue >= 8.0) {
        iconValue -= 8.0;
        CreateIcon(pos[0], xOffset, yOffset, iconWidth, vec2(0.625, 0.4375), vec2(0.125, 0.0625));
        xOffset += iconWidth + h * 0.5;
    }
    if (iconValue >= 4.0) {
        iconValue -= 4.0;
        CreateIcon(pos[0], xOffset, yOffset, iconWidth, vec2(0.25, 0.375), vec2(0.125, 0.0625));
        xOffset += iconWidth + h * 0.5;
    }
    if (iconValue >= 2.0) {
        iconValue -= 2.0;
        CreateIcon(pos[0], xOffset, yOffset, iconWidth, vec2(0.75, 0.25), vec2(0.125, 0.0625));
        xOffset += iconWidth + h * 0.5;
    }
}