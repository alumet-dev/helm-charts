# Testing the Helm Chart Locally

## Prerequisites

Do this first:

1. [Build a container image for the Alumet agent](https://github.com/alumet-dev/packaging/).
2. Install [minikube](https://minikube.sigs.k8s.io/docs/) (to get a local K8S cluster) and [helm](https://helm.sh/docs/intro/quickstart/).
3. Start minikube (run `minikube start`)

## Load the Image in Minikube

The image should now be in your local registry, that is, you should see it in `podman image ls`.
However, it is not accessible to minikube yet. To make it accesible, do the following.

```sh
# TAG is an environment variable that has been set during the build of the image.
podman image save -o alumet-image.tar $TAG

minikube image load alumet-image.tar
```

Check that the image is available in minikube:

```sh
❯❯❯ minikube image ls
ghcr.io/alumet-dev/alumet-agent:0.9.1-snapshot-1-ubuntu_24.04
```

## Deploy with Helm

First, check that the `appVersion` of the `alumet`, `alumet-relay-client` and `alumet-relay-server` match the version of your package.
In the following example, we set:

```yaml
appVersion: "0.9.1-snapshot-1"
```

We use the K8S namespace `alumet-in-namespace` and the Helm release name `alumet-test`.

```sh
helm install alumet-test ./charts/alumet -n alumet-in-namespace --create-namespace
```

Check that the pods have been created:

```sh
❯❯❯ kubectl get pods -n alumet-in-namespace
NAME                                               READY   STATUS            RESTARTS   AGE
alumet-test-alumet-relay-client-rt8jp              0/1     PodInitializing   0          12s
alumet-test-alumet-relay-server-5548fff458-z489g   1/1     Running           0          12s
alumet-test-influxdb2-0                            1/1     Running           0          12s
```

## Troubleshooting: Database Credentials and PVC

When uninstalling and reinstalling the helm chart, you may run into issues with the database connection.

```txt
[2025-09-25T14:06:13Z INFO  alumet::agent::builder] Starting the plugins...
[2025-09-25T14:06:13Z INFO  plugin_influxdb] Testing connection to InfluxDB...
[2025-09-25T14:06:13Z ERROR plugin_influxdb::influxdb2] InfluxDB2 client error: HTTP status client error (401 Unauthorized) for url (http://alumet-test-influxdb2/api/v2/write?org=influxdata&bucket=default&precision=ns)
    Server response: {"code":"unauthorized","message":"unauthorized access"}
Error: startup failure

Caused by:
    0: plugin failed to start: influxdb v0.1.0
    1: Cannot write to InfluxDB host http://alumet-test-influxdb2:80 in org influxdata and bucket default. Please check your configuration.
    2: HT
```

To solve this, you can try to delete the database PVC, which is not removed by helm uninstall, before reinstalling the chart.
A proper uninstallation therefore looks like:

```sh
helm uninstall alumet-test -n alumet-in-namespace
kubectl delete pvc alumet-test-influxdb2 -n alumet-in-namespace
```

Note that this will delete the content of the database, because the persistent volume associated to InfluxDB uses the "Delete" reclaim policy.
