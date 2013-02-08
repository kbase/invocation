/*


*/


(function( $, undefined ) {


    $.widget("kbaseIris.commands", $.kbase.widget, {
        version: "1.0.0",
        options: {
            link : function (evt) {
                alert("clicked on " + $(evt.target).text());
            },
            englishCommands : 1,
        },

        _create : function() {
            if (this.options.client) {
                this.client = this.options.client;
            }
            else {
                this.client = new InvocationService('http://bio-data-1.mcs.anl.gov/services/invocation');
            }

            this.commands = [];

            return this;
        },

        _init: function() {

            this.appendUI( $( this.element ) );

            return this;

        },

        completeCommand : function(command) {

            var completions = [];

            var commandRegex = new RegExp('^' + command + '.*');

            for (var idx = 0; idx < this.commands.length; idx++) {
                if (this.commands[idx].match(commandRegex)) {
                    completions.push(this.commands[idx]);
                }
            }

            return completions;
        },

        appendUI : function($elem) {
            this.client.valid_commands_async(
                $.proxy(
                    function (res) {
                        $.each(
                            res,
                            $.proxy(
                                function (idx, group) {

                                    var $ul = $('<ul></ul>');

                                    $elem.append(
                                        $('<h3></h3>')
                                            .append(
                                                $('<a></a>')
                                                    .attr('href', '#')
                                                    .text(group.title)
                                        )
                                    )
                                    .append(
                                        $('<div></div>')
                                            .css('padding', '0px')
                                            .append($ul)
                                    );

                                    $.each(
                                        group.items,
                                        $.proxy(
                                            function (idx, val) {
                                                var label = val.cmd;
                                                if (this.options.englishCommands) {

                                                    var metaFunc = MetaToolInfo(val.cmd);
                                                    if (metaFunc != undefined) {
                                                        var meta = metaFunc(val.cmd);
                                                        label = meta.label;
                                                    }
                                                }

                                                this.commands.push(val.cmd);

                                                $ul.append(
                                                    $('<li></li>')
                                                        .append($('<a></a>')
                                                            .attr('href', '#')
                                                            .attr('title', val.cmd)
                                                            .data('blockType', 'narrativeBlock')
                                                            .css('display', 'list-item')
                                                            //.tooltip()
                                                            .text(label)
                                                            .bind(
                                                                'click',
                                                                this.options.link
                                                            )
                                                        )
                                                        .draggable(
                                                            {
                                                                distance : 20,
                                                                cursor   : 'pointer',
                                                                opacity  : 0.7,
                                                                helper   : 'clone',
                                                                connectToSortable: this.options.connectToSortable,
                                                                revert : 'invalid',
                                                                disabled : this.options.connectToSortable == undefined,
                                                                cursorAt : {
                                                                    left : 5,
                                                                    top  : 5
                                                                }
                                                            }
                                                        )
                                                );
                                            },
                                            this
                                        )
                                    );
                                },
                                this
                            )
                        );

                        this.loadedCallback($elem);
                    },
                    this
                )
            );

        },

        loadedCallback : function($elem) {

            $elem.accordion({heightStyle : 'fill', collapsible : true, active : false });

        },


    });

}( jQuery ) );
