library(dplyr)
library(readr)
library(here)
library(googlesheets4)

source(here("metadata.R"))
source(here("read_data.R"))

# get station metadata from google sheet
station_meta <- get_metadata()

for (i in seq_len(nrow(station_meta))) {
  curr_fid <- station_meta$FID[i]

  df <- get_all_data(station = curr_fid,
                     live_date = get_deployed_date(station_meta, curr_fid))

  # update metadata
  station_meta <- update_meta(station_meta, curr_fid, df)

  write_csv(df, path=here("data", paste0("station_", curr_fid, ".csv")), na="")
}

write_csv(station_meta, path=here("data", paste0("station_metadata.csv")), na="")
