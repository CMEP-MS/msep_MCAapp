library(dplyr)
library(ggplot2)
library(mseptools)
library(sf)
library(tmap)
library(leaflet)
library(leaflet.extras2)

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

tmp_units <- mca_units |> 
  filter(ParameterNew == parm) |> 
  select(Units) |> 
  unlist() 

mapview::mapview(tmp)
  

tm_shape(tmp) +
  tm_basemap("CartoDB.Positron") +
  tm_symbols(
    col = "Value",      # color gradient
    shape = "LongTermStation",# TRUE/FALSE -> different shapes
    size = 1,
    palette = "brewer.yl_gn_bu"
  )

# basic map ----
tm_shape(tmp) +
  tm_basemap("CartoDB.Positron") +
  tm_symbols(
    col = "purple",   # outline
    fill = "Value",
    fill.scale = tm_scale_continuous(values = "brewer.yl_gn_bu"),
    shape = "LongTermStation",# TRUE/FALSE -> different shapes
    size = 1
  )

tmap_mode("view")
# faceted map ----

tm_shape(tmp2) +
  tm_basemap("CartoDB.Positron") +
  tm_symbols(
    col = "purple",   # outline
    fill = "Value",
    fill.scale = tm_scale_continuous_log1p(values = "brewer.yl_gn_bu"),
    shape = "LongTermStation",# TRUE/FALSE -> different shapes
    fill.legend = tm_legend(position = tm_pos_out("right")),
    shape.legend = tm_legend(position = tm_pos_out("right")),
    size = 1,
    hover = "Value"
  ) +
  tm_facets_wrap(by = "Year", ncol = 3) 
