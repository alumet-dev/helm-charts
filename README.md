# ALUMET helm-charts
## description summary
HELM charts for deploying ALUMET on K8S clusters.
Refer to the github page https://github.com/alumet-dev for more details on ALUMET.

The helm chart contains the following subcharts:
- influxdb: one pod and a LoadBalancer service's type are deployed
- ALUMet relay client: a pod is deployed on each cluster's node
- ALUMet relay server: one pod and a LoadBalancer service's type are deployed
- ALUMet API:  one pod and a LoadBalancer service's type are deployed

All docker images must be located on the same docker registry. A global variable (global.image.registry) is defined to set the URL path; the default value is: ghrc.io/alumet-dev

A kubernetes secret must de defined to be able to connect to the docker registry for downloading the images.
The secret's name is defined as global variable: global.secret

## ALUMET relay server

It receives the metrics by all ALUMET relay client and write the metrics in a CSV file or in an influxdb.
You can activate or deactivate a plugin using a helm variable:
alumet-relay-server.plugins.csv.enable="false" 
alumet-relay-server.plugins.influxdb.enable="true"

The influxdb parameters (token, buket, organization) can be overiden but the default configuration is set to be able a communication with the influxdb deployed.

Its configuration is set in a config map 

## ALUMET relay client

It collects the metrics of the kubernetes nodes where it is running and sends them to ALUMET  relay server.
The default configuration is correctly set-up to allow communication between ALMUET client and ALUMET server. 
You can activate or deactivate a plugin using a helm variable, the default configuration is:
alumet-relay-client.plugins.K8s.enable="true"
alumet-relay-client.plugins.rapl.enable="false"
alumet-relay-client.plugins.EnergyEstimationTdpPlugin.enable="true"
alumet-relay-client.plugins.energyAttribution.enable="false"
alumet-relay-client.plugins.procfs.enable="true"
alumet-relay-client.plugins.perf.enable="true"

Its configuration is set in a config map 

## ALUMET API

An API rest it exposed the data stored in influxdb to retrieve the metrics.
The default configuration does not installed this component.

## Influxdb 

All metrics are wrtitten in influxdb if the plugins Influxdb is enabled.
The credentials to logon to the web page of influxdb are defined by the default helm variables:
    influxdb2.adminUser.user
    influxdb2.adminUser.password
By default the http service is active and can be accessible from outside the k8s cluster on port 80 (default).
Refer to https://github.com/influxdata/helm-charts/tree/master/charts/influxdb2 for more details about influxdb configuration.

