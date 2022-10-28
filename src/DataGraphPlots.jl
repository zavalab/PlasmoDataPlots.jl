module DataGraphPlots

using Plots, NetworkLayout, GeometryBasics, Graphs, DataGraphs

export plot_graph, set_matrix_node_positions!, set_node_positions!, set_tensor_node_positions!

function plot_graph(dg::DataGraphs.DataGraph;
    get_new_positions::Bool=false,
    plot_edges::Bool=true,
    C::Real=1.0,
    K::Real=.1,
    iterations::Int=300,
    tol::Real=.1,
    xdim = 800,
    ydim = 800,
    linewidth = 1,
    linealpha = 1,
    linecolor = :gray,
    line_z = nothing,
    line_z_grad = :inferno,
    nodecolor = :black,
    nodesize = 5,
    nodestrokewidth = 1,
    nodestrokecolor = :black,
    nodestrokealpha = :none,
    node_z = nothing,
    framestyle=:box,
    legend::Bool = false,
    save_fig::Bool = false,
    fig_name::String = "plot.png",
)

    am = DataGraphs.adjacency_matrix(dg)

    if get_new_positions || length(dg.node_positions) <= 1
        pos = NetworkLayout.sfdp(Graphs.SimpleGraph(am); tol = tol, C = C, K = K, iterations = iterations)
        dg.node_positions = pos
    else
        pos = dg.node_positions
    end

    if line_z != nothing
        if length(line_z) != length(dg.edges)
            error("Length of line_z argument is different than the number of edges")
        end

        line_z_cgrad = cgrad(line_z_grad)
        edge_min = minimum(line_z)
        edge_max = maximum(line_z)
        edge_span = edge_max - edge_min
    end


    plt = plot(framestyle = framestyle, grid = false, size = (xdim, ydim), axis = nothing, legend = legend)
    if plot_edges
        if line_z != nothing
            plot!([],[], line_z = line_z, linecolor = line_z_cgrad, label = :none)
            for (j, i) in enumerate(dg.edges)
                from = i[1]
                to   = i[2]

                if line_z != nothing
                    edge_val = (line_z[j] - edge_min) / edge_span
                    color = line_z_cgrad[Int(floor(edge_val * 255 + 1))]

                    #line_options = Dict(:linewidth => linewidth, :linealpha => linealpha, line_z => color)
                    line_options = Dict(:linecolor => color, :linewidth => linewidth, :linealpha => linealpha)
                else
                    line_options = Dict(:linecolor => linecolor, :linewidth => linewidth, :linealpha => linealpha)

                end

                plot!(plt,[pos[from][1], pos[to][1]], [pos[from][2], pos[to][2]];
                    label=:none,
                    line_options...
                )
            end
        else
            edge_type = eltype(dg.edge_data.data)

            x_points = Vector{Vector{edge_type}}()
            y_points = Vector{Vector{edge_type}}()
            for i in dg.edges
                from = i[1]
                to   = i[2]

                xfrom = pos[from][1]
                xto   = pos[to][1]
                yfrom = pos[from][2]
                yto   = pos[to][2]

                push!(x_points, [edge_type(xfrom), edge_type(xto)])
                push!(y_points, [edge_type(yfrom), edge_type(yto)])
            end

            #line_options = Dict(:linewidth => linewidth, :linealpha => linealpha, :linecolor => linecolor, :label => :none)
            if typeof(linecolor) <: Vector && length(linecolor) == length(dg.edges)
                for i in 1:length(linecolor)
                    plot!(plt, x_points[i], y_points[i], linecolor = linecolor[i], linewidth = linewidth, linealpha = linealpha, label = :none)
                end
            else
            plot!(plt, x_points, y_points, linecolor = linecolor, linewidth = linewidth, linealpha = linealpha, label = :none)
            end
        end
    end

    scatter!(plt, [i[1] for i in pos], [i[2] for i in pos];
        markercolor=nodecolor,
        markersize=nodesize,
        markerstrokewidth = nodestrokewidth,
        markerstrokecolor = nodestrokecolor,
        markerstrokealpha = nodestrokealpha,
        marker_z = node_z,
        label=:none,
    )

    if save_fig
        Plots.savefig(fig_name)
    end

    display(plt)
end

# Fix to set in place
function set_matrix_node_positions!(dg, mat)
    dim1, dim2 = size(mat)

    positions = []
    for i in 1:length(dg.nodes)
        node_val  = dg.nodes[i]
        node_x    = Float64(node_val[2] * 5)
        node_y    = Float64((dim1 - node_val[1] * 5))
        push!(positions, Point(node_x, node_y))
    end

    dg.node_positions = positions
end

function set_tensor_node_positions!(dg, tensor)
    dim1, dim2, dim3 = size(tensor)

    function get_es(a0, b0, c0, b1, c1, c2)
        a1 = (-b0 * b1 - c0 * c1) / a0
        b2 = (a0 * c1 * c2 / a1 - c0 * c2) / (b0 - a0 * b1 / a1)
        a2 = (-b1 * b2 - c1 * c2) / a1

        return [a1, b1, c1], [a2, b2, c2]
    end

    n  = [2, 5, -1.5]
    b1 = 3
    c1 = .2
    c2 = 1
    e1, e2 = get_es(n[1], n[2], n[3], b1, c1, c2)
    e1_norm = (e1[1]^2 + e1[2]^2 + e1[3]^2)^(.5)
    e2_norm = (e2[1]^2 + e2[2]^2 + e2[3]^2)^(.5)

    positions = []
    for i in 1:length(dg.nodes)
        node_val = dg.nodes[i]
        node_x = Float64(e1[1] * node_val[1] + e1[2] * node_val[2] + e1[3] * node_val[3]) / e1_norm
        node_y = Float64(e2[1] * node_val[1] + e2[2] * node_val[2] + e2[3] * node_val[3]) / e2_norm
        push!(positions, Point(node_x, node_y))
    end
    dg.node_positions = positions
end

function set_node_positions!(
    dg::D,
    C::Real = 1.0,
    K::Real = 0.1,
    iterations::Int = 300,
    tol::Real = 0.1
) where {D <: Union{DataGraphs.DataGraph, DataGraphs.DataDiGraph}}
    am = DataGraphs.adjacency_matrix(dg)

    pos = NetworkLayout.sfdp(Graphs.SimpleGraph(am); tol = tol, C = C, K = K, iterations = iterations)
    dg.node_positions = pos
end

end
