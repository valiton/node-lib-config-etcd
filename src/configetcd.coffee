###*
 * @name vinsight-lib-config-etcd
 * @description config lib with etcd support
 * @author Valiton GmbH
###


###*
 * Standard library imports
###
EventEmitter = require('events').EventEmitter


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
   * @param {object} config read more about config options in README
   * @this {ConfigEtcd}
  ###
  constructor: (@config) ->


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
    schema = convict require(path.join(process.cwd(), './lib/config/schema'))
    env = argv.VINSIGHT_ENV or process.env.VINSIGHT_ENV
    config = _.extend(
      schema.loadFile path.join(process.cwd(), 'config/config.json')
      schema.loadFile path.join(process.cwd(), "config/#{env}.json")
    ).validate()

    config = _.cloneDeep JSON.parse(config.toString()), (value) ->
      return unless typeof value is 'string'

      if value.indexOf("ENV::") is 0
        return process.env[value.substring(5)] or "ENV_VAR_#{envVar}_NO_SET"

    return config unless typeof cb is 'function'

    @_resolveEtcd config, cb


  ###*
   * resolves etcd...
   *
   * @function global.Config.prototype._resolveEtcd
   * @param    {Object} Config
   * @param    {Function} cb
   * @private
  ###
  _resolveEtcd: (config, cb) ->
    throw new Error('Discover service not initialized. You need to call init() first.') if typeof @discover is 'undefined'
    flattened = flat.flatten config
    remaining = Object.keys(flattened).length

    for key, value of flattened
      do (key, value) =>
        unless value.indexOf('ETCD::') is 0
          if --remaining is 0
            return cb flat.unflatten(flattened)

        item = value.substring 6
        service = @discover.resolve item
        service.on 'resolved', ->
          hostPort = service.url().match /.*\:\/\/(.*)$/
          flattened[key] = hostPort[1]
          if --remaining is 0
            cb flat.unflatten(flattened)
        service.on 'notfound', ->
          throw new Error "Could not resolve config #{value}"
