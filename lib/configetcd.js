
/**
 * @name lib-config-etcd
 * @description config lib with etcd support
 * @author Valiton GmbH
 */

/**
 * Standard library imports
 */
var ConfigEtcd, Discover, EventEmitter, argv, convict, flat, path, _,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

EventEmitter = require('events').EventEmitter;

path = require('path');


/**
 * 3rd library imports
 */

Discover = require('discover-client');

convict = require('convict');

flat = require('flat');

argv = require('optimist').argv;

_ = require('lodash');


/*
 * Local imports
 */

module.exports = ConfigEtcd = (function(_super) {
  __extends(ConfigEtcd, _super);


  /**
   * create a new ConfigEtcd instance,
   *
   * @memberOf global
   *
   * @constructor
   * @this {ConfigEtcd}
   */

  function ConfigEtcd() {
    this.services = [];
    this.trackChange = [];
    this.config = null;
  }


  /**
   * initalize the ConfigEtcd-Instance
   *
   * @function global.ConfigEtcd.prototype.init
   * @returns {this} the current instance for chaining
   */

  ConfigEtcd.prototype.init = function() {
    var etcdHost, etcdPort, etcdPrefix;
    etcdHost = argv.ETCD_HOST || process.env.ETCD_HOST || 'etcd';
    etcdPort = argv.ETCD_PORT || process.env.ETCD_PORT || 4001;
    etcdPrefix = argv.ETCD_PREFIX || process.env.ETCD_PREFIX || 'discover';
    this.discover = new Discover({
      host: etcdHost,
      port: etcdPort,
      prefix: etcdPrefix
    });
    return this;
  };


  /**
   * load the final config, merge with current environment config
   *
   * @function global.Config.prototype.load
   * @param    {Function} cb callback if it needs to be asynchronous
   */

  ConfigEtcd.prototype.load = function(cb) {
    this._loadBaseConfig();
    return this._resolveEtcd((function(_this) {
      return function() {
        _this._buildConfig();
        _this.emit('loaded');
        if (typeof cb === 'function') {
          return cb(_this.config);
        }
      };
    })(this));
  };


  /**
   * get config
   *
   * @function global.Config.prototype.getConfig
   */

  ConfigEtcd.prototype.getConfig = function() {
    return this.config;
  };


  /**
   * build configuration
   *
   * @function global.Config.prototype._buildConfig
   * @private
   */

  ConfigEtcd.prototype._buildConfig = function() {
    var buildConfig, key, value, _fn, _ref;
    buildConfig = {};
    _ref = this.flattened;
    _fn = (function(_this) {
      return function(key, value) {
        var hostPort, service, url;
        if (typeof value === 'string' && value.indexOf('ETCD_') === 0) {
          service = value.substring(11);
          if (_this.services[service] == null) {
            throw Error("Service object for service " + service + " not available");
          }
          url = _this.services[service].uri();
          _this.trackChange[service] = url;
          hostPort = url.match(/.*\:\/\/(.*):(.*)$/);
          if (hostPort == null) {
            throw Error("Invalid ETCD service url format for url " + url);
          }
          if (value.indexOf('ETCD_HOST::') === 0) {
            return buildConfig[key] = hostPort[1];
          } else if (value.indexOf('ETCD_PORT::') === 0) {
            return buildConfig[key] = hostPort[2];
          } else {
            throw Error("Invalid ETCD config parameter: " + value);
          }
        } else {
          return buildConfig[key] = value;
        }
      };
    })(this);
    for (key in _ref) {
      value = _ref[key];
      _fn(key, value);
    }
    return this.config = flat.unflatten(buildConfig);
  };


  /**
   * resolves regular config parameters
   *
   * @function global.Config.prototype._resolveStandardConfig
   * @private
   */

  ConfigEtcd.prototype._loadBaseConfig = function() {
    var config, env, schema;
    schema = convict(require(path.join(process.cwd(), './lib/config/schema')));
    env = argv.NODE_ENV || process.env.NODE_ENV;
    config = _.extend(schema.loadFile(path.join(process.cwd(), 'config/config.json')), schema.loadFile(path.join(process.cwd(), "config/" + env + ".json"))).validate();
    this.baseConfig = _.cloneDeep(JSON.parse(config.toString()), function(value) {
      if (typeof value !== 'string') {
        return;
      }
      if (value.indexOf("ENV::") === 0) {
        return process.env[value.substring(5)] || ("ENV_VAR_" + (value.substring(5)) + "_NO_SET");
      }
    });
    return this.flattened = flat.flatten(this.baseConfig);
  };


  /**
   * resolves etcd config parameters
   *
   * @function global.Config.prototype._resolveEtcd
   * @param    {Object} Config
   * @param    {Function} cb
   * @private
   */

  ConfigEtcd.prototype._resolveEtcd = function(cb) {
    var key, remaining, value, _ref, _results;
    if (typeof this.discover === 'undefined') {
      throw new Error('Discover service not initialized. You need to call init() first.');
    }
    remaining = Object.keys(this.flattened).length;
    _ref = this.flattened;
    _results = [];
    for (key in _ref) {
      value = _ref[key];
      _results.push((function(_this) {
        return function(key, value) {
          var service;
          service = "";
          if (!((typeof value === 'string') && (service = value.substring(11)) && (value.indexOf('ETCD_') === 0) && (_this.services[service] == null))) {
            if (--remaining === 0) {
              cb();
            }
            return;
          }
          _this.services[service] = _this.discover.resolve(service);
          _this.services[service].on('resolved', function() {
            if (--remaining === 0) {
              return cb();
            }
          });
          _this.services[service].on('changed', function() {
            var _ref1;
            if (_ref1 = _this.trackChange[service], __indexOf.call(_this.services[service].list(), _ref1) < 0) {
              _this._buildConfig();
              return _this.emit('changed');
            }
          });
          return _this.services[service].on('notfound', function() {
            throw new Error("Could not resolve config " + value);
          });
        };
      })(this)(key, value));
    }
    return _results;
  };

  return ConfigEtcd;

})(EventEmitter);
