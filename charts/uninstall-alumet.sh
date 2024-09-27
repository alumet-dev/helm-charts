#!/bin/bash
#
# This script install the helm chart  alumet-relay-server
#set -x

basedir=$(dirname $0)
. $basedir/helm-include.sh

# global variables
chartName="alumet"
# alumet instance name installed on the platform
instanceName="demo"

# check input parameters
parametersCheck $*
paramsRet=$?
if [ $paramsRet != 0 ]
then
   exit $paramsRet
fi

   echo "Start alumet deployment on:"
   echo "namespace: $projectNs"

   helm uninstall ${instanceName} \
        --kubeconfig ${kubeconfigfile} \
        --namespace ${projectNs}  