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
~ ❯❯❯ minikube image ls
ghcr.io/alumet-dev/alumet-agent:0.9.1-snapshot-1-ubuntu_24.04
```

## Deploy with Helm

As an example, we use the K8S namespace `alumet-in-namespace` and the Helm release name `alumet-test`.

```sh
helm install alumet-test ./charts/alumet -n alumet-in-namespace --create-namespace
```

Check that the pods have been created:

```sh
~/D/T/A/a/helm-charts ❯❯❯ kubectl get pods -n alumet-in-namespace
NAME                                               READY   STATUS            RESTARTS   AGE
alumet-test-alumet-relay-client-rt8jp              0/1     PodInitializing   0          12s
alumet-test-alumet-relay-server-5548fff458-z489g   1/1     Running           0          12s
alumet-test-influxdb2-0                            1/1     Running           0          12s
```
