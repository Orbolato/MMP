# Multiple Model Predictor for CPT Soil Classification

Public source-code repository associated with:

**Lucas O. Carvalho and Dimas B. Ribeiro, “A multiple model machine learning approach for soil classification from cone penetration test data,” _Soils and Rocks_, 44(4), 2021, e2021072121.**

- DOI: https://doi.org/10.28927/SR.2021.072121
- Journal page: https://www.soilsandrocks.com/sr-2021-072121

## What the paper does

The study compares five supervised machine-learning techniques for reproducing CPT-based soil classification systems—Gaussian distance-weighted nearest neighbors (DWNN), boosted decision trees (DT), random forests (RF), artificial neural networks (ANN), and support vector machines (SVM)—and combines their predictions in a heterogeneous ensemble called the **multiple model predictor (MMP)** using majority voting.

The paper evaluates three CPT datasets and several feature combinations using a 10-fold train/validation/test protocol and balanced accuracy (mean class recall). The published preprocessing includes outlier screening plus edited nearest neighbors, class balancing, and a logarithmic input transformation for ANN/SVM/MMP analyses.

## Repository status

The original GitHub repository contained only short Markdown instructions and referenced source files that were no longer present. In October 2026, an archived author copy (`MMP Codes.rar`) was recovered. The recovered R scripts are preserved byte-for-byte in a source-only archive under [`legacy/2020/`](legacy/2020/README.md).

This distinction matters: the recovered scripts are dated January 2020, while the article was submitted in May 2021. They are authentic development source, but they should **not** be described as guaranteed byte-for-byte final-paper reproduction code.

### Recovered variants

- `mmp_complete.R`: three four-variable CPT input families, linear min-max scaling path;
- `mmp_complete_log.R`: same input families with the recovered signed logarithmic transformation;
- `mmp_simples.R`: `Depth_m`, `qc_MPa`, and `fs_kPa`, without the logarithmic transform;
- `mmp_simples_log.R`: the same three-input experiment with the logarithmic transform;
- `generate_data.R`: historical script used to build folds/workspace from the Tropical dataset.

The recovered implementation contains the five base learners and the MMP majority-voting ensemble.

## Important reproducibility note

There is one material difference between the recovered 2020 source and the final paper that should remain visible rather than being silently “fixed.” The paper describes minority-class balancing with **SMOTE**. The recovered scripts instead generate a synthetic minority example by taking the feature-wise mean of `d + 1` randomly selected examples from the same class, while majority classes are randomly downsampled.

For that reason, this cleanup preserves the recovered scripts unchanged in `legacy/2020/MMP_Codes_source.tar.xz`. The shared helper `R/mmp_core.R` names that behavior `legacy_balance()` instead of calling it SMOTE.

The historical code is also not fully deterministic: `generate_data.R` resets the seed from system randomness when selecting validation folds, and the MMP scripts repeatedly derive seeds from the current time during balancing. The cleaned workspace generator therefore provides an explicit seed for new runs, while the original behavior remains preserved in the legacy directory.

## Confidential Tropical dataset

The archive contained `metro.csv` (41,381 CPT rows) and a derived `data.RData`. They are **not distributed in this public repository**. The paper states that the Tropical dataset was provided by São Paulo Metropolitan Company under a confidentiality term, so publishing those files here would be inappropriate without separate authorization.

Both names are explicitly ignored by `.gitignore`.

## Repository structure

```text
.
├── R/
│   └── mmp_core.R                 # Tested shared helpers and recovered-method utilities
├── legacy/2020/
│   ├── README.md                  # Provenance, checksums, and methodological note
│   └── MMP_Codes_source.tar.xz    # Exact recovered R source only; no confidential data
├── generate_data.R                # Deterministic local workspace generator
├── run_legacy.R                   # Command-line runner for recovered scripts
├── tests/test_core.R              # Static/core regression checks
├── CITATION.cff
└── .github/workflows/tests.yml
```

## Requirements

The recovered scripts use R and the following packages:

```r
install.packages(c("kknn", "kernlab", "randomForest", "C50", "RSNNS", "caret"))
```

They were originally developed with an older R environment. Modern package versions may produce numerical differences or require compatibility adjustments; the legacy scripts are intentionally preserved rather than rewritten in place.

## Create a local workspace

If you are authorized to use the Tropical dataset and have a local `metro.csv` file:

```bash
Rscript generate_data.R --input metro.csv --output data.RData --seed 2021
```

The cleaned generator creates stratified 10-fold partitions reproducibly. This is a **new reproducible partition**, not a claim to recover the exact historical random folds unless you already possess the archived `data.RData`.

## Run a recovered analysis

For example:

```bash
Rscript run_legacy.R --variant complete_log --workspace data.RData
```

Available variants are:

```text
complete
complete_log
simple
simple_log
```

The wrapper runs the recovered source in an isolated R environment and stores its resulting objects under `results/`. It does not change the historical tuning, balancing, or ensemble logic.

## Methodological mapping

The recovered implementation includes:

- Gaussian DWNN with Euclidean distance;
- boosted C5.0 decision trees;
- 500-tree random forests;
- multilayer perceptron ANN models;
- polynomial-kernel SVM models;
- majority voting across ANN, DT, RF, SVM, and DWNN predictions;
- class-wise mean recall as the reported predictive-performance measure;
- 10-fold testing with a separate validation fold;
- training-set min-max scaling;
- IQR candidate screening followed by one-nearest-neighbor editing.

These components closely mirror the published framework, while the recovered-source/paper differences described above remain explicitly documented.

## Tests

```bash
Rscript tests/test_core.R
```

The tests parse all recovered scripts and check the shared definitions for input variants, the signed-log transform, balanced accuracy, majority voting, and recovered balancing behavior. GitHub Actions runs the same checks automatically.

## Citation

If this repository supports your work, please cite the article:

```text
Carvalho, L. O., & Ribeiro, D. B. (2021).
A multiple model machine learning approach for soil classification from
cone penetration test data. Soils and Rocks, 44(4), e2021072121.
https://doi.org/10.28927/SR.2021.072121
```

GitHub can also read the repository-level `CITATION.cff` file and expose a ready-to-copy citation.

## License

No separate software license has been assigned to this repository. The article itself is open access, but that does not automatically establish a software license for the recovered source code.
