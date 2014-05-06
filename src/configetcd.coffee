###*
 * @name vinsight-lib-config-etcd
 * @description config lib with etcd support
 * @author Valiton GmbH
###


###*
 * Standard library imports
###
EventEmitter = require('events').EventEmitter
path = require 'path'


###*
 * 3rd library imports
###
Discover = require 'discover-client'
convict = require 'convict'
flat = require 'flat'
argv = require('optimist').argv
_ = require 'lodash'

###
 * Local imports
###



module.exports = class ConfigEtcd extends EventEmitter

  ###*
   * create a new ConfigEtcd instance,
   *
   * @memberOf global
   *
   * @constructor
   * @this {ConfigEtcd}
  ###
  constructor: ->
    @services = []
    @trackChange = []
    @config = null

  ###*
   * initalize the ConfigEtcd-Instance
   *
   * @function global.ConfigEtcd.prototype.init
   * @returns {this} the current instance for chaining
  ###
  init: ->
    etcdHost = argv.ETCD_HOST or process.env.ETCD_HOST or 'etcd'
    etcdPort =  argv.ETCD_PORT or process.env.ETCD_PORT or 4001
    etcdPrefix =  argv.ETCD_PREFIX or process.env.ETCD_PREFIX or 'discover'
    @discover = new Discover host: etcdHost, port: etcdPort, prefix: etcdPrefix
    this

  ###*
   * load the final config, merge with current environment config
   *
   * @function global.Config.prototype.load
   * @param    {Function} cb callback if it needs to be asynchronous
  ###
  load: (cb) ->
    @_loadBaseConfig()

    @_resolveEtcd =>
      @_buildConfig()
      @emit 'loaded'
      if typeof cb is 'function'
        cb @config

  ###*
   * get config
   *
   * @function global.Config.prototype.getConfig
  ###
  getConfig: ->
    return @config

  ###*
   * build configuration
   *
   * @function global.Config.prototype._buildConfig
   * @private
  ###
  _buildConfig: ->
    buildConfig = {}

    for key, value of @flattened
      do (key, value) =>

        if value.indexOf('ETCD_') is 0

          service = value.substring(11)
          throw Error("Service object for service #{service} not available") unless @services[service]?
          url = @services[service].url()
          @trackChange[service] = url

          hostPort = url.match /.*\:\/\/(.*):(.*)$/
          throw Error("Invalid ETCD service url format for url #{url}") unless hostPort?

          if value.indexOf('ETCD_HOST::') is 0
            buildConfig[key] = hostPort[1]
          else if value.indexOf('ETCD_PORT::') is 0
            buildConfig[key] = hostPort[2]
          else
            throw Error "Invalid ETCD config parameter: #{value}"

        else
          buildConfig[key] = value

    @config = flat.unflatten buildConfig
    

  ###*
   * resolves regular config parameters
   *
   * @function global.Config.prototype._resolveStandardConfig
   * @private
  ###
  _loadBaseConfig: ->
    schema = convict require(path.join(process.cwd(), './coverage/instrument/lib/config/schema'))
    env = argv.VINSIGHT_ENV or process.env.VINSIGHT_ENV
    config = _.extend(
      schema.loadFile path.join(process.cwd(), 'config/config.json')
      schema.loadFile path.join(process.cwd(), "config/#{env}.json")
    ).validate()

    @baseConfig = _.cloneDeep JSON.parse(config.toString()), (value) ->
      return unless typeof value is 'string'

      if value.indexOf("ENV::") is 0
        return process.env[value.substring(5)] or "ENV_VAR_#{envVar}_NO_SET"

    @flattened = flat.flatten @baseConfig

  ###*
   * resolves etcd config parameters
   *
   * @function global.Config.prototype._resolveEtcd
   * @param    {Object} Config
   * @param    {Function} cb
   * @private
  ###
  _resolveEtcd: (cb) ->
    throw new Error('Discover service not initialized. You need to call init() first.') if typeof @discover is 'undefined'

    remaining = Object.keys(@flattened).length

    for key, value of @flattened
      do (key, value) =>
        service = value.substring 11
        # continue if it's not a ETCD value or if etcd service already exists
        unless value.indexOf('ETCD_') is 0 or @services[service]?
          if --remaining is 0
            cb()
          return

        @services[service] = @discover.resolve service

        @services[service].on 'resolved', ->
          if --remaining is 0
            cb()

        @services[service].on 'changed', =>
          if @trackChange[service] not in @services[service].list()
            @_buildConfig()
            @emit 'changed'

        @services[service].on 'notfound', ->
          throw new Error "Could not resolve config #{value}"
