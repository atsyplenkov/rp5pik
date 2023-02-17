#' Get 50\% rain-snow air temperature threshold
#'
#' @description This function uses 50% rain-snow air temperature threshold map
#' created by \emph{Jennings et al.} (\href{https://www.nature.com/articles/s41467-018-03629-7}{2018})
#' and returns the expected threshold value in a point. Works
#' only for Northern Hemisphere. See \emph{Jennings et al.} (\href{https://www.nature.com/articles/s41467-018-03629-7}{2018})
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

get_temp50 <-
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
      terra::rast("data/jennings_et_al_2018_temp50_cog.tiff")

    base::names(rs_rast) <- "temp50"

    rs_rast <- rs_rast / 10^4

    terra::extract(rs_rast, aoi)

  }
