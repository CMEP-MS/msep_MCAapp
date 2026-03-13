This repository contains code for a Shiny app to explore MDEQ Mississippi Coastal Assessment data, downloaded from the Water Quality Portal via `{mseptools}`.

## Steps followed after download

1.  Parameter names in the `CharacteristicName` were combined with associated details from the `ResultSampleFractionText` column, into a single `Parameter` column, to differentiate total and dissolved forms of nutrients.
2.  Verified that parameter names were consistent; one parameter is represented by one name throughout.  
    a.  Many rows had a `CharacteristicName` of "Inorganic nitrogen (nitrate and nitrite) \***retired\***use Nitrate + Nitrite, Total". These were converted to "Nitrate + Nitrite, Total".  
3.  Verified that parameter names had consistent units of reporting.  
    a.  Secchi disk depth was reported in "ft" for 32 sampling events, and in "m" for the remaining 441. This appeared to be limited to 2014 sampling. These values were converted to m to be consistent with other values.  
    b.  Many rows did not have reported units. A separate data frame was made to track units for each parameter.  
4.  When results were below detection (denoted in the original `ResultDetectionConditionText` column as "Present Below Quantification Limit"), the MDL provided in the `DetectionQuantitationLimitMeasure.MeasureValue` column was inserted into the `Value` field (which had been NA otherwise). A `Censored` column was created, with 1s in the same rows to denote \<MDL results, and 0s in rows that were not censored values.  
5.  Long-term stations were identified as those sampled on more than 1 date. This yielded 8 stations, 5 of which were sampled in all 15 years and the others sampled for 10 or 11 years. A `TRUE/FALSE` column, `LongTermStation`, was added to the data frame to denote this.  
6.  GPS Coordinates were corrected for the following:  
    a.  In 2020, one data point had an associated longitude of 88.xxxx rather than -88.xxxx. Now all Longitude values are checked and if they are not negative, they are multiplied by -1.  
    b.  In 2024, 3 data points had latitudes of 32.xxxx. Details follow. These were all corrected by subtracting 2 in order to adjust to 30.xxxx. This correction is specific to the year 2024.  
        i.  21MSWQ_WQX-MS24-496, INDUSTRIAL SEAWAY. Lat given as 32.42299. Could not find other sites in the dataset with the INDUSTRIAL SEAWAY name but based on the following stations, believe correcting this to 30.xxxx is also appropriate.  
        ii.  21MSWQ_WQX-MS24-479, ST LOUIS BAY. Lat given as 32.35370. Other latitudes in the dataset for ST LOUIS BAY ranged from 30.31xxx to 30.37xxx, so correcting to 30.xxxx is appropriate.  
        iii.  21MSWQ_WQX-MS24-477, MISSISSIPPI SOUND. Lat given as 32.32958. Other latitudes in the dataset for MISSISSIPPI SOUND ranged from 30.15xxx - 30.42xxx, so correcting to 30.xxxx is appropriate.  
7.  Short names, suggested scales (log(x+1), sqrt, or continuous), and suggested color palettes were added to `ParamComprehensList.csv`, a table of parameter names and units that had previously been exported upond data processing. This should make it easier to automate mapping with custom parameter settings in a shiny app.  

