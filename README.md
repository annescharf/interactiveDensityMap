# Interactive Density Map

MoveApps

Github repository: *github.com/mscacco/interactiveDensityMap*

## Description
Density raster containing the number of GPS locations, the number of individuals, the number of species or the number of Movebank studies per pixel overlaid on an interactive map. 

## Documentation
The user can choose between displaying the number of GPS locations per pixel, the number of individuals, the number of species or the number of Movebank studies. The variable is rasterized on a grid of user-defined resolution (pixel size) and overlaid on a interactive map. The map can be zoomed, the color palette reversed, and the background openstreetmap can be selected as `TopoMap`or `Aerial`. The map interactively updates when the user selects a different variable to display or a different pixel size.

*Suggestion: if the chosen dataset covers a large area and at first you do not see the raster on the map, try increasing the pixel size.*

### Application scope
#### Generality of App usability
This App was developed for any taxonomic group. Specially useful for large datasets.

#### Required data properties
The App should work for any kind of (location) data.

### Input type
`move2::move2_loc`

### Output type
`move2::move2_loc`

### Artefacts

### Settings 
`Variable to rasterize`: variable that the user wants to be rasterized as number of occurrences per raster cell. The user can choose one of `N. of GPS locations` (default), `N. of individuals`, `N. of species` or `N. of Movebank studies`.

`Raster pixel size (Km)`: desired resolution (pixel size) of the grid used to rasterize the chosen variable. Range 1-500 km. Unit: `km`. Default: 50.

`Reverse color palette`: this will allow you to reverse the order of the colors in the palette. For better visualization, we suggest to tick the "reverse color palette" box in combination with an `Aerial` map (the opposite when using a `TopoMap`).

`Save Plot`: the map with the chosen setting can be downloaded as a `.png` file

`Store settings`: click to store the current settings of the App for future Workflow runs. 

### Changes in output data

The input data remains unchanged.

### Most common errors

### Null or error handling
If your data is not downloaded via de `Movebank Location` App but uploaded via a local upload App, the data set must contain the columns "taxon_canonical_name" and "study_id" to be able to rasterize by species or study id. If these column names are not present in the data set, an error will occurr.
