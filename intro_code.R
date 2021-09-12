
# This is only a file with only the code of this small document

rm(list = ls()) # to clear your working spaces

# These are the libraries that we are going to use for this small post

library(sp)
library(rgdal)
library(raster)
library(maptools)
library(rgeos)

# For special graphs:

library(ggplot2)
library(tidyverse)
library(broom)

library(classInt) # for breaks graphs 
library(RColorBrewer) # Color palette for maps 

# For string
library(stringr)

# For databases 
library(readstata13)
library(dplyr)
library(gdata)


# Open municipality shapefile:

mun <- readOGR(paste0("~/Dropbox/paulo_RA/Narcos/databases/municipios/update"), 
               "BAS_LIM_DISTRITOS") # rgdal library

# Inspect object:
# plot(mun)

# Open Peruvian survey, kind of large spatial object:
enaho <- read.dta13(paste0("~/Dropbox/BDatos/ENAHO/2020/737-Modulo01/",
                           "enaho01-2020-100.dta"))

coordinates(enaho) <- ~ longitud + latitud # transform it to spatial object

# A very important thing is to identify coords systm. For usual lat/long 
# the following works:

proj4string(enaho) <- CRS("+init=epsg:4326") # Here we are defining the coord syst.
# sp library

# plot(enaho) # And we can plot it too 

print(crs(enaho))
print(crs(mun)) ## crs from raster library

enaho <- spTransform(enaho, crs(mun))

# And of course we can plot it together in a graph 
# plot(mun)
# plot(enaho, add = TRUE, col='red', pch=1, cex = .2) 

# Basic operations

# Subsample

mun <- mun[mun@data$NOMBPROV == 'LIMA',] # easily subsampling

# Manipulating variables

# We are going to create a dummy for the newest districts in Lima

# But first, we need to do a little of cleaning, we can easily do this in R
# even if it is an spatial object

# Inspect the data

sample_n(mun@data[,c("IDDIST", "NOMBDIST", "FECHA", "AREA_MINAM")], 15)

# Substring last digits and convert tu numeric variable 

mun$year_creation <- as.numeric(str_sub(mun$FECHA, -4))

print(sum(is.na(mun$year_creation))) ## NA because raw variable

mun$year_creation[is.na(mun$year_creation)] <- 1821 # replace with correct value 

print(sum(is.na(mun$year_creation))) ## Fixed

# Check it again:

sample_n(mun@data[,c("IDDIST", "NOMBDIST", "year_creation", "AREA_MINAM")], 10)

# We can also easily summarize the year variable and any other:

print(summary(mun$year_creation))

# Now we can create a dummy variable for the newest district, and plot them in a
# map 

mun$new_district <- ifelse(mun$year_creation>1980, 1, 0)


# Plot: 

# plot(mun, col = "lightgrey",
#      main = "Lima Municipalities")
# 
# sel <- mun$new_district == 1 # regions with new districts for graph 
# 
# plot(mun[ sel, ], col = "red", add = TRUE) # add selected zones to map
# legend("bottomright", title = "Year of creation",
#        legend = c("After 1980s", "Before"),
#        fill = c("red", "white"),
#        cex = .7)


# We can rename variables and keep only a few vars:

mun <- mun[, c("NOMBPROV", "IDDIST", "NOMBDIST", "year_creation", 
               "new_district", "AREA_MINAM")]

# And rename the variable that we want: 

mun <- rename.vars(mun, c("NOMBPROV", "IDDIST", "NOMBDIST", "AREA_MINAM"), 
       c("provincia", "ubigeo", "distrito", "area_mun")) 

print(mun@data)
print(typeof(mun)) # and we are still dealing with a spatial object 

# Other variables (but for our point spatial object)

enaho$prov_id = substr(enaho$ubigeo,1,4) # creating an prov ID
enaho$household_id = paste0(enaho$ubigeo, enaho$conglome, enaho$vivienda, 
                      enaho$hogar) # creating a household ID

# We of course can quickly check what we did (in 10 random rows):

sample_n(enaho@data[,c("ubigeo", "conglome", "vivienda", 
                       "hogar", "prov_id", "household_id")], 10)

# Our household ID is unique of course 
print(length(enaho$household_id)) # Number of rows 
print(length(unique(enaho$household_id))) # Number of unique rows 

# We can check the number of municipalities and provinces too 

print(length(unique(enaho$ubigeo)))
print(length(unique(enaho$prov_id)))

# We are going to subsample our household database too, in order to match with 
# the mun database 

enaho <- enaho[enaho$prov_id == '1501',] # LIMA province

enaho.df <- as.data.frame(enaho)

# We are going to aggregate this data to merge it with our spatial database 

enaho.ubigeo <- (enaho.df %>% group_by(ubigeo) %>% 
                 summarize(pob_mun = sum(factor07)))

mun.enaho <- merge(mun, enaho.ubigeo, by = "ubigeo")

# And create relevant indicator such as population per 

mun.enaho$density <- mun.enaho$pob_mun/mun.enaho$area_mun

# And plot it (from sp library):

# Figure with quantile breaks:

# Here I make quantiles:

pal <- brewer.pal(7, "OrRd") # we select 7 colors from the palette

brks <- classIntervals(mun.enaho$density, 
                       n=7, style="jenks")$brks # breaks 

# Categorical variable 
mun.enaho$density_cat <- cut(mun.enaho$density, brks, 
                              include.lowest = TRUE, dig.lab=3)
# plot
spplot(mun.enaho, "density_cat", 
       col.regions=pal, main = "Population density")

## Level 2: spatial operations 

# For this new excercise, we are going to open a new database - School in 2013:

schools <- read.dta13(paste0("~/Dropbox/BDatos/escuelas_2013.dta"))

coordinates(schools) <- ~ Longitud + Latitud # transform it to spatial object
  # Note that there should no be any missing here 

# defining coords:
proj4string(schools) <- CRS("+init=epsg:4326") # standard coords

plot(schools, col = "black", lwd = .5, main = "Schools in Peru - 2013")

print(length(schools)) # number of schools 
print(sample_n(schools@data, 10)) # we don't have ubigeo variable here. 

# So in order to select only Lima schools, we have to do an spatial merge
# a merge base on the caracteristics 

schools <- spTransform(schools, crs(mun.enaho)) # we need first to transform the coords
schools.lima <- over(schools, mun.enaho)
schools.lima <- spCbind(schools, schools.lima) # Here I recover the information 

schools.lima <- schools.lima[!is.na(schools.lima$ubigeo), ]

plot(schools.lima)



