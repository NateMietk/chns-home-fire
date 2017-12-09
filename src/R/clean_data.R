
ncores <- 2

proj_ea <- "+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=37.5 +lon_0=-9+x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs"

usa_shp <- st_read(dsn = us_prefix,
                   layer = "cb_2016_us_state_20m", quiet= TRUE) %>%
  st_transform(p4string_ea) %>%  # e.g. US National Atlas Equal Area
  filter(!(NAME %in% c("Alaska", "Hawaii", "Puerto Rico"))) %>%
  mutate(area_m2 = as.numeric(st_area(geometry)),
         StArea_km2 = area_m2/1000000,
         group = 1) %>%
  st_simplify(., preserveTopology = TRUE)
names(usa_shp) %<>% tolower

# Dissolve to the USA Boundary
conus <- usa_shp %>%
  st_union()

# Import the Level 1 Ecoregions
ecoreg1 <- st_read(dsn = ecoregion_prefix, layer = "NA_CEC_Eco_Level1", quiet= TRUE) %>%
  st_par(., st_transform, n_cores = ncores, crs = p4string_ea) %>%
  st_intersection(., st_union(usa_shp)) %>%
  select(NA_L1CODE, NA_L1NAME) %>%
  mutate(ecoreg1.code = NA_L1CODE,
         ecoreg1.name = NA_L1NAME,
         ecoreg1_km2 = as.numeric(st_area(geometry))/1000000,
         region = as.factor(if_else(NA_L1NAME %in% c("EASTERN TEMPERATE FORESTS",
                                                     "TROPICAL WET FORESTS",
                                                     "NORTHERN FORESTS"), "East",
                                    if_else(NA_L1NAME %in% c("NORTH AMERICAN DESERTS",
                                                             "SOUTHERN SEMIARID HIGHLANDS",
                                                             "TEMPERATE SIERRAS",
                                                             "MEDITERRANEAN CALIFORNIA",
                                                             "NORTHWESTERN FORESTED MOUNTAINS",
                                                             "MARINE WEST COAST FOREST"), "West", "Central")))) %>%
  group_by(region) %>%
  summarize()
names(ecoreg1) %<>% tolower
plot(ecoreg1["region"])

st_write(ecoreg1, "data/bounds/ecoregion/east-central-west/ecoreg1_ecw.shp")

# Clean the FPA database class
fpa_fire <- st_read(dsn = file.path(fpa_gdb),
                    layer = "Fires", quiet= FALSE) %>%
  filter(!(STATE %in% c("Alaska", "Hawaii", "Puerto Rico") & FIRE_SIZE >= 0.1)) %>%
  dplyr::select(FPA_ID, LATITUDE, LONGITUDE, ICS_209_INCIDENT_NUMBER, ICS_209_NAME, MTBS_ID, MTBS_FIRE_NAME,
                FIRE_YEAR, DISCOVERY_DATE, DISCOVERY_DOY, STAT_CAUSE_DESCR, FIRE_SIZE, STATE) %>%
  mutate(IGNITION = ifelse(STAT_CAUSE_DESCR == "Lightning", "Lightning", "Human"),
         FIRE_SIZE_m2 = FIRE_SIZE*4046.86,
         FIRE_SIZE_km2 = FIRE_SIZE_m2/1000000,
         FIRE_SIZE_ha = FIRE_SIZE_m2*10000,
         DISCOVERY_DAY = day(DISCOVERY_DATE),
         DISCOVERY_MONTH = month(DISCOVERY_DATE),
         DISCOVERY_YEAR = FIRE_YEAR)
fpa_fire <- st_transform(fpa_fire, p4string_ea)

#Clean and prep the MTBS data to match the FPA database naming convention
mtbs_fire <- st_read(dsn = mtbs_prefix,
                     layer = "mtbs_perims_1984-2015_DD_20170815", quiet= TRUE) %>%
  st_transform(p4string_ea) %>%
  mutate(MTBS_ID = Fire_ID,
         MTBS_FIRE_NAME = Fire_Name,
         MTBS_DISCOVERY_YEAR = Year,
         MTBS_DISCOVERY_DAY = day(ig_date),
         MTBS_DISCOVERY_MONTH = month(ig_date),
         MTBS_DISCOVERY_DOY = yday(ig_date)) %>%
  dplyr::select(MTBS_ID, MTBS_FIRE_NAME, MTBS_DISCOVERY_DOY, MTBS_DISCOVERY_DAY, MTBS_DISCOVERY_MONTH, MTBS_DISCOVERY_YEAR) %>%
  merge(., as.data.frame(fpa_fire), by = c("MTBS_ID", "MTBS_FIRE_NAME"), all = FALSE) %>%
  dplyr::select(FPA_ID, LATITUDE, LONGITUDE, ICS_209_INCIDENT_NUMBER, ICS_209_NAME, MTBS_ID, MTBS_FIRE_NAME, FIRE_SIZE, FIRE_SIZE_m2, FIRE_SIZE_ha, FIRE_SIZE_km2,
                MTBS_DISCOVERY_YEAR, DISCOVERY_YEAR, MTBS_DISCOVERY_DOY, DISCOVERY_DOY, MTBS_DISCOVERY_MONTH, DISCOVERY_MONTH,
                MTBS_DISCOVERY_DAY, DISCOVERY_DAY, STATE, STAT_CAUSE_DESCR, IGNITION)
names(fpa_fire) %<>% tolower
names(mtbs_fire) %<>% tolower
