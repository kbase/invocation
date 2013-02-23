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
            overflow : true,
            sectionHeight : '300px',
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

        commonPrefix : function(str1, str2) {

            var prefix = '';
            for (var idx = 0; idx < str1.length && idx < str2.length; idx++) {
                var chr1 = str1.charAt(idx);
                var chr2 = str2.charAt(idx);
                if (chr1 == chr2) {
                    prefix = prefix + chr1;
                }
                else {
                    break;
                }
            };

            return prefix;
        },

        comonCommandPrefix : function (commands) {

            var prefix = '';

            if (commands.length > 1) {

            //find the longest common prefix for the first two commands. That's our start.
                prefix = this.commonPrefix(commands[0], commands[1]);

                for (var idx = 2; idx < commands.length; idx++) {
                    prefix = this.commonPrefix(prefix, commands[idx]);
                }

            }
            else {
                prefix = commands[0];
            }

            return prefix;

        },

        commandsMatchingRegex : function (regex) {
            console.log(regex);
            var matches =[];
            for (var idx = 0; idx < this.commands.length; idx++) {
                if (this.commands[idx].match(regex)) {
                    matches.push(this.commands[idx]);
                }
            }

            return matches.sort();
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
                                        .css('max-height', this.options.overflow ? this.options.sectionHeight : '5000px')
                                        .css('overflow', this.options.overflow ? 'auto' : 'visible')
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
                                                    this.createLI(val.cmd, label)
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

        createLI : function(cmd, label) {

            if (label == undefined) {
                label = cmd;
            }

            return $('<li></li>')
                .append($('<a></a>')
                    .attr('href', '#')
                    .attr('title', cmd)
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
        },

        loadedCallback : function($elem, commands) {

            var that = this;

            var $div = $('<div></div>')
                .css('border', '1px solid lightgray')
                .css('padding', '2px')
                .append(
                    $('<h5></h5>')
                        .addClass('text-left')
                        .text("Command List")
                        .css('background-color', 'lightgray')
                        .css('padding', '2px')
                        .css('margin', '0px')
                        .bind('click',
                            function(e) {
                                $(this).next().collapse('toggle');
                                if (that.options.fileBrowser) {
                                    that.options.fileBrowser.toggleNavHeight();
                                }
                            }
                        )
                )
                .append(
                    $('<ul></ul>')
                        .css('font-size', this.options.fontSize)
                        .css('padding-left', '15px')
                        .attr('id', 'searchResults')
                        .addClass('unstyled')
                )
            ;
            $elem.append($div);

            this._rewireIds($div, this);

            this._superMethod('appendUI', $div, commands);

            this.data('accordion').css('margin-bottom', '0px');

        },


    });

}( jQuery ) );
