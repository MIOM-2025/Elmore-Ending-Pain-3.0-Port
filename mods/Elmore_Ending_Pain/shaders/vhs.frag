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

// Composite cross-talk matrix. Always applied; this is the essence of COMPOSITE.
// cos^2/sin^2 average to 0.5, so chroma gain uses 2.0 * SATURATION to compensate.
mat3 mix_mat = mat3(
	BRIGHTNESS, FRINGING, FRINGING,
	ARTIFACTING, 2.0 * SATURATION, 0.0,
	ARTIFACTING, 0.0, 2.0 * SATURATION
);

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

// Radial barrel distortion: all points expand along their radius by r^2.
// Same semantics as the original: larger uCurvature means less curvature.
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

// Demodulate -> cross-talk -> remodulate. Always executed; the COMPOSITE / SVIDEO
// difference is entirely encoded in the mix_mat constants.
vec4 pass1(vec2 uv, float basePhase)
{
	vec2 fragCoord = uv * openfl_TextureSize;

	vec4 cola = texture2D(bitmap, uv).rgba;
	vec3 yiq = rgb2yiq(cola.rgb);

	float mod_phase = basePhase + fragCoord.x * CHROMA_MOD_FREQ;

	float i_mod = cos(mod_phase);
	float q_mod = sin(mod_phase);

	yiq.yz *= vec2(i_mod, q_mod);
	yiq *= mix_mat;
	yiq.yz *= vec2(i_mod, q_mod);

	return vec4(yiq, cola.a);
}

void main()
{
	// FIR coefficients. Luma sums to 1.00, chroma sums to 1.00.
	float luma_filter[9];
	float chroma_filter[9];

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
	chroma_filter[4] = 0.28;
	chroma_filter[5] = 0.14;
	chroma_filter[6] = 0.11;
	chroma_filter[7] = 0.07;
	chroma_filter[8] = 0.04;

	vec2 uv = applyCurvature(openfl_TextureCoordv);

	// Outside the curved screen -> pure black.
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0)
	{
		gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
		return;
	}

	// Undistorted screen space: chroma phase uses this so that phase does not
	// drift across a row when curvature is strong.
	vec2 rawFragCoord = openfl_TextureCoordv * openfl_TextureSize;
	// Distorted screen space: scanlines use this so stripes bend with the screen.
	vec2 warpedFragCoord = uv * openfl_TextureSize;

	// Chroma phase:
	//   uInterlace == 1.0 -> flips every frame (true interlace)
	//   uInterlace == 0.0 -> locked across frames (static pattern)
	float frameTerm = float(uFrame) * step(0.5, uInterlace);
	float chroma_phase = PI * (mod(rawFragCoord.y, 2.0) + frameTerm);

	float one_x = 1.0 / openfl_TextureSize.x;

	vec4 signal = vec4(0.0);

	for (int i = 0; i < TAPS; i++)
	{
		float offset = float(i - HALF_TAPS);
		// Clamp to [0,1] to keep taps inside the texture at the edges.
		vec2 sampleUV = clamp(uv + vec2(offset * one_x, 0.0), vec2(0.0), vec2(1.0));

		vec4 passResult = pass1(sampleUV, chroma_phase);

		// Alpha uses luma weights (sum = 1.0) so it matches the brightness edges.
		signal += passResult * vec4(luma_filter[i], chroma_filter[i], chroma_filter[i], luma_filter[i]);
	}

	vec3 rgb = yiq2rgb(signal.xyz);
	vec3 finalColor = pow(rgb, vec3(NTSC_CRT_GAMMA / NTSC_MONITOR_GAMMA));

	// --- CRT horizontal scanlines --- (warped y so they follow the curvature)
	float scanWarp = 0.035 * sin(warpedFragCoord.y * 0.13);
	float scan = 0.5 + 0.5 * cos(warpedFragCoord.y * PI + scanWarp);
	float scanMask = mix(0.88, 1.0, scan);
	vec3 scanTint = mix(vec3(1.015, 0.985, 1.0), vec3(0.985, 1.0, 1.015), scan);
	finalColor *= scanMask * scanTint;

	// Subtle static per-line variation; no per-frame term to avoid flicker.
	float lineVariation = 0.5 + 0.5 * sin(warpedFragCoord.y * 0.37);
	finalColor += (lineVariation - 0.5) * vec3(0.012, -0.006, 0.010);

	gl_FragColor = vec4(finalColor, signal.a);
}