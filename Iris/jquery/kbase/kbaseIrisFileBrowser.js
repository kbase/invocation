/*


*/

(function( $, undefined ) {


    $.kbWidget("kbaseIrisFileBrowser", 'kbaseDataBrowser', {
        version: "1.0.0",
        _accessors : ['client', '$terminal', '$loginbox', 'addFileCallback', 'editFileCallback', 'singleFileSize', 'stalledUploads'],
        options: {
            stalledUploads : {},
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

            this.client().make_directory(
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

                                            while (chunkMap.chunks.length > 0) {
                                                var chunk = chunkMap.chunks.shift();
                                                chunkMap.chunksByName[chunk.name] = chunk;
                                                chunkMap.doneChunks.push(chunk);
                                            }

                                            this.checkAndMergeChunks(chunkMap);
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
console.log(path);
console.log(this.targets);

            var $target;

            if (path == '/') {
                $target = this.data('ul-nav');
            }
            else {
                var path_target = this.targets[path];
                if (path_target == undefined) {
                    return;
                }

                else $target = path_target.next();
            }

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

                        var fullFilePath     = upload_dir + '/' + file.name;
                        fullFilePath         = fullFilePath.replace(/\/\/+/g, '/');

                        var pid = this.uuid();
                        this.trigger(
                            'updateIrisProcess',
                            {
                                pid : pid,
                                msg : 'Uploading ' + fullFilePath + ' ...0%',
                                /*content : $.jqElem('div')
                                    .addClass('progress')
                                    .addClass('progress-striped')
                                    .addClass('active')
                                    .append(
                                        $.jqElem('div')
                                            .addClass('bar')
                                            .css('width', '0%')
                                            .css('overflow', 'visible')
                                            .css('color', '#000')
                                            .css('white-space', 'nowrap')
                                            .css('text-align', 'left')
                                            .css('padding', '2px')
                                            .text('Uploading ' + upload_dir + '/' + file.name)
                                    )//*/
                            }
                        );

                        if (file.size <= this.singleFileSize() ) {

                            var reader = new FileReader();

                            reader.onprogress = $.proxy(function (e) {
                                this.trigger(
                                    'updateIrisProcess',
                                    {
                                        pid : pid,
                                        msg : 'Uploading ' + fullFilePath + ' ... ' + (100 * e.loaded / e.total).toFixed(2) + '%',
                                        /*content : $.jqElem('div')
                                            .addClass('progress')
                                            .addClass('progress-striped')
                                            .addClass('active')
                                            .append(
                                                $.jqElem('div')
                                                    .addClass('bar')
                                                    .css('width', (100 * e.loaded / e.total).toFixed(2) + '%')
                                                    .css('overflow', 'visible')
                                                    .css('color', '#000')
                                                    .css('white-space', 'nowrap')
                                                    .css('text-align', 'left')
                                                    .css('padding', '2px')
                                                    .text('Uploading ' + upload_dir + '/' + file.name)
                                            )//*/
                                    }
                                );
                                this.dbg('progress ' + (e.loaded / e.total));
                                this.dbg(e);
                            }, this);


                            reader.onload = jQuery.proxy(
                                function(e) {

                                    this.client().put_file(
                                        this.sessionId(),
                                        file.name,
                                        e.target.result,
                                        upload_dir,
                                        jQuery.proxy( function (res) {
                                            this.trigger('removeIrisProcess', pid);
                                            this.refreshDirectory(upload_dir)
                                        }, this),
                                        jQuery.proxy( function (res) {
                                        console.log("FAILED?");console.log(res);
                                            this.trigger('removeIrisProcess', pid);
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

                            var chunkUploadPath     = fullFilePath;
                            chunkUploadPath         = chunkUploadPath.replace(/\//g, '::');

                            var fileSize = file.size;
                            var chunkSize = parseInt(this.singleFileSize());
                            var chunk = 1;
                            var offset = 0;
                            var chunkMap = {
                                chunks              : [],
                                doneChunks          : [],
                                chunksByName        : {},
                                size                : 0,
                                fileName            : file.name,
                                upload_dir          : upload_dir,
                                fullFilePath        : fullFilePath,
                                chunkUploadPath     : chunkUploadPath,
                                fullUploadPath      : this.options.uploadDir + '/' + chunkUploadPath,
                                pid                 : pid
                            };
console.log("STALLED UPLOADS");
console.log(this.stalledUploads());
console.log(chunkMap.fullFilePath);
                            if (this.stalledUploads()[chunkMap.fullFilePath] != undefined) {
                                console.log("RESUME IT ANYWAY!");
                                this.data('resumed_chunkMap', this.stalledUploads()[chunkMap.fullFilePath]);
                                this.stalledUploads()[chunkMap.fullFilePath] = undefined;
                            }

                            if (this.data('resumed_chunkMap') != undefined) {
                                chunkMap = this.data('resumed_chunkMap');
                                //remove the junk status created by the newly manufactured pid.
                                this.trigger('removeIrisProcess', pid);
console.log("OLD " + chunkMap.pid + " vs " + pid);
console.log(chunkMap);
                                var percent = (100 * chunkMap.doneChunks.length / (chunkMap.doneChunks.length + chunkMap.chunks.length)).toFixed(2);
                                console.log("PERCENTAGE");
                                console.log(chunkMap.doneChunks.length);
                                console.log(chunkMap.doneChunks.length + chunkMap.chunks.length);
                                console.log((100 * chunkMap.doneChunks.length / (chunkMap.doneChunks.length + chunkMap.chunks.length)).toFixed(2));
                                if (percent >= 100) {
                                    percent = 99;
                                }

                                this.trigger(
                                    'updateIrisProcess',
                                    {
                                        pid : chunkMap.pid,
                                        msg : 'Uploading ' + chunkMap.fullFilePath + ' ... ' + percent + '%',
                                        /*content : $.jqElem('div')
                                            .addClass('progress')
                                            .addClass('progress-striped')
                                            .addClass('active')
                                            .append(
                                                $.jqElem('div')
                                                    .addClass('bar')
                                                    .css('width', percent + '%')
                                                    .css('overflow', 'visible')
                                                    .css('color', '#000')
                                                    .css('white-space', 'nowrap')
                                                    .css('text-align', 'left')
                                                    .css('padding', '2px')
                                                    .text('Uploading ' + chunkMap.fullFilePath)
                                            )//*/
                                    }
                                );

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

                                    chunkMap.chunks.push(
                                        {
                                            chunk : chunk,
                                            name : 'chunk.' + chunk,
                                            start : offset,
                                            end : (offset + chunkSize),
                                            size : chunkSize,
                                            complete : false,
                                        }
                                    );

                                    chunkMap.size += chunkSize;

                                    offset = offset + chunkSize;
                                    chunk++;

                                }

                            }

                            var callback = $.proxy(function (res) {

                                $.each(
                                    chunkMap.chunks,
                                    function (idx, chunk) {
                                        chunkMap.chunksByName[chunk.name] = chunk;
                                    }
                                );

                                var chunker = this.makeChunkUploader(file, chunkMap);
                                for (var i = 0; i < this.options.concurrentUploads; i++) {
                                    chunker();
                                }

                            }, this);

                            this.client().make_directory(
                                this.sessionId(),
                                '/' + this.options.uploadDir,
                                chunkMap.chunkUploadPath

                            ).always(
                                $.proxy(function() {
console.log("CM");console.log(chunkMap);
                                    this.client().put_file(
                                        this.sessionId(),
                                        'chunkMap',
                                        JSON.stringify(chunkMap, undefined, 2),
                                        '/' + chunkMap.fullUploadPath
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

        makeChunkUploader : function(file, chunkMap) {
            chunkMap.jobs = 0;

            var $fb = this;

            return function() {
console.log("FILE IS ");console.log(file);
//console.log(file.prototype.webkitSlice);
//console.log(file.prototype.slice);
console.log("PATH " + chunkMap.fullUploadPath);
console.log(chunkMap);
var recursion = arguments.callee;
                if (chunkMap.chunks.length > 0) {
                    var chunk = chunkMap.chunks.shift();

                    var blob = file.webkitSlice(chunk.start, chunk.end);
console.log('uploading chunk + ' + chunk.chunk);
                    var reader = new FileReader();

                    reader.onloadend = function(e) {

                        if (e.target.readyState == FileReader.DONE) {
console.log("UPLOADS CHUNK " + chunk);
console.log(e);
console.log(chunk.chunk);
console.log(chunkMap.fullUploadPath);
                            $fb.client().put_file(
                                $fb.sessionId(),
                                chunk.name,
                                e.target.result,
                                '/' + chunkMap.fullUploadPath,
                                function (res) {

                                    chunkMap.doneChunks.push(chunk);

                                    //total chunks is done + not done + current jobs - 1 (because we're done, but still flagged as a pending job)
                                    var percent = (100 * chunkMap.doneChunks.length / ((chunkMap.jobs - 1) + chunkMap.doneChunks.length + chunkMap.chunks.length)).toFixed(2);
                                    if (percent >= 100) {
                                        percent = 99;
                                    }



                                console.log("PERCENTAGE==" + percent);
                                console.log(chunkMap.doneChunks.length);
                                console.log(chunkMap.doneChunks.length + chunkMap.chunks.length);
                                console.log(chunkMap.jobs);
                                //total chunks is done + not done + current jobs - 1 (because we're done, but still flagged as a pending job)
                                console.log((100 * chunkMap.doneChunks.length / ((chunkMap.jobs - 1) + chunkMap.doneChunks.length + chunkMap.chunks.length)).toFixed(2));


                                    console.log($fb);
                                    $fb.trigger(
                                        'updateIrisProcess',
                                        {
                                            pid : chunkMap.pid,
                                            msg : 'Uploading ' + file.name + ' ... ' + percent + '%',
                                            /*content : $.jqElem('div')
                                                .addClass('progress')
                                                .addClass('progress-striped')
                                                .addClass('active')
                                                .append(
                                                    $.jqElem('div')
                                                        .addClass('bar')
                                                        .css('width', percent + '%')
                                                        .css('overflow', 'visible')
                                                        .css('color', '#000')
                                                        .css('white-space', 'nowrap')
                                                        .css('text-align', 'left')
                                                        .css('padding', '2px')
                                                        .text('Uploading ' + chunkMap.fullFilePath)
                                                )//*/
                                        }
                                    );

                                    chunkMap.jobs--;
                                    console.log('uploaded chunk!');
                                    recursion();
                                },
                                function (res) {
                                    chunkMap.jobs--;
                                    chunkMap.chunks.push(chunk);
                                    console.log('failed chunk!');
                                    console.log(res);
                                    recursion();
                                }
                            );
                        }
                    };

                    chunkMap.jobs++;
                    reader.readAsBinaryString(blob);
                }
                else if (chunkMap.jobs == 0) {
                    console.log("success...begin concatenation");
                    $fb.checkAndMergeChunks(chunkMap, recursion);
                }
                else {
                    console.log("done uploading, but jobs still pending");
                    console.log(chunkMap.jobs);
                }
            }
        },

        checkAndMergeChunks : function(chunkMap, chunkUploader) {
console.log("PATH " + chunkMap.chunkUploadPath + ", " + this.options.uploadDir);
            this.client().list_files(
                this.sessionId(),
                '/' + this.options.uploadDir,
                chunkMap.chunkUploadPath,
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
console.log("VN " + val.name + ',' + val.size);
                            fileSizes[val.name] = val.size;
                        }, this)
                    );

                    var concatenatedFileSize = fileSizes['upload'] || 0;
                    var newDoneChunks = [];
console.log("DC");console.log(chunkMap);
                    $.each(
                        chunkMap.doneChunks,
                        $.proxy (function (idx, chunk) {
                        console.log(chunk);
                            var size = chunk.size;

console.log("COMPARES SIZE " + size + " vs " + fileSizes[chunk.name] + ' on ' + chunk.name);

                            //if the file sizes are equal, then this chunk was successful.
                            if (size == fileSizes[chunk.name]) {
                                chunk.complete = true;
                                successfulChunks++;
                                newDoneChunks.push(chunk);
                            }
                            //okay, here's a nasty special case to check. If there's no defined file size
                            //(meaning that chunk does not exist on the server) AND we have a concatenatedFileSize
                            //(meaning we've started merging files), then instead we subtract that file's size
                            //from the concatenated size, and assume success.
                            else if (fileSizes[chunk.name] == undefined && concatenatedFileSize > 0) {

                                concatenatedFileSize -= size;

                                chunk.complete = true;
                                successfulChunks++;
                                newDoneChunks.push(chunk);
                            }
                            else {
                                console.log("FAILED ON CHUNK " + chunk.name + " " + size + " != " + fileSizes[chunk.name]);
                                chunk.complete = false;
                                chunkMap.chunks.push(chunk);
                                canMerge = false;
                            }

                        }, this)
                    );

                    chunkMap.doneChunks = newDoneChunks;

                    //one more bitch of a case to handle. If the concatenatedFileSize is NOT zero
                    //then it's possible that we bombed out after a file was concatenated into it, but before
                    //the file was deleted. So we need to find out the lowest chunk and see if its file size
                    //matches the discrepancy. If it does, it needs to be nuked, and then we otherwise continue
                    //stitching it all together as normal.

                    if (concatenatedFileSize != 0) {

                    }


                    if (canMerge) {
                        var merger = this.makeChunkMerger(chunkMap);
                        merger();
                    }
                    else if (chunkUploader) {
                        chunkUploader();
                    }
                    else {
                        console.log("cannot merge, no chunkuploader");console.log(chunkMap);
                        //okay. We fall into here IF we have a chunkmap and no chunkuploader.
                        //this'll occur if we're checking a chunkmap from a prior upload and it's
                        //incomplete.

                        var percent = (100 * chunkMap.doneChunks.length / (chunkMap.doneChunks.length + chunkMap.chunks.length)).toFixed(2);
                        if (percent >= 100) {
                            percent = 99;
                        }
                        var $pe = $('<div></div>').text('Uploading ' + chunkMap.fullFilePath + ' ...stalled at ' + percent + '%');
                        /*var $pe =  $.jqElem('div')
                                    .addClass('progress')
                                    .addClass('progress-striped')
                                    .addClass('active')
                                    .append(
                                        $.jqElem('div')
                                            .addClass('bar')
                                            .css('width', percent + '%')
                                            .css('overflow', 'visible')
                                            .css('color', '#000')
                                            .css('white-space', 'nowrap')
                                            .css('text-align', 'left')
                                            .css('padding', '2px')
                                            .text('Uploading ' + chunkMap.fullFilePath + '...stalled')
                                    );//*/
                        $pe.kbaseButtonControls(
                            {
                                onMouseover : true,
                                context : this,
                                controls : [
                                    {
                                        'icon' : 'icon-refresh',
                                        'tooltip' : 'Resume',
                                        callback : function(e, $fb) {
                                            console.log("Syncing job " + chunkMap.pid);
                                            console.log(chunkMap);
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
                                                '/' + chunkMap.fullUploadPath,
                                                function () {
                                                    $fb.trigger('removeIrisProcess', chunkMap.pid);
                                                    $fb.refreshDirectory('/' + target_dir);
                                                }
                                            );

                                        }
                                    },
                                ]

                            }
                        );

                        this.trigger(
                            'updateIrisProcess',
                            {
                                pid : chunkMap.pid,
                                content : $pe
                            }
                        );

                        this.stalledUploads()[chunkMap.fullFilePath] = chunkMap;
                    }


                }, this)
            );

        },

        makeChunkMerger : function(chunkMap) {
console.log("MCM");console.log(chunkMap);
            var $fb = this;

            var mergedUploadPath = chunkMap.fullUploadPath + '/upload';

            var mergePercent = chunkMap.doneChunks.length
                ? 1 / chunkMap.doneChunks.length
                : 0;
            var mergeCounter = 1;

            return function() {

                if (chunkMap.doneChunks.length == 0) {
console.log("MOVES FROM " + mergedUploadPath + " TO " + chunkMap.fullFilePath);
                    $fb.client().rename_file(
                        $fb.sessionId(),
                        '/',
                        mergedUploadPath,
                        chunkMap.fullFilePath,
                        function () {

                            $fb.client().remove_directory(
                                $fb.sessionId(),
                                '/',
                                chunkMap.fullUploadPath,
                                function () {
                                    $fb.trigger('removeIrisProcess', chunkMap.pid);
                                    console.log("REFRESH " + chunkMap.upload_dir);
                                    $fb.refreshDirectory(chunkMap.upload_dir);
                                }
                            );

                        },
                        function (res) {
                            console.log("RENAME FAIL");
                            console.log(res);
                        }
                    );

                    return;
                }

                var chunk = chunkMap.doneChunks.shift();

                var recursion = arguments.callee;

                console.log(chunk);
//recursion();
//return;

console.log("WILL COPY FROM " + chunkMap.fullUploadPath + '/' + chunk.name + " -> " + mergedUploadPath);


                $fb.client().run_pipeline(
                    $fb.sessionId(),
                    "cat " + chunkMap.fullUploadPath + '/' + chunk.name + ' >> ' + mergedUploadPath,
                    [],
                    0,
                    '/',
                    $.proxy( function (runout) {

                        if (runout) {
                            var output = runout[0];
                            var error  = runout[1];

                            var newPercent = (99 + mergeCounter++ * mergePercent).toFixed(2);

                            $fb.trigger(
                                'updateIrisProcess',
                                {
                                    pid : chunkMap.pid,
                                    msg : 'Uploading ' + chunkMap.fullFilePath + ' ... ' + newPercent + '%',
                                }
                            );

                            if (! error.length) {
                                $fb.client().remove_files(
                                    $fb.sessionId(),
                                    '/' + chunkMap.fullUploadPath,
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
