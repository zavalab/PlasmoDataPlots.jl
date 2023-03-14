function plot_graph(dg::DataGraphs.DataDiGraph;
    get_new_positions::Bool=false,
    dag_positions::Bool=false,
    layout = NetworkLayout.Spring(),
    arrow_shift = .8,
    node_size = 18,
    node_color = :black,
    edge_color = :gray,
    edge_width = 2,
    nlabels_fontsize = 12,
    nlabels = nothing,
    save_fig::Bool = false,
    fig_name::String = "plot.png",
)

    if dag_positions
        xs, ys, paths = LayeredLayouts.solve_positions(LayeredLayouts.Zarate(), dg.g)

        add_node_dataset!(dg, xs, "x_positions")
        add_node_dataset!(dg, ys, "y_positions")
    end

    if get_new_positions || !("x_positions" in dg.node_data.attributes) || !("y_positions" in dg.node_data.attributes)
        if !dag_positions
            am = DataGraphs.adjacency_matrix(dg)
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

    layout_fn = layout_graph

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
