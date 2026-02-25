# Helm Charts for Alumet

## Summary

[Alumet](https://github.com/alumet-dev/alumet) is a modular measurement framework and monitoring tool.

This repository contains Helm charts for deploying the standard Alumet agent on K8S clusters.
The agent is deployed alongside InfluxDB.

The chart contains the following subcharts:

- `influxdb`: deploys InfluxDB to store the measurements (one pod and one service)
- `alumet-relay-client`: deploys a monitoring agent on each node (one pod per node with a daemonSet)
- `alumet-relay-server`: deploys one server that gathers the measurements produced by the clients (one pod and one load balancer service)

Each subcharts has its own `values.yaml` file.
On top of that, there is a main `values.yaml`, where we overwrite the default values of the subcharts.

## Deployment Example

First, add the required repositories to helm:

```sh
helm repo add influxdata https://helm.influxdata.com/
helm repo add alumet https://alumet-dev.github.io/helm-charts/
```

Then, install the chart.
In this example, we use the `test` namespace and the `test-alumet` release.

```txt
~ ❯❯❯ helm install test-alumet alumet --namespace test

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

Check that the pods have been deployed:

```text
local@master:$ kubectl -n test get pods
NAME                                               READY   STATUS                  RESTARTS   AGE
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

## Local Testing

To use the helm chart directly from its source, see [Testing the Helm Chart Locally](local.md).

## Using Private Container Images

<!-- markdownlint-disable MD029 -->

To use private images published to the GitHub Container Registry (GHCR), you need to:

1. Create a token that can access your private registry.
2. Create a secret `kubectl`:

```sh
kubectl  -n <namesapce> create  secret docker-registry gh-registry-secret --docker-server=ghcr.io/alumet-dev --docker-username=<user> --docker-password=<github token>
```

3. When installing the chart, set the `global.secret` variable by appending the following argument:

```sh
--set global.secret=gh-registry-secret
```

## Enabling/Disabling InfluxDB Persistence

InfluxDB persistence is controlled by the influxdb chart.
By default, persistence is **enabled**.
To disable it, use the following argument with `helm install`:

```sh
--set influxdb2.persistence.enabled=false
```

## Configuration Details

## Global Variables

We defined also 2 global variables:

- `global.image.registry`: All alumet docker images must be located on the same docker registry. This variable is used to set the URL path of the docker registry, the default value is: `ghrc.io/alumet-dev`
- `global.secret`: A kubernetes secret can de defined to be able to connect to the docker registry for downloading the images.
The secret's name is defined by this variable, it is not set by default.

### Data Backends

Two backends are available:

- InfluxDb (preferred and default option)
- Prometheus (the pod is annotated with `prometheus.io/scrape: 'true'` so that it can be scrapped automatically by the exporter)

## ALUMET relay server

It receives the metrics by all ALUMET relay client and writes the metrics in the output plugin configured (CSV file, influxdb, mongodb, as a prometheus exporter or opentelemetry).
The default configuration is correctly set-up to write in influxdb. The default value of helm variables related to alumet plugins are:

- alumet-relay-server.plugins.influxdb.enable="true"
- alumet-relay-server.plugins.csv.enable="false"
- alumet-relay-server.plugins.mongodb.enable="false"
- alumet-relay-server.plugins.opentelemetry.enable="false"
- alumet-relay-server.plugins.prometheusExporter.enable="false"

 ALUMET relay server toml configuration file is created as a config map named:
 \<release name\>-alumet-relay-server-config

### influxdb setting

The influxdb parameters listed below can be overwritten, the default configuration is:

- enable: true
- host: <set automatically during deployment; can be set manually if influxdb is not deployed inside this chart>
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

### deployment with tolerations

If your cluster's nodes have taints, you can set tolerations to allow the pod to be deployed on the tainted nodes.

To set a toleration on deployment step, you have to set the helm variable *alumet-relay-server.tolerations*, below an example of toleration.

```text
--set alumet-relay-server.tolerations[0].key=<key name> \
--set alumet-relay-server.tolerations[0].operator=Exists \
--set alumet-relay-server.tolerations[0].effect=NoSchedule \
```

You can add several tolerations: the variable is a list of objects.

Below an example to set a toleration in yaml format:

```yaml
tolerations:
  - key: <key name>
    operator: Exists
    effect: NoSchedule
```

### deployment config map relay server

By default the deployment creates automatically a config map (named *\<release name\>-alumet-relay-server-config*) that contain the toml configuration file for ALUMET relay server. This is a basic configuration that you can modify using the helm variables but the modifications that you can do are limited.
If you want a specific configuration, you can create your own config map. In that case you need to specify the name of your config map in the helm variable:

- alumet-relay-server.configMap.name="myConfigMap"

To create the config map:

```text
kubectl create cm <config map name> --from-file=config=alumet-agent-client.toml
```

## ALUMET relay client

It collects the metrics of the kubernetes nodes where it is running and sends them to ALUMET  relay server.
The default configuration is correctly set-up to allow communication between ALUMET client and ALUMET server. You can activate or deactivate a plugin using a helm variables, the default configuration is:

- alumet-relay-client.plugins.csv.enable="false"
- alumet-relay-client.plugins.aggregation.enable="false"
- alumet-relay-client.plugins.energyAttribution.enable="false"
- alumet-relay-client.plugins.energyEstimationTdpPlugin.enable="false"
- alumet-relay-client.plugins.jetson.enable="false"
- alumet-relay-client.plugins.k8s.enable="true"
- alumet-relay-client.plugins.nvml.enable="false"
- alumet-relay-client.plugins.oar.enable="false"
- alumet-relay-client.plugins.perf.enable="false"
- alumet-relay-client.plugins.procfs.enable="false"
- alumet-relay-client.plugins.rapl.enable="false"
- alumet-relay-client.plugins.relay_client.enable="true"
- alumet-relay-client.plugins.socket_control.enable="false"
- alumet-relay-client.plugins.opentelemetry.enable="false"
- alumet-relay-client.plugins.prometheusExporter.enable="false"

relay client configuration file is created as a config map named: *\<release name\>-alumet-relay-client-config*

As for Alumet relay server, if your cluster's nodes have taints, you can set tolerations to deploy Alumet relay client on node with a specific taint.
To set a toleration at deployment step, you have to set the helm variable *alumet-relay-client.tolerations*.
Refer to [deployment with tolerations](#deployment-with-tolerations) for more details.

### deployment config map relay client

By default the deployment creates automatically a config map (named *\<release name\>-alumet-relay-client-config*) that contain the toml configuration file for ALUMET relay server. This is a basic configuration that you can modify using the helm variables but the modifications that you can do are limited.
If you want a specific configuration, you can create your own config map. In that case you need to specify the name of your config map in the helm variable:

- alumet-relay-client.configMap.name="myConfigMap"

To create the config map:

```text
kubectl create cm <config map name> --from-file=config=alumet-agent-client.toml
```

## InfluxDB

If `influxdb` is deployed and the `influxdb` Alumet plugin is enabled (by setting `alumet-relay-server.plugins.influxdb.enable="true"`), all the measurements are written to InfluxDB by the relay server.

Here is a quick summary of the most important InfluxDB options.
For more details, refer to [InfluxDB's chart documentation](https://github.com/influxdata/helm-charts/tree/master/charts/influxdb2).

### Database Credentials

The credentials are defined by a secret, whose name name is defined by the variable `influxdb2.adminUser.existingSecret`.

The user login is `admin`.

To get the password, decode the `admin-password` entry from the secret using the following command:

```sh
kubectl  get secret <secret name> -o jsonpath="{.data.admin-password}" | base64 -d
```

If the secret does not exist at the time of the deployment, it is automatically created and credentials are generated randomly.

### HTTP Service

By default the http service is not activated, if needed, the variable `influxdb2.service.type` must be set to `LoadBalancer`.
