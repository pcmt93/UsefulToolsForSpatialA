
# This is only a file with only the code of this small document

rm(list = ls()) # to clear your working spaces

# These are the libraries that we are going to use for this small post

library(sp)
library(rgdal)
library(readstata13)
library(raster)

# For graph: 
library(tidyverse)
library(broom) 

# Open municipality shapefile:

mun <- readOGR(paste0("~/Dropbox/paulo_RA/Narcos/databases/municipios/update"), 
               "BAS_LIM_DISTRITOS") # rgdal library

# Inspect object:
plot(mun)

# Open Peruvian survey, kind of large spatial object:
enaho <- read.dta13(paste0("~/Dropbox/BDatos/ENAHO/2020/737-Modulo01/",
                           "enaho01-2020-100.dta"))

coordinates(enaho) <- ~ longitud + latitud # transform it to spatial object

# A very important thing is to identify coords systm. For usual lat/long 
# the following works:

proj4string(enaho) <- CRS("+init=epsg:4326") # Here we are defining the coord syst.
# sp library

plot(enaho) # And we can plot it too 

print(crs(enaho))
print(crs(mun)) ## crs from raster library

enaho <- spTransform(enaho, crs(mun))

# And of course we can plot it together in a graph 
plot(mun)
plot(enaho, add = TRUE, col='red', pch=1, cex = .2) 
