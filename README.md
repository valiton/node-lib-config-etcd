# lib-config-etcd

config lib with etcd support

## Installation

    $ npm install git+ssh://git@github.com:valiton/node-lib-config-etcd.git --save

## Benutzung

### NODE_ENV

Set this environment var in your home-directory (eg. .bash_profile) or run this application with --NODE_ENV=...

### Necessary files

* config/config.json
* config/{env}.json (where ENV is the environment var NODE_ENV)
* config/schema.coffee (the validation schema)

### ENV
`lib-config-etcd` can load values form envioronment variable.
Use the prefix `ENV::` to load a config value from a environment variabel:

    $ export MYKEY=0123456789

Used in config.json:

    {
        "config": {
           "key": "ENV::MYKEY"
        }
    }

### ETCD
##### Using ETCD
[ETCD](https://github.com/coreos/etcd) is a highly-available key value store for shared configuration and service discovery. You can define configuration options that will result in an etcd lookup by using an `ETCD_HOST::` and `ETCD_PORT::` prefix like this in your config file:

    {
        "config": {
           "serviceLocationHost": "ETCD_HOST::myService"
           "serviceLocationPort": "ETCD_PORT::myService"
        }
    }

To alow `lib-config-etcd` to find service in ETCD, the service have to be registerd e.g. by using [discover](https://github.com/totem/discover)
`lib-config-etcd` uses internal the [discover-client](https://github.com/totem/discover-client-node)

#### Configuring ETCD

`lib-config-etcd`  uses envioronment variable or CLI-parameter `ETCD_HOST`, `ETCD_PORT`, `ETCD_PREFIX`  to find the ETCD Servers.

Default values are the following

- ETCD_HOST etcd
- ETCD_PORT 4001
- ETCD_PREFIX discover


## Example.coffee

    configEtcd = require 'lib-config-etcd'

    configEtcd.on 'loaded', ->
      config = configEtcd.getConfig()
      # start application

    configEtcd.on 'changed', ->
      newConfig = configEtcd.getConfig()
      # reconfigure application

    configEtcd.load()


see folder **examples**

## Api-Dokumentation

**doc/index.html** open in Brower

### Methoden

#### load()
`laod()` load's the config. Config loading is async since it has make network calls to etcd.

#### getConfig()
`getConfig()` get the current config values. Only avalible after the `loaded` event got fired.

#### on('event', cb)
`on('event', cb)` register event hanlder

### Events
#### loaded
event fires when config is load and  `getConfig()` can be used.

##### changed
event fires when a config change in etcd happes.
To get the updated config value use `getConfig()` 

## Developlment

###### clone repo

    $ git clone git@github.com:valiton/node-lib-config-etcd.git


###### install node module

    $ npm install

###### Development-Workflow/ and watch (each code change restarts the build)

    $ grunt dev


###### run Jasmine tests 

runs internal **grunt vihbm** 

    $ npm test


###### creat release

    $ grunt release:xxx ( xxx = major || minor || patch )


## Release History

### 0.1.0

* Initiale Version

## Autoren

* Valiton GmbH
* Johannes Stark
* Benedikt Weiner
