#!/usr/bin/env Rscript
source(file.path("R", "mmp_core.R"))

assert_true <- function(value, message) {
  if (!isTRUE(value)) stop(message, call. = FALSE)
}
assert_equal <- function(a, b, tolerance = 1e-10, message = "Assertion failed") {
  if (!isTRUE(all.equal(a, b, tolerance = tolerance, check.attributes = FALSE))) {
    stop(message, call. = FALSE)
  }
}

for (file in c(file.path("R", "mmp_core.R"), "generate_data.R", "run_legacy.R")) {
  parse(file = file)
}

archive <- file.path("legacy", "2020", "MMP_Codes_source.tar.xz")
assert_true(file.exists(archive), "Recovered source archive is missing")
source_dir <- tempfile("mmp-test-")
dir.create(source_dir)
utils::untar(archive, exdir = source_dir)
legacy_files <- c(
  "generate_data.R",
  "mmp_complete.R",
  "mmp_complete_log.R",
  "mmp_simples.R",
  "mmp_simples_log.R"
)
for (file in legacy_files) parse(file = file.path(source_dir, file))

assert_true(length(mmp_variant_config("complete")$inputs) == 3L, "Complete variant must have 3 input sets")
assert_true(length(mmp_variant_config("simple")$inputs) == 1L, "Simple variant must have 1 input set")
assert_true(mmp_variant_config("complete_log")$signed_log, "Log variant flag is wrong")
assert_equal(
  signed_log_transform(c(0, 1)),
  c(0, 1),
  message = "Signed-log transform regression failed"
)
assert_equal(
  balanced_accuracy(c(1, 1, 2, 2), c(1, 2, 2, 2)),
  (1 + 2 / 3) / 2,
  message = "Balanced-accuracy regression failed"
)

votes <- matrix(c(
  1, 1, 2, 2, 1,
  3, 4, 3, 4, 5
), nrow = 2L, byrow = TRUE)
assert_equal(
  majority_vote(votes),
  c(1, 3),
  message = "Majority-vote regression failed"
)

validation <- make_validation_fold_map(k = 10L, seed = 2021L)
assert_true(length(unique(validation)) == 10L, "Validation folds must be used without replacement")
assert_true(all(validation != seq_len(10L)), "Validation fold cannot equal test fold")

sample_data <- data.frame(
  x = c(1, 2, 3, 10, 11, 12),
  y = c(2, 3, 4, 20, 21, 22),
  class = c(1, 1, 1, 2, 2, 2)
)
balanced <- legacy_balance(
  sample_data,
  output = "class",
  features = c("x", "y"),
  minimum_per_class = 3L,
  seed = 7L
)
assert_true(length(unique(table(balanced$class))) == 1L, "Legacy balancing failed")

cat("All MMP core/static tests passed.\n")
