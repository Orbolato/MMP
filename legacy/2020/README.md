# Recovered 2020 source snapshot

The source-only archive `MMP_Codes_source.tar.xz` was created from the author's archived `MMP Codes.rar` in October 2026. It contains the five recovered R scripts **without** the confidential Tropical dataset or its derived R workspace.

Archive SHA-256:

```text
270adf676dd23f7386a730d9cd7b14032be052dc358ee0ec0853d24fc7384da2  MMP_Codes_source.tar.xz
```

Contents and original-file SHA-256 hashes:

| File | SHA-256 | Timestamp in recovered RAR |
| --- | --- | --- |
| `generate_data.R` | `25c39a476ff3104f5c94331d85f25b35073dc68106d735f28cb2e49de0f036a3` | 2020-01-05 06:32:38 |
| `mmp_complete.R` | `7ee2c48939ad6769180bdd895e4e1aafbb84f0c6cc9b3f0538332705296b3b75` | 2020-01-05 06:44:08 |
| `mmp_complete_log.R` | `1ea07dc0d39199e20d9d30ee9fd76d8999af5197f0c0a15b61080183c076b81a` | 2020-01-05 06:43:33 |
| `mmp_simples.R` | `655f7a9e91a4e66043eeb5460b0713a4c05c7d678b53e4f9d101953cd87cc7d0` | 2020-01-05 12:31:45 |
| `mmp_simples_log.R` | `51738ff615b9d291a08d6c920f9862a8af7b2433ce156a5bb625865a91096798` | 2020-01-05 06:42:55 |

The original RAR also contained `metro.csv` and `data.RData`. They are deliberately **not** committed. The associated paper states that the Tropical dataset was supplied by São Paulo Metropolitan Company under a confidentiality term.

The recovered source predates the final 2021 paper. It should therefore be read as an authentic development snapshot, not automatically as the exact code that generated every published table. In particular, the paper describes SMOTE oversampling, whereas these scripts generate minority-class rows by averaging `d + 1` randomly selected examples from the same class.
