/*


*/

define('kbasePlantsNetworkTable',
    [
        'jquery',
        'kbaseIrisWidget',
        'kbaseTable',
    ],
    function ($) {
        $.KBWidget(
        {

            name: "kbasePlantsNetworkTable",
            parent: 'kbaseIrisWidget',

            version: "1.0.0",

            _accessors : [
                'terminal',
                'networkGraph',
            ],

            options: {
                visibleRows : 5,
                extractHeaders : false,
            },

            setInput : function(newInput) {
                this.setValueForKey('input',  newInput);
                this.appendUI(this.$elem);
            },

            appendUI : function($elem) {

                var $self = this;

                if (this.input() == undefined) {
                    this.setError("Cannot use network table widget w/o input file");
                }
                else {
                    var input = this.input();

                    if (input.length > 0) {

                        var $checkbox = $.jqElem('input')
                            .attr('type', 'checkbox')
                        ;

                        var data = {
                            structure : {
                                header      : [
                                    {
                                        value : 'dataset',
                                        label : 'Dataset',
                                        style: "max-width : 200px; background-color : black; color : white",
                                    },
                                    {
                                        value : 'description',
                                        label : 'Description',
                                        style: "min-width : 375px; background-color : black; color : white",
                                    },
                                    {
                                        value : 'num_nodes',
                                        label : 'No. Of Nodes',
                                        style: "max-width : 45px; background-color : black; color : white",
                                    },
                                    {
                                        value : 'num_edges',
                                        label : 'No. Of Edges',
                                        style: "max-width : 45px; background-color : black; color : white",
                                    },
                                    {
                                        value : 'density',
                                        label : 'Density',
                                        style: "max-width : 65px; background-color : black; color : white",
                                    },
                                    {
                                        value : 'type',
                                        label : 'Type',
                                        style: "max-width : 170px; background-color : black; color : white",
                                    },
                                    {
                                        value : 'source',
                                        label : 'Source',
                                        style: "max-width : 60px; background-color : black; color : white",
                                    }
                                ],
                                rows        : [],
                            },
                            sortable    : true,
                            hover       : true,
                            //resizable   : true,
                            headerOptions : {
                                style : 'background-color : black; color : white;',
                                sortable : true,
                            },
                            visibleRows : this.options.visibleRows,
                            visControls : true,
                        };

                        if (this.networkGraph() != undefined) {
                            data.structure.header.unshift({
                                value : 'checkbox',
                                label : '',
                                sortable : false,
                            });
                        };

                        /*data.structure.footer = [
                            {
                                value : 'checkbox',
                                label : 'This is a footer value',
                                style : 'color : blue',
                                colspan : data.structure.header.length,
                            }
                        ];*/


                        var colorCats = d3.scale.category20();

                        $.each(
                            input,
                            function (ridx, row) {

                                row.checkbox = {
                                    value : $checkbox.clone(),
                                    setup : function($checkbox) {
                                            $checkbox.on('click',
                                                function(e) {

                                                    var $check = this;
                                                    //not that we should be able to be here w/o a graph, but just in case.
                                                    if ($self.networkGraph == undefined) {
                                                        return;
                                                    }

                                                    var dataset = $self.networkGraph().dataset();

                                                    if (dataset == undefined) {
                                                        dataset = {
                                                            nodes : [],
                                                            edges : []
                                                        };
                                                    }

                                                    var newDataset = {
                                                        nodes : [],
                                                        edges : []
                                                    };

                                                    var activeNodes = {};
                                                    var activeEdges = {};

                                                    //first thing we do is pull over all the existing nodes/edges
                                                    //only copy from our network if we're checked (not really possible)
                                                    //otherwise, copy all the other networks.
                                                    $.each(
                                                        dataset.nodes,
                                                        function(idx, node) {
                                                            if (node.activeDatasets[row.datasetID] && ! $check.checked) {
                                                                delete node.activeDatasets[row.datasetID];
                                                            }

                                                            if (d3.keys(node.activeDatasets).length) {
                                                                newDataset.nodes.push(node);
                                                                activeNodes[node.name] = 1;
                                                            }
                                                        }
                                                    );

                                                    $.each(
                                                        dataset.edges,
                                                        function(idx, edge) {
                                                            if (edge.activeDatasets[row.datasetID] && ! $check.checked) {
                                                                delete edge.activeDatasets[row.datasetID];
                                                            }

                                                            if (d3.keys(edge.activeDatasets).length) {
                                                                newDataset.edges.push(edge);
                                                                activeEdges[edge.name] = 1;
                                                            }
                                                        }
                                                    );

                                                    if ($check.checked) {
                                                        //okay, now the fun. Finally. Fucking finally. Iterate through the row's
                                                        //nodes and edges and add 'em all to the network.

                                                        $.each(
                                                            row.nodes,
                                                            function (idx, node) {
                                                                node.activeDatasets[row.datasetID] = 1;
                                                                if (! activeNodes[node.name]) {
                                                                    newDataset.nodes.push(node);
                                                                    activeNodes[node.name] = 1;
                                                                }

                                                                node.label = '<b>' + node.name + '</b>'
                                                                    + '<hr>'
                                                                    + d3.keys(node.activeDatasets).sort().join('<br>');
                                                            }
                                                        );

                                                        var color = colorCats(ridx % 20);

                                                        $.each(
                                                            row.edges,
                                                            function (idx, edge) {
                                                                edge.activeDatasets[row.datasetID] = 1;
                                                                edge.color = color;
                                                                if (! activeEdges[edge.name]) {
                                                                    newDataset.edges.push(edge);
                                                                    activeEdges[edge.name] = 1;
                                                                }
                                                            }
                                                        );
                                                    }

                                                    $.each(
                                                        newDataset.nodes,
                                                        function (idx, node) {
                                                            node.label = '<b>' + node.name + '</b>'
                                                                + '<hr>'
                                                                + d3.keys(node.activeDatasets).sort().join('<br>');

                                                            node.radius = 8 + 3 * d3.keys(node.activeDatasets).length;
                                                            node.tagOffsetY = node.radius + 7;
                                                        }
                                                    );

                                                    $.each(
                                                        newDataset.edges,
                                                        function (idx, edge) {
                                                            edge.label = '<b>' + edge.description + '</b>'
                                                                + '<hr>'
                                                                + d3.keys(edge.activeDatasets).sort().join('<br>');
                                                                //edge.weight = d3.keys(edge.activeDatasets).length;
                                                                edge.weight = 1.5;

                                                            if (d3.keys(edge.activeDatasets).length > 1) {
                                                                edge.color = 'black';
                                                            }
                                                            else {
                                                                edge.color = edge.colors[d3.keys(edge.activeDatasets)[0]];
                                                            }
                                                        }
                                                    );

                                                    $self.networkGraph().setDataset(newDataset);
                                                    $self.networkGraph().renderChart();


                                                }
                                            )
                                        }
                                };

                                row.num_nodes = row.nodes.length;
                                row.num_edges = row.edges.length;
                                row.density = (row.num_edges / row.num_nodes).toFixed(3);

                                data.structure.rows.push(row);
                            }
                        );

                        var $tbl = $.jqElem('div').kbaseTable(data);
                        $tbl.sort('num_nodes', -1);
                        $tbl.$elem.css('font-size', '85%');
                        this.setOutput($tbl.$elem);
                        this.$elem.append($tbl.$elem);

                        if (this.options.$terminal) {
                            this.options.$terminal.scroll();
                        }


                        this.setValue(input);


                    }
                }

            }
        }

    );
} ) ;
