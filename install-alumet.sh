#!/bin/bash
#
# This script install the helm chart  alumet-relay-server
set -x

basedir=$(dirname $0)
. $basedir/helm-include.sh

# global variables
chartName="alumet"
# alumet instance name installed on the platform
instanceName="alumet-manu"

# check input parameters
parametersCheck $*
paramsRet=$?
if [ $paramsRet != 0 ]
then
   exit $paramsRet
fi

   echo "Start alumet deployment on:"
   echo "namespace: $projectNs"

   helm install ${instanceName} ./${chartName} \
        --kubeconfig ${kubeconfigfile} \
        --namespace ${projectNs}  \
        --set global.service.port=50054 \
        --set alumet-relay-client.env.RUST_LOG="trace" \
        --set alumet-relay-client.cmd.Arg1="--max-update-interval=1000ms" \
        --set alumet-relay-server.env.RUST_LOG="trace" \
        --set alumet-relay-server.influxdb.org="seed" \
        --set influxdb2.enabled=true \
        --set alumet-relay-server.enabled=true \
        --set alumet-relay-client.enabled=true \
        --set global.plugin.relay.collector_uri="http://${instanceName}-alumet-relay-server" \
#--set alumet-relay-server.cmd.Arg1=" "       

