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
                            });
                        };


                        $.each(
                            input,
                            function (idx, row) {

                                row.checkbox = {
                                    value :
                                        $checkbox.clone()
                                            .on('click',
                                                function(e) {
                                                    var $check = this;
                                                    //not that we should be able to be here w/o a graph, but just in case.
                                                    if ($self.networkGraph == undefined) {
                                                        return;
                                                    }
console.log('clicked it!');
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

                                                    //first thing we do is pull over all the existing nodes/edges
                                                    //only copy from our network if we're checked (not really possible)
                                                    //otherwise, copy all the other networks.
                                                    $.each(
                                                        dataset.nodes,
                                                        function(idx, node) {
                                                            if (node.activeDatasets[row.dataset] && ! $check.checked) {
                                                                delete node.activeDatasets[row.dataset];
                                                            }

                                                            if (d3.keys(node.activeDatasets).length) {
                                                                newDataset.nodes.push(node);
                                                            }
                                                        }
                                                    );
console.log('check edges');
console.log(dataset.edges);
                                                    $.each(
                                                        dataset.edges,
                                                        function(idx, edge) {
                                                        console.log(edge);
                                                        console.log(row.edges);
                                                        console.log(row.edges.indexOf(edge));
                                                        console.log($check.checked);
                                                            if (row.edges.indexOf(edge) == -1 || $check.checked) {
                                                                newDataset.edges.push(edge);
                                                            }
                                                        }
                                                    );

                                                    if ($check.checked) {
                                                        //okay, now the fun. Finally. Fucking finally. Iterate through the row's
                                                        //nodes and edges and add 'em all to the network.

                                                        $.each(
                                                            row.nodes,
                                                            function (idx, node) {
                                                                node.activeDatasets[row.dataset] = 1;
                                                                newDataset.nodes.push(node);
                                                            }
                                                        );

                                                        $.each(
                                                            row.edges,
                                                            function (idx, edge) {
                                                                newDataset.edges.push(edge);
                                                            }
                                                        );
                                                    }

                                                    $self.networkGraph().setDataset(newDataset);
                                                    $self.networkGraph().renderChart();


                                                }
                                            )
                                };

                                row.num_nodes = row.nodes.length;
                                row.num_edges = row.edges.length;
                                row.density = row.num_edges / row.num_nodes;

                                data.structure.rows.push(row);
                            }
                        );

                        var $tbl = $.jqElem('div').kbaseTable(data);
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
