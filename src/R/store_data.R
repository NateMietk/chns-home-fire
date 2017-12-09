# Libraries ---------------------------------------------------------------
x <- c("data.table", "tidyverse", "magrittr", "sf", "gridExtra", "rgdal",
       "assertthat", "purrr", "httr", "rvest", "lubridate", "parallel", "raster")
lapply(x, library, character.only = TRUE, verbose = FALSE)

# Load helper functions for external script
source("src/R/functions/st_par.R")

# Raw data folders
prefix <- file.path("data")
raw_prefix <- file.path(prefix, "raw") 
us_prefix <- file.path(raw_prefix, "cb_2016_us_state_20m")
ecoregion_prefix <- file.path(raw_prefix, "us_eco_l3")
fpa_prefix <- file.path(raw_prefix, "fpa-fod")
mtbs_prefix <- file.path(raw_prefix, "mtbs_fod_perimeter_data")

# Prepare output directories
bounds_crt <- file.path(prefix, "bounds")
conus_crt <- file.path(bounds_crt, "conus")
ecoreg_crt <- file.path(bounds_crt, "ecoregion")
anthro_crt <- file.path(prefix, "anthro")
fire_crt <- file.path(prefix, "fire")
climate_crt <- file.path(prefix, "climate")

us_out <- file.path(conus_crt, "cb_2016_us_state_20m")
ecoregion_out <- file.path(bounds_crt, "ecoregion", "us_eco_l3")
wui_out <- file.path(anthro_crt, "us_wui_2010")
fpa_out <- file.path(fire_crt, "fpa-fod")
mtbs_out <- file.path(fire_crt, "mtbs_fod_perimeter_data")
tmean_dir <- file.path(climate_crt, "tmean")
tmean_mnth <- file.path(tmean_dir, "monthly_mean")

# Check if directory exists for all variable aggregate outputs, if not then create
var_dir <- list(prefix, raw_prefix, us_prefix, ecoregion_prefix, climate_crt, tmean_dir, tmean_mnth,
                fpa_prefix, mtbs_prefix, bounds_crt, conus_crt, ecoreg_crt, 
                anthro_crt, fire_crt, us_out, ecoregion_out, wui_out, fpa_out, mtbs_out)
lapply(var_dir, function(x) if(!dir.exists(x)) dir.create(x, showWarnings = FALSE))
