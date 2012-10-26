
function dbg(txt) { if (window.console) console.log(txt); }

var CommandHistory = new Class(
    {
	items: [],

	initialize: function() {

	},
	length: function() {
	    return this.items.length;
	},

	push: function(cmd) {
	    this.items.push(cmd);
	    // var i;
	    // for (i = 0; i < this.items.length; i++)
	    // {
	    // 	dbg(i + ": " + this.items[i]);
	    // }
	},

	item: function(pos) {
	    return this.items[pos];
	},

	save: function(client, session) {
	    var txt;
	    txt = JSON.stringify(this.items);
	    client.put_file(session, "history", txt, "/");
	    // dbg(txt);
	},

	load: function(client, session) {
	    var txt;
	    try {
		txt = client.get_file(session, "history", "/");
		// dbg("got history " + txt);
		h = JSON.parse(txt);
		this.items = h;
	    }
	    catch (e)
	    {
		dbg("error on history load: " + e);
	    }
	},
    }
);

var CommandHistoryPosition = new Class(
    {
	history: undefined,
	pos: -1,
	initialize: function(h) {
	    this.history = h;
	    this.reset();
	},

	reset: function() {
	    this.pos = this.history.length();
	},

	move_back: function() {
	    if (this.pos > 0)
	    {
		this.pos--;
	    }
	},
	move_ahead: function() {
	    if (this.pos < this.history.length())
	    {
		this.pos++;
	    }
	},
	value: function() {
	    return this.history.item(this.pos);
	},
    }
);

var Terminal = new Class(
{
    maxOutput: 100,

    initialize: function(container) {

	this.tutorial_position = 1;

	this.commandHistory = new CommandHistory();
	this.commandHistoryPosition =  new CommandHistoryPosition(this.commandHistory);

	//this.baseUrl = 'http://bio-data-1.mcs.anl.gov:5000';
	this.baseUrl = 'http://bio-data-1.mcs.anl.gov/services/invocation';
	//this.baseUrl = 'http://ash.mcs.anl.gov:5000';
	this.client = new InvocationService(this.baseUrl);

	this.terminal = container;

	this.fx = new Fx.Scroll(this.terminal);
	this.out('Welcome to the interactive KBase.');
	this.out_line();

	this.path = '.';
	this.cwd = "/";

	this.input_box = document.id(input_box);
	this.input_box.addEvent('keypress', function(event) { this.keypress(event); }.bind(this));
	this.input_box.addEvent('keydown', function(event) { this.keydown(event); }.bind(this));
	this.input_box.addEvent("onchange", function(event) { dbg("change"); });

	this.input_box.focus();

        window.addEvent("resize", function(event) { this.resize_contents(container) }.bind(this));

	this.uploader = new qq.FileUploader({
	    element: document.id('file-uploader'),
	    action: this.baseUrl + '/upload',
	    // params: { session_id: this.sessionId },
	    debug: true,
	    onProgress: function() { this.resize_contents(container) } .bind(this),
	    onComplete: function() { this.resize_contents(container) } .bind(this)
	});
	this.resize_contents(container);

    },

    set_session: function(session) {
	this.sessionId = session;
	this.uploader.setParams({ session_id: this.sessionId,
				  onProgress: function() { this.resize_contents(this.terminal) } .bind(this),
				  onComplete: function() { this.resize_contents(this.terminal) } .bind(this)
				});
    },

    resize_contents: function(container) {
	var newx = window.getSize().y - document.id(pageheader).getSize().y - document.id(footer).getSize().y - 35;
	container.style.height = newx;
    },

    keypress: function(event) {
	if (event.key == 'enter')
	{
	    event.preventDefault();
 	    var cmd = this.input_box.value;
	    dbg("Run " + cmd);
	    this.out_cmd(cmd);
	    this.run(cmd);
	    this.input_box.set('value','');
	}
    },

    keydown: function(event) {
	if (event.key == 'up')
	{
	    event.preventDefault();
	    this.commandHistoryPosition.move_back();
	    //dbg(this.commandHistoryPosition.pos + " " + this.commandHistoryPosition.value());
	    this.input_box.set('value', this.commandHistoryPosition.value());
	}
	else if (event.key == 'down')
	{
	    event.preventDefault();
	    this.commandHistoryPosition.move_ahead();
	    //dbg(this.commandHistoryPosition.pos + " " + this.commandHistoryPosition.value());
	    this.input_box.set('value', this.commandHistoryPosition.value());
	}
    },

    out_cmd: function(text) {
	var p = new Element('div');
	p.grab(new Element('span').addClass('command').set('text', "> " + this.cwd + " " + text));
	this.terminal.grab(p);
    },

    // Outputs a line of text
    out: function(text) {
	var p = new Element('div');
	p.set('html', text);
	this.terminal.grab(p);
    },

    // Outputs a line of text
	out_to_div: function(div, text) {
	var p = new Element('div');
	p.set('html', text);
	div.grab(p);
    },

    // Outputs a line of text
    out_line: function(text) {
	var p = new Element('hr');
	this.terminal.grab(p);
	this.fx.toElement(p);
    },

    scroll: function() {
    },

    // Executes a command
    run: function(command) {

	if (command == 'help') {
	    this.out('Show some help');
	    this.scroll();
	    return;
	}

	var commandDiv = new Element('div');
	this.terminal.grab(commandDiv);
	this.out_line();
	this.scroll();

	var m;
	command = command.replace("logon", "login");
	if (m = command.match(/^login\s*(.*)/))
	{
	    var args = m[1].split(/\s+/)
	    if (args.length != 1)
	    {
		this.out_to_div(commandDiv, "Invalid login syntax.");
		return;
	    }
	    sid = args[0];

	    $("#login-dialog").data('username', sid);
	    $("#login-dialog").dialog('open');
	    return;

	    //old login code. copy and pasted into iris.html.
	    this.client.start_session_async(sid,
					    function (newsid)
					    {
						this.set_session(sid);
						this.commandHistory.load(this.client, sid);
						this.out_to_div(commandDiv, "Set session to " + sid);
					    }.bind(this),
					    function (err)
					    {
						this.out_to_div(commandDiv, "<i>Error on session_start:<br>" +
						   		err.message.replace("\n", "<br>\n") + "</i>");
					    }.bind(this)
					   );
	    return;
	}

	if (m = command.match(/^authenticate\s*(.*)/))
	{
	    var args = m[1].split(/\s+/)
	    if (args.length != 1)
	    {
		this.out_to_div(commandDiv, "Invalid login syntax.");
		return;
	    }
	    sid = args[0];

	    $("#login-dialog").data('username', sid);
	    $("#login-dialog").dialog('open');

	    return;
	}


	if (!this.sessionId)
	{
	    this.out_to_div(commandDiv, "You are not logged in.");
	    return;
	}

	this.commandHistory.push(command);
	this.commandHistory.save(this.client, this.sessionId);
	this.commandHistoryPosition.reset();

	var m;
	if (command == 'history')
	{
	    var i;
	    var tbl = "<table>";
	    for (i = 0; i < this.commandHistory.length(); i++)
	    {
		tbl += "<tr><td>" + i + "</td><td style='padding-left: 10px'>" + this.commandHistory.item(i) + "</td></tr>\n";
	    }
	    tbl += "</table>";
	    this.out_to_div(commandDiv, tbl);
	    return;
	}
	else if (m = command.match(/^!(\d+)/))
	{
	    command = this.commandHistory.item(m[1]);
	}


	if (m = command.match(/^cd\s*(.*)/))
	{
	    var obj = this;
	    var args = m[1].split(/\s+/)
            if (args.length != 1)
            {
                this.out_to_div(commandDiv, "Invalid cd syntax.");
                return;
            }
            dir = args[0];
	    this.client.change_directory_async(this.sessionId, this.cwd, dir,
			function (path)
			{
				this.cwd = path;
			}. bind(this),
			function (err)
			{
				var m = err.message.replace("/\n", "<br>\n");
                             	obj.out_to_div(commandDiv, "<i>Error received:<br>" + err.code + "<br>" + m + "</i>");
			}
		);
	    return;
	}


	if (m = command.match(/^cp\s*(.*)/))
	{
	    var obj = this;
	    var args = m[1].split(/\s+/)
            if (args.length != 2)
            {
                this.out_to_div(commandDiv, "Invalid cp syntax.");
                return;
            }
            from = args[0];
            to  = args[1];
	    this.client.copy_async(this.sessionId, this.cwd, from, to,
			  function () {},
			  function (err)
				 {
				     var m = err.message.replace("\n", "<br>\n");
				     obj.out_to_div(commandDiv, "<i>Error received:<br>" + err.code + "<br>" + m + "</i>");
				 }
		);
	    return;
	}
	if (m = command.match(/^mv\s*(.*)/))
	{
	    var args = m[1].split(/\s+/)
            if (args.length != 2)
            {
                this.out_to_div(commandDiv, "Invalid mv syntax.");
                return;
            }
            from = args[0];
            to  = args[1];
	    this.client.rename_file_async(this.sessionId, this.cwd, from, to);
	    return;
	}
	if (m = command.match(/^mkdir\s*(.*)/))
	{
	    var args = m[1].split(/\s+/)
            if (args.length != 1)
            {
                this.out_to_div(commandDiv, "Invalid mkdir syntax.");
                return;
            }
	    dir = args[0];
	    this.client.make_directory(this.sessionId, this.cwd, dir);
	    return;
	}
	if (m = command.match(/^rmdir\s*(.*)/))
	{
	    var args = m[1].split(/\s+/)
            if (args.length != 1)
            {
                this.out_to_div(commandDiv, "Invalid rmdir syntax.");
                return;
            }
	    dir = args[0];
	    this.client.remove_directory(this.sessionId, this.cwd, dir);
	    return;
	}
	if (m = command.match(/^rm\s*(.*)/))
	{
	    var args = m[1].split(/\s+/)
            if (args.length != 1)
            {
                this.out_to_div(commandDiv, "Invalid rm syntax.");
                return;
            }
	    file = args[0];
	    this.client.remove_files_async(this.sessionId, this.cwd, file);
	    return;
	}
	if (command == "next") {
	    if (this.tutorial_next >= 0)
		this.tutorial_position = this.tutorial_next;
	    command = "show_tutorial";
	}
	if (command == "back") {
	    if (this.tutorial_prev >= 0)
		this.tutorial_position = this.tutorial_prev;
	    command = "show_tutorial";
	}
	if (command == "tutorial") {
	    this.tutorial_position = 1;
	    command = "show_tutorial";
	}

	if (command == 'show_tutorial')
	{
	    this.client.get_tutorial_text_async(this.tutorial_position,
						function (what)
						{
						    var text = what[0];
						    var prev = what[1];
						    var next = what[2];
						    this.tutorial_next = next;
						    this.tutorial_prev = prev;
						    if (prev >= 0)
						    {
							text += "<br>Type <i>back</i> to move to the previous step in the tutorial.";
						    }
						    if (next >= 0)
						    {
							text += "<br>Type <i>next</i> to move to the next step in the tutorial.";
						    }
						    this.out_to_div(commandDiv, text);
						}.bind(this),
						function (err)
						{
						    var m = err.message.replace("\n", "<br>\n");
						    this.out_to_div(commandDiv, "<i>Error received:<br>" + err.code + "<br>" + m + "</i>");
						}.bind(this));
	    return;
	}

	if (command == 'commands')
	{
	    this.client.valid_commands_async(function (cmds)
				       {
					   var tbl = document.createElement('table');
					   for (gi = 0; gi < cmds.length; gi++)
					   {
					       var group = cmds[gi];
					       // this.out_to_div(commandDiv, "Group " + group.name + "<br>");
					       var row = document.createElement('tr');
					       var cell = document.createElement('th');
					       cell.setAttribute('colspan', 2);
					       cell.innerHTML = group.title;
					       tbl.appendChild(row);
					       row.appendChild(cell);

					       var n = group.items.length;
					       var coln = Math.ceil(n / 2);
					       for (ri = 0; ri < coln; ri++)
					       {
						   var row = document.createElement('tr');

						   var item = group.items[ri];
						   var cell = document.createElement('td');
						   cell.innerHTML = item.cmd;
						   row.appendChild(cell);

						   cell = document.createElement('td');
						   if (ri + coln < n)
						   {
						       item = group.items[ri + coln];
						       cell.innerHTML = item.cmd;
						   }
						   row.appendChild(cell);

						   tbl.appendChild(row);
					       }
					   }
					   commandDiv.appendChild(tbl);
				       }.bind(this));
	    return;
	}

	if (d = command.match(/^ls\s*(.*)/)) {
	    var args = d[1].split(/\s+/)
	    var obj = this;
            if (args.length == 0) {
		d = ".";
            } else {
		    if (args.length != 1) {
			this.out_to_div(commandDiv, "Invalid ls syntax.");
			return;
		    } else {
			d = args[0];
		   }
	    }

	    var f = this.client.list_files_async(this.sessionId, this.cwd, d,
			 function (filelist)
			 {
			     var dirs = filelist[0];
			     var files = filelist[1];

			     var tbl = document.createElement('table');
			     tbl.setAttribute('border', 1);

    			     for (var d=0; d < dirs.length; d++)
			     {
				 var row = document.createElement('tr')
				 var cell = document.createElement('td');
				 cell.innerHTML = '0';
				 row.appendChild(cell);
				 cell = document.createElement('td');
				 cell.innerHTML = dirs[d]['mod_date'];
				 row.appendChild(cell);

				 cell = document.createElement('td');
				 cell.innerHTML = dirs[d]['name'];
				 row.appendChild(cell);

				 tbl.appendChild(row);
			     }

			     for (var i=0; i < files.length; i++)
			     {
				 var url = obj.baseUrl + "/download/" + files[i]['full_path'] +
				     "?session_id=" + obj.sessionId;

				 var row = document.createElement('tr')
				 var cell = document.createElement('td');
				 cell.innerHTML = files[i]['size'];
				 row.appendChild(cell);
				 cell = document.createElement('td');
				 cell.innerHTML = files[i]['mod_date'];
				 row.appendChild(cell);

				 cell = document.createElement('td');
				 var link = document.createElement('a');
				 link.innerHTML = files[i]['name'];
				 link.setAttribute('href', url);
				 link.setAttribute('target', '_blank');
				 cell.appendChild(link);
				 row.appendChild(cell);

				 tbl.appendChild(row);
			     }
			     commandDiv.appendChild(tbl);

			 }.bind(this),
			 function (err)
			 {
			     var m = err.message.replace("\n", "<br>\n");
			     obj.out_to_div(commandDiv, "<i>Error received:<br>" + err.code + "<br>" + m + "</i>");
			 }
			);
	    return;
	}

	var runout;
	var obj = this;
	command = command.replace(/\\\n/g, " ");
	command = command.replace(/\n/g, " ");
	this.client.run_pipeline2_async(this.sessionId, command, [], this.maxOutput, this.cwd,
				       function (runout)
				       {
					   if (runout)
					   {
					       var output = runout[0];
					       var error = runout[1];
					       var stdweb= runout[2];

					       if (stdweb != "")
					       {
						   obj.out_to_div(commandDiv, stdweb);
						   return;
					       }

					       if (output.length > 0 && output[0].indexOf("\t") >= 0)
					       {

						   var tbl = document.createElement('table');
						   tbl.setAttribute('border', 1);

						   for (var i=0; i < output.length; i++)
						   {
						       var parts = output[i].split("\t");
						       var row = document.createElement('tr');

						       for (var j = 0; j < parts.length; j++)
						       {
							   var cell = document.createElement('td');
							   cell.innerHTML = parts[j];
							   row.appendChild(cell);
						       }
						       tbl.appendChild(row);

						   }
						   commandDiv.appendChild(tbl);

					       }
					       else
					       {
						   for (var i=0; i < output.length; i++)
						   {
						       var line = output[i];
						       obj.out_to_div(commandDiv, line);
						   }
					       }
					       if (error.length > 0)
					       {
						   for (var i=0; i < error.length; i++)
						   {
						       var line = error[i];
						       obj.out_to_div(commandDiv, "<i>" + line + "</i>");
						   }
					       }
					   }
					   else
					   {
					       obj.out_to_div(commandDiv, "Error running command.");
					   }
				       });

    }
});

window.addEvent('domready', function() {
		       window.terminal = new Terminal(document.id('terminal'));
		   });
