# ALUMET helm-charts
## description summary
HELM charts for deploying ALUMET on K8S clusters.
Refer to the github page https://github.com/alumet-dev for more details on ALUMET.

The helm chart contains the following subcharts:
- influxdb: one pod and a LoadBalancer service's type are deployed
- ALUMet relay client: a pod is deployed on each cluster's node
- ALUMet relay server: one pod and a LoadBalancer service's type are deployed
- ALUMet API:  one pod and a LoadBalancer service's type are deployed

All docker images must be located on the same docker registry. A global variable (global.image.registry) is defined to set the URL path. 

A kubernetes secret must de defined to be able to connect to the docker registry for downloading the images.
The secret's name is defined as global variable: global.secret.name

## ALUMET relay server

It receives the metrics by all ALUMET relay client and write the metrics in a CSV file or in an influxdb.
You can activate or deactivate a plugin using a helm variable:
alumet-relay-server.plugins.csv.enable="false" 
alumet-relay-server.plugins.influxdb.enable="true"

The influxdb parameters (token, buket, organization, attributes_as) can be overiden and set as global variables.

Its configuration is set in a config map 

## ALUMET relay client

It collects the metrics of the kubernetes nodes where it is running and sends them to ALUMET  relay server.
The default configuration is correctly set-up to allow communication between ALMUET client and ALUMET server. 
The default port is 50051 and can be change using the global helm variable: global.service.port
You can activate or deactivate a plugin using a helm variable:
alumet-relay-client.plugins.K8s.enable="true"
alumet-relay-client.plugins.rapl.enable="true"
alumet-relay-client.plugins.EnergyEstimationTdpPlugin.enable="true"
alumet-relay-client.plugins.energyAttribution.enable="true"
alumet-relay-client.plugins.procfs.enable="true"
alumet-relay-client.plugins.perf.enable="true"

Its configuration is set in a config map 

## ALUMET API

An API rest it exposed the data stored in influxdb to retrieve the metrics.
The default configuration does not installed this component.

## Influxdb 

All metrics are wrtitten in influxdb if the plugins Influxdb is enabled.
The credentials to logon to the web page of influxdb are defined by helm variables:
    influxdb2.adminUser.user (default value: admin)
    influxdb2.adminUser.password (default value: passwordToChange)

