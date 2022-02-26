# clear workspace
rm(list = ls())

# required
lop <- c("tidyverse", "haven", "sf" , "units", "redist", 
         "parallel", "data.table", "ggplot2", "ggthemes")
newp <- lop[!(lop %in% installed.packages()[,"Package"])]
if(length(newp)) install.packages(newp)
lapply(lop, require, character.only = TRUE)

# working dir
wd.path <- "/bigstore/Dropbox/Nighttime_lights_and_DIDs/Draft/Replication/"
setwd(wd.path)

### set the parameters for the simulation
nsims <- 1000
seednr <- 10101

# random no gen options
set.seed(seednr)

## get the data
brazil.sf <- st_read("./data/brazil/BRMUE250GC_SIR.gpkg", stringsAsFactors=F) %>% st_transform("+proj=laea")

## find islands
st_rook <- function(a, b = a) st_relate(a, b, pattern = "F***1****")
nb_rooks <- st_rook(brazil.sf)
nb_rooks <- t(sapply(nb_rooks, '[', seq(max(sapply(nb_rooks, length)))))
which(rowSums(is.na(nb_rooks)) == ncol(nb_rooks))
brazil.sf[which(rowSums(is.na(nb_rooks)) == ncol(nb_rooks)),]

# buffer and replace the island for adjacency calculation
s2171_new <- brazil.sf[2171,] %>%  st_buffer(10e3)
brazil.sf[2171,] <- s2171_new

brazil.sf <- brazil.sf %>%  st_as_sf()

# 1774 is 350 km away
# 2171 is super close
# 3947 is a municipality that is a "hole" inside another poly

#brazil.sf <- brazil.sf[-which(rowSums(is.na(nb_rooks)) == ncol(nb_rooks)),]

brazil.sf <- brazil.sf[-c(1774),] # we only drop 2605459
brazil.sf <- brazil.sf[order(brazil.sf$CD_GEOCMU),]

## islands are too far away from anything, let's remove them

# calc adjacency mat
brazil.adj <- redist.adjacency(shp = brazil.sf)

brazil.sf$POP <- 1

# run the MCMC chains using redist flip
system.time({
  lapply(c(50,seq(200,5400, by=200)), function(x){
    # just to move the seed along, mclapply calls each worker with new seed 
    # but does not move master seed, consider switching to clusterApply or parLapply
    set.seed(seednr+x)
    plans<-mcmapply(function(nreps) {
      ken89.sim.block <- redist.rsg(adj = brazil.adj, total_pop = brazil.sf$POP,
                                     ndists = x, pop_tol = Inf)$plan
      return(ken89.sim.block)   
    }, 1:nsims, mc.set.seed = TRUE, mc.cores = detectCores())  
    plans <- as.data.frame(plans)
    plans$CD_GEOCMU <- brazil.sf$CD_GEOCMU
    write_csv(plans, paste0("./data/brazil/test_plans_",x,".csv"))

   return(NULL) 
  }) 
})

## plt an example
ndists <- 50
plan <-  read_csv(paste0("./data/brazil/test_plans_",ndists,".csv"))

brazil.all.sf <- cbind(brazil.sf, plan)

brazil.all.sf$State <- brazil.all.sf$V1
brazil.all.sf$State <- as.factor(brazil.all.sf$State)

map_theme <- function(x) { theme(
  axis.title.x = element_blank(),
  axis.title.y = element_blank(),
)}

png("./figures/figure_4b_brazil.png", width=1.5*5.5, height=1.5*4, units = "in", res = 300)

brazil.all.sf %>% st_transform(4326) %>%
  ggplot() + 
  geom_sf(aes(fill = State),
          color = 'white',
          alpha = .65,
          lwd = .1) +
  scale_fill_manual(
    values = colorRampPalette(ggthemes::stata_pal()(8))(ndists)) +
  geom_sf_text(aes(label = State),
               color = 'black',
               size = 2.5, 
               check_overlap = TRUE) +
  theme_minimal() + map_theme() + 
  theme(legend.position = "none")

dev.off()
