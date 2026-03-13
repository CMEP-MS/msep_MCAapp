library(dplyr)
library(ggplot2)
# library(mseptools)
library(sf)
library(tmap)
# library(leaflet)
# library(leaflet.extras2)

load(here::here("data",
                "MCA_dfs.RData"))


params <- unique(mca_data$Parameter)

# if it's something with censored data, deal with censoring somehow
# maybe a completely different color than the rest of the palette??

i = 3
parm <- params[i]

yr = 2021

tmp <- mca_data |> 
  filter(Parameter == parm,
         Year == yr) |> 
  st_as_sf(coords = c("Lng", "Lat"),
           crs = "WGS84")

tmp2 <- mca_data |> filter(Parameter == parm) |> 
  st_as_sf(coords = c("Lng", "Lat"),
           crs = "WGS84")
tmp2$hover_text <- paste(
  "Parameter:", tmp2$Parameter,
  "\nArea:", tmp2$LocationName,
  "\nValue:", round(tmp2$Value, 2)
)


# static map ----

tmap_mode("plot")
tm_shape(tmp) +
  tm_basemap("CartoDB.Positron") +
  tm_symbols(
    col = "purple",   # outline
    fill = "Value",
    fill.scale = tm_scale_continuous_sqrt(values = "brewer.pu_or"),
    shape = "LongTermStation",
    size = 0.9
  ) 

# divide into regions ----
library(msepBoundaries)


tmp2 <- tmp2 |>
  mutate(Area = case_when(
    LocationName %in% c("MISSISSIPPI SOUND", "GULF OF MEXICO") ~ "Sound",
    stringr::str_detect(LocationName, "\\bBAY\\b") ~ "Bays",
    .default = "Rivers/Lakes/Tributaries"
  ),
  Area = factor(Area, levels = c("Sound & Gulf", "Bays", "Rivers/Lakes/Tributaries")))


ggplot(tmp2,
       aes(x = Year,
           y = Value,
           col = Area)) +
  geom_jitter() +
  scale_y_log10() +
  facet_wrap(~ Area) +
  geom_smooth(se = FALSE) +
  theme_bw()



allpts <- tmp2 |> 
  select(Area, LongTermStation, LocationID, LocationName, geometry) |> 
  distinct()

tmap_mode("view")
tm_shape(subbasins_mdeqExt) +
  tm_basemap("CartoDB.Positron") +
  tm_polygons(fill = NULL,
              col = "black",
              lwd = 2) +
  tm_shape(allpts) +
  tm_symbols(
    col = "purple",   # outline
    fill = "Area",
    shape = "LongTermStation",
    size = 0.9
  ) 







# a few are mislabelled but not enough to really throw anything off
# might be a good idea to use msepBoundaries subbasins_mdeqExt to differentiate
# Sound and Gulf since most of the issues are there, from Bays and Others

# calculate summary stats ----
summs <- tmp2 |> 
  st_drop_geometry() |> 
  dplyr::summarize(.by = c(Area, Year),
                   min = min(Value, na.rm = TRUE),
                   mean = mean(Value, na.rm = TRUE),
                   median = median(Value, na.rm = TRUE),
                   max = max(Value, na.rm = TRUE),
                   IQR = IQR(Value, na.rm = TRUE),
                   sd = sd(Value, na.rm = TRUE)) |> 
  mutate(across(c(min:sd),
                function(x) round(x, 2))) |> 
  arrange(Area, Year)
reactable::reactable(summs)

# time series of medians ----
ggplot(summs,
       aes(x = Year,
           y = median,
           col = Area,
           shape = Area)) +
  geom_point(size = 3,
             stroke = 1,
             alpha = 0.8) +
  geom_line() +
  theme_bw()




# old stuff ----


tmap_mode("view")
first_year <- min(tmp2$Year)
# faceted map ----

tm_shape(tmp2) +
  tm_basemap("CartoDB.Positron") +
  tm_symbols(
    col = "purple",   # outline
    fill = "Value",
    fill.scale = tm_scale_continuous_log1p(values = "brewer.yl_gn_bu"),
    shape = "LongTermStation",# TRUE/FALSE -> different shapes
    fill.legend = tm_legend(position = tm_pos_in("left", "bottom"),
                            orientation = "landscape"),
    shape.legend = tm_legend(show = FALSE),
    size = 1,
    hover = "Value"
  ) +
  tm_facets_wrap(by = "Year", ncol = 3) 


# individual maps with shared scale
shared_scale <- tm_scale_continuous_log1p(
  values = "brewer.yl_gn_bu",
  limits = c(0, 160)      # set explicit domain here
)

shared_legend <- tm_legend(
  position    = tm_pos_out("right", "bottom")
)

map_2020 <- tm_shape(tmp2 |> filter(Year == 2020)) +
  tm_basemap("CartoDB.Positron") +
  tm_symbols(
    col        = "purple",
    fill       = "Value",
    fill.scale = shared_scale,
    fill.legend = shared_legend,
    shape      = "LongTermStation",
    size       = 1,
    hover      = "Value"
  )

map_2021 <- tm_shape(tmp2 |> filter(Year == 2021)) +
  tm_basemap("CartoDB.Positron") +
  tm_symbols(
    col        = "purple",
    fill       = "Value",
    fill.scale = shared_scale,
    fill.legend = shared_legend,
    shape      = "LongTermStation",
    size       = 1,
    hover      = "Value"
  )

tmap_arrange(map_2020, map_2021, ncol = 2)


# tm_arrange with multiple years ----
years = 2010:2012

shared_scale <- tm_scale_continuous_sqrt(
  values = "brewer.yl_gn",
  limits = c(min(tmp2$Value), max(tmp2$Value))      # set explicit domain here
)


legend_with <- tm_legend(
  position    = tm_pos_in("right", "bottom"),
  show        = TRUE
)

legend_without <- tm_legend(show = FALSE)


maps <- lapply(seq_along(years), function(i) {
  leg <- if (i == 1) legend_with else legend_without
  
  tm_shape(tmp2 |> filter(Year == years[i])) +
    tm_basemap("CartoDB.Positron") +
    tm_symbols(
      col          = "purple",
      fill         = "Value",
      fill.scale   = shared_scale,
      fill.legend  = leg,
      shape        = "LongTermStation",
      shape.legend = leg,
      size         = 1,
      hover        = "Value"
    ) +
    tm_title(as.character(years[i]),
             position = tm_pos_in("left", "top"))
})

tmap_arrange(maps, ncol = 3)
