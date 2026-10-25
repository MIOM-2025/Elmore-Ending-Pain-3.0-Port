#pragma header

#pragma format R8G8B8A8_SRGB

#define NTSC_CRT_GAMMA 2.5
#define NTSC_MONITOR_GAMMA 2.0

#define TWO_PHASE
#define COMPOSITE

#define PI 3.14159265

#if defined(TWO_PHASE)
	#define CHROMA_MOD_FREQ (4.0 * PI / 15.0)
#elif defined(THREE_PHASE)
	#define CHROMA_MOD_FREQ (PI / 3.0)
#endif

#if defined(COMPOSITE)
	#define SATURATION 1.0
	#define BRIGHTNESS 1.0
	#define ARTIFACTING 1.0
	#define FRINGING 1.0
#elif defined(SVIDEO)
	#define SATURATION 1.0
	#define BRIGHTNESS 1.0
	#define ARTIFACTING 0.0
	#define FRINGING 0.0
#endif

uniform int uFrame;
uniform float uInterlace;
uniform float uCurvature;

#if defined(COMPOSITE) || defined(SVIDEO)
mat3 mix_mat = mat3(
	BRIGHTNESS, FRINGING, FRINGING,
	ARTIFACTING, 2.0 * SATURATION, 0.0,
	ARTIFACTING, 0.0, 2.0 * SATURATION
);
#endif

const mat3 yiq2rgb_mat = mat3(
	1.0, 0.956, 0.6210,
	1.0, -0.2720, -0.6474,
	1.0, -1.1060, 1.7046);

vec3 yiq2rgb(vec3 yiq)
{
	return yiq * yiq2rgb_mat;
}

const mat3 yiq_mat = mat3(
	0.2989, 0.5870, 0.1140,
	0.5959, -0.2744, -0.3216,
	0.2115, -0.5229, 0.3114
);

vec3 rgb2yiq(vec3 col)
{
	return col * yiq_mat;
}

vec2 applyCurvature(vec2 uv)
{
	if (uCurvature <= 0.0) return uv;
	vec2 c = uv * 2.0 - 1.0;
	vec2 offset = abs(c.yx) / vec2(uCurvature);
	c += c * offset * offset;
	return c * 0.5 + 0.5;
}

const int TAPS = 9;
const int HALF_TAPS = 4;

float luma_filter[9];
float chroma_filter[9];

vec4 pass1(vec2 uv, float basePhase)
{
	vec2 fragCoord = uv * openfl_TextureSize;

	vec4 cola = texture2D(bitmap, uv).rgba;
	vec3 yiq = rgb2yiq(cola.rgb);

	float mod_phase = basePhase + fragCoord.x * CHROMA_MOD_FREQ;

	float i_mod = cos(mod_phase);
	float q_mod = sin(mod_phase);

	if(uInterlace == 1.0) {
		yiq.yz *= vec2(i_mod, q_mod);
		yiq *= mix_mat;
		yiq.yz *= vec2(i_mod, q_mod);
	}
	return vec4(yiq, cola.a);
}

void main()
{
	luma_filter[0] = 0.05;
	luma_filter[1] = 0.08;
	luma_filter[2] = 0.12;
	luma_filter[3] = 0.15;
	luma_filter[4] = 0.20;
	luma_filter[5] = 0.15;
	luma_filter[6] = 0.12;
	luma_filter[7] = 0.08;
	luma_filter[8] = 0.05;

	chroma_filter[0] = 0.04;
	chroma_filter[1] = 0.07;
	chroma_filter[2] = 0.11;
	chroma_filter[3] = 0.14;
	chroma_filter[4] = 0.18;
	chroma_filter[5] = 0.14;
	chroma_filter[6] = 0.11;
	chroma_filter[7] = 0.07;
	chroma_filter[8] = 0.04;

	vec2 uv = applyCurvature(openfl_TextureCoordv);

	// Outside the curved screen => pure black (no stretched edge pixels)
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0)
	{
		gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
		return;
	}

	vec2 fragCoord = uv * openfl_TextureSize;

	float one_x = 1.0 / openfl_TextureSize.x;

	float chroma_phase = PI * (mod(fragCoord.y, 2.0) + float(uFrame));
	float basePhase = chroma_phase;

	vec4 signal = vec4(0.0);

	for (int i = 0; i < TAPS; i++)
	{
		float offset = float(i - HALF_TAPS);
		vec2 sampleUV = uv + vec2(offset * one_x, 0.0);
		vec4 passResult = pass1(sampleUV, basePhase);
		signal += passResult * vec4(luma_filter[i], chroma_filter[i], chroma_filter[i], 1.0);
	}

	vec3 rgb = yiq2rgb(signal.xyz);
	gl_FragColor = vec4(pow(rgb, vec3(NTSC_CRT_GAMMA / NTSC_MONITOR_GAMMA)), flixel_texture2D(bitmap, uv).a);
}