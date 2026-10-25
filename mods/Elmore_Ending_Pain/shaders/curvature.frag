#pragma header

#pragma format R8G8B8A8_SRGB

uniform float uCurvature;

vec2 applyCurvature(vec2 uv)
{
	if (uCurvature <= 0.0) return uv;
	vec2 c = uv * 2.0 - 1.0;
	vec2 offset = abs(c.yx) / vec2(uCurvature);
	c += c * offset * offset;
	return c * 0.5 + 0.5;
}

void main()
{
	vec2 uv = applyCurvature(openfl_TextureCoordv);
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0)
	{
		gl_FragColor = vec4(0.0);
		return;
	}
	gl_FragColor = flixel_texture2D(bitmap, uv);
}
