

function InvocationService(url, auth, auth_cb) {

    _url = url;
    this.url = _url;
    var deprecationWarningSent = false;

    function deprecationWarning() {
        if (!deprecationWarningSent) {
            deprecationWarningSent = true;
            if (!window.console) return;
            console.log(
                "DEPRECATION WARNING: '*_async' method names will be removed",
                "in a future version. Please use the identical methods without",
                "the'_async' suffix.");
        }
    }

    this._auth = auth ? auth : { 'token' : '', 'user_id' : ''};
    this._auth_cb = auth_cb;


    this.start_session = function (session_id, _callback, _errorCallback) {
    return this.json_call_ajax("InvocationService.start_session",
        [session_id], 1, _callback, _errorCallback);
};


InvocationService.prototype.setAuth = function(newAuth, newAuth_cb) {
    this._auth = newAuth ? newAuth : { 'token' : '', 'user_id' : ''};
    this._auth_cb = newAuth_cb;
}

    InvocationService.prototype.start_session_async = function (session_id, _callback, _error_callback) {
        deprecationWarning();
        return this.json_call_ajax("InvocationService.start_session", [session_id], 1, _callback, _error_callback);
    };

    InvocationService.prototype.list_files = function (session_id, cwd, d, _callback, _errorCallback) {
    return this.json_call_ajax("InvocationService.list_files",
        [session_id, cwd, d], 2, _callback, _errorCallback);
};

    InvocationService.prototype.list_files_async = function (session_id, cwd, d, _callback, _error_callback) {
        deprecationWarning();
        return this.json_call_ajax("InvocationService.list_files", [session_id, cwd, d], 2, _callback, _error_callback);
    };

    InvocationService.prototype.remove_files = function (session_id, cwd, filename, _callback, _errorCallback) {
    return this.json_call_ajax("InvocationService.remove_files",
        [session_id, cwd, filename], 0, _callback, _errorCallback);
};

    InvocationService.prototype.remove_files_async = function (session_id, cwd, filename, _callback, _error_callback) {
        deprecationWarning();
        return this.json_call_ajax("InvocationService.remove_files", [session_id, cwd, filename], 0, _callback, _error_callback);
    };

    InvocationService.prototype.rename_file = function (session_id, cwd, from, to, _callback, _errorCallback) {
    return this.json_call_ajax("InvocationService.rename_file",
        [session_id, cwd, from, to], 0, _callback, _errorCallback);
};

    InvocationService.prototype.rename_file_async = function (session_id, cwd, from, to, _callback, _error_callback) {
        deprecationWarning();
        return this.json_call_ajax("InvocationService.rename_file", [session_id, cwd, from, to], 0, _callback, _error_callback);
    };

    InvocationService.prototype.copy = function (session_id, cwd, from, to, _callback, _errorCallback) {
    return this.json_call_ajax("InvocationService.copy",
        [session_id, cwd, from, to], 0, _callback, _errorCallback);
};

    InvocationService.prototype.copy_async = function (session_id, cwd, from, to, _callback, _error_callback) {
        deprecationWarning();
        return this.json_call_ajax("InvocationService.copy", [session_id, cwd, from, to], 0, _callback, _error_callback);
    };

    InvocationService.prototype.make_directory = function (session_id, cwd, directory, _callback, _errorCallback) {
    return this.json_call_ajax("InvocationService.make_directory",
        [session_id, cwd, directory], 0, _callback, _errorCallback);
};

    InvocationService.prototype.make_directory_async = function (session_id, cwd, directory, _callback, _error_callback) {
        deprecationWarning();
        return this.json_call_ajax("InvocationService.make_directory", [session_id, cwd, directory], 0, _callback, _error_callback);
    };

    InvocationService.prototype.remove_directory = function (session_id, cwd, directory, _callback, _errorCallback) {
    return this.json_call_ajax("InvocationService.remove_directory",
        [session_id, cwd, directory], 0, _callback, _errorCallback);
};

    InvocationService.prototype.remove_directory_async = function (session_id, cwd, directory, _callback, _error_callback) {
        deprecationWarning();
        return this.json_call_ajax("InvocationService.remove_directory", [session_id, cwd, directory], 0, _callback, _error_callback);
    };

    InvocationService.prototype.change_directory = function (session_id, cwd, directory, _callback, _errorCallback) {
    return this.json_call_ajax("InvocationService.change_directory",
        [session_id, cwd, directory], 1, _callback, _errorCallback);
};

    InvocationService.prototype.change_directory_async = function (session_id, cwd, directory, _callback, _error_callback) {
        deprecationWarning();
        return this.json_call_ajax("InvocationService.change_directory", [session_id, cwd, directory], 1, _callback, _error_callback);
    };

    InvocationService.prototype.put_file = function (session_id, filename, contents, cwd, _callback, _errorCallback) {
    return this.json_call_ajax("InvocationService.put_file",
        [session_id, filename, contents, cwd], 0, _callback, _errorCallback);
};

    InvocationService.prototype.put_file_async = function (session_id, filename, contents, cwd, _callback, _error_callback) {
        deprecationWarning();
        return this.json_call_ajax("InvocationService.put_file", [session_id, filename, contents, cwd], 0, _callback, _error_callback);
    };

    InvocationService.prototype.get_file = function (session_id, filename, cwd, _callback, _errorCallback) {
    return this.json_call_ajax("InvocationService.get_file",
        [session_id, filename, cwd], 1, _callback, _errorCallback);
};

    InvocationService.prototype.get_file_async = function (session_id, filename, cwd, _callback, _error_callback) {
        deprecationWarning();
        return this.json_call_ajax("InvocationService.get_file", [session_id, filename, cwd], 1, _callback, _error_callback);
    };

    InvocationService.prototype.run_pipeline = function (session_id, pipeline, input, max_output_size, cwd, _callback, _errorCallback) {
    return this.json_call_ajax("InvocationService.run_pipeline",
        [session_id, pipeline, input, max_output_size, cwd], 2, _callback, _errorCallback);
};

    InvocationService.prototype.run_pipeline_async = function (session_id, pipeline, input, max_output_size, cwd, _callback, _error_callback) {
        deprecationWarning();
        return this.json_call_ajax("InvocationService.run_pipeline", [session_id, pipeline, input, max_output_size, cwd], 2, _callback, _error_callback);
    };

    InvocationService.prototype.run_pipeline2 = function (session_id, pipeline, input, max_output_size, cwd, _callback, _errorCallback) {
    return this.json_call_ajax("InvocationService.run_pipeline2",
        [session_id, pipeline, input, max_output_size, cwd], 3, _callback, _errorCallback);
};

    InvocationService.prototype.run_pipeline2_async = function (session_id, pipeline, input, max_output_size, cwd, _callback, _error_callback) {
        deprecationWarning();
        return this.json_call_ajax("InvocationService.run_pipeline2", [session_id, pipeline, input, max_output_size, cwd], 3, _callback, _error_callback);
    };

    InvocationService.prototype.exit_session = function (session_id, _callback, _errorCallback) {
    return this.json_call_ajax("InvocationService.exit_session",
        [session_id], 0, _callback, _errorCallback);
};

    InvocationService.prototype.exit_session_async = function (session_id, _callback, _error_callback) {
        deprecationWarning();
        return this.json_call_ajax("InvocationService.exit_session", [session_id], 0, _callback, _error_callback);
    };

    InvocationService.prototype.valid_commands = function (_callback, _errorCallback) {
    return this.json_call_ajax("InvocationService.valid_commands",
        [], 1, _callback, _errorCallback);
};

    InvocationService.prototype.valid_commands_async = function (_callback, _error_callback) {
        deprecationWarning();
        return this.json_call_ajax("InvocationService.valid_commands", [], 1, _callback, _error_callback);
    };

    InvocationService.prototype.installed_modules = function (_callback, _errorCallback) {
    return this.json_call_ajax("InvocationService.installed_modules",
        [], 1, _callback, _errorCallback);
};

    InvocationService.prototype.installed_modules_async = function (_callback, _error_callback) {
        deprecationWarning();
        return this.json_call_ajax("InvocationService.installed_modules", [], 1, _callback, _error_callback);
    };

    InvocationService.prototype.get_tutorial_text = function (step, _callback, _errorCallback) {
    return this.json_call_ajax("InvocationService.get_tutorial_text",
        [step], 3, _callback, _errorCallback);
};

    InvocationService.prototype.get_tutorial_text_async = function (step, _callback, _error_callback) {
        deprecationWarning();
        return this.json_call_ajax("InvocationService.get_tutorial_text", [step], 3, _callback, _error_callback);
    };


    /*
     * JSON call using jQuery method.
     */
    InvocationService.prototype.json_call_ajax = function  json_call_ajax(method, params, numRets, callback, errorCallback) {
        var deferred = $.Deferred();

        if (typeof callback === 'function') {
           deferred.done(callback);
        }

        if (typeof errorCallback === 'function') {
           deferred.fail(errorCallback);
        }

        var rpc = {
            params : params,
            method : method,
            version: "1.1",
            id: String(Math.random()).slice(2),
        };

        var beforeSend = null;
        var token = (this._auth_cb && typeof this._auth_cb === 'function') ? this._auth_cb()
            : (this._auth.token ? this._auth.token : null);
        if (token != null) {
            beforeSend = function (xhr) {
                xhr.setRequestHeader("Authorization", token);
            }
        }

        var xhr = jQuery.ajax({
            url: _url,
            dataType: "text",
            type: 'POST',
            processData: false,
            data: JSON.stringify(rpc),
            beforeSend: beforeSend,
            success: function (data, status, xhr) {
                var result;
                try {
                    var resp = JSON.parse(data);
                    result = (numRets === 1 ? resp.result[0] : resp.result);
                } catch (err) {
                    deferred.reject({
                        status: 503,
                        error: err,
                        url: _url,
                        resp: data
                    });
                    return;
                }
                deferred.resolve(result);
            },
            error: function (xhr, textStatus, errorThrown) {
                var error;
                if (window.console) {
                    console.log("FAILURE!");
                    console.log(xhr);
                    console.log(textStatus);
                    console.log(errorThrown);
                }
                if (xhr.responseText) {
                    try {
                        var resp = JSON.parse(xhr.responseText);
                        error = resp.error;
                    } catch (err) { // Not JSON
                        error = "Unknown error - " + xhr.responseText;
                    }
                } else {
                    error = "Unknown Error";
                }
                deferred.reject({
                    status: 500,
                    error: error
                });
            }
        });

        var promise = deferred.promise();
        promise.xhr = xhr;

        return promise;
    }
}


