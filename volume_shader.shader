/*
	Smoke Volume Rendering Shader by Yui Kinomoto @arlez80
*/
shader_type spatial;
render_mode blend_mix, unshaded;

// shader parameters
uniform int LOOP = 32;
uniform float NOISE_SCALE = 4.0;
uniform float SIZE = 1.0;
uniform float ABSORPTION = 0.05;
uniform float OPACITY = 2.0;
uniform float OFFSET = 0.0;
uniform vec3 SMOKE_COLOR = vec3( 1, 1, 1 );

varying vec3 varying_local_pos;

float random( float n )
{ 
	return fract( sin( n ) * ( 43758.5453 + sin( OFFSET ) ) );
}

float noise( vec3 v )
{
	vec3 p = floor( v );
	vec3 f = fract( v );
	f = f * f * ( 3.0 - 2.0 * f );
	float n = p.x + p.y * 57.0 + 113.0 * p.z;
	return mix(
		mix(
			mix(random(n), random(n + 1.0), f.x),
			mix(random(n + 57.0), random(n + 58.0), f.x),
			f.y
		),
		mix(
			mix(random(n + 113.0), random(n + 114.0), f.x),
			mix(random(n + 170.0), random(n + 171.0), f.x),
			f.y
		),
		f.z
	);
}

float fbm( vec3 p )
{
	mat3 m = mat3(
		vec3( +0.00, +0.80, +0.60 ),
		vec3( -0.80, +0.36, -0.48 ),
		vec3( -0.60, -0.48, +0.64 )
	);

	float f = 0.0;
	f += 0.5 * noise( p ); p = m * p * 2.02;
	f += 0.3 * noise( p ); p = m * p * 2.03;
	f += 0.2 * noise( p );

	return f;
}

float density_function( vec3 p )
{
	return fbm( p * NOISE_SCALE ) - length( p / SIZE ) * 2.0;
}

void fragment( )
{
	vec3 local_pos = varying_local_pos;
	vec3 local_dir = normalize( WORLD_MATRIX[3].xyz + local_pos - CAMERA_MATRIX[3].xyz );

	float one_step = SIZE / float( LOOP );
	vec3 local_one_step = local_dir * one_step;

	float alpha = 0.0;
	float transmittance = 1.0;

	for( int i=0; i<LOOP; i++ ) {
		float density = density_function( local_pos );
		float d = density * one_step;
		transmittance *= ( 0.01 < density ) ? 1.0 - d * ABSORPTION : 1.0;
		alpha += ( 0.01 < density ) ? ( ( transmittance < 0.01 ) ? 0.0 : ( OPACITY * d * transmittance ) ) : 0.0;
		local_pos += local_one_step;
	}

	ALBEDO = SMOKE_COLOR;
	ALPHA = clamp( alpha , 0.0, 1.0 );
}

void vertex( )
{
	varying_local_pos = VERTEX;
}
