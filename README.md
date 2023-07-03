# Segmentation
R code to segment clumps of trees using watershed segmentation

Load the required libraries: lidR, raster, rgl, dplyr, RANN, terra, and sf.

Read the LAS file from the specified directory and set its Coordinate Reference System (CRS) to 32633.

Filter the point cloud to remove points with a height (Z coordinate) less than 3.

Compute the mean and maximum height of the point cloud.

Define a function filter_by_height() to process the point cloud data:

a. The function takes as arguments a LiDAR dataset and a function f() that describes a Gaussian-like curve. The Gaussian-like curve function f() is used later in the creation of the Canopy Height Model (CHM) and in tree segmentation.

b. Rasterize the point cloud using the rasterize_canopy() function from the lidR package and smooth the resulting Canopy Height Model (CHM) using a Gaussian filter.

c. Set the CRS of the CHM raster to EPSG:25832.

d. Use the watershed algorithm from the lidR package to segment trees in the point cloud, based on the smoothed CHM.

e. Filter out points without a tree ID from the segmented point cloud.

f. Loop through all clusters (trees), and filter out clusters with fewer than 50 points.

g. Return the thinned point cloud data.

Define three Gaussian-like curve functions f3(), f6(), and f9(), each capping the function's output at 3, 6, and 9 respectively. These are to be used as inputs for the filter_by_height() function.

Define the extract_tree_crowns() function to extract the tree crowns:

a. Plot the thinned point cloud color-coded by tree ID.

b. Identify the treetops in the point cloud using the lidR's lmf() function and add these treetops to the 3D plot.

c. Compute various metrics for each crown, and generate concave polygons to represent the crowns.

d. Filter out polygons that contain more than one treetop point.

e. Return polygons (representing tree crowns) with only one treetop point.

Apply the filter_by_height() function to the original point cloud using the three Gaussian-like curve functions f3(), f6(), and f9(). Store these thinned point clouds in variables lasThinned3, lasThinned6, and lasThinned9, respectively.

Apply the extract_tree_crowns() function to the thinned point clouds lasThinned3, lasThinned6, and lasThinned9 to extract tree crowns. Store these in variables polygons3, polygons6, and polygons9, respectively.

Compute the intersections of the polygons (tree crowns) extracted from lasThinned3 and lasThinned6, and those from lasThinned6 and lasThinned9.

For each intersection from step 10, create a new polygon where the original polygons overlap, and bind these into new spatial objects polygons36_clipped and polygons69_clipped.

Merge (bind) polygons36_clipped and polygons69_clipped into a single spatial object merged_polygons.

Finally, plot the geometry of the merged polygons.
