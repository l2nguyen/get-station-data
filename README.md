# Description
This retrieves all the data from the freestations and saves it as CSVs.

# How to use
The function [get_all_data](get_all_data.R) will retrieve all data for all the stations and save it as a csv into a folder named `data`. Be sure to create the `data` folder first before running this file. It will also update the metadata and save it as in the file station_metadata.csv

[read_data.R](read_data.R) contains two functions:
- get_year_data: This retrieves all the data for a specified data and year
- get_all_data: This retrieves all the data for a specified station. There is the option to keep all the data after a specified date using the `live_data` parameter. 

[metadata.R](metadata.R) contains all functions relating to getting and updating the metadata.

