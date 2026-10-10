# Vulkan RDNA1 tuning

This fork adds scalar decode and prefill paths for RDNA1, including gfx1013.
They use the existing Vulkan backend and its memory and submission model.
The initial source base is upstream `aa94f2086147cd4bfbcff818ce998dffce5fcb39`.

PROVENANCE: TechMakesArt/llama.cpp-bc250 (MIT), fused gate/up mat-vec design, Q4_K minimum-term regrouping and RDNA1 row tuning, reviewed at `82fac30`.

## What upstream already does

At this source revision, Vulkan already fuses matrix multiplication with bias,
some expert operations, activation/multiply operations, RMS normalization and
several routing patterns. It also has dedicated IQ decode shaders and shared
grid tables. Those paths remain in use.

The added fusion computes the gate and up projections together, shares the
input loads and applies the GLU before writing the result. Both ordinary and
expert-selected single-token graphs are supported. A graph with an externally
used intermediate, unsupported layout, input type or pair of weight types uses
the existing operations. The optimization does not change model tensor formats.
It also handles a merged gate/up projection split by views or by a single-source
GLU, including reversed halves and an optional bias.

The same-type kernels cover Q4_0, Q8_0, Q2_K, Q3_K, Q4_K, Q5_K, Q6_K, IQ1_S,
IQ1_M, IQ2_XXS, IQ2_XS, IQ2_S, IQ3_XXS, IQ3_S, IQ4_XS, IQ4_NL and MXFP4.
Mixed gate/up pairs cover the IQ1, IQ2, IQ3, IQ4_XS, Q2_K and Q4_K families. This matters
for importance-matrix quants: the inspected Saluki model has 50 mixed pairs and
14 same-type pairs. Shared lookup tables are reused when the pair needs the
same table family.

## Device selection and controls

The default gate is the backend's existing `AMD_RDNA1` classification. The
classifier uses AMD vendor identity, subgroup limits of 32 and 64, the required
property extensions and `wavefrontsPerSimd == 20`. A device name alone does not
select the path. Startup prints the detected classification and each switch.
Rows, decode arithmetic and packed FP16 are enabled by default on RDNA1.
Gate/up fusion requires an explicit opt-in: matched gfx1013 model runs showed
slower decode with this fusion. It does not apply to multi-token prefill.

All switches below are presence-based, as are upstream's other Vulkan switches.
Unset a switch to restore its normal default. Any value, including `0`, activates
a `DISABLE` switch. Presence of `GGML_VK_RDNA1_TUNING` enables the test override,
but does not enable gate/up fusion. The enable switch is also presence-based.

| Environment variable | Effect when set |
| --- | --- |
| `GGML_VK_ENABLE_GATE_UP_FUSION` | Opt into dual-projection/GLU fusion on an RDNA1 tuning device. |
| `GGML_VK_DISABLE_GATE_UP_FUSION` | Disable the new dual-projection/GLU fusion. |
| `GGML_VK_DISABLE_RDNA1_ROWS` | Restore upstream scalar mat-vec row counts. |
| `GGML_VK_DISABLE_DEQUANT_TUNING` | Restore the original decode arithmetic and MXFP4 LUT. |
| `GGML_VK_DISABLE_RDNA1_PACKED_F16` | Restore separate scalar FP16 dot products. |
| `GGML_VK_DISABLE_FUSION` | Disable all backend graph fusion, including upstream fusion. |
| `GGML_VK_RDNA1_TUNING` | Test override: enable the tuning on a different Vulkan device. |

Both fusion disable switches take precedence over the gate/up enable switch.
Shader creation and graph selection use the same effective fusion choice.
The override is for correctness tests, not automatic device detection. On a
device with matrix units, disable cooperative matrices and integer dot products
as well when testing the scalar prefill path. The lab comparison should use the
actual classification without this override.

## Decode changes

IQ2 and IQ3 sign handling uses signed packed-byte extraction. Q4_0 uses signed
nibble extraction. Both retain the decoded integer values. Q4_K groups the
minimum terms to avoid repeated multiplication; this changes floating-point
association and is covered by numerical tests.

MXFP4 decodes its 16 values from a packed constant. This removes shared table
reads and a barrier, at the cost of more arithmetic instructions. Compiler
counts alone do not establish a speedup for this change. Keep the per-change
toggle when measuring it.

IQ tables stay in shared memory. IQ1_S, IQ1_M, Q2_K, IQ4_XS and Q8_0 retain their
upstream decoding formulas. They can still use the new fusion and row tuning.

## Packed FP16 prefill

The scalar matrix shader pairs two independent output rows in an `f16vec2`
FMA. Each output keeps its original accumulation order. Only the existing
FP16 accumulator variants use it: an explicit FP32 precision request is never
narrowed to FP16. Cooperative-matrix and dot2 variants are unchanged.

Compiler-only RADV/ACO results for gfx1013, wave32, large 128 x 128 tile, with
128 invocations and K tile 32:

| Shader | Packed path | Code bytes | VGPRs | `v_pk_fma_f16` instructions |
| --- | --- | ---: | ---: | ---: |
| IQ2_XS, FP16 accumulation | Off | 42112 | 256 | 0 |
| IQ2_XS, FP16 accumulation | On | 35008 | 168 | 2048 |
| Q4_0, FP16 accumulation | Off | 41156 | 256 | 0 |
| Q4_0, FP16 accumulation | On | 34056 | 168 | 2048 |

These are static instruction counts, not executed instructions or throughput.
Both FP32-accumulator controls produce byte-identical machine code with the
switch off and on. The compiler pin is Mesa
`ac5ea6cdfe482cc28cced35fa7fc6d69cb7d562f`; shaderc is v2026.4 and the machine
code was decoded by LLVM 22.1.8 with AMDGPU enabled. No GPU submission is needed
for this compiler check. Runtime correctness and model speed are separate tests.

## Comparing one binary

For a baseline that keeps upstream graph fusion, set all four per-change
disable variables. Compare it with the same executable with those variables
unset. Gate/up fusion remains off in the default candidate; use
`GGML_VK_ENABLE_GATE_UP_FUSION` for its separate measurement. To reproduce the
original all-on comparison, set that enable switch, then disable one change at
a time. `GGML_VK_DISABLE_FUSION` is an extra
control that also removes upstream fusion; it is not the isolated new-fusion
comparison.

Use `llama-bench -p 512 -n 128 -r 3 -ngl 99 -fa on -t 6` with the same model,
default batch sizes, driver, clock policy and temperature range. Report prefill
and decode separately. Keep the first-run shader-compilation cost separate from
steady-state measurements. The supplied validation record identifies the tested
artifact, GPU, backend-op cases and model perplexity comparison.
