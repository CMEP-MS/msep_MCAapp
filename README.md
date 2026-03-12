This repository contains code for a Shiny app to explore MDEQ Mississippi Coastal Assessment data, downloaded from the Water Quality Portal via `{mseptools}`.  


## Steps followed after download  

1. Parameter names in the `CharacteristicName` were combined with associated details from the `ResultSampleFractionText` column, into a single `Parameter` column, to differentiate total and dissolved forms of nutrients.
1. Verified that parameter names were consistent; one parameter is represented by one name throughout.  
    a. Many rows had a `CharacteristicName` of "Inorganic nitrogen (nitrate and nitrite) \\***retired\\***use Nitrate + Nitrite, Total". These were converted to "Nitrate + Nitrite, Total".  
1. Verified that parameter names had consistent units of reporting.  
    a. Secchi disk depth was reported in "ft" for 32 sampling events, and in "m" for the remaining 441. This appeared to be limited to 2014 sampling. These values were converted to m to be consistent with other values.  
    a. Many rows did not have reported units. A separate data frame was made to track units for each parameter.  
1. When results were below detection (denoted in the original `ResultDetectionConditionText` column as "Present Below Quantification Limit"), the MDL provided in the `DetectionQuantitationLimitMeasure.MeasureValue` column was inserted into the `Value` field (which had been NA otherwise). A `Censored` column was created, with 1s in the same rows to denote <MDL results, and 0s in rows that were not censored values.    
1. Long-term stations were identified as those sampled on more than 1 date. This yielded 8 stations, 5 of which were sampled in all 15 years and the others sampled for 10 or 11 years. A `TRUE/FALSE` column, `LongTermStation`, was added to the data frame to denote this.
  
 

### To address:  

1. some data point (chlorophyll) in 2020 is plotted in Asia - maybe a forgotten "-" in coords. check.
1. a few data points (chlorophyll) in 2024 are plotted in very inland MS - look into these 