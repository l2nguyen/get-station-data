# gets metadata from google sheet
get_metadata <- function(){
  # load package to access googlesheet -> will need authentication
  require(googlesheets4)

  station_meta <- googlesheets4::read_sheet("1Ye3sTA6W6N0LOMHkA5wOxt22gYDMWdwycZsCbBBuXmA")

  return(station_meta)
}

# gets deployed date
get_deployed_date <- function(data, station){
  require(dplyr)

  deployed_date <- data %>%
    dplyr::filter(FID==station) %>%
    pull(deployed)

  if (is.null(deployed_date)){
    # if no match, return error
    stop("No match for station. Please check station name.")
  } else {
    # return as date as string
    return(format(deployed_date, "%Y-%m-%d"))
  }
}

update_meta <- function(meta, station, data){

  # get last record
  last_record <- data[which(data["unix_time_secs"]== max(data$unix_time_secs)),]

  #=== DATE OF LAST RECORDING BY STATION
  # change to character if not character
  if (!is.character(meta$last_record)){
    meta$last_record <- as.character(meta$last_record)
  }

  meta[which(meta["FID"] == station), "last_record"] <- as.character(last_record$date_gmt)

  #=== CURRENT FIRMWARE
  if (!is.character(meta$fware_current)){
    meta$fware_current <- as.character(meta$fware_current)
  }

  meta[which(meta["FID"] == station), "fware_current"] <- last_record$firmware_version_unique_number

  #=== UPDATE DATE
  if (!is.character(meta$data_updated)){
    meta$data_updated <- as.character(meta$data_updated)
  }

  meta[which(meta["FID"] == station), "data_updated"] <- format(Sys.Date(), "%Y-%m-%d")

  return(meta)
}
