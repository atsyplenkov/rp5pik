
<!-- README.md is generated from README.Rmd. Please edit that file -->

# rp5pik <img src="man/figures/rp5pik_logo.png" align="right" height="139" />

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
![GitHub R package
version](https://img.shields.io/github/r-package/v/atsyplenkov/rp5pik?label=github)
![GitHub last
commit](https://img.shields.io/github/last-commit/atsyplenkov/rp5pik)
<!-- badges: end -->

The `rp5pik` package provides a set of functions to download and
preprocess meteorological data from <http://www.pogodaiklimat.ru/>

## Installation

You can install the development version of rp5pik from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("atsyplenkov/rp5pik")
```

## Example

For now there is only one function exists – `parse_pik`. It allows you
to download meteo data at 3h temporal resolution for various stations
using their WMO ID:

``` r
library(rp5pik)

example <-
  parse_pik(
    wmo_id = c("20069", "27524"),
    start_date = "2022-05-01",
    end_date = "2022-05-31"
  )
#> ⠙ 1/2 ETA: 1s | Downloading data

example
#> # A tibble: 496 × 11
#>    wmo   datetime_utc           ta    td    rh    ps   psl  prec windd winds_m…¹
#>    <chr> <dttm>              <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <int>     <dbl>
#>  1 20069 2022-05-01 00:00:00  -7.9  -9.1    91  993   996.   0.8    90         6
#>  2 20069 2022-05-01 03:00:00  -7    -8.2    91  994.  997.  NA      90         7
#>  3 20069 2022-05-01 06:00:00  -7.2  -8.4    91  994.  997.  NA      90         9
#>  4 20069 2022-05-01 09:00:00  -7.7  -8.8    92  994.  998.  NA      90        11
#>  5 20069 2022-05-01 12:00:00  -8.4  -9.5    92  995.  998.   0.6    90        11
#>  6 20069 2022-05-01 15:00:00  -9.8 -11      91  995   998.  NA      45        11
#>  7 20069 2022-05-01 18:00:00 -11.3 -12.7    89  995.  998.  NA      45         9
#>  8 20069 2022-05-01 21:00:00 -14.2 -16      86  995.  999.  NA      45         7
#>  9 20069 2022-05-02 00:00:00 -14.3 -15.9    88  995.  998.  NA      45         6
#> 10 20069 2022-05-02 03:00:00 -11.8 -14.4    81  994.  997.  NA       0         6
#> # … with 486 more rows, 1 more variable: winds_max <dbl>, and abbreviated
#> #   variable name ¹​winds_mean
```

List of available variables:

- `wmo` character. WMO index of the meteostation

- `datetime_utc` POSIXct. Date and Time of the measurement at UTC

- `ta` numeric. Air temperature at 2m above the surface, °C

- `td` numeric. Dew point, °C

- `rh` numeric. Relative humidity at 2m above the surface, %

- `ps` numeric. Atmosphere pressure at meteostation, hPa

- `psl` numeric. Atmosphere pressure adjusted to the height of mean sea
  level, hPa

- `prec` numeric. Cumulative precipitation for the last 12 hours, mm

- `windd` integer. Wind direction, deg

- `winds_mean` numeric. Average 10-min wind speed, m/s

- `winds_max` numeric. Maximum wind speed, m/s

We can visualize the `example` dataset using `ggplot2` as follows:

``` r
library(ggplot2)

example |> 
  ggplot(
    aes(
      x = datetime_utc,
      y = ta,
      group = wmo
    )
  ) +
  geom_line(aes(color = wmo)) +
  labs(
    x = "",
    y = "Average Temperature, °C"
  ) +
  theme_minimal()
```

<img src="man/figures/README-plot-1.png" width="100%" style="display: block; margin: auto;" />

## Roadmap

    rp5pik 📦
    ├── Parser functions for
    │   ├── pogodaiklimat
    │   │   └── rp5pik::parse_pik ☑
    │   ├── rp5 ☐
    │   └── gmvo.skniivh ☐
    └── WMO stations coordinates  ☐
