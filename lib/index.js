var ConfigEtcd, config;

ConfigEtcd = require('./configetcd');

config = new ConfigEtcd();

module.exports = config.init();
