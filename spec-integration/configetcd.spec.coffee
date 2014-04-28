require 'jasmine-matchers'
ConfigEtcd = require "#{process.cwd()}/lib/configetcd"

describe 'ConfigEtcd', ->

  # Integration-Tests
  describe 'Integration', ->

    it 'should ...', ->
      testConfig = {}
      configetcd = new ConfigEtcd(testConfig).init()
      expect(true).toBeTruthy()