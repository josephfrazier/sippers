var gulp = require('gulp');
var gutil = require('gulp-util');
var peg = require('gulp-peg');
var jshint = require('gulp-jshint');
var mocha = require('gulp-mocha');

// make gulp work from subdirectories
process.chdir(__dirname);

var options = {
  peg: {
    'allowedStartRules': [
      'SIP_message'
    ]
  },
  jshint: {
    laxcomma: true,
    laxbreak: true,
    '-W100': true
  },
  mocha: {
    reporter: 'spec'
  }
};

gulp.task('build', function() {
  return gulp
    .src('src/sippers.pegjs')
    .pipe(peg(options.peg).on('error', gutil.log))
    .pipe(gulp.dest('dist'))
  ;
});

gulp.task('lint', ['build'], function () {
  return gulp
    .src('dist/sippers.js')
    .pipe(jshint(options.jshint))
    .pipe(jshint.reporter('default'))
  ;
});

gulp.task('test', ['lint'], function () {
  return gulp
    .src('test/**/index.js')
    .pipe(jshint())
    .pipe(jshint.reporter('default'))
    .pipe(mocha(options.mocha))
  ;
});

gulp.task('default', ['test']);
