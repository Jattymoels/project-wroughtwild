shader_type spatial;
#include "res://rf07/mineral.gdshaderinc"
varying vec3 p;
varying vec3 n;
void vertex(){p=(MODEL_MATRIX*vec4(VERTEX,1)).xyz;n=MODEL_NORMAL_MATRIX*NORMAL;}
void fragment(){
 vec3 normal=normalize(n),relief;
 float roughness;
 ALBEDO=rf07_mineral(p,normal,relief,roughness);
 vec3 bumped=normalize(normal-(relief-normal*dot(normal,relief)));
 NORMAL=normalize((VIEW_MATRIX*vec4(bumped,0.0)).xyz);
 ROUGHNESS=roughness;SPECULAR=.22;
}
