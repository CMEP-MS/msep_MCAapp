library(dplyr)
library(tibble)
library(tmap)
load(here::here("data", "MCA_dfs.RData"))

make_scale <- function(scale_type, palette, limits) {
  switch(scale_type,
         sqrt       = tm_scale_continuous_sqrt(values = palette, limits = limits),
         log1p      = tm_scale_continuous_log1p(values = palette, limits = limits),
         continuous = tm_scale_continuous(values = palette, limits = limits)
  )
}


# Precompute ranges across all years for each variable
var_ranges <- mca_data |>
  group_by(Parameter) |>
  summarise(
    min_val = min(Value, na.rm = TRUE),
    max_val = max(Value, na.rm = TRUE)
  )
# add that into the big data frame
mca_params <- left_join(mca_params, var_ranges)

# apply the make_scales function from above to this
var_scales <- mca_params |>
  rowwise() |>
  mutate(
    limits = list(c(min_val, max_val)),
    scale  = list(make_scale(ScaleType, Palette, limits))
  ) |>
  select(Parameter, scale) |>
  deframe()


# now we've got a named list with info for each variable


# in shiny server:
shared_scale <- reactive({
  var_scales[[input$variable]]
})



output$mymap <- renderTmap({
  years      <- sort(unique(df$Year))
  param_data <- df |> filter(Parameter == input$variable)
  
  maps <- lapply(seq_along(years), function(i) {
    leg <- if (i == 1) legend_with else legend_without
    
    tm_shape(param_data |> filter(Year == years[i])) +
      tm_basemap("CartoDB.Positron") +
      tm_symbols(
        col          = "purple",
        fill         = "Value",      # always "Value" now, not input$variable
        fill.scale   = var_scales[[input$variable]],
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
})