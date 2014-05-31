var gulp = require('gulp');
var gutil = require('gulp-util');
var peg = require('gulp-peg');
var jshint = require('gulp-jshint');
var mocha = require('gulp-mocha');
var replace = require('gulp-replace');

// make gulp work from subdirectories
process.chdir(__dirname);

var options = {
  peg: {
    'allowedStartRules': [
      'SIP_message'
      ,'encoding'
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
    // modify generated parse method
    .pipe(replace('parse:       parse',
      'parse: function (input, options){' +
        // allow startRule to be passed as string, default to 'SIP_message'
        'options = options || "SIP_message";' +
        'if (options.constructor === String) {' +
          'options = {startRule: options};' +
        '}' +
        // RFC 3261 25.1:
        // All linear white space, including folding, has the same semantics as SP.
        'var emptyLine = "\\r\\n\\r\\n";' +
        'var hadEmptyLine = input.indexOf(emptyLine) > -1;' +
        'var folding = /[\\t ]*\\r\\n[\\t ]+/g;' +
        'var headersBody = input.split(emptyLine, 2);' +
        'var headers = headersBody[0].replace(folding, " ");' +
        'var body = headersBody[1] || "";' +
        'var result = headers + (hadEmptyLine ? emptyLine : "") + body;' +
        'return parse(result, options);' +
      '}'))
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
