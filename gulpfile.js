var gulp = require('gulp'),
  stylus = require('gulp-stylus'),
  coffee = require('gulp-coffee'),
  nodemon = require('gulp-nodemon')

var paths = {
  styl: './src/styl/*.styl',
  css: './public/css',
  coffee: './src/coffee/*.coffee',
  core: './src/core/*.coffee',
  app: './app',
  js: './public/js/'
}

gulp.task('start', function () {
  nodemon({
    script: 'index.js'
  , ext: 'js html'
  , env: { 'NODE_ENV': 'development' }
  })
})

gulp.task('stylus', function() {
  gulp.src('./src/styl/main.styl')
    .pipe(stylus({
      compress: true
    }))
    .pipe(gulp.dest(paths.css))
})

gulp.task('core', function() {
  gulp.src(paths.core)
    .pipe(coffee({
      bare: true
    }))
    .pipe(gulp.dest(paths.app))
})

gulp.task('coffee', function() {
  gulp.src(paths.coffee)
      .pipe(coffee({
        bare: true
      }))
      .pipe(gulp.dest(paths.js))
})

gulp.task('watch', function() {
  gulp.watch(paths.styl, ['stylus'])
  gulp.watch(paths.core, ['core'])
  gulp.watch(paths.coffee, ['coffee'])
})

gulp.task('build', ['stylus', 'coffee', 'core'])

gulp.task('default', ['build', 'watch', 'start'])
