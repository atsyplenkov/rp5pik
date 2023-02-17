#' Get 50% rain-snow air temperature threshold
#'
#' `r lifecycle::badge('experimental')`
#'
#' @description This function uses 50% rain-snow air temperature threshold map
#' created by *Jennings et al.* ([2018](https://www.nature.com/articles/s41467-018-03629-7))
#' and returns the expected threshold value in a point. Works
#' only for Northern Hemisphere. See *Jennings et al.* ([2018](https://www.nature.com/articles/s41467-018-03629-7))
#' for coverage details.
#'
#' At this temperature precipitation occurs as rain and snow
#' with equal frequency, while above the threshold precipitation
#' is primarily rain and below primarily snow.
#'
#' @param poi SpatVector. A point layer for the Point Of Interest
#'
#' @return A data.frame
#'
#' @references Jennings, K.S., Winchell, T.S., Livneh, B. et al. Spatial variation of the rain–snow temperature threshold across the Northern Hemisphere. Nat Commun 9, 1148 (2018). https://doi.org/10.1038/s41467-018-03629-7
#'
#' @export
#'
#' @import cli
#' @importFrom terra vect project extract rast

rp_get_temp50 <-
  function(
    poi
  ) {

    if (base::any(base::class(poi) == c("sf", "SpatialPointsDataFrame"))) {

      aoi <- terra::vect(poi)
      aoi <- terra::project(aoi, "EPSG:4326")

    } else if (base::any(base::class(poi) == "SpatVector")) {

      aoi <- poi
      aoi <- terra::project(aoi, "EPSG:4326")

    }

    rs_rast <-
      terra::rast("inst/extdata/jennings_et_al_2018_temp50_cog.tiff")

    base::names(rs_rast) <- "temp50"

    rs_rast <- rs_rast / 10^4

    terra::extract(rs_rast, aoi)

  }


# todo --------------------------------------------------------------------

# get_temp50 <-
#   function(
    #     wmo_id = "29231",
#     lat,
#     lon,
#     sf_obj
#   ) {
#
#     # load observed 50% rain-snow threshold
#     obs_file <- "inst/extdata/jennings_et_al_2018_file3_temp50_observed_by_station.Rds"
#       # system.file("extdata2/jennings_et_al_2018_file3_temp50_observed_by_station.Rds",
#                   # package = "rp5pik")
#     obs_rs <-
#       base::readRDS(obs_file)
#
#     # Check if wmo_id is provided
#     if (!base::is.null(wmo_id)) {
#
#       obs_rs_wmo <-
#         base::match(
#           base::as.character(wmo_id),
#           obs_rs$Station_ID
#         )
#
#       if (base::is.na(obs_rs_wmo)) {
#
#         cli::cli_abort(
#           c("x" = "There is no measured 50% temperature
#             rain-snow threshold in Jennings et al. (2018).
#             Please, provide {.var sf_obj} or coordinates
#             ({.var lat} and {.var lon})")
#         )
#
#       } else if (!base::is.na(obs_rs_wmo)) {
#
#         return(obs_rs$temp50[obs_rs_wmo])
#
#       } else {
#
#         cli::cli_abort(
#           c("x" = "Unexpected error!")
#         )
#
#       }
#
#     } else if (base::is.null(wmo_id)) {
#
#       cli::cli_abort(
#         c("x" = "Please, provide {.var sf_obj} or coordinates ({.var lat} and {.var lon})")
#       )
#
#     }
#
#   }
#
# get_temp50()


