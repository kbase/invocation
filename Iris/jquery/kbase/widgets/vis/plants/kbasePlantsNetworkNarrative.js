/*


*/

define('kbasePlantsNetworkNarrative',
    [
        'jquery',
        'kbasePlantsNetworkTable',
        'kbaseForcedNetwork',
        'kbaseTable',
        'KbaseNetworkServiceClient',
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
                'networkClient',
            ],

            options: {
                networkClientURL : 'http://140.221.85.171:7064/KBaseNetworksRPC/networks',
            },

            init : function(options) {
                this._super(options);

                this.networkClient(
                    new window.KBaseNetworks(
                        this.options.networkClientURL,
                        this.auth()
                    )
                );

                return this;
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
console.log("about to call t2d @ " + new Date());
                    this.networkClient().taxon2datasets(
                        species
                    )
                    .done(
                        function(res) {
console.log("t2d results @ " + new Date());
                            var records = {};
                            var datasets = [];

                            $.each(
                                res,
                                function(idx, rec) {

                                    datasets.push(rec.id);

                                    var datasetRec = records[rec.id];
                                    if (datasetRec == undefined) {
                                        datasetRec = records[rec.id] = {
                                            nodes   : [],
                                            edges   : [],
                                            nodesByName : {},
                                            edgesByName : {},
                                            dataset : rec.id,
                                        };

                                        datasetRec.description = rec.name + ' ' + rec.description;
                                        datasetRec.type = rec.networkType;
                                        datasetRec.source = rec.sourceReference;
                                    };

                                }
                            );
datasets = ['kb|netdataset.plant.cn.191', 'kb|netdataset.plant.cn.192'];
console.log("about to call bin @ " + new Date());
console.log("BIG DATA : " + datasets.length + ',' + cdses.length);
                            $self.networkClient().buildInternalNetwork(
                                datasets,
                                cdses,
                                ['GENE_GENE']
                            )
                            .done(
                                function(results) {
console.log("bin results @ " + new Date());
console.log("RESULTS");
console.log(results);

                                    var colorCats = d3.scale.category20();
                                    var linkScale = d3.scale.linear()
                                        .domain([0, datasets.length])
                                        .range([0,100]);
                                    var nodes = {};

                                    $.each(
                                        results.nodes,
                                        function (idx, node) {
                                            var nodeObj = nodes[node.name];
                                            if (nodeObj == undefined) {
                                                nodeObj = nodes[node.id] = { name : node.name, activeDatasets : {}, id : node.id };
                                            }
                                        }
                                    );

                                    $.each(
                                        results.edges,
                                        function (idx, edge) {

                                            var node1 = nodes[edge.nodeId1];
                                            var node2 = nodes[edge.nodeId2];
                                            var datasetRec = records[edge.datasetId];

                                            if (! datasetRec.nodesByName[node1.name]) {
                                                datasetRec.nodesByName[node1.name] = 1;
                                                datasetRec.nodes.push(node1);
                                            }

                                            if (! datasetRec.nodesByName[node2.name]) {
                                                datasetRec.nodesByName[node2.name] = 1;
                                                datasetRec.nodes.push(node2);
                                            }

                                            var edgeName = [edge.datasetId, node1.name, node2.name].sort().join('-');//node1.name + '-' + node2.name;

                                            var color = colorCats(datasets.indexOf(edge.datasetId) % 20);
                                            var edgeObj = {
                                                    source : node1,
                                                    target : node2,
                                                    color : color,
                                                    activeDatasets : {},
                                                    name : edgeName,
                                                    label : edge.name + '<br>' + node1.name + ' to ' + node2.name + ' (' + edge.strength + ')',
                                                    linknum : linkScale(datasets.indexOf(edge.datasetId)),
                                                };
                                                if (edgeObj.linknum == 14) {
                                                    edgeObj.linknum = 150;
                                                }
console.log("LINKNUM FOR " + edge.datasetId + " IS " + edgeObj.linknum);
                                            if (! datasetRec.edgesByName[edgeName]) {
                                                datasetRec.edgesByName[edgeName] = 1;
                                                datasetRec.edges.push(
                                                    edgeObj
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

                                    $self.data('loader').remove();
console.log("about to set input @ " + new Date());
                                    $self.networkTable().setInput(tabularData);

                                }
                            )
                            .fail(function(res) {
                                $self.dbg("Could not run buildInternalNetwork");
                                $self.dbg(res);
                            });

                        }
                    )
                    .fail(function(res) {
                        $self.dbg("Could not run taxon2datasets");
                        $self.dbg(res);
                    });

//                            net_build_internal_network_promise.done();


                    this.networkTable().setInput('');
                }
                else {
                    this.$elem.empty();
                    this.$elem.append('File format error');
                }
            },

            appendUI : function($elem) {

                this.$elem.css('border', '1px solid gray');

                $elem.empty();
                var $loader = $.jqElem('div')
                            .append('<br>&nbsp;Loading data...<br>&nbsp;please wait...')
                            .append($.jqElem('br'))
                            .append(
                                $.jqElem('div')
                                    .attr('align', 'center')
                                    .append($.jqElem('i').addClass('fa fa-spinner').addClass('fa fa-spin fa fa-4x'))
                            )
                ;
                $elem.append($loader);

                this.data('loader', $loader);

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
