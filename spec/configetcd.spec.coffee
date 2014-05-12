require 'jasmine-matchers'
path = require 'path'
rewire = require 'rewire'
flat = require 'flat'
ConfigEtcd = rewire "#{process.cwd()}/lib/configetcd"

serviceVars =
  "hans": "tcp://wurst:4711"
  "hans3": "tcp://wurst3:1234"

changeCallback = null

class ServiceMock
  constructor: (@key) ->
  uri: ->
    serviceVars[@key]
  list: ->
    serviceVars
  on: (event, cb) ->
    process.nextTick ->
      if event == 'resolved'
        cb?()
      if event == 'changed'
        changeCallback = cb

class DiscoverMock
  constructor: ->
    @services = []
  resolve: (key) ->
    @services[key] = new ServiceMock key
    return @services[key]

describe 'ConfigEtcd', ->

  it 'should initialize the config', (done) ->
    process.env.VINSIGHT_ENV = 'jasmine'
    spyOn(path, 'join').andCallFake (args...) ->
      if args[1] is './lib/config/schema'
        return "#{process.cwd()}/spec/helper/schema"
      if args[1] is 'config/config.json'
        return "#{process.cwd()}/spec/helper/config.json"
      if args[1] is 'config/jasmine.json'
        return "#{process.cwd()}/spec/helper/jasmine.json"
      #path.join.call path, args

    config = new ConfigEtcd()
    config.discover = new DiscoverMock()

    expected =
      "prop1": "value1"
      "prop2": "value2-new"
      "prop3":
        "prop31": "value31"
        "prop32":
          "prop321": "value321"
          "prop322": "value322-new"
      "__get__" : config.__get__ #work around to be able to realdo the moduel use rewire therefor have to pathch the test
      "__set__" : config.__set__


    config.on 'loaded', ->
      config = config.getConfig()
      expect(config).toEqual(expected)
      done()
    config.load()

  it 'should initialize the config and replace env values', (done) ->
    process.env.VINSIGHT_ENV = 'jasmine_with_env'
    spyOn(path, 'join').andCallFake (args...) ->
      if args[1] is './lib/config/schema'
        return "#{process.cwd()}/spec/helper/schema"
      if args[1] is 'config/config.json'
        return "#{process.cwd()}/spec/helper/config.json"
      if args[1] is 'config/jasmine_with_env.json'
        return "#{process.cwd()}/spec/helper/jasmine_with_env.json"
      #path.join.call path, args

    config = new ConfigEtcd()
    config.discover = new DiscoverMock()

    expected =
      "prop1": "value1"
      "prop2": "value2-new"
      "prop3":
        "prop31": "value31"
        "prop32":
          "prop321": "value321"
          "prop322": "jasmine_with_env"
      "__get__" : config.__get__  #work around to be able to realdo the moduel use rewire therefor have to pathch the test
      "__set__" : config.__set__

    config.on 'loaded', ->
      config = config.getConfig()
      expect(config).toEqual(expected)
      done()
    config.load()

  it 'should initialize the config and replace etcd values', (done) ->

    testConfig =
      "bool": true
      "hanshost": "ETCD_HOST::hans"
      "hansport": "ETCD_PORT::hans"
      "hans2":
        "hans3host": "ETCD_HOST::hans3"
        "hans3port": "ETCD_PORT::hans3"

    expected =
      "bool": true
      "hanshost": "wurst"
      "hansport": "4711"
      "hans2":
        "hans3host": "wurst3"
        "hans3port": "1234"
    configInstance = new ConfigEtcd()
    configInstance.discover = new DiscoverMock()
    configInstance.baseConfig = testConfig
    configInstance.flattened = flat.flatten testConfig
    configInstance._loadBaseConfig = ->

    configInstance.load ->
      config = configInstance.getConfig()
      expect(config).toEqual expected
      done()


  it 'should emit a changed event if an etcd value changes an provide an updated config', (done) ->
    testConfig =
      "hanshost": "ETCD_HOST::hans"
      "hansport": "ETCD_PORT::hans"
      "hans2":
        "hans3host": "ETCD_HOST::hans3"
        "hans3port": "ETCD_PORT::hans3"

    expected =
      "hanshost": "wurst"
      "hansport": "4711"
      "hans2":
        "hans3host": "wurst3"
        "hans3port": "4711"

    configInstance = new ConfigEtcd()
    configInstance.discover = new DiscoverMock()
    configInstance.baseConfig = testConfig
    configInstance.flattened = flat.flatten testConfig
    configInstance._loadBaseConfig = ->

    configInstance.load ->
      serviceVars.hans3 = "tcp://wurst3:4711"

      configInstance.on 'changed', ->
        config = configInstance.getConfig()
        expect(config).toEqual expected
        done()

      changeCallback()

