function plot_graph(dg::PlasmoData.DataDiGraph;
    get_new_positions::Bool=false,
    dag_positions::Bool=false,
    layout = NetworkLayout.Spring(),
    arrow_shift = .8,
    node_size = 25,
    node_color = :black,
    edge_color = :gray,
    edge_width = 3,
    nlabels_fontsize = 16,
    nlabels = nothing,
    save_fig::Bool = false,
    fig_name::String = "plot.png",
)
    layout_fn = _get_digraph_layout(dg, get_new_positions, dag_positions, layout)

    plt = GraphMakie.graphplot(
        dg.g,
        layout = layout_fn,
        arrow_shift = arrow_shift,
        node_size = node_size,
        node_color = node_color,
        edge_color = edge_color,
        edge_width = edge_width,
        nlabels_fontsize = nlabels_fontsize,
        nlabels = nlabels
    )

    Makie.hidespines!(plt.axis)
    Makie.hidedecorations!(plt.axis)
    if save_fig
        Makie.save(fig_name, plt)
    end

    return plt
end

function plot_graph_path(dg::PlasmoData.DataDiGraph,
    src::Any,
    dst::Any;
    path_color = :black,
    get_new_positions::Bool=false,
    dag_positions::Bool=false,
    layout = NetworkLayout.Spring(),
    arrow_shift = .8,
    node_size = 25,
    node_color = :gray,
    edge_color = :gray,
    edge_width = 3,
    nlabels_fontsize = 16,
    nlabels = nothing,
    save_fig::Bool = false,
    fig_name::String = "plot.png",
    intermediate::Bool = false,
    int::Any = dg.nodes[1]
)
    layout_fn = _get_digraph_layout(dg, get_new_positions, dag_positions, layout)

    if isa(node_color, Vector) || isa(node_color, Matrix)
        node_cols = copy(node_color)
    else
        node_cols = Vector{Any}(undef, length(dg.nodes))
        node_cols[:] .= node_color
    end

    if isa(edge_color, Vector) || isa(edge_color, Matrix)
        edge_cols = copy(edge_color)
    else
        edge_cols = Vector{Any}(undef, length(dg.edges))
        edge_cols[:] .= edge_color
    end

    if intermediate
        path = get_path(dg, src, int, dst)
    else
        path = get_path(dg, src, dst)
    end

    node_map = dg.node_map
    nodes = dg.nodes
    edge_map = _get_edge_order(dg)

    for i in 1:(length(path) - 1)
        node_cols[node_map[path[i]]] = path_color
        edge = (node_map[path[i]], node_map[path[i + 1]])
        edge_cols[edge_map[edge]] = path_color
    end

    node_cols[node_map[path[length(path)]]] = path_color

    plt = GraphMakie.graphplot(
        dg.g,
        layout = layout_fn,
        arrow_shift = arrow_shift,
        node_size = node_size,
        node_color = node_cols,
        edge_color = edge_cols,
        edge_width = edge_width,
        nlabels_fontsize = nlabels_fontsize,
        nlabels = nlabels
    )

    Makie.hidespines!(plt.axis)
    Makie.hidedecorations!(plt.axis)
    if save_fig
        Makie.save(fig_name, plt)
    end

    return plt
end


function _get_digraph_layout(dg, get_new_positions, dag_positions, layout)

    if dag_positions
        xs, ys, paths = LayeredLayouts.solve_positions(LayeredLayouts.Zarate(), dg.g)

        add_node_dataset!(dg, xs, "x_positions")
        add_node_dataset!(dg, ys, "y_positions")
    end

    if get_new_positions || !("x_positions" in dg.node_data.attributes) || !("y_positions" in dg.node_data.attributes)
        if !dag_positions
            am = PlasmoData.adjacency_matrix(dg)
            pos = layout(am)

            for i in 1:length(pos)
                add_node_data!(dg, dg.nodes[i], pos[i][1], "x_positions")
                add_node_data!(dg, dg.nodes[i], pos[i][2], "y_positions")
            end
        end
    end

    function layout_graph(g)
        node_vec = Vector{GeometryBasics.Point}()
        for i in 1:length(dg.nodes)
            push!(node_vec, Point(get_node_data(dg, dg.nodes[i], "x_positions"), get_node_data(dg, dg.nodes[i], "y_positions")))
        end

        return node_vec
    end

    return layout_graph
end

function _get_edge_order(
    dg::PlasmoData.DataDiGraph
)

    T = eltype(dg)

    edge_order = [T(1) for i in 1:length(dg.edges)]
    edge_map   = dg.edge_map

    current_index = 1
    for i in 1:length(dg.nodes)
        fadjlist = dg.g.fadjlist[i]
        for j in fadjlist
            edge_order[current_index] = edge_map[(i, j)]
            current_index += 1
        end
    end

    new_edge_map = Dict{Tuple{T, T}, T}()
    new_edges = copy(dg.edges)[edge_order]
    for i in 1:length(new_edges)
        new_edge_map[new_edges[i]] = i
    end

    return new_edge_map
end
