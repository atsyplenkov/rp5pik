
<!-- README.md is generated from README.Rmd. Please edit that file -->

# rp5pik <img src="man/figures/rp5pik_logo.png" align="right" height="139" />

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![CRAN
status](https://www.r-pkg.org/badges/version/rp5pik)](https://CRAN.R-project.org/package=rp5pik)
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

# OR

# install.packages("remotes")
remotes::install_github("atsyplenkov/rp5pik")
```

## Examples

### 1. Data download

Below is an example for `parse_pik` functions. It allows you to download
meteo data at **3-hour** temporal resolution for various stations using
their WMO ID from <http://www.pogodaiklimat.ru/>:

``` r
library(rp5pik)

example <-
  parse_pik(
    wmo_id = c("20069", "27524"),
    start_date = "2022-05-01",
    end_date = "2022-05-31"
  )

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

<img src="man/figures/README-plot-1.png" width="80%" style="display: block; margin: auto;" />

### 2. Data preprocessing

Since the downloaded with `parse_pik` data contains raw data, it
requires additional checking and cleaning. We suggest to explore the raw
dataset by yourselves before any further manipulations.

However, the `rp5pik` package has a function to aggregate raw data on
daily (`24h`) or semi-daily (`12h`) periods. The `aggregate_pik`
function removes known error codes from precipitation data (`699`
values). Additionally, it calculates daily precipitation sums based on
measured precipitation at 06 UTC and 18 UTC in European part of Russia
(see [meteostation manuals for more
info](https://method.meteorf.ru/ansambl/pojasnenijaansambl.html)).

⚠ As of 2023-02-17 this function works only with Moscow timezone.

This is how you can aggregate data daily:

``` r
library(dplyr)

example_daily <- 
  example |> 
  aggregate_pik(.period = "24h") |> 
  group_split(wmo)

example_daily
#> <list_of<
#>   tbl_df<
#>     wmo       : character
#>     date      : date
#>     p         : double
#>     ta        : double
#>     td        : double
#>     rh        : double
#>     ps        : double
#>     psl       : double
#>     windd     : double
#>     winds_mean: double
#>     winds_max : double
#>   >
#> >[2]>
#> [[1]]
#> # A tibble: 32 × 11
#>    wmo   date           p     ta     td    rh    ps   psl windd winds_…¹ winds…²
#>    <chr> <date>     <dbl>  <dbl>  <dbl> <dbl> <dbl> <dbl> <dbl>    <dbl>   <dbl>
#>  1 20069 2022-05-01   1.4  -8.47  -9.67  91    994.  998.  77.1     9.14      13
#>  2 20069 2022-05-02   0.3 -12.9  -14.9   85    992.  995. 129.      6.12      10
#>  3 20069 2022-05-03   0.8 -16.0  -19.0   77.8  988.  992. 152.      2.25      NA
#>  4 20069 2022-05-04   0.3 -14.3  -17.4   77.2  996.  999. 248.      5.38      10
#>  5 20069 2022-05-05  NA   -14.2  -16.0   86.6  998. 1002.  67.5     3.38      NA
#>  6 20069 2022-05-06  NA   -12.6  -14.3   87.2  994.  997. 253.      4.12      NA
#>  7 20069 2022-05-07   0.7  -9.31 -11.1   86.9  999. 1002. 231.      3.12      NA
#>  8 20069 2022-05-08  NA    -6.88  -8.25  90.1  999. 1003. 152.      9.25      18
#>  9 20069 2022-05-09   2.3  -7.19  -9.02  86.6  991.  995. 202.      9.62      17
#> 10 20069 2022-05-10   0.6  -7.25  -8.89  88    987.  990. 197.      7.75      12
#> # … with 22 more rows, and abbreviated variable names ¹​winds_mean, ²​winds_max
#> 
#> [[2]]
#> # A tibble: 32 × 11
#>    wmo   date           p    ta     td    rh    ps   psl windd winds_m…¹ winds…²
#>    <chr> <date>     <dbl> <dbl>  <dbl> <dbl> <dbl> <dbl> <dbl>     <dbl>   <dbl>
#>  1 27524 2022-05-01  NA    7.21 -5.59   43    996. 1023.  238.      3.71      NA
#>  2 27524 2022-05-02   0    9.85 -2.4    44.1  991. 1018.  199.      3         NA
#>  3 27524 2022-05-03  NA   11.6   1.54   53.9  982. 1008.  231.      5.88      13
#>  4 27524 2022-05-04   0.6  6    -1.14   60.5  985. 1012.  298.      5.25      14
#>  5 27524 2022-05-05  NA    5.24 -6.68   45.5  997. 1025.  248.      3.75      NA
#>  6 27524 2022-05-06  NA    9.59 -5.91   34.2 1001. 1028.  191.      3.5       NA
#>  7 27524 2022-05-07  NA   13.1  -2.59   34.2  999. 1025.  180       3.62      11
#>  8 27524 2022-05-08   1   13.6   2.17   47.8  992. 1019.  208.      4.75      11
#>  9 27524 2022-05-09   2.6  6.99  0.575  64.2  994. 1021.  158.      6.25      14
#> 10 27524 2022-05-10   0    6.62 -3.5    50.6  992. 1019.  158.      7.38      17
#> # … with 22 more rows, and abbreviated variable names ¹​winds_mean, ²​winds_max
```

Or semi-daily:

``` r
library(dplyr)

example_12h <- 
  example |> 
  aggregate_pik(.period = "12h") |> 
  group_split(wmo)

example_12h
#> <list_of<
#>   tbl_df<
#>     wmo        : character
#>     datetime_tz: datetime<Europe/Moscow>
#>     p          : double
#>     ta         : double
#>     td         : double
#>     rh         : double
#>     ps         : double
#>     psl        : double
#>     windd      : double
#>     winds_mean : double
#>     winds_max  : double
#>   >
#> >[2]>
#> [[1]]
#> # A tibble: 63 × 11
#>    wmo   datetime_tz             p     ta     td    rh    ps   psl windd winds…¹
#>    <chr> <dttm>              <dbl>  <dbl>  <dbl> <dbl> <dbl> <dbl> <dbl>   <dbl>
#>  1 20069 2022-05-01 09:00:00   0.6  -7.58  -8.72  91.5  994.  997.  90      9.5 
#>  2 20069 2022-05-01 21:00:00   0.8  -9.67 -10.9   90.3  994.  998.  60      8.67
#>  3 20069 2022-05-02 09:00:00   0.3 -11.6  -13.7   84.2  992.  995.  78.8    6.5 
#>  4 20069 2022-05-02 21:00:00  NA   -14.2  -16.0   85.8  992.  995  180      5.75
#>  5 20069 2022-05-03 09:00:00   0.3 -15.7  -18.8   77.2  988.  992. 112.     1.5 
#>  6 20069 2022-05-03 21:00:00   0.5 -16.4  -19.3   78.2  989.  992. 191.     3   
#>  7 20069 2022-05-04 09:00:00   0   -13.8  -16.6   79.5  996.  999. 236.     6.25
#>  8 20069 2022-05-04 21:00:00   0.3 -14.7  -18.2   75    996.  999. 259.     4.5 
#>  9 20069 2022-05-05 09:00:00  NA   -12.9  -14.8   86.2  999. 1002.  45      3.25
#> 10 20069 2022-05-05 21:00:00  NA   -15.4  -17.1   87    998. 1001.  90      3.5 
#> # … with 53 more rows, 1 more variable: winds_max <dbl>, and abbreviated
#> #   variable name ¹​winds_mean
#> 
#> [[2]]
#> # A tibble: 63 × 11
#>    wmo   datetime_tz             p    ta     td    rh    ps   psl windd winds_…¹
#>    <chr> <dttm>              <dbl> <dbl>  <dbl> <dbl> <dbl> <dbl> <dbl>    <dbl>
#>  1 27524 2022-05-01 09:00:00  NA    7.58 -5.98   40.8  997. 1024.  236.     3.75
#>  2 27524 2022-05-01 21:00:00  NA    6.73 -5.07   46    995. 1022.  240      3.67
#>  3 27524 2022-05-02 09:00:00  NA   10.4  -3.2    41.5  992. 1019.  225      3.25
#>  4 27524 2022-05-02 21:00:00   0    9.25 -1.6    46.8  991. 1017.  180      2.75
#>  5 27524 2022-05-03 09:00:00  NA   12.3   2.32   54.8  982. 1008.  214.     6.5 
#>  6 27524 2022-05-03 21:00:00  NA   10.9   0.75   53    983. 1009.  248.     5.25
#>  7 27524 2022-05-04 09:00:00   0.3  5.65 -0.325  65.2  985. 1012.  304.     6.25
#>  8 27524 2022-05-04 21:00:00   0.3  6.35 -1.95   55.8  986. 1013.  292.     4.25
#>  9 27524 2022-05-05 09:00:00  NA    5.62 -7.18   42    998. 1025.  236.     4.5 
#> 10 27524 2022-05-05 21:00:00  NA    4.85 -6.18   49    997. 1024.  259.     3   
#> # … with 53 more rows, 1 more variable: winds_max <dbl>, and abbreviated
#> #   variable name ¹​winds_mean
```

## Roadmap

    rp5pik 📦
    ├── Parser functions for
    │   ├── pogodaiklimat
    │   │   ├── rp5pik::parse_pik ✅
    │   │   └── rp5pik::aggregate_pik ✅
    │   ├── rp5 🔲
    │   └── gmvo.skniivh 🔲
    ├── WMO stations coordinates  🔲
    └── Rain/Snow guessing  ✅
