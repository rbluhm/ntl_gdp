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
conus.sf <- st_read("./data/usa/BEA_counties_2021.gpkg", stringsAsFactors=F) %>% st_transform("+proj=laea")

## find islands
st_rook <- function(a, b = a) st_relate(a, b, pattern = "F***1****")
nb_rooks <- st_rook(conus.sf)
nb_rooks <- t(sapply(nb_rooks, '[', seq(max(sapply(nb_rooks, length)))))
which(rowSums(is.na(nb_rooks)) == ncol(nb_rooks))

# buffer and replace the island for adjacency calculation
s1187_new <- conus.sf[1187,] %>%  st_buffer(10e3)
conus.sf[1187,] <- s1187_new
s1193_new <- conus.sf[1193,] %>%  st_buffer(10e3)
conus.sf[1193,] <- s1193_new
s2919_new <- conus.sf[2919,] %>%  st_buffer(10e3)
conus.sf[2919,] <- s2919_new
conus.sf <- conus.sf %>%  st_as_sf()

conus.adj <- redist.adjacency(shp = conus.sf )

conus.sf$POP <- 1

# run the MCMC chains using redist flip
system.time({
  lapply(c(50,seq(200,3000, by=200)), function(x){
    # just to move the seed along, mclapply calls each worker with new seed 
    # but does not move master seed, consider switching to clusterApply or parLapply
    set.seed(seednr+x)
    plans<-mcmapply(function(nreps) {
      sim.block <- redist.rsg(adj = conus.adj, total_pop = conus.sf$POP, 
                                     ndists = x, pop_tol = Inf)$plan
      return(sim.block)   
    }, 1:nsims, mc.set.seed = TRUE, mc.cores = detectCores())  
    
    write_csv(as.data.frame(plans), paste0("./data/usa/test_plans_",x,".csv"))

   return(NULL) 
  }) 
})

## plt some examples
ndists <- 50
plan <-  read_csv(paste0("./data/usa/test_plans_",ndists,".csv"))

conus.all.sf <- cbind(conus.sf, plan)

conus.all.sf$State <- conus.all.sf$V1
conus.all.sf$State <- as.factor(conus.all.sf$State)

map_theme <- function(x) { theme(
  axis.title.x = element_blank(),
  axis.title.y = element_blank(),
)}

png("./figures/figure_4a_usa.png", width=1.5*5.5, height=1.5*4, units = "in", res = 300)

conus.all.sf %>%  st_transform(4326) %>%
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
