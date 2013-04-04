/*


*/

(function( $, undefined ) {


    $.kbWidget("kbaseIrisFileBrowser", 'kbaseFileBrowser', {
        version: "1.0.0",
        options: {

        },

        listDirectory : function (path, $ul) {
            this.data(path, $ul);

            this.client.list_files_async(
                this.sessionId(),
                '/',
                path,
                $.proxy( function(filelist) {
                    var dirs = filelist[0].sort(this.sortByName);
                    var files = filelist[1].sort(this.sortByName);

                    var allFiles = [];

                    $.each(
                        dirs,
                        $.proxy(function(idx, val) {
                            allFiles.push({
                                name : val['name'],
                                path : val['full_path'].replace(/\/+/g, '/'),
                                type : 'directory'
                            })
                        }, this)
                    );

                    $.each(
                        files,
                        $.proxy(function(idx, val) {
                            allFiles.push({
                                name : val['name'],
                                path : val['full_path'].replace(/\/+/g, '/'),
                                type : 'file'
                            });
                        }, this)
                    );

                    this.displayPath(path, $ul, allFiles);

                }, this),
                $.proxy(function (err) {this.dbg(err)},this)
            );
        },

        makeDirectoryCallback : function (dir, parentDir) {
            this.client.make_directory_async(
                this.sessionId,
                parentDir,
                dir,
                $.proxy(function (res) { this.refreshDirectory(parentDir) }, this),
                function() {}
                );
        },

        fetchContent : function(file, win) {

            this.client.get_file_async(
                this.sessionId(),
                file,
                '/',
                $.proxy(
                    function(res) {
                        try {
                            var obj = JSON.parse(res);
                            var jsonStr = JSON.stringify(obj, undefined, 2);
                            res = jsonStr;
                        }
                        catch(e) {
                            this.dbg("FAILURE");
                            this.dbg(e);
                        }
                        this.openFile(file, res, win);
                    }, this),
                $.proxy(function (err) { this.dbg("FILE FAILURE"); this.dbg(err) }, this)
            );
        },

        deleteFileCallback : function(file, active_dir) {
            this.client.remove_files_async(
                this.sessionId,
                '/',
                file,
                $.proxy(function (res) { this.refreshDirectory(active_dir) }, this),
                function() {}
                );
        },

        deleteDirectoryCallback : function(file, active_dir) {
            this.client.remove_directory_async(
                this.sessionId,
                '/',
                file,
                $.proxy(function (res) { this.refreshDirectory(active_dir) }, this),
                function() {}
                );
        },

        uploadFile : function(name, content, upload_dir, $processElem) {
             this.client.put_file_async(
                    this.sessionId(),
                    name,
                    content,
                    upload_dir,
                    jQuery.proxy( function (res) {
                        if (this.options.processList) {
                            this.options.processList.removeProcess($processElem);
                        }
                        this.refreshDirectory(upload_dir)
                    }, this),
                    jQuery.proxy( function (res) {
                        if (this.options.processList) {
                            this.options.processList.removeProcess($processElem);
                        }
                        this.dbg(res);
                    }, this)
                );
        },

        toggleNavHeight : function () {
            if (this.options.shouldToggleNavHeight) {
                var $ul = this.data('ul-nav');
                var height = $ul.css('height');
                $ul.css(
                    'height',
                    height == this.options.height
                        ? this.options.tallHeight
                        : this.options.height
                );
            }
        },

    });

}( jQuery ) );
