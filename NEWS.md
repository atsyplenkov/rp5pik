# rp5pik 0.0.2.2

* The previous update contained a critical issue with time aggregating, therefore the `.period` param from `rp_aggregate_pik` has been removed. Currently the aggregation in semi-daily format is working only in left direction, i.e. it calculates a mean value of all params before the timestamp.

# rp5pik 0.0.2.1

* Added new variable to `rp_aggregate_pik` controlling the aggregation direction: left or center. Still works only with "Europe/Moscow" timezone

# rp5pik 0.0.2

* Minor improvements in `rp_parse_pik` description and dependencies.
* Added function `rp_aggregate_pik` to summarise meteo data on a daily or 12-hours basis
* New function `rp_get_temp50` for detecting a 50% rain-snow air temperature treshold based on the work by *Jennings et al. ([2018](https://www.nature.com/articles/s41467-018-03629-7))*


# rp5pik 0.0.1

* Initial version with `rp_parse_pik` functionality.
