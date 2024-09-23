#!/bin/bash
# Project: SEED
# This is the include heml script used for deploying helm application

# Parameters check function
parametersCheck()
{
if [ $# != 1 ]
   then
      echo "Parameters required :"
      echo "- platform id: [otpaasmanu|ovh]"
      exit 1
   fi

   # read parameters
   platformId=$1

   case $platformId in
   otpaasmanu)
      # set the namespace
      projectNs=manu-test
      
      # kubernetes platform
      kubeconfigfile=$HOME/.kube/config
      ;;

   ovh)
      # set the namespace
      projectNs=manu-test
      
      # kubernetes platform
      kubeconfigfile=$HOME/.kube/kubeconfig-ovh-2.yml
      ;;

   *)
      # unknown platform
      echo "PlatformId '$platformId' unknown (valid plateformId : [otpaasmanu|ovh])"
      exit 2
      ;;

   esac

    echo "namespace: $projectNs"

return 0
} 
