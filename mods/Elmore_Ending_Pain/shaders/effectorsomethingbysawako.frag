#pragma header

uniform float intensity;
uniform float iTime;

float rand(vec2 co)
{
    return fract(sin(dot(co, vec2(12.9898,78.233))) * 43758.5453);
}

void main()
{
    vec2 uv = openfl_TextureCoordv;

    vec2 offset = vec2(0.0);

	offset.x += sin(uv.y * 18.0 + iTime * 6.0) * 0.025;
	offset.x += sin(uv.y * 42.0 - iTime * 4.0) * 0.012;

	offset.y += cos(uv.x * 20.0 + iTime * 5.0) * 0.018;
	offset.y += sin((uv.x + uv.y) * 16.0 - iTime * 7.0) * 0.015;

	vec2 center = uv - 0.5;
	float dist = length(center);

	offset += normalize(center + 0.0001) *
          sin(dist * 35.0 - iTime * 10.0) *
          0.03;

	offset *= intensity;
	
    vec2 rUV = uv + offset;
	vec2 gUV = uv + offset * 0.5;
	vec2 bUV = uv - offset * 0.8;

    float r = flixel_texture2D(bitmap, rUV).r;
    float g = flixel_texture2D(bitmap, gUV).g;
    float b = flixel_texture2D(bitmap, bUV).b;

    vec4 col = vec4(r,g,b,1.0);

    gl_FragColor = col;
}