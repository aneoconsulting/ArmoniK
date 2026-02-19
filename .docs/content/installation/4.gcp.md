# ArmoniK on GCP
## GCP All-in-One Deployment Guide

This guide will help you deploy your ArmoniK project on Google Cloud Platform (GCP).

### Step 1: Preparation

#### 1. Install Google CLI

When receiving your credentials (email and password).
Download and install the Google CLI by following the instructions on the [following link](https://cloud.google.com/sdk/docs/install)

#### 2. Initial Setup

After installation, you can authenticate using your credentials (email and password) and select the project you want to deploy the resources on.
Follow [following tutorial](https://cloud.google.com/docs/authentication/provide-credentials-adc#how-to) to authenticate using the CLI.

You can authenticate using the following command:

```bash
gcloud auth login
```

then :

```bash
gcloud auth application-default login
```

To configure the project, if you don't know the project ID, you can list all the projects using the following command:

```bash
gcloud projects list
```

To configure the project, use the following command:

```bash
gcloud config set project <PROJECT_ID>
```

Once authenticated, you should see a confirmation page with the message:

*You are now authenticated with the gcloud CLI!*

### Step 2: Deployment

Navigate to `infrastructure/quick-deploy/gcp` folder and follow the steps below to deploy your resources.

#### 1. Bootstrap

Generate a prefix key ready in the GCP environment to deploy your resources.

```bash
make bootstrap-deploy PREFIX=<PREFIX_KEY>
```

#### 2. Deploy

To deploy your resources, execute:

```bash
make deploy PREFIX=<PREFIX_KEY>
```

### Step 3: Cleanup

#### 1. Destroy the deployment

- Warning: After using the deployment, you have to make sure to destroy it to avoid any additional costs. The next command will destroy all the resources created during the deployment and the project will be deleted. It will only conserve the prefix key for future use. The terraform state will be saved in the GCP environment.

To destroy the deployment, use the following command:

```bash
make destroy PREFIX=<PREFIX_KEY>
```

#### 2. Destroy the GCP Prefix Key - In case you don't need to deploy on GCP anymore

:warning: In case you ALREADY HAVE DESTROYED and you don't need to deploy on GCP anymore :warning:

It's an optional step if you are not willing to use the prefix key in the future. However, please note that if you delete the prefix key and the terraform state from the GCP environment, you will not be able to reproduce this exact deployment on GCP. It is not recommended to perform this step unless you are certain that you will not need the prefix key again, such as when you are leaving the project.

To clean up the GCP prefix key, use the following command:

```bash
make bootstrap-destroy PREFIX=<PREFIX_KEY>
```

### Step 4: Add a Sample Partition

Just as with an **AWS** or **localhost** deployment, you can add a sample partition to test a deployment on the **GCP** environment. You need to build the images and redeploy the services after adding the sample partition in the parameters.tfvars file.


## GCP Troubleshooting Guide

This guide will help you troubleshoot common issues when deploying your Armonik project on Google Cloud Platform (GCP).

### 1. Deployment Error with New Partition

If you encounter an error during deployment after adding a new partition with the value `replicas > 0`, follow these steps:
1. Set the replicas to `0`.
2. Redeploy the resources.
3. If the deployment succeeds, update the replicas to the desired value.
4. Redeploy the resources again.

---

### 2. Pub/Sub Client-Side Issue

If you encounter an issue with the Pub/Sub client and see the error message: `FAILED_PRECONDITION: Requested entity was not found.`, follow the steps below to resolve the issue.

#### Error Message

When running the application, you may encounter the following error:

```bash
grpc._channel._InactiveRpcError: <_InactiveRpcError of RPC that terminated with:
    status = StatusCode.FAILED_PRECONDITION
    details = "Cloud Pub/Sub did not have the necessary permissions configured to support this operation.
    Please verify that the service account [SERVICE_ACCOUNT] was granted the Cloud KMS CryptoKey Encrypter/Decrypter role
    for the project containing the CryptoKey resource [PROJECT_ID]/locations/[LOCATION]/keyRings/[KEY_RING]/cryptoKeys/[CRYPTO_KEY]."
    debug_error_string = "UNKNOWN:Error received from peer {created_time:"[TIMESTAMP]",
    grpc_status:9,
    grpc_message:"Cloud Pub/Sub did not have the necessary permissions configured to support this operation.
    Please verify that the service account [SERVICE_ACCOUNT] was granted the Cloud KMS CryptoKey Encrypter/Decrypter role
    for the project containing the CryptoKey resource [PROJECT_ID]/locations/[LOCATION]/keyRings/[KEY_RING]/cryptoKeys/[CRYPTO_KEY]."}
```

#### Problem Description

This error occurs because Cloud Pub/Sub requires access to the specified CMEK to encrypt or decrypt messages. The service account used by Pub/Sub does not have the **Cloud KMS CryptoKey Encrypter/Decrypter** role for the specified CryptoKey.

#### Key Components in the Error

- **Service Account**: `service-[NUMERIC_ID]@gcp-sa-pubsub.iam.gserviceaccount.com`
- **CryptoKey Resource**:
  - Project: `[PROJECT_ID]`
  - Location: `[LOCATION]` (e.g., `europe-west1`)
  - Key Ring: `[KEY_RING]`
  - CryptoKey: `[CRYPTO_KEY]`
- **Missing Role**: `roles/cloudkms.cryptoKeyEncrypterDecrypter`

Without this role, Cloud Pub/Sub cannot perform encryption or decryption using the CMEK.

#### Solution

To resolve the issue, grant the **Cloud KMS CryptoKey Encrypter/Decrypter** role to the Pub/Sub service account for the specified CryptoKey.

##### Step 1: Identify the Service Account

The service account mentioned in the error typically has the format: `service-[NUMERIC_ID]@gcp-sa-pubsub.iam.gserviceaccount.com`. This service account is automatically created by Google Cloud to manage Pub/Sub operations.

##### Step 2: Grant the Necessary Role

You can grant the **Cloud KMS CryptoKey Encrypter/Decrypter** role to the service account using the Google Cloud Console or the gcloud command-line tool.

###### Using the Google Cloud Console

1. Open the [Google Cloud Console](https://console.cloud.google.com).
2. Navigate to **Key Management > CryptoKeys**.
3. Locate the CryptoKey resource:
    - **Project**: `[PROJECT_ID]`
    - **Location**: `[LOCATION]` (e.g., `europe-west1`)
    - **Key Ring**: `[KEY_RING]`
    - **CryptoKey**: `[CRYPTO_KEY]`
4. Click on the CryptoKey and go to the **Permissions** tab.
5. Add the service account as a principal:
    - **Principal**: `service-[NUMERIC_ID]@gcp-sa-pubsub.iam.gserviceaccount.com`
    - **Role**: `Cloud KMS CryptoKey Encrypter/Decrypter`
6. Save the changes.

---

After granting the role, Cloud Pub/Sub should be able to access the specified CMEK for encryption and decryption operations. Retry the operation that triggered the error. Ensure that the deployment is successful and verify that the Pub/Sub client can now access the CMEK without any issues.
