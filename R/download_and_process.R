library(dplyr)

# not working with get_wqp_data
# had to grab from website
# this is project ids MCA10-MCA24

query_url <- "https://www.waterqualitydata.us/#statecode=US%3A28&organization=21MSWQ_WQX&sampleMedia=Water&project=MCA10&project=MCA11&project=MCA12&project=MCA13&project=MCA14&project=MCA15&project=MCA16&project=MCA17&project=MCA18&project=MCA19&project=MCA20&project=MCA21&project=MCA22&project=MCA23&project=MCA24&startDateLo=01-01-2000&startDateHi=12-31-2025&mimeType=csv&dataProfile=resultPhysChem&providers=NWIS&providers=STORET"



dat_in <- read.csv(here::here("data",
                           "resultphyschem.csv"))
dat <- janitor::remove_empty(dat_in, "cols")

# want:

dat_clean <- dat |> 
  dplyr::select(
    Date = ActivityStartDate,
    Lat = ActivityLocation.LatitudeMeasure,
    Lng = ActivityLocation.LongitudeMeasure,
    Parameter = CharacteristicName,
    ParameterDetail = ResultSampleFractionText,
    Value = ResultMeasureValue,
    Units = ResultMeasure.MeasureUnitCode,
    SurfaceDepth = ActivityTopDepthHeightMeasure.MeasureValue,
    SurfaceDepthUnits = ActivityTopDepthHeightMeasure.MeasureUnitCode,
    TotalDepth = ActivityBottomDepthHeightMeasure.MeasureValue,
    TotalDepthUnits = ActivityBottomDepthHeightMeasure.MeasureUnitCode,
    MonitoringLocationIdentifier,
    Station = MonitoringLocationName,
    DetectionResult = ResultDetectionConditionText,  # sometimes has 'present below quantification limit'
    AcceptanceStatus = ResultStatusIdentifier,   # Accepted or not
    TypeOfValue = ResultValueTypeName,   # Actual or Calculated
    SampleDepth = ResultDepthHeightMeasure.MeasureValue,  # presumably this is depth at which sample was taken? and Activity stuff is total depth?
    MDL = DetectionQuantitationLimitMeasure.MeasureValue,   # MDL
    MDLunits = DetectionQuantitationLimitMeasure.MeasureUnitCode
  ) |> 
  mutate(Censored = case_when(DetectionResult == "Present Below Quantification Limit" ~ 1,
                              .default = 0),
         ParameterFull = case_when(!is.na(ParameterDetail) & ParameterDetail != "" ~ paste(Parameter, ParameterDetail, sep = ", "),
                                   .default = Parameter),
         Date = lubridate::ymd(Date))


# do some checking
test <- dat_clean |> 
  select(Date, Parameter, Value, DetectionResult,
         Censored, MDL) |> 
  mutate(ValueNA = is.na(Value),
         MDLNA = is.na(MDL))

# make sure value is always NA when something is marked as Censored 
table(test$ValueNA, test$Censored)
# it is

# make sure there's always an MDL when something is flagged as censored
table(test$MDLNA, test$Censored)
# nice, so whenever an MDL is present, it's because the value was below MDL


# substitute MDL for blank values in those cases
dat_clean2 <- dat_clean |> 
  mutate(Value = case_when(is.na(Value) & Censored == TRUE ~ MDL,
                           .default = Value))
# only the 3 not reported ones should still be NA
sum(is.na(dat_clean2$Value))
# good


# check parameters and units
table(dat_clean2$ParameterFull, dat_clean2$Units)
# units look okay, though sometimes are reported as "None" or are blank
# but I don't see conflicting units, so that's good

table(dat_clean2$ParameterFull)
# no conflicting parameters either
# seem to get both dissolved and total Ammonia


dat_clean2 <- dat_clean2 |> 
  mutate(ParameterNew = case_when(stringr::str_starts(ParameterFull, "Inorganic nitrogen") ~ "Nitrate + Nitrite, Total",
                                  .default = ParameterFull))
table(dat_clean2$ParameterNew)


# make a table of units
dat_units <- dat_clean2 |> 
  select(ParameterNew, Units) |> 
  distinct() |> 
  filter(Units != "")
janitor::get_dupes(dat_units, ParameterNew)
# ARGH we have different units for secchi depth

dat_clean2 |> 
  filter(ParameterNew == "Depth, Secchi disk depth") |> 
  janitor::tabyl(Units)

dat_clean2 |> 
  filter(ParameterNew == "Depth, Secchi disk depth") |> 
  summarize(.by = Units,
            min = min(Value),
            max = max(Value),
            mean = mean(Value),
            median = median(Value))
# doesn't seem to be a labeling error


dat_clean2 |> 
  filter(ParameterNew == "Depth, Secchi disk depth",
         Units == "ft") |>
  View()
# it's 2014 when they reported it in feet

# convert
dat_clean3 <- dat_clean2 |> 
  mutate(Value = case_when(ParameterNew == "Depth, Secchi disk depth" & Units == "ft" ~ Value / 3.28084,
                           .default = Value),
         Units = case_when(ParameterNew == "Depth, Secchi disk depth" & Units == "ft" ~ "m",
                           .default = Units),
         Year = lubridate::year(Date))

# make sure everything is Accepted
table(dat_clean3$AcceptanceStatus)
# looks good

# remake that table of units
mca_units <- dat_clean3 |> 
  select(ParameterNew, Units) |> 
  distinct() |> 
  filter(Units != "")

mca_data <- dat_clean3 |> 
  select(
    Year,
    Date,
    ParameterNew,
    Value,
    Censored,
    Units,
    Lat,
    Lng,
    everything()
  ) |> 
  select(-ParameterDetail, -ParameterFull, -Parameter) |> 
  rename(Parameter = ParameterNew) |> 
  arrange(Date, Parameter)

mca_repeatStns <- mca_data |> 
  summarize(.by = MonitoringLocationIdentifier,
            n = length(unique(Year))) |> 
  filter(n > 1)

mca_data <- mca_data |> 
  mutate(LongTermStation = case_when(MonitoringLocationIdentifier %in% mca_repeatStns$MonitoringLocationIdentifier ~ TRUE,
                                     .default = FALSE))

# 8 stations that have been sampled more than once
# 5 in all years
# can make time series with those


# save out ----
save(mca_data, mca_units, mca_repeatStns,
     file = here::here("data",
                       "MCA_dfs.RData"))
