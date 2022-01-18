# Table of contents

1. [Introduction](#introduction)
2. [Allowed storage resources](#allowed-storage-resources)
3. [Storage deployment](#storage-deployment)
    1. [Onpremise storage](#onpremise-storage)

# Introduction

This project presents an example of source codes to create storage resources for ArmoniK.

# Allowed storage resources

To date, the storage resources allowed for each type of ArmoniK data are defined
in [allowed storage resources](../modules/needed-storage/storage_for_each_armonik_data.tf).

# Storage deployment

## Onpremise storage

The storage resources will be created as **Kubernetes services**. Therefore, you must already have a Kubernetes already
installed.

The source codes to create the needed storage resources for ArmoniK are defined
in [Onpremise storage resources](onpremise/README.md).