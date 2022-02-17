# Table of contents

- [Introduction](#introduction)
- [Quick install of ArmoniK](#quick-install-of-armonik)
    - [On dev/test local machine](#on-devtest-local-machine)
    - [On Amazon Web Services (AWS)](#on-amazon-web-services-aws)

# Introduction

In this project, we present the different steps to deploy ArmoniK scheduler in different environments.

# Quick install of ArmoniK

Your can deploy ArmoniK scheduler:

1. on your local machine or a VM, Linux machine or Windows machine on WSL 2, on a single-node of Kubernetes. This is
   useful for development and testing environment only!
2. on an onpremise cluster composed of a master node and several worker nodes of Kubernetes.
3. on Cloud as AWS, Azure or GCP.

ArmoniK deployment needs installation of Kubernetes, monitoring tools and different storage (Table, cache storage and
queue).

## On dev/test local machine

You can follow instructions described in [Quick deploy ArmoniK on local machine](quick-deploy/localhost/README.md) to
install ArmoniK and its infrastructure requirements upon your local machine.

## On Amazon Web Services (AWS)

You can follow instructions described in [Quick deploy ArmoniK on AWS](quick-deploy/aws/README.md) to install ArmoniK
and its infrastructure requirements on AWS.