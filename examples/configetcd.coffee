# run this from your project-directory like this:
# $ coffee examples/configetcd.coffee

ConfigEtcd = require "#{process.cwd()}/src/configetcd"

config = {}

configetcd = new ConfigEtcd config
configetcd.init()
