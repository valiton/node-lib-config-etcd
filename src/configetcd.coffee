#  @name lib-config-etcd
#  @description config lib with etcd support
#  @author Valiton GmbH


# Standard library imports
EventEmitter = require('events').EventEmitter
path = require 'path'


# 3rd library imports
Discover = require 'discover-client'
cjson = require 'cjson'
flat = require 'flat'
argv = require('optimist').argv
_ = require 'lodash'


module.exports = class ConfigEtcd extends EventEmitter

  # create a new ConfigEtcd instance,
  constructor: ->
    @services = []
    @trackChange = []
    @config = null


  # initalize the ConfigEtcd-Instance
  # @method ConfigEtcd.prototype.init
  # @return {Object} the current instance for chaining
  init: ->
    etcdHost = argv.ETCD_HOST or process.env.ETCD_HOST or 'localhost'
    etcdPort =  argv.ETCD_PORT or process.env.ETCD_PORT or 4001
    etcdPrefix =  argv.ETCD_PREFIX or process.env.ETCD_PREFIX or 'discover'
    @discover = new Discover host: etcdHost, port: etcdPort, prefix: etcdPrefix
    this


  # load the final config, merge with current environment config
  # @method Config.prototype.load
  # @param {String} configPath - the path from where to load the config (default: config)
  # @param {Function} cb - callback if it needs to be asynchronous
  load: (@configPath = 'config', cb) ->
    @_loadBaseConfig()
    @_resolveEtcd =>
      @_buildConfig()
      process.nextTick => @emit 'loaded'
      cb? @config


  # get the current config
  # @method Config.prototype.getConfig
  # @return {Object} public Interface for getting the config
  getConfig: ->
    return @config


  # build configuration
  # @method Config.prototype._buildConfig
  # @private
  # @return [Object] config final
  _buildConfig: ->
    buildConfig = {}

    for key, value of @flattened
      do (key, value) =>

        if typeof value isnt 'string' or value.indexOf('ETCD_') isnt 0
          return buildConfig[key] = value

        service = value.substring 11
        throw Error("Service object for service #{service} not available") unless @services[service]?
        url = @services[service].uri()
        @trackChange[service] = url

        hostPort = url.match /.*\:\/\/(.*):(.*)$/
        throw new Error("Invalid ETCD service url format for url #{url}") unless hostPort?

        if value.indexOf('ETCD_HOST::') is 0
          buildConfig[key] = hostPort[1]
        else if value.indexOf('ETCD_PORT::') is 0
          buildConfig[key] = hostPort[2]
        else
          throw new Error "Invalid ETCD config parameter: #{value}"

    @config = flat.unflatten buildConfig


  # resolves regular config parameters
  # @method Config.prototype._resolveStandardConfig
  # @private
  # @return [Object] flattened config
  _loadBaseConfig: ->
    env = argv.NODE_ENV or process.env.NODE_ENV or 'development'
    config = _.merge(
      cjson.load path.join(process.cwd(), @configPath, 'config.json')
      cjson.load path.join(process.cwd(), @configPath, "#{env}.json")
    )

    @baseConfig = _.cloneDeep config, (value) ->
      return unless typeof value is 'string'

      if value.indexOf("ENV::") is 0
        return process.env[value.substring(5)] or "ENV_VAR_#{value.substring(5)}_NO_SET"

    @flattened = flat.flatten @baseConfig


  # resolves etcd config parameters
  # @method Config.prototype._resolveEtcd
  # @param [Function] cb
  # @private
  _resolveEtcd: (cb) ->
    remaining = Object.keys(@flattened).length

    for key, value of @flattened
      do (key, value) =>

        if typeof value isnt 'string'
          cb() if --remaining is 0
          return

        service = value.substring 11
        if value.indexOf('ETCD_') isnt 0 or @services[service]?
          cb() if --remaining is 0
          return

        @services[service] = @discover.resolve service

        @services[service].on 'resolved', ->
          cb() if --remaining is 0

        @services[service].on 'changed', =>
          if @trackChange[service] not in @services[service].list()
            @_buildConfig()
            @emit 'changed'

        @services[service].on 'notfound', ->
          throw new Error "Could not resolve config #{value}"
