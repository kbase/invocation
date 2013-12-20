define('kbpaths',[], function (paths) {
 requirejs.config({
    //baseUrl: 'jquery/FUCK/',
    baseUrl : 'jquery/kbase/widgets',
    urlArgs: "bust=" + (new Date()).getTime(),
    paths : {
     jquery : '../../ext/jquery/jquery-1.10.2.min',
     bootstrap : "../../ext/bootstrap/3.0.3/js/bootstrap.min",
     kbwidget : '../kbwidget',
        //iris widgets
        iris              : 'iris/iris',
        kbaseIrisCommands : 'iris/kbaseIrisCommands',
        kbaseIrisContainerWidget : 'iris/kbaseIrisContainerWidget',
        kbaseIrisEchoWidget : 'iris/kbaseIrisEchoWidget',
        kbaseIrisFileBrowser : 'iris/kbaseIrisFileBrowser',
        kbaseIrisFileEditor : 'iris/kbaseIrisFileEditor',
        kbaseIrisGrammar : 'iris/kbaseIrisGrammar',
        kbaseIrisGUIWidget : 'iris/kbaseIrisGUIWidget',
        kbaseIrisProcessList : 'iris/kbaseIrisProcessList',
        kbaseIrisTerminal : 'iris/kbaseIrisTerminal',
        kbaseIrisTerminalWidget : 'iris/kbaseIrisTerminalWidget',
        kbaseIrisTextWidget : 'iris/kbaseIrisTextWidget',
        kbaseIrisTutorial : 'iris/kbaseIrisTutorial',
        kbaseIrisWidget : 'iris/kbaseIrisWidget',
        kbaseIrisWorkspace : 'iris/kbaseIrisWorkspace',
    },
    shim: {
        bootstrap:    { deps: ["jquery"] },
    }
 });
});


