# ALUMET helm-charts

## Table of Contents <!-- omit in toc -->
- [ALUMET helm-charts](#alumet-helm-charts)
  - [description summary](#description-summary)
  - [ALUMET relay server](#alumet-relay-server)
  - [ALUMET relay client](#alumet-relay-client)
  - [Influxdb](#influxdb)

## description summary
HELM charts for deploying ALUMET on K8S clusters.
Refer to the github page https://github.com/alumet-dev for more details on ALUMET.

This helm chart contains the following subcharts:
- influxdb: one pod and a service are deployed
- ALUMet relay client: a pod is deployed on each cluster's node
- ALUMet relay server: one pod and a LoadBalancer service's type are deployed

All alumet docker images must be located on the same docker registry. A global variable (global.image.registry) is defined to set the URL path; the default value is: **ghrc.io/alumet-dev**

A kubernetes secret must de defined to be able to connect to the docker registry for downloading the images.
The secret's name is defined ny the global variable **global.secret**, the default value is: **registry-secret**

## ALUMET relay server

It receives the metrics by all ALUMET relay client and writes the metrics in a CSV file or in an influxdb.
You can activate or deactivate a plugin using a helm variable:
- alumet-relay-server.plugins.csv.enable="false" 
- alumet-relay-server.plugins.influxdb.enable="true"

The influxdb parameters (bucket, organization) can be overwritten, the default configuration is:
- organization: "influxdata"
- bucket: "default"

The token variable is automatically set using the secret defined.
A secret must be created before installing Alumet relay server/influxdb, 2 variables must be set with the same secret name:
- influxdb2.existingSecret
- plugins.influxdb.existingSecret

Default secret name is : **influxdb2-auth**

When creating the secret the 2 keys (admin-token and admin-password) must be added, below an example of creating the secret:

>kubectl create secret generic influxdb2-auth --from-literal=token=influwToken --from-literal=password=influxPasswd


 relay server configuration file is created as a config map named: 
 \<release name\>-alumet-relay-server-config

## ALUMET relay client

It collects the metrics of the kubernetes nodes where it is running and sends them to ALUMET  relay server.
The default configuration is correctly set-up to allow communication between ALMUET client and ALUMET server. 
You can activate or deactivate a plugin using a helm variables, the default configuration is:
- alumet-relay-client.plugins.K8s.enable="true"
- alumet-relay-client.plugins.rapl.enable="false"
- alumet-relay-client.plugins.EnergyEstimationTdpPlugin.enable="true"
- alumet-relay-client.plugins.energyAttribution.enable="false"
- alumet-relay-client.plugins.procfs.enable="true"
- alumet-relay-client.plugins.perf.enable="true"

relay client configuration file is created as a config map named: 
\<release name\>-alumet-relay-client-config

## Influxdb 

All metrics are written in influxdb if the plugins Influxdb is enabled (alumet-relay-server.plugins.influxdb.enable="true").

The credentials to logon to the web page of influxdb are defined by a secret. The secret name is defined by the variable:
- influxdb2.existingSecret

If the secret does not exist, the secret is automatically created and credentials generated randomly; nevertheless to enable alumet relay server accessing to influxdb the secret must be created first before installation ([see above chapter related to alumet-relay-server for more details](#alumet-relay-server)) 

By default the http service is active and can be accessible from outside the k8s cluster on port 80 (default).
Refer to https://github.com/influxdata/helm-charts/tree/master/charts/influxdb2 for more details about influxdb configuration.

