# Shared helpers for the recovered MMP implementation associated with
# Carvalho & Ribeiro (2021), Soils and Rocks 44(4), e2021072121.
# https://doi.org/10.28927/SR.2021.072121

mmp_required_packages <- function() {
  c("kknn", "kernlab", "randomForest", "C50", "RSNNS")
}

mmp_variant_config <- function(variant = c(
    "complete", "complete_log", "simple", "simple_log")) {
  variant <- match.arg(variant)
  complete_inputs <- list(
    c("Depth_m", "qt_MPa", "fs_kPa", "u_kPa"),
    c("Depth_m", "Qt1", "Fr_p", "Bq"),
    c("Depth_m", "Qtn", "Fr_p", "U2")
  )
  simple_inputs <- list(c("Depth_m", "qc_MPa", "fs_kPa"))

  list(
    name = variant,
    inputs = if (startsWith(variant, "complete")) complete_inputs else simple_inputs,
    signed_log = grepl("_log$", variant),
    legacy_script = paste0("mmp_", variant, ".R")
  )
}

validate_columns <- function(data, columns, data_name = "data") {
  missing <- setdiff(columns, names(data))
  if (length(missing) > 0L) {
    stop(
      sprintf(
        "%s is missing required column(s): %s",
        data_name,
        paste(missing, collapse = ", ")
      ),
      call. = FALSE
    )
  }
  invisible(TRUE)
}

fit_minmax <- function(data, features) {
  validate_columns(data, features)
  mins <- vapply(data[features], min, numeric(1), na.rm = TRUE)
  maxs <- vapply(data[features], max, numeric(1), na.rm = TRUE)
  spans <- maxs - mins
  if (any(!is.finite(mins)) || any(!is.finite(maxs))) {
    stop("Non-finite values found while fitting min-max scaling.", call. = FALSE)
  }
  if (any(spans == 0)) {
    stop(
      sprintf(
        "Cannot scale constant feature(s): %s",
        paste(names(spans)[spans == 0], collapse = ", ")
      ),
      call. = FALSE
    )
  }
  list(min = mins, max = maxs)
}

apply_minmax <- function(data, scaler, features) {
  result <- data
  for (feature in features) {
    result[[feature]] <-
      (result[[feature]] - scaler$min[[feature]]) /
      (scaler$max[[feature]] - scaler$min[[feature]])
  }
  result
}

signed_log_transform <- function(x) {
  # Exact transformation found in the recovered *_log.R scripts.
  sign(x) * log10(1 + (10^2 - 1) * abs(x)) / 2
}

apply_signed_log <- function(data, features) {
  result <- data
  for (feature in features) {
    result[[feature]] <- signed_log_transform(result[[feature]])
  }
  result
}

balanced_accuracy <- function(predicted, observed) {
  predicted <- as.character(predicted)
  observed <- as.character(observed)
  classes <- sort(unique(observed[!is.na(observed)]))
  all_classes <- sort(unique(c(predicted, observed)))
  all_classes <- all_classes[!is.na(all_classes)]
  confusion <- table(
    factor(predicted, levels = all_classes),
    factor(observed, levels = all_classes)
  )
  recalls <- vapply(classes, function(class_value) {
    denominator <- sum(confusion[, class_value])
    if (denominator == 0L) return(NA_real_)
    confusion[class_value, class_value] / denominator
  }, numeric(1))
  mean(recalls, na.rm = TRUE)
}

majority_vote <- function(predictions) {
  if (is.null(dim(predictions))) predictions <- matrix(predictions, nrow = 1L)
  apply(predictions, 1L, function(row) {
    values <- unique(row)
    counts <- tabulate(match(row, values))
    values[[which.max(counts)]]
  })
}

legacy_balance <- function(
    data,
    output,
    features,
    minimum_per_class = 1000L,
    seed = 2021L) {
  # Reproduces the balancing rule implemented in the recovered 2020 scripts:
  # majority classes are randomly downsampled; minority synthetic rows are the
  # feature-wise mean of d+1 randomly selected same-class examples.
  #
  # This is intentionally named "legacy_balance" because the published paper
  # describes SMOTE, whereas the recovered source does not implement canonical
  # SMOTE. We preserve the source behavior rather than silently changing it.
  validate_columns(data, c(features, output))
  classes <- sort(unique(data[[output]]))
  counts <- vapply(
    classes,
    function(value) sum(data[[output]] == value),
    integer(1)
  )
  target <- max(as.integer(minimum_per_class), 2L * min(counts))
  set.seed(seed)
  result <- data

  for (class_value in classes) {
    class_rows <- result[result[[output]] == class_value, , drop = FALSE]
    n_class <- nrow(class_rows)
    if (n_class > target) {
      keep <- sample(seq_len(n_class), target)
      result <- rbind(
        result[result[[output]] != class_value, , drop = FALSE],
        class_rows[keep, , drop = FALSE]
      )
    } else if (n_class < target) {
      d_plus_one <- length(features) + 1L
      if (n_class < d_plus_one) {
        stop(
          sprintf(
            "Class %s has %d rows; at least %d are required.",
            class_value,
            n_class,
            d_plus_one
          ),
          call. = FALSE
        )
      }
      synthetic <- vector("list", target - n_class)
      for (i in seq_along(synthetic)) {
        sampled <- sample(seq_len(n_class), d_plus_one)
        row <- class_rows[1L, , drop = FALSE]
        for (feature in features) {
          row[[feature]] <- mean(class_rows[sampled, feature])
        }
        row[[output]] <- class_value
        synthetic[[i]] <- row
      }
      result <- rbind(result, do.call(rbind, synthetic))
    }
  }
  rownames(result) <- NULL
  result
}

make_validation_fold_map <- function(k = 10L, seed = 2021L) {
  if (k < 2L) stop("k must be at least 2.", call. = FALSE)
  set.seed(seed)
  test_folds <- seq_len(k)
  repeat {
    validation <- sample(test_folds, k, replace = FALSE)
    if (all(validation != test_folds)) return(validation)
  }
}

load_mmp_workspace <- function(path = "data.RData") {
  if (!file.exists(path)) {
    stop(sprintf("Workspace not found: %s", path), call. = FALSE)
  }
  env <- new.env(parent = globalenv())
  loaded <- load(path, envir = env)
  required <- c("dataNet", "foldsNet", "validFolds")
  missing <- setdiff(required, loaded)
  if (length(missing) > 0L) {
    stop(
      sprintf(
        "Workspace is missing required object(s): %s",
        paste(missing, collapse = ", ")
      ),
      call. = FALSE
    )
  }
  env
}

check_legacy_dependencies <- function() {
  missing <- mmp_required_packages()[
    !vapply(mmp_required_packages(), requireNamespace, logical(1), quietly = TRUE)
  ]
  if (length(missing) > 0L) {
    stop(
      sprintf(
        "Missing required package(s): %s",
        paste(missing, collapse = ", ")
      ),
      call. = FALSE
    )
  }
  invisible(TRUE)
}
