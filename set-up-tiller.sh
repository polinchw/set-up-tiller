#!/usr/bin/env bash

kubectl create -f create-tiller-user.yaml
kubectl create -f role-binding-tiller-to-cluster-admin.yaml
kubectl create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:default
kubectl create clusterrolebinding tiller-default-cluster-admin-role-binding --clusterrole=cluster-admin --serviceaccount=default:default
