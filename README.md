# vinsight-lib-config-etcd

config lib with etcd support

## Installation

    $ npm install git+ssh://git@gitlab-openvpn:bigdata/vinsight-lib-config-etcd.git --save

## Benutzung

    config = {}
    ConfigEtcd = require 'vinsight-lib-config-etcd'
    configetcd = new ConfigEtcd config
    configetcd.init()


## Beispiele

siehe Folder **examples**

## Api-Dokumentation

**doc/index.html** im Browser öffnen

### Config

#### config.xxx

...

### Methoden

#### init

Muss mit der Konfiguration **config** aufgerufen werden

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

###### Library releasen

    $ grunt release:xxx (wobei xxx = __major__, __minor__ oder __patch__ sein kann)


## Release History

### 0.1.0

* Initiale Version

## Autoren

* Valiton GmbH