shader_type spatial;

uniform float transition_strength = 1.0;
uniform sampler2D texture_x:source_color,repeat_enable;
uniform sampler2D texture_y:source_color,repeat_enable;
uniform sampler2D texture_z:source_color,repeat_enable;

void fragment() {
	vec3 world_vertex = (INV_VIEW_MATRIX * vec4(VERTEX,1.0)).xyz;
	vec3 world_normal = normalize((INV_VIEW_MATRIX * vec4(NORMAL,0.0)).xyz);
	world_normal = pow(abs(world_normal),vec3(transition_strength));
	vec3 weights = world_normal/(world_normal.x+world_normal.y+world_normal.z)*3.0;
	
	vec3 color_x = texture(texture_x,world_vertex.yz).xyz * weights.x;
	vec3 color_y_up = texture(texture_y,world_vertex.xz).xyz * weights.y;
	vec3 color_y_down = texture(texture_x,world_vertex.xz).xyz *weights.y;
	vec3 color_z = texture(texture_z,world_vertex.xy).xyz * weights.z;
	
	vec3 color_y_adjusted = mix(color_y_down,color_y_up,abs(world_normal.y));
	
	ALBEDO = (color_x+color_y_up+color_z)/3.0;
}