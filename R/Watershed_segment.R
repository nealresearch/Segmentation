library("lidR")
library("raster")
library(rgl)
library(dplyr)
library(RANN)
library(terra)
library(sf)
library(ggplot2)
library(EBImage)

las <- readLAS("M:\\lidar\\Test\\cloud_compare\\anHavel-Cloud.las")
st_crs(las) <- 32633
las <-
  filter_poi(las, Z > 3 )

mean_height <- mean(las$Z)
max_height <- max(las$Z)


filter_by_height <- function(las, f) {
  heights <- seq(0 ,40, 0.5)
  ws <- f(heights)
  
  chm <- rasterize_canopy(las, res = 0.5, p2r(0.3, na.fill = kriging()))
  gf <- focalWeight(chm, .4, "Gauss")
  chm_smooth <- focal(chm, w = gf)
  
  # Set the CRS of the raster
  terra::crs(chm) <- "+init=epsg:25832"
  
  lasSegmentTrees <- segment_trees(las, lidR::watershed(chm = chm_smooth, th_tree = 2,tol = 1,ext = 1))
  
  lasFilterZero <- filter_poi(lasSegmentTrees, !(is.na(treeID)))
  
  # We loop through every cluster and remove those who have less than 150 cluster of points.
  p <- list()
  ids = base::unique(lasFilterZero$treeID)
  idl <- length(ids)
  i = 1
  while (i <= idl) {
    las_i <- filter_poi(lasFilterZero, treeID == i)
    dataHeader <- header(las_i)
    nop <- dataHeader@PHB
    points <- nop$`Number of point records`
    
    if (points <= 50) {
      p[[i]] <- i
    }
    i = i + 1
  }
  
  treeidlist <- p[lengths(p) != 0]
  lasThinned <- filter_poi(lasFilterZero, !treeID %in% treeidlist)
  
  return(lasThinned)
}

f3 <- function(x) {
  y <- 2.6 * (-(exp(-0.08*(x-2)) - 1)) + 3
  y[x >3 ] <- 3
  return(y)
}

f6 <- function(x) {
  y <- 2.6 * (-(exp(-0.08*(x-2)) - 1)) + 3
  y[x >3 ] <- 6
  return(y)
}

f9 <- function(x) {
  y <- 2.6 * (-(exp(-0.08*(x-2)) - 1)) + 3
  y[x >3 ] <- 9
  return(y)
}

extract_tree_crowns <- function(lasThinned, f) {
  x<- plot(lasThinned, color="treeID",bg="white")
  ttops <- locate_trees(lasThinned, lmf(f, shape="circular"))
  add_treetops3d(x, ttops)
  
  crowns <- crown_metrics(lasThinned, func = .stdtreemetrics, geom = "concave")
  polygons1 <- crowns$geometry
  ttops_sf <- st_as_sf(ttops)
  crowns_sf <- st_as_sf(crowns)
  check_sf <- st_as_sf(polygons1)
  
  indices <- st_intersects(crowns_sf, ttops_sf)
  num_points <- lapply(indices, length)
  
  # Create a vector of TRUE/FALSE where TRUE means that the polygon contains only one point
  one_point <- sapply(indices, function(x) length(x) == 1)
  
  # Filter the polygons
  polygons_with_one_point <- crowns_sf[one_point, ]
  
  return(polygons_with_one_point)
}



lasThinned3 <- filter_by_height(las, f3)
lasThinned6 <- filter_by_height(las, f6)
lasThinned9 <- filter_by_height(las, f9)

polygons3 <- extract_tree_crowns(lasThinned3, f3)
polygons6 <- extract_tree_crowns(lasThinned6, f6)
polygons9<- extract_tree_crowns(lasThinned9, f9)


matching36 <- st_intersects(polygons3, polygons6)


matching69 <- st_intersects(polygons6, polygons9)

# Compute intersections for polygons from windows 3 and 6
intersections36 <- lapply(matching36, function(indices) {
  if (length(indices) > 0) {
    return(st_intersection(polygons3, polygons6[indices, ]))
  }
})

# Remove NULL elements (where there were no intersections)
intersections36 <- intersections36[!sapply(intersections36, is.null)]

# Bind all intersected polygons into a single sf object
polygons36_clipped <- do.call(rbind, intersections36)



# Repeat the same process for polygons from windows 6 and 9
intersections69 <- lapply(matching69, function(indices) {
  if (length(indices) > 0) {
    return(st_intersection(polygons6, polygons9[indices, ]))
  }
})
intersections69 <- intersections69[!sapply(intersections69, is.null)]
polygons69_clipped <- do.call(rbind, intersections69)
plot(polygons69_clipped$geometry)
# Finally, merge the clipped polygons from both sets
merged_polygons <- rbind(polygons36_clipped, polygons69_clipped)


plot(merged_polygons$geometry)