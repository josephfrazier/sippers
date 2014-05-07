var gulp = require('gulp');
var gutil = require('gulp-util');
var peg = require('gulp-peg');

var pegOptions = {
  'allowedStartRules': [
    'SIP_message'
  ]
};

gulp.task('default', function() {
  gulp
    .src('src/sippers.pegjs')
    .pipe(peg(pegOptions).on('error', gutil.log))
    .pipe(gulp.dest('dist'))
});

