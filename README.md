# DataGraphPlots

DataGraphPlots.jl is a package for [Julia](https://julialang.org/) designed for visualizing graphs from the [PlasmoData.jl](https://github.com/zavalab/PlasmoData.jl) package. 

## Bug Reports and Support

This package is functional and can be installed as is. It is still under development, and significant changes will continue to come. If you encounter any issues or bugs, please submit them through the [Github issue tracker](https://github.com/dlcole3/DataGraphPlots.jl/issues). 

## Installation

To install this package, you can use 

```julia
using Pkg
Pkg.add(url="https://github.com/dlcole3/DataGraphPlots.jl")
```

or

```julia
pkg> add https://github.com/dlcole3/DataGraphPlots.jl
```

## Overview

DataGraphPlots.jl is designed for plotting the `DataGraph` object. Node positions are saved under the NodeData of the `DataGraph` object. For these positions to be recognized, they must be called "x_positions" and "y_positions". If the user does not define these, the node positions are determined by NetworkLayout.jl's `sfdp` function (stands for Scalable Force Directed Placement). Alternatively, when the `DataGraph` was constructed from a matrix or a tensor, the user can set the node positions using `set_matrix_node_positions!` or `set_tensor_node_positions!` functions which take the argument of the `DataGraph` and the original matrix or tensor. 

The primary function in DataGraphPlots.jl is `plot_graph`, which takes the following, optional keyword arguments:

 * `get_new_positions::Bool`: If true, calculates new positions using NetworkLayout.jl's `sfdp` function. 
 * `plot_edges::Bool`: If false, only the nodes of the `DataGraph` will be plotted. The edges take the longest time to plot, so this can reduce the plotting time for graphs with many nodes where the edges are less important to visualize (e.g., large matrices formed as graphs)
 * `C`, `K`, `iterations`, `tol`: These are arguments used by NetworkLayout.jl's `sfdp` function for determining node positions.
 * `xdim`, `ydim`: Determing the dimensions of the final plot (default is 800 for both)
 * `linewidth`: Determines the width of the edges
 * `linealpha`: Determines the alpha value (how transparent the edge is). 
 * `line_z`: The set of data corresponding to edge weights. This should be a vector of length equal to the number of edges. Can be used if the edges should be color coded by weight
 * `line_z_grad`: The color gradient used when `line_z` is defined.
 * `nodecolor`: Color of the node markers. When `node_z` is defined, this should be a color gradient.
 * `nodesize`: size of the node markers
 * `nodestrokewidth`: Width of the border on the node markers
 * `nodestrokecolor`: Color of the border on the node markers
 * `nodestrokealpha`: alpha (transparency) of the border on the node markers
 * `node_z`: Set of data corresponding to node weights. This should be a vector of length equal to the number of nodes. Can be used if the nodes should be color coded by weight
 * `framestyle`: framestyle of plot
 * `rev`: Boolean indicating, if node_z is defined, that the color gradient from node color will be reversed
 * `legend`: Boolean determining whether there should be a colorbar when `node_z` is defined
 * `save_fig`: Boolean to determine if the figure should be saved or not
 * `fig_name`: Name of the file name that the saved figure should have. 

 ## Example

 Any `DataGraph` can be plotted simple by calling 

 ```julia
plot_graph(datagraph)
 ```

 However, it may be useful to use keyword arguments depending on the visualization you desire. For example:

 ```julia
random_matrix = rand(15, 15)

matrix_graph = PlasmoData.matrix_to_graph(random_matrix)

set_matrix_node_positions!(matrix_graph, random_matrix)

plot_graph(
   matrix_graph, 
   nodesize = 8, 
   linecolor = :grey, 
   linewidth = 4, 
   node_z = get_node_data(matrix_graph).data[:],
   nodecolor = :algae
)
 ```
