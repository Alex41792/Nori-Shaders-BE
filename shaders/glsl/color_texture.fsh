// __multiversion__

#include "fragmentVersionCentroidUV.h"

#include "uniformEntityConstants.h"
#include "uniformShaderConstants.h"

LAYOUT_BINDING(0) uniform sampler2D TEXTURE_0;
LAYOUT_BINDING(1) uniform sampler2D TEXTURE_1;

#ifdef EFFECTS_OFFSET
#include "uniformEffectsConstants.h"
#endif

varying vec4 color;

#ifdef ENABLE_FOG
varying vec4 fogColor;
#endif

#ifdef GLINT
	varying vec2 layer1UV;
	varying vec2 layer2UV;

	vec4 glintBlend(vec4 dest, vec4 source) {
		return vec4(source.rgb * source.rgb, 0.0) + dest;
	}
#endif

void main()
{
	highp vec2 tmCoord = fract(uv * 32.0) * 0.015625;
	bool ismap = (TEXTURE_DIMENSIONS.xy == vec2(1024, 1024) || TEXTURE_DIMENSIONS.xy == vec2(2048, 2048) || TEXTURE_DIMENSIONS.xy == vec2(4096, 4096) || TEXTURE_DIMENSIONS.xy == vec2(8192, 8192));

	vec4 diffuse = vec4(0, 0, 0, 0);

#ifdef EFFECTS_OFFSET
	if(ismap){
		diffuse = textureLod(TEXTURE_0, uv - tmCoord, 0.0);
	} else {
		diffuse = texture2D(TEXTURE_0, uv + EFFECT_UV_OFFSET);
	}
#else
	if(ismap){
		diffuse = textureLod(TEXTURE_0, uv - tmCoord, 0.0);
	} else {
		diffuse = texture2D(TEXTURE_0, uv);
	}
#endif

#ifdef MULTI_COLOR_TINT
	// Texture is a mask for tinting with two colors
	vec2 colorMask = diffuse.rg;

	// Apply the base color tint
	diffuse.rgb = colorMask.rrr * color.rgb;

	// Apply the secondary color mask and tint so long as its grayscale value is not 0
	diffuse.rgb = mix(diffuse, colorMask.gggg * CHANGE_COLOR, ceil(colorMask.g)).rgb;
#endif

#ifdef ALPHA_TEST
#ifdef ENABLE_VERTEX_TINT_MASK
	if(diffuse.a <= 0.0)
#else
	if(diffuse.a < 0.5)
#endif
	 	discard;
#endif

#if defined(ENABLE_VERTEX_TINT_MASK) && !defined(MULTI_COLOR_TINT)
	diffuse.rgb = mix(diffuse.rgb, diffuse.rgb*color.rgb, diffuse.a);
	if (color.a > 0.0) {
		diffuse.a = (diffuse.a > 0.0) ? 1.0 : 0.0; // This line is needed for horse armour icon and dyed leather to work properly
	}
#endif

#ifdef GLINT
	vec4 layer1 = texture2D(TEXTURE_1, fract(layer1UV)).rgbr * GLINT_COLOR;
	vec4 layer2 = texture2D(TEXTURE_1, fract(layer2UV)).rgbr * GLINT_COLOR;
	vec4 glint = (layer1 + layer2);
	glint.rgb *= color.a;

	#ifdef INVENTORY
		diffuse.rgb = glint.rgb;
	#else
		diffuse.rgb = glintBlend(diffuse, glint).rgb;
	#endif
#endif

#ifdef USE_OVERLAY
	//use either the diffuse or the OVERLAY_COLOR
	diffuse.rgb = mix(diffuse, OVERLAY_COLOR, OVERLAY_COLOR.a).rgb;
#endif

#ifdef ENABLE_VERTEX_TINT_MASK

#ifdef ENABLE_CURRENT_ALPHA_MULTIPLY
	diffuse = diffuse * vec4(1.0, 1.0, 1.0, HUD_OPACITY);
#endif

#elif !defined(MULTI_COLOR_TINT)
	diffuse = diffuse * color;
#endif

	// Fog needs to be applied after the color tinting.
#ifdef ENABLE_FOG
	//apply fog
	diffuse.rgb = mix(diffuse.rgb, fogColor.rgb, fogColor.a);
#endif

	gl_FragColor = diffuse;
}
