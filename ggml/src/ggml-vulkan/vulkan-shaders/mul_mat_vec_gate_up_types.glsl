// The mixed path uses block-256, consecutive-element formats on both sides.
// types.glsl has already declared these layouts and initialized both IQ tables.
#if defined(DATA_UP_Q2_K)
#define UP_TYPE block_q2_K
#define UP_TYPE_PACKED16 block_q2_K_packed16
#define UP_TYPE_PACKED32 block_q2_K_packed32
#elif defined(DATA_UP_Q4_K)
#define UP_TYPE block_q4_K
#define UP_TYPE_PACKED16 block_q4_K_packed16
#define UP_TYPE_PACKED32 block_q4_K_packed32
#elif defined(DATA_UP_IQ1_S)
#define UP_TYPE block_iq1_s
#define UP_TYPE_PACKED16 block_iq1_s_packed16
#elif defined(DATA_UP_IQ1_M)
#define UP_TYPE block_iq1_m
#define UP_TYPE_PACKED16 block_iq1_m_packed16
#define UP_TYPE_PACKED32 block_iq1_m_packed32
#elif defined(DATA_UP_IQ2_XXS)
#define UP_TYPE block_iq2_xxs
#define UP_TYPE_PACKED16 block_iq2_xxs_packed16
#elif defined(DATA_UP_IQ2_XS)
#define UP_TYPE block_iq2_xs
#define UP_TYPE_PACKED16 block_iq2_xs_packed16
#elif defined(DATA_UP_IQ2_S)
#define UP_TYPE block_iq2_s
#define UP_TYPE_PACKED16 block_iq2_s_packed16
#elif defined(DATA_UP_IQ3_XXS)
#define UP_TYPE block_iq3_xxs
#define UP_TYPE_PACKED16 block_iq3_xxs_packed16
#elif defined(DATA_UP_IQ3_S)
#define UP_TYPE block_iq3_s
#define UP_TYPE_PACKED16 block_iq3_s_packed16
#elif defined(DATA_UP_IQ4_XS)
#define UP_TYPE block_iq4_xs
#define UP_TYPE_PACKED16 block_iq4_xs_packed16
#define UP_TYPE_PACKED32 block_iq4_xs_packed32
#else
#define UP_TYPE A_TYPE
#ifdef A_TYPE_PACKED16
#define UP_TYPE_PACKED16 A_TYPE_PACKED16
#endif
#ifdef A_TYPE_PACKED32
#define UP_TYPE_PACKED32 A_TYPE_PACKED32
#endif
#endif
