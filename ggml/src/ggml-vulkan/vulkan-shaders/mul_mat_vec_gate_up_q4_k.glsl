// PROVENANCE: TechMakesArt/llama.cpp-bc250 (MIT), paired Q4_K superblock dot product.
float GATE_UP_Q4_K_DOT(uint ib, uint v_im, uint q_offset, vec4 b0, vec4 b1, vec4 b2, vec4 b3, float sum) {
    const vec2 dm = vec2(data_a[ib].dm);
    const uint scale0 = data_a_packed16[ib].scales[v_im];
    const uint scale4 = data_a_packed16[ib].scales[v_im + 2];
    const uint scale8 = data_a_packed16[ib].scales[v_im + 4];
    const uint sc04 = (scale4 << 16) | scale0;
    const vec4 sc0 = vec4(unpack8(sc04 & 0x3f3f3f3f));
    const vec4 sc1 = vec4(unpack8((((scale8 << 12) | scale8) & 0x0f0f0f0f) | ((sc04 & 0xc0c0c0c0) >> 2)));
    const uint q0 = data_a_packed32[ib].qs[q_offset / 4];
    const uint q1 = data_a_packed32[ib].qs[q_offset / 4 + 16];
    const vec4 v0 = vec4(unpack8(q0 & 0x0f0f0f0f));
    const vec4 v1 = vec4(unpack8((q0 >> 4) & 0x0f0f0f0f));
    const vec4 v2 = vec4(unpack8(q1 & 0x0f0f0f0f));
    const vec4 v3 = vec4(unpack8((q1 >> 4) & 0x0f0f0f0f));
    const float sx = fma(b0.x, v0.x, fma(b0.y, v0.y, fma(b0.z, v0.z, b0.w * v0.w)));
    const float sy = fma(b1.x, v1.x, fma(b1.y, v1.y, fma(b1.z, v1.z, b1.w * v1.w)));
    const float sz = fma(b2.x, v2.x, fma(b2.y, v2.y, fma(b2.z, v2.z, b2.w * v2.w)));
    const float sw = fma(b3.x, v3.x, fma(b3.y, v3.y, fma(b3.z, v3.z, b3.w * v3.w)));
    float smin;
    if (DEQUANT_OPT) {
        smin = fma(dot(b0, vec4(1.0)), sc0.z, fma(dot(b1, vec4(1.0)), sc0.w,
               fma(dot(b2, vec4(1.0)), sc1.z, dot(b3, vec4(1.0)) * sc1.w)));
    } else {
        smin = fma(b0.x, sc0.z, fma(b1.x, sc0.w, fma(b2.x, sc1.z, fma(b3.x, sc1.w,
               fma(b0.y, sc0.z, fma(b1.y, sc0.w, fma(b2.y, sc1.z, fma(b3.y, sc1.w,
               fma(b0.z, sc0.z, fma(b1.z, sc0.w, fma(b2.z, sc1.z, fma(b3.z, sc1.w,
               fma(b0.w, sc0.z, fma(b1.w, sc0.w, fma(b2.w, sc1.z, b3.w * sc1.w)))))))))))))));
    }
    return fma(dm.x, fma(sx, sc0.x, fma(sy, sc0.y, fma(sz, sc1.x, sw * sc1.y))), fma(-dm.y, smin, sum));
}
