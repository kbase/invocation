/*


*/

define('kbasePlantsNetworkNarrative',
    [
        'jquery',
        'kbasePlantsNetworkTable',
        'kbaseForcedNetwork',
        'kbaseTable',
    ],
    function ($) {
        $.KBWidget(
        {

            name: "kbasePlantsNetworkNarrative",
            parent: 'kbaseIrisWidget',

            version: "1.0.0",

            _accessors : [
                'networkTable',
                'networkGraph',
            ],

            options: {

            },

            setInput : function(cds_list) {

                var $self = this;

                var cdses = cds_list.split(/\n/);
                var keyedSpecies = {};
                $.each(
                    cdses,
                    function(idx, cds) {
                        var m;
                        if (m = cds.match(/^(kb\|g\.\d+)/)) {
                            if (m[1]) {
                                keyedSpecies[m[1]]++;
                            }
                        }
                    }
                );

                var species = Object.keys(keyedSpecies);

                if (species.length) {
                    species = species[0];

                    var net_taxon_to_datasets_promise = this.options.$terminal.invoke(
                        this,
                        '((echo "' + species + '" | net_taxon_to_datasets  --url=http://140.221.85.171:7064/KBaseNetworksRPC/networks))'
                    )
                    net_taxon_to_datasets_promise.done(
                        function() {

                            var results = net_taxon_to_datasets_promise.$widget.value();

                            var records = {};
                            var datasets = [];

                            $.each(
                                results,
                                function(idx, val) {
                                    val = val.replace(/\n$/, "");
                                    var array = val.split(/\t/);
                                    var dsObj =
                                        {
                                            dataset : array[0],
                                            network_type : array[1],
                                            source : array[2],
                                            name : array[3],
                                            description : array[4],
                                        }
                                    ;
                                    datasets.push(dsObj.dataset);

                                    var datasetRec = records[dsObj.dataset];
                                    if (datasetRec == undefined) {
                                        datasetRec = records[dsObj.dataset] = {
                                            nodes   : [],
                                            edges   : [],
                                            dataset : dsObj.dataset
                                        };
                                    };

                                    datasetRec.description = dsObj.description;
                                    datasetRec.type = dsObj.network_type;
                                    datasetRec.source = dsObj.source;
                                }
                            );

                            var net_build_internal_network_promise = $self.options.$terminal.invoke(
                                $self,
                                '((echo "' + cds_list + '" | net_build_internal_network --url=http://140.221.85.171:7064/KBaseNetworksRPC/networks "' +
                                    datasets.join(',') + '" "GENE_GENE"))'
                            );

                            net_build_internal_network_promise.done(
                                function() {

                                    var results = net_build_internal_network_promise.$widget.value();

                                    var colorCats = d3.scale.category20();
                                    var nodes = {};

                                    $.each(
                                        results,
                                        function(idx, val) {
                                            val = val.replace(/\n$/, '');
                                            var array = val.split(/\t/);

                                            var datasetRec = records[array[3]];

                                            var color = colorCats(datasets.indexOf(array[3]) % 20);

                                            if (datasetRec) {

                                                var node1 = nodes[array[4]];
                                                if (node1 == undefined) {
                                                    node1 = nodes[array[4]] = { name : array[4], activeDatasets : {} };
                                                }

                                                var node2 = nodes[array[5]];
                                                if (node2 == undefined) {
                                                    node2 = nodes[array[5]] = { name : array[5], activeDatasets : {} };
                                                }

                                                datasetRec.nodes.push(node1);
                                                datasetRec.nodes.push(node2);
                                                datasetRec.edges.push(
                                                    {
                                                        source : node1,
                                                        target : node2,
                                                        color : color
                                                    }
                                                );
                                            }
                                        }
                                    );

                                    var tabularData = [];
                                    $.each(
                                        records,
                                        function(idx, val) {
                                            if (val.nodes.length) {
                                                tabularData.push(
                                                    {
                                                        dataset         : val.dataset,
                                                        nodes           : val.nodes,
                                                        edges           : val.edges,
                                                        description     : val.description,
                                                        type            : val.type,
                                                        source          : val.source,
                                                    }
                                                );
                                            }
                                        }
                                    );

                                    $self.networkTable().setInput(tabularData);

                                }
                            );

                        }
                    );

                    this.networkTable().setInput('');
                }
            },

            appendUI : function($elem) {

                this.$elem.css('border', '1px solid gray');

                var $networkGraph = $.jqElem('div')
                    .css({width : 500, height : 500})
                    .attr('align', 'center')
                    .kbaseForcedNetwork();

                this.networkGraph($networkGraph);


                var $networkTable = $.jqElem('div').kbasePlantsNetworkTable(
                    {
                        $terminal       : this.options.$terminal,
                        networkGraph    : $networkGraph,
                    }
                );
                this.networkTable($networkTable);

                this.$elem
                    .append($networkTable.$elem)
                    .append(
                        $.jqElem('div')
                            .attr('align', 'center')
                            .append($networkGraph.$elem)
                    )
                ;

                $networkGraph.render();

            }
        }

    );
} ) ;
