var gulp = require('gulp');
var gutil = require('gulp-util');
var peg = require('gulp-peg');
var jshint = require('gulp-jshint');
var mocha = require('gulp-mocha');

// make gulp work from subdirectories
process.chdir(__dirname);

var pegOptions = {
  'allowedStartRules': [
    'SIP_message'
  ]
};

var jshintOptions = {
   laxcomma: true
  ,laxbreak: true
};

gulp.task('build', function() {
  return gulp
    .src('src/sippers.pegjs')
    .pipe(peg(pegOptions).on('error', gutil.log))
    .pipe(gulp.dest('dist'))
  ;
});

gulp.task('lint', ['build'], function () {
  return gulp
    .src('dist/sippers.js')
    .pipe(jshint(jshintOptions))
    .pipe(jshint.reporter('default'))
  ;
});

gulp.task('test', ['lint'], function () {
  return gulp
    .src('test/**/index.js')
    .pipe(jshint())
    .pipe(jshint.reporter('default'))
    .pipe(mocha())
  ;
});

gulp.task('default', ['test']);
