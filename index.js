require('coffee-script/register');
var ConfigEtcd = require('./src/configetcd');
module.exports = new ConfigEtcd().init();
