#!/usr/bin/env Rscript

# Wrapper for executing one preserved 2020 MMP script without modifying its
# historical source. The wrapper validates inputs, unpacks the preservation
# archive into a temporary directory, executes the requested script in an
# isolated environment, and saves the resulting analysis objects.

source(file.path("R", "mmp_core.R"))

args <- commandArgs(trailingOnly = TRUE)

# Return the value immediately following a named command-line option.
value_after <- function(flag, default = NULL) {
  pos <- match(flag, args)
  if (is.na(pos)) return(default)
  if (pos == length(args)) stop(sprintf("%s requires a value.", flag), call. = FALSE)
  args[[pos + 1L]]
}

if ("--help" %in% args) {
  cat(paste(
    "Run one recovered 2020 MMP analysis script in an isolated environment.",
    "",
    "Usage:",
    "  Rscript run_legacy.R --variant complete_log --workspace data.RData",
    "",
    "Variants: complete, complete_log, simple, simple_log",
    "Options:",
    "  --workspace PATH   local RData workspace (default: data.RData)",
    "  --output PATH      saved analysis environment (default: results/<variant>.RData)",
    "",
    "The recovered scripts are intentionally not rewritten by this runner.",
    "They use time-dependent random reseeding internally and should be treated",
    "as historical source, not as a deterministic modern reproduction.",
    sep = "\n"
  ))
  quit(status = 0L)
}

# Resolve the requested public variant to the exact script stored in the
# preservation archive. Variant validation is centralized in mmp_variant_config().
variant <- value_after("--variant", NULL)
if (is.null(variant)) stop("--variant is required.", call. = FALSE)
config <- mmp_variant_config(variant)
workspace <- value_after("--workspace", "data.RData")
output <- value_after(
  "--output",
  file.path("results", paste0("legacy_", config$name, ".RData"))
)
archive <- file.path("legacy", "2020", "MMP_Codes_source.tar.xz")
if (!file.exists(archive)) stop("Recovered source archive is missing.", call. = FALSE)

# Keep historical execution isolated from the caller's global environment. This
# preserves the source as recovered while preventing its objects from polluting
# an interactive R session that launches the wrapper.
check_legacy_dependencies()
env <- load_mmp_workspace(workspace)
source_dir <- tempfile("mmp-source-")
dir.create(source_dir)
utils::untar(archive, exdir = source_dir)
script <- file.path(source_dir, config$legacy_script)
if (!file.exists(script)) {
  stop(sprintf("Recovered script not found in archive: %s", config$legacy_script), call. = FALSE)
}
sys.source(script, envir = env)

# Save only analysis products; the input data and fold objects remain available
# from the original workspace and are excluded to avoid unnecessary duplication.
dir.create(dirname(output), recursive = TRUE, showWarnings = FALSE)
objects <- setdiff(ls(env, all.names = TRUE), c("dataNet", "foldsNet", "validFolds"))
save(list = objects, envir = env, file = output)
message(sprintf("Saved legacy analysis objects to %s", output))
