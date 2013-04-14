import 'dart:async';
import 'dart:io';
import 'package:hop/hop.dart';
import 'package:hop/hop_tasks.dart';

/*
 * Ideas of how to deploy some default server for static files
 * http://financecoding.github.io/blog/2013/03/09/rikulo-stream-on-heroku/
 * https://gist.github.com/darktable/873098
 */

/*
mkdir stream_todomvc
cd stream_todomvc
heroku create stream-todomvc
heroku config:add BUILDPACK_URL=https://github.com/igrigorik/heroku-buildpack-dart.git
git init
git remote add heroku git@heroku.com:stream-todomvc.git
 */

String server_dart =
"""
// cat web/webapp/server.dart 
library server;

import 'dart:io';
import "package:stream/stream.dart";

void main() {
  var port = Platform.environment.containsKey('PORT') ? int.parse(Platform.environment['PORT']) : 8080;
  var host = '0.0.0.0';
  var streamServer = new StreamServer();
  streamServer
  ..port = port
  ..host = host
  ..start();
}
""";

String proc_file =
"""
web: ./dart-sdk/bin/dart --package-root=./packages/ web/webapp/server.dart
""";

// TODO: make function that inserts the application name.
String gae_app_yaml =
"""
application: you-app-name-here
version: 1
runtime: python
api_version: 1

handlers:
- url: /(.*)
  static_files: static/\\1
  upload: static/(.*)
""";

void main() {
  _assertKnownPath();
  final paths = ['web/sunflower.dart'];
  addTask('dart2js', createDart2JsTask(paths, minify: true, liveTypeAnalysis: true, rejectDeprecatedFeatures: true));
  addAsyncTask('dart2js_dart', (ctx) => startProcess(ctx, 'dart2js', ['--output-type=dart', '--minify','-oweb/sunflower.dart','web/sunflower.dart']));

  //
  // heroku
  //
  addTask('deploy_heroku', copyDirectory("web", "deploy_heroku/web", followLinks: true));
  addAsyncTask('create_webapp', (ctx) {
    // dart --package-root=../packages/ web/webapp/server.dart
    var completer = new Completer();
    File outFile = new File("deploy_heroku/web/webapp/server.dart");
    Directory outDir = new Directory("deploy_heroku/web/webapp/");
    outDir.createSync(recursive: true);
    outFile.writeAsStringSync(server_dart);

    outFile = new File("deploy_heroku/Procfile");
    outFile.writeAsStringSync(proc_file);

    completer.complete(true);
    return completer.future;
  });

  //
  // google app engine
  //
  addTask('deploy_gae', copyDirectory("web", "deploy_gae/static", followLinks: true));
  addAsyncTask('create_gae', (ctx) {
    var completer = new Completer();

    File outFile = new File("deploy_gae/App.yaml");
    outFile.writeAsStringSync(gae_app_yaml);

    completer.complete(true);
    return completer.future;
  });

  //
  // github gh_pages
  //
  addTask('deploy_github', copyDirectory("web", "deploy_github", followLinks: true));
  addAsyncTask('deploy_gh_pages', (ctx) => branchForDir(ctx, 'master', 'deploy_github', 'gh-pages'));

  //addAsyncTask('deploy', (ctx) => startProcess(ctx, 'rsync', ['-RLr', 'web/', 'deploy/']));
  addAsyncTask('compress', (ctx) => startProcess(ctx, 'tar', ['-zcvf', 'deploy.tar.gz', '-C', 'deploy/web/', '.']));
  addAsyncTask('clean', (ctx) => startProcess(ctx, 'rm', ['-rf', 'deploy']));
  runHop();
}


void _assertKnownPath() {
  // since there is no way to determine the path of 'this' file
  // assume that Directory.current() is the root of the project.
  // So check for existance of /bin/hop_runner.dart
  final thisFile = new File('tool/hop_runner.dart');
  assert(thisFile.existsSync());
}