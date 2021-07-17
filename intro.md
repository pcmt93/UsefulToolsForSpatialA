Very useful tools in R/Python for Geospatial Analysis
================

In this document, I will explain some very useful and easy tools that I
use in R for geospatial analysis and for spatial object manipulation
(e.g shapefiles, raster files, spatial databases, etc.). I also going to
present some libraries and commands that I usually use in my-day-to-day
code work for cleaning and dataset manipulation (Stata alike)

For all this I’m going to use mainly examples of public databases from
the Peruvian context (the country that I come from). This is going to be
a very short post, but I’m going to try to include great variety of
tools at least for every basic analysis (e.g open spatial object, modify
them, plot maps, polygons, points, etc.)

\#\# The basics

Open shapefiles:

``` r
  mun <- readOGR(paste0("~/Dropbox/paulo_RA/Narcos/databases/municipios/update"), 
                        "BAS_LIM_DISTRITOS")
```

    ## OGR data source with driver: ESRI Shapefile 
    ## Source: "/Users/ptrifu/Dropbox/paulo_RA/Narcos/databases/municipios/update", layer: "BAS_LIM_DISTRITOS"
    ## with 1834 features
    ## It has 18 fields
    ## Integer64 fields read as strings:  Hectares

``` r
  # An easly inspect some objects:
  plot(mun)
```

![](intro_files/figure-gfm/unnamed-chunk-2-1.png)<!-- -->
