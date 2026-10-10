// Select the second decoder without including another copy of the type/table
// definitions. All admitted mixed formats have QUANT_K=256 and QUANT_R=1.
#undef DATA_A_Q2_K
#undef DATA_A_Q4_K
#undef DATA_A_IQ1_S
#undef DATA_A_IQ1_M
#undef DATA_A_IQ2_XXS
#undef DATA_A_IQ2_XS
#undef DATA_A_IQ2_S
#undef DATA_A_IQ3_XXS
#undef DATA_A_IQ3_S
#undef DATA_A_IQ4_XS
#if defined(DATA_UP_Q2_K)
#define DATA_A_Q2_K
#elif defined(DATA_UP_Q4_K)
#define DATA_A_Q4_K
#elif defined(DATA_UP_IQ1_S)
#define DATA_A_IQ1_S
#elif defined(DATA_UP_IQ1_M)
#define DATA_A_IQ1_M
#elif defined(DATA_UP_IQ2_XXS)
#define DATA_A_IQ2_XXS
#elif defined(DATA_UP_IQ2_XS)
#define DATA_A_IQ2_XS
#elif defined(DATA_UP_IQ2_S)
#define DATA_A_IQ2_S
#elif defined(DATA_UP_IQ3_XXS)
#define DATA_A_IQ3_XXS
#elif defined(DATA_UP_IQ3_S)
#define DATA_A_IQ3_S
#elif defined(DATA_UP_IQ4_XS)
#define DATA_A_IQ4_XS
#else
#error Missing up format for mixed gate/up mat-vec
#endif
