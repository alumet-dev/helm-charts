# ALUMET helm-charts <!-- omit in toc -->

- [description summary](#description-summary)
- [ALUMET relay server](#alumet-relay-server)
  - [influxdb setting](#influxdb-setting)
  - [deployment nodeSelector](#deployment-nodeselector)
- [ALUMET relay client](#alumet-relay-client)
- [Influxdb](#influxdb)
- [Deployment example](#deployment-example)

## description summary

HELM charts for deploying ALUMET on K8S clusters.
Refer to the github page <https://github.com/alumet-dev> for more details on ALUMET.

This helm chart contains the following subcharts:

- influxdb: one pod and a service are deployed
- ALUMET relay client: a pod is deployed on each cluster's node
- ALUMET relay server: one pod and a LoadBalancer service's type are deployed

All alumet docker images must be located on the same docker registry. A global variable (*global.image.registry*) is defined to set the URL path; the default value is: *ghrc.io/alumet-dev*

A kubernetes secret must de defined to be able to connect to the docker registry for downloading the images.
The secret's name is defined by the global variable *global.secret*, the default value is: *registry-secret*

## ALUMET relay server

It receives the metrics by all ALUMET relay client and writes the metrics in a CSV file or in an influxdb.
You can activate or deactivate a plugin using a helm variable:

- alumet-relay-server.plugins.csv.enable="false"
- alumet-relay-server.plugins.influxdb.enable="true"

 relay server configuration file is created as a config map named:
 \<release name\>-alumet-relay-server-config

### influxdb setting

The influxdb parameters listed below can be overwritten, the default configuration is:

- enable: true
- organization: "influxdata"
- bucket: "default"
- attribute_as: "tag"
- existingSecret: ""

The token variable is automatically set using the influxdb secret.
You have 2 choices for creating the influxdb secret:

- let helm creating the secret: in this case it is created by influxdb chart and its name is: *\<release name\>-influxdb2-auth*
- use an existing secret: in this case, 2 variables must be set with the same secret name:
  - influxdb2.adminUser.existingSecret
  - alumet-relay-server.plugins.influxdb.existingSecret

When creating the secret the 2 keys (admin-token and admin-password) must be added, below an example of creating the secret:

```text
kubectl create secret generic influxdb2-auth --from-literal=token=influxToken --from-literal=password=influxPasswd
```

### deployment nodeSelector

By default the deployment of the alumet-relay-server is done on any available node.
But you can specify a target node by setting the variables:

- alumet-relay-server.nodeSelector.nodeLabelName
- alumet-relay-server.nodeSelector.nodeLabelValue

For example if you want to specify a node using its role name and deploy on master node, you need to apply the following configuration:

- alumet-relay-server.nodeSelector.nodeLabelName: "kubernetes.io/role"
- alumet-relay-server.nodeSelector.nodeLabelValue: "master"

You can also specify a label instead of a role, then you have to set the appropriate key in nodeLabelName and label's value in *nodeLabelValue* variable.

## ALUMET relay client

It collects the metrics of the kubernetes nodes where it is running and sends them to ALUMET  relay server.
The default configuration is correctly set-up to allow communication between ALUMET client and ALUMET server. You can activate or deactivate a plugin using a helm variables, the default configuration is:

- alumet-relay-client.plugins.K8s.enable="true"
- alumet-relay-client.plugins.rapl.enable="false"
- alumet-relay-client.plugins.EnergyEstimationTdpPlugin.enable="true"
- alumet-relay-client.plugins.energyAttribution.enable="false"
- alumet-relay-client.plugins.perf.enable="true"
- alumet-relay-client.plugins.procfs.enable="true"
- alumet-relay-client.plugins.perf.enable="true"

relay client configuration file is created as a config map named: *\<release name\>-alumet-relay-client-config*

## Influxdb

All metrics are written in influxdb if the plugins Influxdb is enabled (*alumet-relay-server.plugins.influxdb.enable="true"*).

The credentials to logon to the web page of influxdb are defined by a secret. The secret name is defined by the variable:

- influxdb2.adminUser.existingSecret

The user login is: *admin*

The password is get by decoding the *admin-password* key from the secret using the following command:

```text
kubectl  get secret \<secret name> -o jsonpath="{.data.admin-password}" | base64 -d
```

If the secret does not exist, the secret is automatically created and credentials generated randomly.

By default the http service is not actived, if needed, the variable *influxdb2.service.type* must be set with *LoadBalancer* value.
Refer to <https://github.com/influxdata/helm-charts/tree/master/charts/influxdb2> for more details about influxdb configuration.

## Deployment example

Below an exemple of ALUMET deployment on k8s cluster with 4 nodes. In our example, the influxdb persistence is not activated, if you want persistence , you need to set the variable *influxdb2.persistence.enabled* to *true* and you need to create the persistence volume before deployment.

Before executing the *helm install* command you need to add the helm repositories:

```text
helm repo add influxdata https://helm.influxdata.com/
helm repo add alumet https://alumet-dev.github.io/helm-charts/
```

And the command to create the secret to get access to the github registry if the docker images are privates:

```text
kubectl  -n <namesapce> create  secret docker-registry gh-registry-secret --docker-server=ghcr.io/alumet-dev --docker-username=<user> --docker-password=<github token>
```

```text
helm test-alumet alumet --namespace test --set influxdb2.persistence.enabled=false --set global.secret=gh-registry-secret
NAME: test-alumet
LAST DEPLOYED: Wed Jan 22 09:35:29 2025
NAMESPACE: test
STATUS: deployed
REVISION: 1
NOTES:
Installing alumet
Your installed version  0.1.0
Your instance name is:  test-alumet


    influxdb plugin is enabled, a secret to get access to influxdb database must be defined



            A secret test-alumet-influxdb2-auth was created
            To get influxdb admin user password, decode the admin-password key from your secret:
            kubectl  -n test get secret test-alumet-influxdb2-auth -o jsonpath="{.data.admin-password}" | base64 -d
            To get influxdb token, decode the admin-token key from your secret:
            kubectl  -n test get secret test-alumet-influxdb2-auth -o jsonpath="{.data.admin-token}" | base64 -d
```

List of pods and services running:

```text
local@master:$ kubectl -n test get pod
NAME                                               READY   STATUS                  RESTARTS   AGE
mongodb-6d6fc5d86f-pttb5                           1/1     Running                 0          19d
test-alumet-alumet-relay-client-6ssmd              1/1     Running                 0          56s
test-alumet-alumet-relay-client-h4ntl              1/1     Running                 0          56s
test-alumet-alumet-relay-client-hsgdl              1/1     Running                 0          56s
test-alumet-alumet-relay-client-ms2hd              1/1     Running                 0          56s
test-alumet-alumet-relay-client-zvvbg              1/1     Running                 0          56s
test-alumet-alumet-relay-server-54d548d487-9v62r   1/1     Running                 0          56s
test-alumet-influxdb2-0                            1/1     Running                 0          56s

local@master:$ kubectl -n test get svc
NAME                        TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)        AGE
test-alumet-alumet-relay-server   ClusterIP      10.102.121.155   <none>         50051/TCP      63s
test-alumet-influxdb2             LoadBalancer   10.104.55.25     192.168.1.48   80:30421/TCP   63s
```
