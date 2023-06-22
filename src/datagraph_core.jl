
function plot_graph(dg::PlasmoData.DataGraph;
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
    nodecolor = :black,
    nodesize = 5,
    nodestrokewidth = 1,
    nodestrokecolor = :black,
    nodestrokealpha = :none,
    node_z = nothing,
    framestyle=:box,
    rev::Bool = false,
    legend::Bool = false,
    save_fig::Bool = false,
    fig_name::String = "plot.png",
)

    am = PlasmoData.adjacency_matrix(dg)
    nodes = dg.nodes

    if get_new_positions || !("x_positions" in dg.node_data.attributes) || !("y_positions" in dg.node_data.attributes)
        pos = NetworkLayout.sfdp(Graphs.SimpleGraph(am); tol = tol, C = C, K = K, iterations = iterations)
        if !("x_positions" in dg.node_data.attributes)
            add_node_attribute!(dg, "x_positions", 0.0)
        end

        if !("y_positions" in dg.node_data.attributes)
            add_node_attribute!(dg, "y_positions", 0.0)
        end

        for i in 1:length(pos)
            add_node_data!(dg, dg.nodes[i], pos[i][1], "x_positions")
            add_node_data!(dg, dg.nodes[i], pos[i][2], "y_positions")

        end
    end

    if line_z != nothing
        if length(line_z) != length(dg.edges)
            error("Length of line_z argument is different than the number of edges")
        end

        line_z_cgrad = cgrad(linecolor, rev = rev)
        cgrad_len = length(line_z_cgrad)
        edge_min = minimum(line_z)
        edge_max = maximum(line_z)
        edge_span = edge_max - edge_min
    end


    plt = Plots.plot(framestyle = framestyle, grid = false, size = (xdim, ydim), axis = nothing, legend = legend)
    if plot_edges
        if line_z != nothing
            Plots.plot!([],[], line_z = line_z, linecolor = line_z_cgrad, label = :none)
            for (j, i) in enumerate(dg.edges)
                from = i[1]
                to   = i[2]

                if line_z != nothing
                    edge_val = (line_z[j] - edge_min) / edge_span
                    color = line_z_cgrad[Int(floor(edge_val * (cgrad_len - 1) + 1))]
                    #line_options = Dict(:linewidth => linewidth, :linealpha => linealpha, line_z => color)
                    line_options = Dict(:linecolor => color, :linewidth => linewidth, :linealpha => linealpha)
                else
                    line_options = Dict(:linecolor => linecolor, :linewidth => linewidth, :linealpha => linealpha)

                end

                x_from = get_node_data(dg, nodes[from], "x_positions")
                x_to   = get_node_data(dg, nodes[to], "x_positions")
                y_from = get_node_data(dg, nodes[from], "y_positions")
                y_to   = get_node_data(dg, nodes[to], "y_positions")

                Plots.plot!(plt,[x_from, x_to], [y_from, y_to];
                    label=:none,
                    line_options...
                )
            end
        else
            x_points = Vector{Vector}()
            y_points = Vector{Vector}()
            for i in dg.edges
                x_from = get_node_data(dg, nodes[i[1]], "x_positions")
                x_to   = get_node_data(dg, nodes[i[2]], "x_positions")
                y_from = get_node_data(dg, nodes[i[1]], "y_positions")
                y_to   = get_node_data(dg, nodes[i[2]], "y_positions")

                push!(x_points, [x_from, x_to])
                push!(y_points, [y_from, y_to])
            end

            #line_options = Dict(:linewidth => linewidth, :linealpha => linealpha, :linecolor => linecolor, :label => :none)
            if typeof(linecolor) <: Vector && length(linecolor) == length(dg.edges)
                for i in 1:length(linecolor)
                    Plots.plot!(plt, x_points[i], y_points[i], linecolor = linecolor[i], linewidth = linewidth, linealpha = linealpha, label = :none)
                end
            else
            Plots.plot!(plt, x_points, y_points, linecolor = linecolor, linewidth = linewidth, linealpha = linealpha, label = :none)
            end
        end
    end

    attribute_map = dg.node_data.attribute_map

    if !(isequal(node_z, nothing))
        nodecolor = cgrad(nodecolor, rev = rev)
    end

    Plots.scatter!(plt, get_node_data(dg)[:, attribute_map["x_positions"]], get_node_data(dg)[:, attribute_map["y_positions"]];
        markercolor=nodecolor,
        markersize=nodesize,
        markerstrokewidth = nodestrokewidth,
        markerstrokecolor = nodestrokecolor,
        markerstrokealpha = nodestrokealpha,
        marker_z = node_z,
        label=:none
    )

    if save_fig
        Plots.savefig(fig_name)
    end

    display(plt)
    return plt
end

# Fix to set in place
function set_matrix_node_positions!(dg::PlasmoData.DataGraph, mat)
    dim1, dim2 = size(mat)

    node_x_vals = zeros(length(dg.nodes))
    node_y_vals = zeros(length(dg.nodes))
    for i in 1:length(dg.nodes)
        node_val  = dg.nodes[i]
        node_x    = Float64(node_val[2] * 5)
        node_y    = Float64((dim1 - node_val[1] * 5))

        node_x_vals[i] = node_x
        node_y_vals[i] = node_y

    end

    add_node_dataset!(dg, node_x_vals, "x_positions")
    add_node_dataset!(dg, node_y_vals, "y_positions")
end

function set_tensor_node_positions!(dg::PlasmoData.DataGraph, tensor)
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

    node_x_vals = zeros(length(dg.nodes))
    node_y_vals = zeros(length(dg.nodes))
    for i in 1:length(dg.nodes)
        node_val = dg.nodes[i]
        node_x = Float64(e1[1] * node_val[1] + e1[2] * node_val[2] + e1[3] * node_val[3]) / e1_norm
        node_y = Float64(e2[1] * node_val[1] + e2[2] * node_val[2] + e2[3] * node_val[3]) / e2_norm

        node_x_vals[i] = node_x
        node_y_vals[i] = node_y
    end

    add_node_dataset!(dg, node_x_vals, "x_positions")
    add_node_dataset!(dg, node_y_vals, "y_positions")
end

function set_node_positions!(
    dg::D,
    C::Real = 1.0,
    K::Real = 0.1,
    iterations::Int = 300,
    tol::Real = 0.1
) where {D <: Union{PlasmoData.DataGraph, PlasmoData.DataDiGraph}}
    am = PlasmoData.adjacency_matrix(dg)

    pos = NetworkLayout.sfdp(Graphs.SimpleGraph(am); tol = tol, C = C, K = K, iterations = iterations)
    nodes = dg.nodes
    for i in 1:length(pos)
        add_node_data!(dg, nodes[i], pos[i][1], "x_positions")
        add_node_data!(dg, nodes[i], pos[i][2], "y_positions")
    end
end

function set_circle_node_positions!(
    dg::D
) where {D <: Union{PlasmoData.DataGraph, PlasmoData.DataDiGraph}}
    num_nodes = length(dg.nodes)

    nodes = dg.nodes
    for i in 1:num_nodes
        value = i / num_nodes * 2 * pi
        add_node_data!(dg, nodes[i], cos(value), "x_positions")
        add_node_data!(dg, nodes[i], sin(value), "y_positions")
    end
end
