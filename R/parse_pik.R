#' Parse pogodaiklimat.ru
#'
#' A function to parse \href{http://www.pogodaiklimat.ru/}{http://www.pogodaiklimat.ru/}
#' 3-hourly meteo data.
#'
#' @param wmo_id character. WMO meteostation ID to parse
#' @param start_date character. The beginning of the parsing
#' period. Write date in the following format \code{YYYY-MM-DD}
#' @param end_date character. The end of the parsing period
#' period. Write date in the following format \code{YYYY-MM-DD}
#'
#' @details
#' The function returns a \code{\link[tibble]{tibble}} with
#' following variables:
#'
#' \describe{
#'  \item{wmo}{character. WMO index of the meteostation}
#'  \item{datetime_utc}{POSIXct. Date and Time of the measurement at UTC}
#'  \item{ta}{numeric. Air temperature at 2m above the surface, \eqn{^{\circ}C}}
#'  \item{td}{numeric. Dew point, \eqn{^{\circ}C}}
#'  \item{rh}{numeric. Relative humidity at 2m above the surface, \eqn{\%}}
#'  \item{ps}{numeric. Atmosphere pressure at meteostation, \eqn{hPa}}
#'  \item{psl}{numeric. Atmosphere pressure adjusted to the height of mean sea level, \eqn{hPa}}
#'  \item{prec}{numeric. \bold{Cumulative} precipitation for the last 12 hours, \eqn{mm}}
#'  \item{windd}{integer. Wind direction, \eqn{^{\circ}deg}}
#'  \item{winds_mean}{numeric. Average 10-min wind speed, \eqn{m {\cdot} s^{-1}}}
#'  \item{winds_max}{numeric. Maximum wind speed, \eqn{m {\cdot} s^{-1}}}
#' }
#'
#' @return A \code{\link[tibble]{tibble}}
#' @export
#'
#' @examples
#' library(rp5pik)
#'
#' example <-
#'   parse_pik(
#'     wmo_id = c("20069", "27524"),
#'     start_date = "2022-05-01",
#'     end_date = "2022-05-31"
#'   )
#'
#' example
#'
#' @import cli rvest
#' @importFrom stats time
#' @importFrom lubridate day days_in_month month year make_datetime with_tz force_tz
#' @importFrom stringr str_split
#' @importFrom purrr map_df
#' @importFrom tidyr unnest
#' @importFrom dplyr mutate select
#'

parse_pik <-
  function(wmo_id = "27524",
           start_date = "2022-04-01",
           end_date = "2022-05-31"){

    # Create a sequence of monthes
    .dates <-
      base::seq.Date(
        from = base::as.Date(start_date),
        to = base::as.Date(end_date),
        by = 'month'
      )

    # Helper variables
    # Empty dataframe to write data to
    .all_df <- base::data.frame()
    # Amount of iterations
    .tot_blocks <- base::length(wmo_id) * base::length(.dates)

    # Initialize the progress bar
    cli::cli_progress_bar(
      "Downloading data",
      type = "tasks",
      total = .tot_blocks
    )

    # Double for-loop
    for(i in wmo_id){
      for(d in .dates){

        # create url to parse
        d <-
          base::as.Date(d,
                  origin = '1970-01-01')
        u <-
          base::paste0(
            'http://www.pogodaiklimat.ru/weather.php?id=', i,
            '&bday=', lubridate::day(d),
            '&fday=', lubridate::days_in_month(d),
            '&amonth=', lubridate::month(d),
            '&ayear=', lubridate::year(d),
            '&bot=2'
          )

        pik_one <-
          tryCatch(
            {
              .parse_pik(u, i, lubridate::year(d))
            },
            error = function(e) {
              cli::cli_inform(
                c("i" = "No data at station {i} for {lubridate::month(d, label = TRUE, abbr = FALSE, locale = 'en_us')} {lubridate::year(d)}")
              )
              return(NULL)
            },
            warning = function(w) {
              return(NULL)
            }
          )

        # Add downloaded data to an empty dataframe
        .all_df <- base::rbind(.all_df, pik_one)

        # Progress bar update
        cli::cli_progress_update()
      }
    }

    # End of progress bar
    cli::cli_progress_done()

    if (nrow(.all_df) == 0) {
      cli::cli_abort(c(
        "Your {.var start_date} or {.var end_date} are out of the data range available on the http://www.pogodaiklimat.ru/",
        "x" = "There is no data available from {start_date} to {end_date} period",
        "i" = "Try different period or reduce the amount of stations"
      ))
    }

    .all_df |>
      dplyr::mutate(wind = purrr::map_df(winds,
                                         ~.parse_winds(.x))) |>
      tidyr::unnest(cols = c(wind)) |>
      dplyr::mutate(windd = .parse_windd(windd)) |>
      dplyr::mutate(datetime_utc =
                      lubridate::make_datetime(
                        year = year,
                        month = base::as.integer(stringr::str_split(daymon, "\\.", simplify = T)[,2]),
                        day = base::as.integer(stringr::str_split(daymon, "\\.", simplify = T)[,1]),
                        hour = time, tz = "UTC"
                      ),
                    .before = "ta"
      )  |>
      dplyr::select(
        wmo,
        datetime_utc,
        ta,
        td,
        rh,
        ps,
        psl,
        prec,
        windd,
        winds_mean,
        winds_max
      )

  }

#' Initial parsing function
#'
#' @import rvest
#'
#' @noRd

.parse_pik <-
  function(url, ind, yr){

    tables <-
      rvest::html_nodes(
        rvest::read_html(url), "table"
      )  # парсим по тэгу

    tbl1 <-
      rvest::html_table(tables[[1]],
                        header = F) # список из двух таблиц, в одной - сроки и дата, во второй - данные ??\_(???)_/??
    tbl2 <-
      rvest::html_table(tables[[2]],
                        header = F)

    tbl1 <- tbl1[-1,] # избавляемся от ненужных хэдеров
    tbl2 <- tbl2[-1,]

    # записываем в фрейм
    df <-
      base::data.frame(
        wmo = ind,
        year = yr,
        daymon = base::as.character(tbl1$X2),
        time = base::as.numeric(tbl1$X1),
        ta = base::as.numeric(tbl2$X6),
        td = base::as.numeric(tbl2$X7),
        rh = base::as.numeric(tbl2$X8),
        ps = base::as.numeric(tbl2$X13),
        psl = base::as.numeric(tbl2$X12),
        winds = tbl2$X2,
        windd = tbl2$X1,
        prec = base::as.numeric(tbl2$X16)
      )

    return(df)

  }

#' Parse wind speed
#'
#' @importFrom stringr str_detect
#' @importFrom tibble tibble
#'
#' @noRd

.parse_winds <-
  function(x){

    # Conditions
    con_storm <-
      stringr::str_detect(x, "\\{") & !stringr::str_detect(x, "(-)")
    con_mean <-
      stringr::str_detect(x, "(-)") & !stringr::str_detect(x, "\\{")
    con_mean_storm <-
      stringr::str_detect(x, "(-)") & stringr::str_detect(x, "\\{")

    if (con_storm) {

      .values <-
        .extract_values(x)

      .df <-
        tibble::tibble(
          winds_mean = .values[1],
          winds_max = NA_real_,
          winds_nesrok = .values[2]
        )

      return(.df)

    } else if (con_mean) {

      .values <-
        .extract_values(x)

      .df <-
        tibble::tibble(
          winds_mean = .values[1],
          winds_max = .values[2],
          winds_nesrok = NA_real_
        )

      return(.df)

    } else if (con_mean_storm) {

      .values <-
        .extract_values(x)

      .df <-
        tibble::tibble(
          winds_mean = .values[1],
          winds_max = .values[2],
          winds_nesrok = .values[3]
        )

      return(.df)

    } else {

      .df <-
        tibble::tibble(
          winds_mean = base::as.numeric(x),
          winds_max = NA_real_,
          winds_nesrok = NA_real_
        )

      return(.df)

    }

  }

#' Extract values from a string with wind speed
#'
#' @noRd

.extract_values <-
  function(string) {

    values <- base::strsplit(string, "[{}|-]")[[1]]
    return(base::as.numeric(values))

  }

#' Parse wind direction
#'
#' @importFrom tibble tibble
#'
#' @noRd

.parse_windd <-
  function(x) {

    # С - северный,
    # СВ - северо-восточный,
    # В - восточный,
    # ЮВ - юго-восточный,
    # Ю - южный,
    # ЮЗ - юго-западный,
    # З - западный,
    # СЗ - северо-западный
    # нст - нет данных (?)

    .trans_table <-
      tibble::tibble(
        dir_char =
          c("С", "СВ", "В", "ЮВ", "Ю",
            "ЮЗ", "З", "СЗ", "нст"),
        dir_deg =
          c(0L, 45L, 90L, 135L, 180L,
            225L, 270L, 315L, NA_integer_)
      )

    matches <- base::match(x, .trans_table$dir_char)
    result <- .trans_table$dir_deg[matches]

    return(result)

  }

