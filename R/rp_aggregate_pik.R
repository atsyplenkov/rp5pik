#' Aggregate parsed PiK data
#'
#' `r lifecycle::badge('experimental')`
#'
#' @description This functions calculates from raw data parsed earlier with
#' the [rp5pik::rp_parse_pik()] function to a daily averages. It
#' took rainfall precipitation sums `prec` measured at 06 UTC and 18 UTC
#' to calculate a daily precipitation sums `p` (For European part of Russia).
#' The temperature `t` and other parameters calculates as a daily average.
#'
#' @param .data dataframe. Outcome of the [rp5pik::rp_parse_pik()]
#' function.
#' @param .period character. Either `12h` or `24h` --
#' a string specifying the desired aggregation period. If it equal to
#' `12h` than an average of all parameters preceeding the timestamp
#' will be returned
#' @param .tz character. A string describing timezone of the
#' meteostation of interest. See [lubridate::with_tz()]
#' for details.
#'
#' @return A [tibble::tibble()]
#' @export
#'
#' @import cli
#' @importFrom tidyr fill complete drop_na everything
#' @importFrom dplyr mutate first last na_if group_by
#' @importFrom dplyr summarise ungroup case_when left_join arrange
#' @importFrom lubridate with_tz hour as_date day month year make_datetime
#'
#' @md


rp_aggregate_pik <-
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
      dplyr::arrange(dt, .by_group = TRUE) |>
      tidyr::complete(dt = base::seq.POSIXt(
        from = dplyr::first(dt),
        to = dplyr::last(dt),
        by = "3 hour"
      )) |>
      dplyr::arrange(dt, .by_group = TRUE) |>
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
          p = .sum_na(p12),
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
        mutate(
          datetime_tz = .floor_9h(.dt = dt, .tz = .tz)
        )


      .prec_df <-
        .data_tz |>
        dplyr::mutate(prec = dplyr::na_if(prec, 699)) |>
        dplyr::mutate(
          p12 = dplyr::case_when(
            # for Europe/Moscow tz only!!!!
            lubridate::hour(dt) %in% c(9, 21) ~ prec,
            TRUE ~ NA_real_
          )
        ) |>
        tidyr::drop_na(p12) |>
        dplyr::select(wmo, datetime_tz = dt, p = p12)

      .data_12h |>
        dplyr::group_by(wmo, datetime_tz) |>
        dplyr::summarise(
          # p = .sum_na(p12),
          ta = .mean_na(ta),
          td = .mean_na(td),
          rh = .mean_na(rh),
          ps = .mean_na(ps),
          psl = .mean_na(psl),
          windd = .mean_na(windd),
          winds_mean = .mean_na(winds_mean),
          winds_max = .max_na(winds_max),
          .groups = "drop"
        ) |>
        dplyr::left_join(.prec_df, by = c("wmo", "datetime_tz")) |>
        dplyr::select(wmo, datetime_tz, p, tidyr::everything())

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

#' Helper function to floor datetime object
#'
#' @noRd
.floor_9h <-
  function(.dt, .tz){

    .round <-
      dplyr::if_else(lubridate::hour(.dt) %in% c(10:21),
                     "21:00:00", "09:00:00")

    .round <-
      paste0(lubridate::as_date(.dt), " ", .round)

    .round <-
      lubridate::as_datetime(.round, tz = .tz)

    .round <-
      dplyr::if_else(.round < .dt,
                     .round + lubridate::days(1), .round)

  }
