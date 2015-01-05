
module.exports = (grunt) ->

  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')
    coffeelint:
      app: ["src/**/*.coffee"]
      options:
        max_line_length: value: 1000, level: "error"
        no_trailing_whitespace: level: "error"
        no_trailing_semicolons: level: "error"
        no_unnecessary_fat_arrows: level: "error"
        arrow_spacing: level: "error"
        camel_case_classes: level: "error"
        duplicate_key: level: "error"
        indentation: level: "error"
        missing_fat_arrows: level: "error"
        no_empty_param_list: level: "error"
        no_stand_alone_at: level: "error"
        no_tabs: level: "error"
        space_operators: level: "error"

    clean:
      before:
        src: ["coverage", "lib", "reports", "doc"]
      spec:
        src: ["spec-lib", "coverage/instrument", "spec-integration-lib"]

    coffee:
      compile:
        options:
          bare: true
        files: [
          {expand: true, cwd: './src', src: ['**/*.coffee'], dest: './lib', ext: '.js'}
          {expand: true, cwd: './spec', src: ['**/*.coffee'], dest: './spec-lib', ext: '.spec.js'}
          {expand: true, cwd: './spec-integration', src: ['**/*.coffee'], dest: './spec-integration-lib', ext: '.spec.js'}
        ]

    jasmine_node:
      spec:
        options:
          projectRoot: "./spec-lib"
          jUnit:
            report: true
            savePath: "reports/"
            useDotNotation: true
            consolidate: false
      integration:
        options:
          projectRoot: "./spec-integration-lib"
          jUnit:
            report: true
            savePath: "reports/"
            useDotNotation: true
            consolidate: false

    instrument :
      files : 'lib/**/*.js'
      options :
        basePath : './coverage/instrument/'

    storeCoverage :
      options :
        dir : './coverage'

    makeReport :
      src : './coverage/*.json'
      options :
        type : 'cobertura'
        dir : './coverage'
        print : 'detail'

    jsdoc:
      dist:
        src: ['lib/*.js'],
        options:
          destination: 'doc'

    replace:
      coverage:
        options:
          variables: '/lib/': '/coverage/instrument/lib/'
          prefix: ''
        files: [expand: true, cwd: './spec-lib', src: ['*.spec.js'], dest: './spec-lib', ext: '.spec.js']

    watch:
      scripts:
        files: ['src/**/*.coffee','spec/**/*.coffee']
        tasks: ['test_and_run']
        options:
          delayTime: 1
          spawn: true

    exec:
      start_release:
        cmd: (version) ->
          "git flow release start v#{version}"
      commit_release_version:
        cmd: (version) ->
          "git commit -am 'v#{version}'"
      push_release_version:
        cmd: (version) ->
          "git push --set-upstream origin release/v#{version}"
      finish_release:
        cmd: (version) ->
          "git flow release finish -pm 'v#{version}' v#{version}"

  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-jasmine-node'
  grunt.loadNpmTasks 'grunt-istanbul'
  grunt.loadNpmTasks 'grunt-replace'
  grunt.loadNpmTasks 'grunt-jsdoc'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-funky-bump'
  grunt.loadNpmTasks 'grunt-exec'

  grunt.registerTask 'vihbm', ['coffeelint', 'clean:before', 'coffee', 'instrument', 'replace:coverage', 'jasmine_node:spec', 'storeCoverage', 'makeReport', 'clean:spec', 'jsdoc']
  grunt.registerTask 'int', ['coffeelint', 'clean:before', 'coffee', 'jasmine_node:integration', 'clean:spec']
  grunt.registerTask 'test_and_run', ['coffeelint', 'clean:before','coffee', 'jasmine_node:spec', 'clean:spec']
  grunt.registerTask 'dev', [ 'vihbm', 'watch']

  grunt.registerTask 'release', (version) ->
    versions = ['major', 'minor', 'patch']
    unless version in versions
      grunt.log.error 'release version needs to be one of %j', versions
      return false

    newVersion = require('semver').inc grunt.config.get('pkg.version'), version
    grunt.task.run "exec:start_release:#{newVersion}"
    grunt.task.run "bump:#{version}"
    grunt.task.run "exec:commit_release_version:#{newVersion}"
    grunt.task.run "exec:push_release_version:#{newVersion}"
    grunt.task.run "exec:finish_release:#{newVersion}"
