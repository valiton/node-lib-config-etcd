# run this from your project-directory like this:
# $ export ETCD_HOST=<etcd-host> # default etcd
# $ export ETCD_PORT=<etcd-port> # default 4001
# $ export ETCD_PREFIX=<etcd-prefix> # default discover
# $ coffee examples/configetcd.coffee

configEtcd = require "#{process.cwd()}/src/configetcd"

configEtcd.on 'loaded', ->

  config = configEtcd.getConfig()
  console.log config

configEtcd.on 'changed', ->

  newConfig = configEtcd.getConfig()
  console.log newCconfig

configEtcd.load()
