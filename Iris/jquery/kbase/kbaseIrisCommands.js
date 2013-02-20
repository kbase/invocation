/*


*/

(function( $, undefined ) {


    $.kbWidget("kbaseIrisCommands", 'kbaseAccordion', {
        version: "1.0.0",
        options: {
            link : function (evt) {
                alert("clicked on " + $(evt.target).text());
            },
            englishCommands : 0,
            fontSize : '75%',
        },

        init: function(options) {

            this._super(options);

            if (options.client) {

                this.client = options.client;
            }

            this.commands = [];

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
                        var commands = [];
                        $.each(
                            res,
                            $.proxy(
                                function (idx, group) {

                                group.title;

                                    var $ul = $('<ul></ul>')
                                        .addClass('unstyled')
                                        .css('max-height', '300px')
                                        .css('overflow', 'auto')
                                    ;

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
                                                        /*.draggable(
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
                                                        )*/
                                                );
                                            },
                                            this
                                        )
                                    );

                                    commands.push(
                                        {
                                            'title' : group.title,
                                            'body' : $ul
                                        }
                                    );
                                },
                                this
                            )
                        );

                        this.loadedCallback($elem, commands);
                    },
                    this
                )
            );

        },

        loadedCallback : function($elem, commands) {

            var $div = $('<div></div>')
                .css('border', '1px solid lightgray')
                .css('padding', '2px')
                .append(
                    $('<h5></h5>')
                        .addClass('text-left')
                        .text("Command List")
                        .css('background-color', 'lightgray')
                        .css('padding', '2px')
                        .css('border-collapse', 'collapse')
                        .css('margin', '0px')
                    )
            ;
            $elem.append($div);

            this._superMethod('appendUI', $div, commands);

            this.data('accordion').css('margin-bottom', '0px');

        },


    });

}( jQuery ) );
