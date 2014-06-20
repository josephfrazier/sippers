var gulp = require('gulp');
var gutil = require('gulp-util');
var peg = require('gulp-peg');
var jshint = require('gulp-jshint');
var mocha = require('gulp-mocha');
var groc = require('groc');

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
  },
  groc: {
    args: ['index.js', 'src/helpers.js', 'src/ParsedError.js']
  }
};

gulp.task('build', function() {
  gulp.src('src/*.js')
    .pipe(gulp.dest('dist'))
  ;

  return gulp.src('src/grammar.pegjs')
    .pipe(peg(options.peg).on('error', gutil.log))
    .pipe(gulp.dest('dist'))
  ;
});

gulp.task('lint', ['build'], function () {
  return gulp.src('dist/grammar.js')
    .pipe(jshint(options.jshint))
    .pipe(jshint.reporter('default'))
  ;
});

gulp.task('test', ['lint'], function () {
  return gulp.src('test/**/index.js')
    .pipe(jshint())
    .pipe(jshint.reporter('default'))
    .pipe(mocha(options.mocha))
  ;
});

function grocCLI (args) {
  return groc.CLI(args, function(error) {
    if (error) {
      console.error(error);
      process.exit(1)
    }
  });
}

gulp.task('doc', function () {
  return grocCLI(options.groc.args);
});

gulp.task('docpush', function () {
  return grocCLI(options.groc.args.concat('--github'));
});

gulp.task('default', ['test']);
