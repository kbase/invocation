/*


*/

(function( $, undefined ) {


    $.KBWidget(
        {

            name: "kbaseIrisTerminalWidget",
            parent: 'kbaseIrisWidget',

            version: "1.0.0",

            _accessors : [

            ],

            options: {
                subCommand : false,
            },

            init : function(options) {
                this._super(options);

                $(document).on(
                    'updateIrisProcess.kbaseIris',
                    $.proxy(function (e, params) {
                        if (params.pid == this.pid()) {
                            this.startThinking();
                        }
                    }, this)
                );

                $(document).on(
                    'removeIrisProcess.kbaseIris',
                    $.proxy(function (e, pid) {
                        if (pid == this.pid()) {
                            this.stopThinking();
                        }
                    }, this)
                );

                $(document).on(
                    'clearIrisProcesses.kbaseIris',
                    $.proxy(function (e) {
                        this.stopThinking();
                    }, this)
                );

                return this;
            },

            appendUI : function($elem) {

                var $inputDiv = $.jqElem('div')
                    .css('white-space', 'pre')
                    .css('position', 'relative')
                    .css('style', 'font-weight : bold')
                    .append('&gt;')
                    .append(
                        $.jqElem('span')
                            .attr('id', 'cwd')
                            .addClass('command')
                            .kb_bind(this, 'cwd')
                    )
                    .append('&nbsp;')
                    .append(
                        $.jqElem('span')
                            .attr('id', 'input')
                            .addClass('command')
                            .kb_bind(this, 'input')
                    )
                    .mouseover(
                        function(e) {
                            $(this).children().first().show();
                        }
                    )
                    .mouseout(
                        function(e) {
                            $(this).children().first().hide();
                        }
                    )
                ;

                $inputDiv.kbaseButtonControls(
                    {
                        context : this,
                        controls : [
                            {
                                icon : 'icon-eye-open',
                                //tooltip : 'view output',
                                callback :
                                    function (e, $it) {
                                        $it.viewOutput();
                                    },
                            },
                            {
                                icon : 'icon-remove',
                                //tooltip : 'remove command',
                                callback :
                                    function (e) {
                                        var $next = $elem.next();
                                        if ($next.prop('tagName') == 'HR') {
                                            $next.remove();
                                        }
                                        $elem.remove();
                                    }
                            },
                            {
                                icon : 'icon-caret-up',
                                'icon-alt' : 'icon-caret-down',
                                //tooltip : {title : 'collapse / expand', placement : 'bottom'},
                                callback : $.proxy(function(e) {
                                    this.data('output').toggle();
                                    this.data('error').toggle();
                                    this.data('line').toggle();
                                }, this)
                            },

                        ]
                    }
                );

                $elem
                    .append(
                        $.jqElem('div')
                            .attr('id', 'thoughtBox')
                            .addClass('pull-left')
                            .append( $.jqElem('i').addClass('icon-spinner icon-spin') )
                            .css('display', 'none')
                    )
                    .append(
                        $inputDiv
                            .attr('id', 'inputContainer')
                            .on('click',
                                $.proxy(function(e) {
                                    this.data('output').show();
                                    this.data('error').show();
                                    this.data('line').show();
                                }, this)
                            )
                    )
                    .append(
                        $.jqElem('div')
                            .attr('id', 'output')
                            .kb_bind(this, 'output')
                    )
                    .append(
                        $.jqElem('div')
                            .attr('id', 'error')
                            .css('font-style', 'italic')
                            .kb_bind(this, 'error')
                    )
                    .append($.jqElem('hr').attr('id', 'line'))
                ;

                this._rewireIds($elem, this);

                return $elem;

            },

            startThinking : function() {
                this.data('thoughtBox').show();
            },

            stopThinking : function() {
                this.data('thoughtBox').hide();
            },

            setError : function (newVal) {
                this._super(newVal);

                if ( newVal.match(/error/i) ) {
                    this.data('inputContainer').css('color', 'red');
                }

            },

            setSubCommand : function(subCommand, open) {

                if (this.data('inputContainer') == undefined) {
                    return;
                }

                if (subCommand) {
                    this.data('inputContainer').css('color', 'gray');
                    if (! open) {
                        this.data('output').hide();
                        this.data('error').hide();
                        this.data('line').hide();
                    }
                }
                else {
                    this.data('inputContainer').css('color', 'black');
                }

                this._super(subCommand);

            },
        }

    );

}( jQuery ) );
