shader_type spatial;
render_mode world_vertex_coords;

uniform vec3 triplanar_scale = vec3(1.0);
uniform vec3 triplanar_offset = vec3(0.0);
uniform sampler2D x_texture:filter_nearest;
uniform sampler2D y_texture:filter_nearest;
uniform sampler2D z_texture:filter_nearest;


varying vec3 triplanar_pos;
varying vec3 frag_normal;
varying vec3 triplanar_weight;

vec3 triplanar_map(vec3 x,vec3 y, vec3 z, vec3 n){
	n = n*n;
	return(x*n.x+y*n.y+z*n.z)/(n.x+n.y+n.z);
}

vec3 triplanar_tritexutre(sampler2D texture_a,sampler2D texture_b,sampler2D texture_c,vec3 d, vec3 n){
	vec3 colx = texture(texture_a,d.zy*triplanar_scale.x).xyz;
	vec3 coly = texture(texture_b,d.xz*triplanar_scale.y).xyz;
	vec3 colz = texture(texture_c,d.xy*triplanar_scale.z).xyz;
	return triplanar_map(colx,coly,colz,n);
}

void vertex() {
	triplanar_pos = VERTEX;
	triplanar_pos *= triplanar_scale;
	triplanar_pos += triplanar_offset;
	frag_normal = NORMAL;
}

void fragment() {	
	ALBEDO = triplanar_tritexutre(x_texture,y_texture,z_texture,triplanar_pos,frag_normal);
}