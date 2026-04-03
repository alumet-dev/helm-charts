# Testing the Helm Chart Locally

## Test and lint

### Requirements

These tools must be installed before following the test and lint steps:

- [helm-unittest](https://github.com/helm-unittest/helm-unittest/blob/main/README.md#install)
- [helm-chart-testing](https://github.com/helm/chart-testing/blob/main/README.md#installation)
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start#installation)

### Lint

You can either use `helm lint` on the chart you want to check, or use ct (chart-testing)
to perform advanced lint of the desired chart. If you want to lint the three charts from this
repo, run:

```bash
ct lint --config ct.yaml --charts charts/alumet \
  --charts charts/alumet/charts/alumet-relay-client \
  --charts charts/alumet/charts/alumet-relay-server
```

### Test

There are two types of tests that are available for these charts.
Static one that uses `helm-unittest` and dynamic one that uses `chart-testing`.

#### Helm unittest

To run the existing tests, simply run:

```bash
cd charts/alumet
helm unittest .
```

If you want to add more tests, please refer to the
[documentation](https://github.com/helm-unittest/helm-unittest/blob/main/DOCUMENT.md) from unittest.

#### Helm chart-testing

In order to be able to run the tests with chart-testing, you first need to deploy
a new k8s cluster using `kind`, to do so, run:

```bash
kind create cluster --config .github/kind/config.yaml
find .github/kind/ -type f -not -name "config.yaml" -exec kubectl apply -f {} \; 
```

If you need a more advanced configuration for your cluster, check [the documentation from kind](https://kind.sigs.k8s.io/docs/user/configuration/).

You should now be able to run the tests with:

```bash
ct install
```

The tests are defined with two things:

- the values files located in [the ci](charts/alumet/ci/) directory of alumet chart
- the [test charts](https://helm.sh/docs/topics/chart_tests/) that are defined in
  [the test](charts/alumet/charts/alumet-relay-server/templates/tests/) directory of alumet(relay-server)

⚠️ Don't forget to delete your kind cluster once you finished your test session.

## Deploy

### Prerequisites

Do this first:

1. [Build a container image for the Alumet agent](https://github.com/alumet-dev/packaging/).
2. Install [minikube](https://minikube.sigs.k8s.io/docs/) (to get a local K8S cluster) and [helm](https://helm.sh/docs/intro/quickstart/).
3. Start minikube (run `minikube start`)

### Load the Image in Minikube

The image should now be in your local registry, that is, you should see it in `podman image ls`.
However, it is not accessible to minikube yet. To make it accessible, do the following.

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

### Deploy with Helm

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

### Troubleshooting: Database Credentials and PVC

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
