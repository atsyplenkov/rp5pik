#' Aggregate parsed PiK data
#'
#' This functions calculates from raw data parsed earlier with
#' the [rp5pik::parse_pik()] function to a daily averages. It
#' took rainfall precipitation sums \code{prec} measured at 06 UTC and 18 UTC
#' to calculate a daily precipitation sums \code{p} (For European part of Russia).
#' The temperature \code{t} calculates as a daily average.
#'
#' @param .data dataframe. Outcome of the [rp5pik::parse_pik()]
#' function.
#' @param .period character. Either \code{12h} or \code{24h} --
#' a string specifying the desired aggregation period.
#' @param .tz character. A string describing timezone of the
#' meteostation of interest. See \code{\link[lubridate]{with_tz}}
#' for details.
#'
#' @return A \code{\link[tibble]{tibble}}
#' @export
#'
#' @import cli
#' @importFrom tidyr fill complete
#' @importFrom dplyr mutate first last na_if group_by summarise ungroup case_when
#' @importFrom lubridate with_tz hour as_date day month year make_datetime
#'
#' @md


aggregate_pik <-
  function(
    .data,
    .period = c("24h", "12h"),
    .tz = "Europe/Moscow"
  ){

    if (any(base::is.null(.period), base::length(.period) > 1)) {

      cli::cli_abort(
        c(
          "x" = "Please, indicate the desired aggregation
          period {.var .period}: either {.str 24h} or {.str 12h}"
        )
      )

    }

    .data_tz <-
      .data |>
      dplyr::mutate(
        dt = lubridate::with_tz(datetime_utc, .tz)
      ) |>
      dplyr::group_by(wmo) |>
      tidyr::complete(dt = base::seq.POSIXt(
        from = dplyr::first(dt),
        to = dplyr::last(dt),
        by = "3 hour"
      )) |>
      tidyr::fill(wmo, .direction = "down") |>
      dplyr::ungroup()

    if (.period == "24h") {

      .data_tz |>
        # check for errors
        dplyr::mutate(prec = dplyr::na_if(prec, 699)) |>
        dplyr::mutate(
          p12 = dplyr::case_when(
            # for Europe/Moscow tz only!!!!
            lubridate::hour(dt) %in% c(9, 21) ~ prec,
            TRUE ~ NA_real_
          )
        ) |>
        dplyr::group_by(wmo, date = lubridate::as_date(dt)) |>
        dplyr::summarise(
          p = .sum_na(prec),
          ta = .mean_na(ta),
          td = .mean_na(td),
          rh = .mean_na(rh),
          ps = .mean_na(ps),
          psl = .mean_na(psl),
          windd = .mean_na(windd),
          winds_mean = .mean_na(winds_mean),
          winds_max = .max_na(winds_max),
          .groups = "drop"
        )

    } else if (.period == "12h") {

      .data_12h <-
        .data_tz |>
        dplyr::mutate(prec = dplyr::na_if(prec, 699)) |>
        dplyr::mutate(
          p12 = dplyr::case_when(
            # for Europe/Moscow tz only!!!!
            lubridate::hour(dt) %in% c(9, 21) ~ prec,
            TRUE ~ NA_real_
          )
        ) |>
        dplyr::mutate(
          flag = dplyr::case_when(
            # for Europe/Moscow tz only!!!!
            lubridate::hour(dt) %in% c(4:15) ~ 9,
            !lubridate::hour(dt) %in% c(4:15) ~ 21
          )
        ) %>%
        dplyr::mutate(
          datetime_tz = lubridate::make_datetime(
            year = lubridate::year(dt),
            month = lubridate::month(dt),
            day = lubridate::day(dt),
            hour = flag,
            tz = .tz
          ),
          .after = "wmo"
        )

      .data_12h |>
        dplyr::group_by(wmo, datetime_tz) |>
        dplyr::summarise(
          p = .sum_na(prec),
          ta = .mean_na(ta),
          td = .mean_na(td),
          rh = .mean_na(rh),
          ps = .mean_na(ps),
          psl = .mean_na(psl),
          windd = .mean_na(windd),
          winds_mean = .mean_na(winds_mean),
          winds_max = .max_na(winds_max),
          .groups = "drop"
        )

    } else {

      cli::cli_abort(
        c(
          "x" = "Please, indicate the desired aggregation
          period {.var .period}: either {.str 24h} or {.str 12h}"
        )
      )

    }

  }



#' Helper function to calculate correct sum
#'
#' @noRd
.sum_na <-
  function(.v){

    if (base::all(base::is.na(.v))) {

      return(NA_real_)

    } else {

      base::sum(.v, na.rm = T)

    }

  }

#' Helper function to calculate correct mean
#'
#' @noRd
.mean_na <-
  function(.v){

    if (base::all(base::is.na(.v))) {

      return(NA_real_)

    } else {

      base::mean(.v, na.rm = T)

    }

  }

#' Helper function to calculate correct max
#'
#' @noRd
.max_na <-
  function(.v){

    if (base::all(base::is.na(.v))) {

      return(NA_real_)

    } else {

      base::max(.v, na.rm = T)

    }

  }
