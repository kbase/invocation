/*


*/

(function( $, undefined ) {


    $.kbWidget("kbaseIrisFileBrowser", 'kbaseDataBrowser', {
        version: "1.0.0",
        _accessors : ['client', '$terminal', '$loginbox', 'addFileCallback', 'editFileCallback', 'singleFileSize'],
        options: {
            uploadDir : 'uploads',
            concurrentUploads : 3,
            singleFileSize : '1000000',
            title : 'File Browser',
            'root' : '/',
            types : {
                file : {
                    controls :
                    [
                        {
                            icon : 'icon-minus',
                            callback : function(e, $fb) {
                                $fb.deleteFile($(this).data('id'), 'file');
                            },
                            id : 'removeButton',
                            tooltip : 'delete this file',
                        },
                        {
                            icon : 'icon-eye-open',
                            callback : function(e, $fb) {
                                $fb.openFile($(this).data('id'));
                            },
                            id : 'viewButton',
                            'tooltip' : 'view this file',
                        },
                        {
                            icon : 'icon-pencil',
                            callback : function(e, $fb) {
                                if ($fb.editFileCallback() != undefined) {
                                    $fb.editFileCallback()($(this).data('id'), $fb);
                                }
                            },
                            id : 'editButton',
                            tooltip : 'edit this file',
                            condition : function (control, $fb) {
                                return $fb.editFileCallback() == undefined
                                    ? false
                                    : true;
                            },
                        },
                        {
                            icon : 'icon-arrow-right',
                            callback : function(e, $fb) {
                                if ($fb.addFileCallback() != undefined) {
                                    $fb.addFileCallback()($(this).data('id'), $fb);
                                }
                            },
                            id : 'addButton',
                            'tooltip' : 'add this file to terminal input',
                        },
                    ],
                },
                folder : {
                    childrenCallback : function (path, callback) {

                        this.listDirectory(path, function (results) {
                            callback(results);
                        });
                    },
                    controls : [
                        {
                            icon : 'icon-minus',
                            'tooltip' : 'delete this folder',
                            callback : function(e, $fb) {
                                $fb.deleteFile($(this).data('id'), 'folder');
                            },
                            id : 'removeDirectoryButton'
                        },
                        {
                            icon : 'icon-plus',
                            'tooltip' : 'add a subdirectory',
                            callback : function(e, $fb) {
                                $fb.addDirectory($(this).data('id'));
                            },
                            id : 'addDirectoryButton'
                        },
                        {
                            icon : 'icon-arrow-up',
                            'tooltip' : 'upload a file',
                            callback : function(e, $fb) {
                                $fb.data('active_directory', $(this).data('id'));
                                $fb.data('fileInput').trigger('click');
                            },
                            id : 'uploadFileButton'
                        },

                    ],
                }
            },
        },

        init: function (options) {

            this._super(options);

            this.listDirectory(this.options.root, $.proxy(function (results) {
                this.appendContent(results, this.data('ul-nav'))
            }, this));

            this.client().make_directory_async(
                this.sessionId(),
                '/',
                this.options.uploadDir
            )
            .always(
                $.proxy( function(res) {
                console.log(res);
                console.log('list files after create upload');
                    this.client().list_files(
                        this.sessionId(),
                        '/',
                        this.options.uploadDir
                    )
                    .done(
                        $.proxy(function(filelist) {
                            var dirs = filelist[0];

                            $.each(
                                dirs,
                                $.proxy(function (idx, dir) {
                                    console.log('already has dir ' + dir.name);
                                    console.log(dir);
                                    this.client().get_file(
                                        this.sessionId(),
                                        'chunkMap',
                                        '/' + this.options.uploadDir + '/' + dir.name
                                    )
                                    .done(
                                        $.proxy( function (res) {
                                            var chunkMap;
                                            try {
                                                var chunkMap = JSON.parse(res);
                                            }
                                            catch(e) {
                                                this.dbg("Could not load chunk map");
                                                this.dbg(e);
                                            };

                                            console.log("LOADED CHUNKMAP");
                                            console.log(chunkMap);
                                            console.log(dir.name);

                                            chunkMap.doneChunks = 0;;
                                            chunkMap.numChunks  = chunkMap.length;
                                            chunkMap.complete = {};

                                            while (chunkMap.length > 0) {
                                                var chunk = chunkMap.shift();
                                                chunkMap.complete[chunk.name] = chunk;
                                            }

                                            this.checkAndMergeChunks(dir.name, chunkMap);
                                        }, this)
                                    )


                                }, this)
                            );


                        }, this)
                    )
                }, this)
            );

            return this;

        },

        prepareRootContent : function() {

            var $ul = this._super();
            $ul.css('height', (parseInt(this.options.height) - 25) + 'px');

            var $pc = $('<div></div>').css('margin-top', '2px')
            $pc.kbaseButtonControls(
                {
                    onMouseover : false,
                    context : this,
                    controls : [
                        {
                            'icon' : 'icon-plus',
                            'tooltip' : 'add directory',
                            callback : function(e, $fb) {
                                $fb.addDirectory('/');
                            },

                        },
                        {
                            'icon' : 'icon-arrow-up',
                            'tooltip' : 'upload a file',
                            callback : function(e, $fb) {
                                $fb.data('active_directory', $(this).data('id'));
                                $fb.data('fileInput').trigger('click');
                            }
                        },
                    ]

                }
            );
            return $('<div></div>')
                .css('height', this.options.height)
                .append($ul)
                .append($pc)
                .append(
                    $('<input></input>')
                        .attr('type', 'file')
                        .attr('id', 'fileInput')
                        .css('display', 'none')
                        .bind( 'change', $.proxy(this.handleFileSelect, this) )
                )
        },

        sessionId : function() {
            if (this.$terminal() != undefined) {
                return this.$terminal().sessionId;
            }
            else if (this.$loginbox() != undefined) {
                return this.$loginbox().sessionId();
            }
            else {
                return undefined;
            }
        },

        refreshDirectory : function(path) {

            if (this.sessionId() == undefined) {
                this.data('ul-nav').empty();
                return;
            }

            var $target = path == '/'
                ? this.data('ul-nav')
                : this.targets[path].next();

            var pathRegex = new RegExp('^' + path);

            var openTargets = [];
            for (var subPath in this.targets) {
                if (
                       subPath.match(pathRegex)
                    && ! this.targets[subPath].next().is(':hidden')
                    && this.targets[subPath].next().is('ul')) {
                        openTargets.push(subPath);
                }
            }

            if (! $target.is(':hidden')) {
                this.listDirectory(path, $.proxy(function (results) {
                    $target.empty();
                    this.appendContent(results, $target)
                }, this), openTargets);
            }

            $.each(
                openTargets,
                $.proxy(function (idx, subPath) {
                    var $target = this.targets[subPath].next();

                    this.listDirectory(subPath, $.proxy(function (results) {
                        $target.empty();
                        this.appendContent(results, $target)
                        $target.show();
                    }, this));
                }, this)
            );

        },

        listDirectory : function (path, callback) {

            this.client().list_files(
                this.sessionId(),
                '/',
                path,
                jQuery.proxy( function (filelist) {
                    var dirs = filelist[0];
                    var files = filelist[1];

                    var results = [];

                    var $fb = this;

                    jQuery.each(
                        dirs.sort(this.sortByKey('name')),
                        $.proxy(function (idx, val) {
                            val['full_path'] = val['full_path'].replace(/\/+/g, '/');
                            results.push(
                                {
                                    'type' : 'folder',
                                    'id' : val['full_path'],
                                    'label' : val['name'],
                                    'open' : $fb.openTargets[ val['full_path'] ]
                                }
                            )
                        }, this)
                    );

                    jQuery.each(
                        files.sort(this.sortByKey('name')),
                        $.proxy(function (idx, val) {
                            val['full_path'] = val['full_path'].replace(/\/+/g, '/');

                            results.push(
                                {
                                    'type' : 'file',
                                    'id' : val['full_path'],
                                    'label' : val['name'],
                                }
                            )
                        }, this)
                    );

                    results = results.sort(this.sortByKey('label'));

                    callback(results);

                    }, this
                ),
                $.proxy(function (err) {this.dbg(err)},this)
            );

        },

        handleFileSelect : function(evt) {

            evt.stopPropagation();
            evt.preventDefault();

            var files = evt.target.files
                || evt.originalEvent.dataTransfer.files
                || evt.dataTransfer.files;

            $.each(
                files,
                jQuery.proxy(
                    function (idx, file) {


                        var upload_dir = '/';
                        if (this.data('active_directory')) {
                            upload_dir = this.data('active_directory');
                        }

console.log("LOADS FILE " + file.name);
console.log("LOADS size " + file.size);

                        var $processElem;
                        if (this.options.processList) {
                            $processElem = this.options.processList.addProcess('Uploading ' + file.name + ' ...0%');
                        }

                        if (file.size <= this.singleFileSize() ) {

                            var reader = new FileReader();

                            if (this.options.processList) {
                                reader.onprogress = $.proxy(function (e) {
                                    this.options.processList.removeProcess($processElem);
                                    $processElem = this.options.processList.addProcess('Uploading ' + file.name + ' ... ' + (100 * e.loaded / e.total).toFixed(2) + '%')
                                    this.dbg('progress ' + (e.loaded / e.total));
                                    this.dbg(e);
                                }, this)
                            }


                            reader.onload = jQuery.proxy(
                                function(e) {

                                    this.client().put_file(
                                        this.sessionId(),
                                        file.name,
                                        e.target.result,
                                        upload_dir,
                                        jQuery.proxy( function (res) {
                                            if (this.options.processList) {
                                                this.options.processList.removeProcess($processElem);
                                            }
                                            this.refreshDirectory(upload_dir)
                                        }, this),
                                        jQuery.proxy( function (res) {
                                        console.log("FAILED?");console.log(res);
                                            if (this.options.processList) {
                                                this.options.processList.removeProcess($processElem);
                                            }
                                            this.dbg(res);
                                        }, this)
                                    );
                                },
                                this
                            );

                            reader.readAsText(file);
                        }
                        else {
                            console.log('file needs to be chunked');
                            var fileSize = file.size;
                            var chunkSize = parseInt(this.singleFileSize());
                            var chunk = 1;
                            var offset = 0;
                            var chunkMap = [];

                            if (this.data('resumed_chunkMap') != undefined) {
                                chunkMap = this.data('resumed_chunkMap');

                                if (this.options.processList) {
                                    this.options.processList.removeProcess($processElem);
                                    if (chunkMap.$processElem) {
                                        this.options.processList.removeProcess(chunkMap.$processElem);
                                    }
console.log("CM");
console.log(chunkMap.doneChunks);
console.log(chunkMap.numChunks);
                                    var percent = (100 * chunkMap.doneChunks / chunkMap.numChunks).toFixed(2);
                                    if (percent >= 100) {
                                        percent = 99;
                                    }
                                    chunkMap.$processElem = this.options.processList.addProcess('Uploading ' + chunkMap.realizedPath + ' ... ' + percent + '%')

                                }

                                this.data('resumed_chunkMap', undefined);
                                console.log("RESTART WITH");console.log(chunkMap);
                                console.log(chunkMap.complete);

                            }
                            else {

                                while (fileSize > 0) {
                                    if (chunkSize > fileSize) {
                                        chunkSize = fileSize;
                                    }
                                    fileSize -= chunkSize;
                                    console.log("chunk " + chunk + " == " + chunkSize);
                                    console.log("from " + offset + " to " + (offset + chunkSize - 1));

                                    chunkMap.push(
                                        {
                                            chunk : chunk,
                                            name : 'chunk.' + chunk,
                                            start : offset,
                                            end : (offset + chunkSize),
                                            size : chunkSize,
                                            complete : false,
                                        }
                                    );

                                    offset = offset + chunkSize;
                                    chunk++;
                                }

                                chunkMap.doneChunks = 0;;
                                chunkMap.numChunks  = chunkMap.length;
                                chunkMap.$processElem = $processElem;
                            }

                            var pathName = upload_dir + '/' + file.name;
                            pathName = pathName.replace(/\/\/+/g, '/');
                            pathName = pathName.replace(/\//g, '::');

                            if (this.data('resumed_pathName') != undefined) {
                                pathName = this.data('resumed_pathName');
                                this.data('resumed_pathName', undefined);
                            }

console.log(pathName);
                            var callback = $.proxy(function (res) {
                                var chunker = this.makeChunkUploader(file, pathName, chunkMap, $processElem);
                                for (var i = 0; i < this.options.concurrentUploads; i++) {
                                    chunker();
                                }

                            }, this);

                            this.client().make_directory(
                                this.sessionId(),
                                '/' + this.options.uploadDir,
                                pathName

                            ).always(
                                $.proxy(function() {
                                    this.client().put_file(
                                        this.sessionId(),
                                        'chunkMap',
                                        JSON.stringify(chunkMap, undefined, 2),
                                        '/' + this.options.uploadDir + '/' + pathName
                                    ).done(callback)
                                }, this)
                            );

                        }

                    },
                    this
                )
            );

            this.data('fileInput').val('');

        },

        makeChunkUploader : function(file, pathName, chunkMap, $processElem) {
            chunkMap.jobs = 0;
            if (chunkMap.complete == undefined) {
                chunkMap.complete = {};
            }
            var $fb = this;

            var uploadPath = '/' + this.options.uploadDir + '/' + pathName;

            return function() {
console.log("FILE IS ");console.log(file);
//console.log(file.prototype.webkitSlice);
//console.log(file.prototype.slice);
console.log("PATH " + uploadPath);
console.log(chunkMap);
var recursion = arguments.callee;
                if (chunkMap.length > 0) {
                    var chunk = chunkMap.shift();
                    chunkMap.complete[chunk.name] = chunk;

                    var blob = file.webkitSlice(chunk.start, chunk.end);
console.log('uploading chunk + ' + chunk.chunk);
                    var reader = new FileReader();

                    reader.onloadend = function(e) {

                        if (e.target.readyState == FileReader.DONE) {
console.log("UPLOADS CHUNK " + chunk);
console.log(e);
console.log(chunk.chunk);
console.log(uploadPath);
                            $fb.client().put_file(
                                $fb.sessionId(),
                                chunk.name,
                                e.target.result,
                                uploadPath,
                                jQuery.proxy( function (res) {

                                    chunkMap.doneChunks++;

                                    if ($fb.options.processList) {
                                        $fb.options.processList.removeProcess(chunkMap.$processElem);
                                        var percent = (100 * chunkMap.doneChunks / chunkMap.numChunks).toFixed(2);
                                        if (percent >= 100) {
                                            percent = 99;
                                        }
                                        chunkMap.$processElem = $fb.options.processList.addProcess('Uploading ' + file.name + ' ... ' + percent + '%')
                                    }

                                    chunkMap.jobs--;
                                    console.log('uploaded chunk!');
                                    recursion();
                                }, this),
                                jQuery.proxy( function (res) {
                                    chunkMap.jobs--;
                                    chunkMap.push(chunk);
                                    chunkMap.complete[chunk.name] = undefined;
                                    console.log('failed chunk!');
                                    console.log(res);
                                }, this)
                            );
                        }
                    };

                    chunkMap.jobs++;
                    reader.readAsBinaryString(blob);
                }
                else if (chunkMap.jobs == 0) {
                    console.log("success...begin concatenation");
                    $fb.checkAndMergeChunks(pathName, chunkMap, recursion);
                }
                else {
                    console.log("done uploading, but jobs still pending");
                    console.log(chunkMap.jobs);
                }
            }
        },

        checkAndMergeChunks : function(pathName, chunkMap, chunkUploader) {

            var completeChunks = chunkMap.complete;

            this.client().list_files(
                this.sessionId(),
                '/' + this.options.uploadDir,
                pathName,
                $.proxy( function (filelist) {
                    var dirs    = filelist[0];
                    var files   = filelist[1];

                    var results = [];

                    var $fb = this;
                    var canMerge = true;

                    var successfulChunks = 0;

                    var fileSizes = {};

                    jQuery.each(
                        files,
                        $.proxy(function (idx, val) {
console.log("VN " + val.name);
                            fileSizes[val.name] = val.size;
                        }, this)
                    );

                    $.each(
                        completeChunks,
                        $.proxy (function (name, val) {
                            var size = completeChunks[val.name].size;

console.log("COMPARES SIZE " + size + " vs " + fileSizes[name] + ' on ' + name);

                            if (size == fileSizes[name]) {
                                completeChunks[val.name].complete = true;
                                successfulChunks++;
                            }
                            else {
                                console.log("FAILED ON CHUNK " + name + " " + size + " != " + fileSizes[name]);
                                completeChunks[val.name].complete = false;
                                chunkMap.push(completeChunks[val.name]);
                                canMerge = false;
                            }

                        }, this)
                    );

                    if (canMerge) {
                        var chunkList = [];
                        for (chunk in completeChunks) {
                            chunkList.push(completeChunks[chunk]);
                        }
                        chunkMap.chunkList = chunkList;
                        var merger = this.makeChunkMerger(pathName, chunkMap);
                        merger();
                    }
                    else if (chunkUploader) {
                        chunkUploader();
                    }
                    else {
                        console.log("cannot merge, no chunkuploader");
                        //okay. We fall into here IF we have a chunkmap and no chunkuploader.
                        //this'll occur if we're checking a chunkmap from a prior upload and it's
                        //incomplete.
                        if (this.options.processList) {
                            if (chunkMap.$processElem) {
                                this.options.processList.removeProcess(chunkMap.$processElem);
                            }

                            var realizedPath = pathName.replace(/::/g, '/');
                            realizedPath = realizedPath.replace(/^\//, '');

                            chunkMap.realizedPath = realizedPath;
                            chunkMap.doneChunks = successfulChunks;
                            chunkMap.numChunks = chunkMap.length + successfulChunks;

                            console.log("CM1");
                            console.log(chunkMap.numChunks);
                            console.log(chunkMap.doneChunks);

                            var percent = (100 * chunkMap.doneChunks / chunkMap.numChunks).toFixed(2);
                            if (percent >= 100) {
                                percent = 99;
                            }
                            var $pe = $('<div></div>').text('Uploading ' + realizedPath + ' ...stalled at ' + percent + '%');
                            $pe.kbaseButtonControls(
                                {
                                    onMouseover : true,
                                    context : this,
                                    controls : [
                                        {
                                            'icon' : 'icon-refresh',
                                            'tooltip' : 'Restart',
                                            callback : function(e, $fb) {
                                                console.log("Syncing job");
                                                $fb.data('resumed_pathName', pathName);
                                                $fb.data('resumed_chunkMap', chunkMap);
                                                $fb.data('fileInput').trigger('click');
                                            },

                                        },
                                        {
                                            'icon' : 'icon-ban-circle',
                                            'tooltip' : 'Cancel',
                                            callback : function(e, $fb) {
                                                console.log("Canceling job");

                                                $fb.client().remove_directory(
                                                    $fb.sessionId(),
                                                    '/',
                                                    $fb.options.uploadDir + '/' + pathName,
                                                    function () {
                                                        if ($fb.options.processList) {
                                                            $fb.options.processList.removeProcess(chunkMap.$processElem);
                                                        }
                                                        $fb.refreshDirectory('/' + target_dir);
                                                    }
                                                );

                                            }
                                        },
                                    ]

                                }
                            );

                            chunkMap.$processElem = this.options.processList.addProcess($pe);
                        }
                    }


                }, this)
            );

        },

        makeChunkMerger : function(pathName, chunkMap) {

            var chunkList = chunkMap.chunkList;

            var $fb = this;
            var realizedPath = pathName.replace(/::/g, '/');
            realizedPath = realizedPath.replace(/^\//, '');

            var target_dir = realizedPath.replace(/\/[^\/]+$/, '');

            var uploadPath = $fb.options.uploadDir + '/' + pathName + '/upload';
            uploadPath = uploadPath.replace(/\/\/+/, '/');

            return function() {

                if (chunkList.length == 0) {

                    $fb.client().rename_file(
                        $fb.sessionId(),
                        '/',
                        uploadPath,
                        realizedPath,
                        function () {

                            $fb.client().remove_directory(
                                $fb.sessionId(),
                                '/',
                                $fb.options.uploadDir + '/' + pathName,
                                function () {
                                    if ($fb.options.processList) {
                                        $fb.options.processList.removeProcess(chunkMap.$processElem);
                                    }
                                    $fb.refreshDirectory('/' + target_dir);
                                }
                            );

                        }
                    );

                    return;
                }

                var chunk = chunkList.shift();

                var recursion = arguments.callee;

                console.log(chunk);
//recursion();
//return;

                var fullChunkPath = $fb.options.uploadDir + '/' + pathName + '/' + chunk.name;
                fullChunkPath = fullChunkPath.replace(/\/\/+/, '/');

console.log("WILL COPY FROM " + fullChunkPath + " -> " + uploadPath);
console.log("IN PATH" + '/' + $fb.options.uploadDir + '/' + pathName);


                $fb.client().run_pipeline(
                    $fb.sessionId(),
                    "cat " + fullChunkPath + ' >> ' + uploadPath,
                    [],
                    0,
                    '/',
                    $.proxy( function (runout) {

                        if (runout) {
                            var output = runout[0];
                            var error  = runout[1];

                            if (! error.length) {
                                $fb.client().remove_files(
                                    $fb.sessionId(),
                                    '/' + $fb.options.uploadDir + '/' + pathName,
                                    chunk.name,
                                    $.proxy(function (res) {
                                        recursion();
                                    }, $fb)
                                )
                            }
                        }
                    }, this),
                    function (res) {
                        console.log("OMFG ERR");console.log(res);
                    }
                )

            }

        },


        openFile : function(file) {

            // can't open the window in trhe callback!
            var win = window.open();
            win.document.open();

            this.client().get_file(
                this.sessionId(),
                file,
                '/',
                $.proxy(
                    function (res) {

                        try {
                            var obj = JSON.parse(res);
                            res = JSON.stringify(obj, undefined, 2);
                        }
                        catch(e) {
                            this.dbg("FAILURE");
                            this.dbg(e);
                        }

                        win.document.write(
                            $('<div></div>').append(
                                $('<div></div>')
                                    .css('white-space', 'pre')
                                    .append(res)
                            )
                            .html()
                        );
                        win.document.close();

                    },
                    this
                ),
                function (err) { this.dbg("FILE FAILURE"); this.dbg(err) }
            );
        },

        deleteFile : function(file, type) {

            var deleteMethod = type == 'file'
                ? 'remove_files'
                : 'remove_directory';

            file = file.replace(/\/+$/, '');

            var matches = file.match(/(.+)\/[^/]+$/);

            var active_dir = '/';
            if (matches != undefined && matches.length > 1) {
                active_dir = matches[1];
            }

            var that = this; //sigh. The confirm button needs it for now.

            var promptFile = file.replace(this.options.root, '');

            var $deleteModal = $('<div></div>').kbaseDeletePrompt(
                {
                    name : promptFile,
                    callback : function(e, $prompt) {
                        $prompt.closePrompt();
                        that.client()[deleteMethod](
                            that.sessionId,
                            '/',
                            file,
                            function (res) { that.refreshDirectory(active_dir) },
                            function() {}
                            );
                    }
                }
            );

            $deleteModal.openPrompt();

        },

        addDirectory : function(parentDir) {
            var that = this;

            var displayDir = parentDir.replace(this.options.root, '/');

            var $addDirectoryModal = $('<div></div>').kbasePrompt(
                {
                    title : 'Create directory',
                    body : $('<p></p>')
                            .append('Create directory ')
                            .append(
                                $('<span></span>')
                                    .css('font-weight', 'bold')
                                    .text(displayDir)
                            )
                            .append(' ')
                            .append(
                                $('<input></input>')
                                    .attr('type', 'text')
                                    .attr('name', 'dir_name')
                                    .attr('size', '20')
                            )
                    ,
                    controls : [
                        'cancelButton',
                        {
                            name : 'Create directory',
                            type : 'primary',
                            callback : function(e, $prompt) {
                                $prompt.closePrompt();
                                that.client().make_directory(
                                    that.sessionId,
                                    parentDir,
                                    $addDirectoryModal.dialogModal().find('input').val(),
                                    function (res) { that.refreshDirectory(parentDir) },
                                    function() {}
                                    );
                            }
                        }
                    ]
                }
            );

            $addDirectoryModal.openPrompt();


        },

    });

}( jQuery ) );
