library(readr)
library(dplyr)
library(here)

# look at later
# http://www1.policysupport.org/cgi-bin/ecoengine/fsl.cgi?action=SendTR

get_year_data <- function(station = NULL, year = NULL){
  require(readr)
  require(dplyr)
  require(stringr)
  require(janitor)
  require(lubridate)

  # turn off scientific notation
  options(scipen=999)

  # Check variables
  if (is.null(station)) {
    stop("Station missing. Specify station.")
  }

  # set year to get
  if (is.null(year)){
    year_to_get <- as.integer(format(Sys.Date(), "%Y"))
  } else if (is.character(year)) {
    year_to_get <- as.integer(year)
  } else {
    year_to_get <- year
  }

  # base url for all data
  base_url <- "http://www1.policysupport.org/cgi-bin/ecoengine/fsl.cgi?action=Data2Dash&Query=SendAllData&AutoRange=False&NoFilter=True&NoRemove=True&ChartType=Line&FilterDates=1Y&format=CSV&notFilterVars=TM"

  data_url <- paste0(base_url, "&FID=", station, "&year=", year_to_get, "&")

  # get column names
  column_names <- invisible(colnames(readr::read_csv(data_url, skip=1, n_max=0)))

  # check for errors
  #first_part <- tolower(stringr::str_extract(column_names[1], "^(.*?)\\.\\s"))
  any_error <- stringr::str_detect(tolower(column_names), "error")
  if (sum(any_error) > 0){
    message("ERROR GETTING DATA. THERE IS PROBABLY NO DATA FOR ", year_to_get, ".")
    output_df <- NULL
  } else {
    # clean column names
    cols <- column_names[!(column_names %in% "HH:MM)")]
    cleaner_cols <- gsub("<br>", "", cols)
    #dot_names <- tolower(make.names(cols))
    #clean_names <- gsub("\\.+", "_", gsub("\\.+$", "", dot_names))
    # read data with no column, skip first row
    raw_df <- readr::read_csv(data_url, col_names=cleaner_cols, skip=2)

    output_df <- raw_df %>%
      # clean column names
      janitor::clean_names() %>%
      # remove line breaks
      dplyr::mutate_all(~gsub("<br>", "", .)) %>%
      # change column types
      dplyr::mutate(unix_time_secs = as.integer(unix_time_secs)) %>%
      # drop empty rows
      janitor::remove_empty(which = c("rows", "cols")) %>%
      # add station name
      mutate(station = station) %>%
      # convert date column to datetime
      dplyr::mutate(date_gmt = lubridate::dmy_hms(date_dd_mm_yyyy, tz="gmt")) %>%
      dplyr::mutate(record_number_incremental = as.integer(record_number_incremental)) %>%
      dplyr::mutate_at(vars("rainfall_mm", "air_temperature_deg_c",
                            "humidity_percent"), as.numeric) %>%
      dplyr::mutate_at(vars(starts_with("soil_moisture")), as.numeric) %>%
      dplyr::select(station, unix_time_secs, date_gmt, everything(), -date_dd_mm_yyyy)

    # for columns that may not be in every station data
    if ("distance_1_metres" %in% colnames(output_df)){
      output_df$distance_1_metres <- as.numeric(output_df$distance_1_metres)
    }
  }

  return(output_df)
}

# test_deployed <- get_deployed_date("L131")

# get all data for a station
get_all_data <- function(station = NULL, live_date=NULL){
  require(readr)
  require(dplyr)
  require(lubridate)

  # Check variables
  if (is.null(station)) {
    stop("Station missing. Specify station.")
  }

  # set current year
  curr_year <- as.integer(format(Sys.Date(), "%Y"))
  deployed_year <-as.integer(lubridate::year(lubridate::ymd(live_date)))

  years_to_fetch <- deployed_year:curr_year

  years_list <- lapply(years_to_fetch, get_year_data, station=station)
  # drop nulls
  nulls_removed <- years_list[lengths(years_list) > 0]

  if (janitor::compare_df_cols_same(nulls_removed)){
    all_data <- dplyr::bind_rows(nulls_removed)
  } else{
    warning("Columns are different between the years.")
    all_data <- dplyr::bind_rows(nulls_removed)
  }

  # if no live date, then
  if (is.null(live_date)){
    trimmed_data <- all_data
  } else {
    trimmed_data <- filter(all_data, date_gmt >= lubridate::ymd(live_date))
  }

  return(trimmed_data)
}
