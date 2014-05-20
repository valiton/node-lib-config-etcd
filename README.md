# vinsight-lib-config-etcd

config lib with etcd support

## Installation

    $ npm install git+ssh://git@gitlab-openvpn:bigdata/vinsight-lib-config-etcd.git --save

## Benutzung

### VINSIGHT_ENV

Set this environment var in your home-directory (eg. .bash_profile) or run this application with --VINSIGHT_ENV=...

### Benötigte Dateien

* config/config.json
* config/{env}.json (where ENV is the environment var VINSIGHT_ENV)
* config/schema.coffee (the validation schema)

### ENV
`vinsight-lib-config-etcd` hat das Feature aus der alten `vinsight-lib-config` übernommen, Konfigurationswerte aus dem Environment einzulesen. Solche Parameter müssen mit dem Prefix `ENV::` gekennzeichnet sein:

    $ export MYKEY=0123456789

Es folgt das entsprechende Format der Konfigurationsdatei:

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

Damit `vinsight-lib-config-etcd` Services in ETCD finden kann, müssen diese zuvor über [discover](https://github.com/totem/discover) registriert worden sein. `vinsight-lib-config-etcd` nutzt intern den [discover-client](https://github.com/totem/discover-client-node)

#### Configuring ETCD

Die Lib kann über die ENV-Variablen oder CLI-Parameter `ETCD_HOST`, `ETCD_PORT` und `ETCD_PREFIX` konfiguriert werden.

Auf dem angegebenen Host muss auf dem angegebenen Port ein ETCD-Service laufen. Man hat zusätzlich die Möglichkeit, alle seine Services unterhalb eines Prefixes zu registrieren.

Die Default-Werte sind folgende:

- ETCD_HOST etcd
- ETCD_PORT 4001
- ETCD_PREFIX discover


## Beispiele

    configEtcd = require 'vinsight-lib-config-etcd'

    configEtcd.on 'loaded', ->
      config = configEtcd.getConfig()
      # start application

    configEtcd.on 'changed', ->
      newConfig = configEtcd.getConfig()
      # reconfigure application

    configEtcd.load()


und siehe Folder **examples**

## Api-Dokumentation

**doc/index.html** im Browser öffnen

### Methoden

#### load()
`laod()` veranlasst die Lib dazu, die Konfiguration zu laden und nedem den JSON-Konfigurationsdateien, ENV-Werte und ETCD-Werte aufzulösen.

#### getConfig()
`getConfig()` liefert das fertig aufbereitet Konfigurations-Objekt zurück. Die Funktion kann aufgerufen werden, sobald das Event `loaded` (s.u.) emittiert wurde.

#### on('event', cb)
`on('event', cb)` dient dem Registrieren von Event-Handlern (s.u.).

### Events
#### loaded
Diese Event wird emittiert, sobald die Konfiguration vollständig geladen ist. Die Konfiguration kann dann über `getConfig()` abgerufen werden.

##### changed
Dieses Event wird emittiert, sobald eine Änderung in der Konfiguration statt gefunden hat. Eine Applikation hat dann die Möglichkeit, die aktualisierte Konfiguration über `getConfig()` abzurufen.

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
