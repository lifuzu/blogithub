
module.exports = (grunt) ->

  # Project configuration.
  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')

    coffee:
      compile:
        files:
          'build/onsite/js/inspect.js': 'src/js/inspect.coffee'


    copy:
      main:
        files: [
          {
            cwd: 'src/'
            expand: true
            src: ['**/*.html', '**/*.png']
            dest: 'build/onsite'
            filter: 'isFile'
          },
          {
            cwd: 'extension/'
            expand: true
            src: ['**/*.html', '**/*.*.js', '**/*.json', '**/*.png']
            dest: 'build/extension'
            filter: 'isFile'
          }
        ]


    watch:
      src:
        files: ['src/**/*','extension/src/**/*'],
        tasks: ['default']

  # Grunt coffee
  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.loadNpmTasks('grunt-contrib-copy')
  grunt.loadNpmTasks('grunt-contrib-watch');

  grunt.registerTask('default', ['coffee', 'copy'])