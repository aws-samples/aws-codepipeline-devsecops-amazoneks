#!/bin/sh
##################################################################################################################
#Script to patch aws_auth configmap in EKS cluster with EKSCodebuild Role ARN, temporary workaround until support# 
#for adding additional IAM Users/Roles in aws_auth configmap via Cloudformation is supported.                    #
#Reference: Known Issue - https://github.com/aws/containers-roadmap/issues/185 in container roadmap of EKS.      #
#Also, this script should be executed by the same role of EKS cluster creator, so probably the EKS cluster       #
#creator can execute this script                                                                                 #
##################################################################################################################

##Validate rolearn has been passed as an argument##
if [ ! $# -eq 1 ]
  then
    echo "You must provide exactly one argument: Role ARN of EKS CodeBuild Kubectl to the script"
    echo "Usage: bash $0 <rolearn-eks-codebuild-kubectl>"
    exit 1
fi


##Patch configmap aws_auth with arn of the required IAM role to be added##
EKS_CODEBUILD_KUBECTL_ROLE_ARN=$1
ROLE="    - rolearn: $EKS_CODEBUILD_KUBECTL_ROLE_ARN\n      username: build\n      groups:\n        - system:masters"

kubectl get -n kube-system configmap/aws-auth -o yaml | awk "/mapRoles: \|/{print;print \"$ROLE\";next}1" > /tmp/aws-auth-patch.yml

kubectl patch configmap/aws-auth -n kube-system --patch "$(cat /tmp/aws-auth-patch.yml)"
