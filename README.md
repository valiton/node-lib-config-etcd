# vinsight-lib-config-etcd

config lib with etcd support

## Installation

    $ npm install git+ssh://git@gitlab-openvpn:bigdata/vinsight-lib-config-etcd.git --save

## Benutzung

    configEtcd = require 'vinsight-lib-config-etcd'
    configEtcd.load()
    configEtcd.on 'loaded', ->
      config = configEtcd.getConfig()
      // start application


## Beispiele

siehe Folder **examples**

## Api-Dokumentation

**doc/index.html** im Browser öffnen

### Config

#### config.xxx

...

### Methoden

#### load

## Entwicklung

###### Applikation klonen

    $ git clone git@gitlab-openvpn:bigdata/vinsight-lib-config-etcd.git


###### Alle Module installieren

    $ npm install

###### Development-Workflow/und watch (jeder Code-Change restarted die Tests)

    $ grunt dev


###### Jasmine Tests laufen lassen

lässt intern **grunt vihbm** laufen - definiert im scripts-block der package.json

    $ npm test

Damit die Tests erfolgreich durchlaufen, muss die Zeile `124` in der Datei `src/configetcd.coffee` wie folgt angepasst werden:

    +    schema = convict require(path.join(process.cwd(), './coverage/instrument/lib/config/schema'))
    -    schema = convict require(path.join(process.cwd(), './lib/config/schema'))

Jasmine ersetzt da irgendwelche String-Values, wohl um die Coverage messen zu können.

###### Library releasen

    $ grunt release:xxx (wobei xxx = __major__, __minor__ oder __patch__ sein kann)


## Release History

### 0.1.0

* Initiale Version

## Autoren

* Valiton GmbH
