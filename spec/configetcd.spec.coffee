require 'jasmine-matchers'
rewire = require 'rewire'
ConfigEtcd = rewire "#{process.cwd()}/lib/configetcd"

describe 'ConfigEtcd', ->

  # tests for init()
  describe 'init', ->

    it 'should initialize the config', ->
      testConfig = {}
      configetcd = new ConfigEtcd testConfig
      expect(configetcd.config).toEqual({})