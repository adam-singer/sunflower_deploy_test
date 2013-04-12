import 'dart:async';
import 'dart:io';
import 'package:hop/hop.dart';
import 'package:hop/hop_tasks.dart';

/*
 * Ideas of how to deploy some default server for static files
 * http://financecoding.github.io/blog/2013/03/09/rikulo-stream-on-heroku/
 * https://gist.github.com/darktable/873098
 */

void main() {
  _assertKnownPath();
  final paths = ['web/sunflower.dart'];
  addTask('dart2js', createDart2JsTask(paths, minify: true, liveTypeAnalysis: true, rejectDeprecatedFeatures: true));
  addAsyncTask('dart2js_dart', (ctx) => startProcess(ctx, 'dart2js', ['--output-type=dart', '--minify','-oweb/sunflower.dart','web/sunflower.dart']));
  addAsyncTask('deploy', (ctx) => startProcess(ctx, 'rsync', ['-RLr', 'web/', 'deploy/']));
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