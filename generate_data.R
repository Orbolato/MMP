#!/usr/bin/env Rscript

source(file.path("R", "mmp_core.R"))

args <- commandArgs(trailingOnly = TRUE)
value_after <- function(flag, default = NULL) {
  pos <- match(flag, args)
  if (is.na(pos)) return(default)
  if (pos == length(args)) stop(sprintf("%s requires a value.", flag), call. = FALSE)
  args[[pos + 1L]]
}

if ("--help" %in% args) {
  cat(paste(
    "Create a local MMP workspace from an authorized Tropical CPT CSV file.",
    "",
    "Usage:",
    "  Rscript generate_data.R --input metro.csv [--output data.RData] [--seed 2021]",
    "",
    "The Tropical dataset is not distributed by this repository because the",
    "paper states that it was supplied under a confidentiality term.",
    sep = "\n"
  ))
  quit(status = 0L)
}

input_path <- value_after("--input", "metro.csv")
output_path <- value_after("--output", "data.RData")
seed <- suppressWarnings(as.integer(value_after("--seed", "2021")))
if (is.na(seed)) stop("--seed must be an integer.", call. = FALSE)
if (!file.exists(input_path)) {
  stop(sprintf("Input CSV not found: %s", input_path), call. = FALSE)
}
if (!requireNamespace("caret", quietly = TRUE)) {
  stop("Package 'caret' is required to generate folds.", call. = FALSE)
}

dataNet <- utils::read.csv(input_path, check.names = FALSE)
validate_columns(dataNet, c("SBTn", "MSBTn"), "input data")
set.seed(seed)
foldsNet <- caret::createFolds(dataNet$SBTn, k = 10L, list = TRUE, returnTrain = FALSE)
validFolds <- make_validation_fold_map(k = 10L, seed = seed + 1L)
save(dataNet, foldsNet, validFolds, file = output_path)
message(sprintf("Saved reproducible workspace to %s", output_path))
