# GCP all in one deployment Guide

This guide will help you deploy your Armonik project on Google Cloud Platform (GCP).



## Step  1: Preparation

### 1. Install Google CLI

When receiving your credentials (email and password).
Download and install the Google CLI by following the instructions on the [following link](https://cloud.google.com/sdk/docs/install?hl=fr#deb)


### 2. Initial Setup


After installation, authenticate using the provided credentials (email and password) and select the project **armonik gcp 13469**
Follow [following tutorial](https://cloud.google.com/docs/authentication/provide-credentials-adc?hl=fr#how-to) to authenticate into the CLI.

You can authenticate using the following command:

```bash
gcloud auth login
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


## Step 2: Deployment

### 1. Boostrap

Navigate to the **gcp folder** (infrastructure/quick-deploy/gcp) and generate a prefix key by running the following command:

```bash
make bootstrap-deploy PREFIX=<PREFIX_KEY>
``` 

### 2. Deploy

To deploy your resources, execute:
```
make deploy PREFIX=<PREFIX_KEY>
```

## Step 3: Cleanup

### 1. Destroy the deployment

#### After using the deployment, you have to make sure to destroy it to avoid any additional costs. ####

To destroy the deployment, use the following command:

```bash
make destroy PREFIX=<PREFIX_KEY>
```

### 2. Destroy the GCP Prefix Key

To clean up the GCP prefix key, use the following command:

```bash
make bootstrap-destroy PREFIX=<PREFIX_KEY>
```


## Step 4: Add a Sample Partition

Just like with an **AWS** or **localhost** deployment, you can add a sample partition to test deployment on the **GCP** environment.


## Troubleshooting

### 1. Deployment Error with New Partition
In case of an error during deployment after adding a new partition with the value replicas > 0, you can put the replicas to 0 and redeploy the resources.
If the deployment succeeds, you can then update the replicas to the desired value and redeploy the resources.

---
### 2. Pub/Sub Issue client side
If you encounter an issue with the Pub/Sub client, with the following error message: `FAILED_PRECONDITION: Requested entity was not found.`, you can follow the steps in the [following link](https://cloud.google.com/pubsub/docs/customer-managed-encryption-keys#troubleshooting) to resolve the issue.

---
#### Error Message 

When running the application, you may encounter the following error:
grpc._channel._InactiveRpcError: <_InactiveRpcError of RPC that terminated with: status = StatusCode.FAILED_PRECONDITION details = "Cloud Pub/Sub did not have the necessary permissions configured to support this operation. Please verify that the service account [SERVICE_ACCOUNT] was granted the Cloud KMS CryptoKey Encrypter/Decrypter role for the project containing the CryptoKey resource [PROJECT_ID]/locations/[LOCATION]/keyRings/[KEY_RING]/cryptoKeys/[CRYPTO_KEY]." debug_error_string = "UNKNOWN:Error received from peer {created_time:"[TIMESTAMP]", grpc_status:9, grpc_message:"Cloud Pub/Sub did not have the necessary permissions configured to support this operation. Please verify that the service account [SERVICE_ACCOUNT] was granted the Cloud KMS CryptoKey Encrypter/Decrypter role for the project containing the CryptoKey resource [PROJECT_ID]/locations/[LOCATION]/keyRings/[KEY_RING]/cryptoKeys/[CRYPTO_KEY]."}"


---

#### Problem Description

This error occurs because Cloud Pub/Sub requires access to the specified CMEK to encrypt or decrypt messages. The service account used by Pub/Sub does not have the **Cloud KMS CryptoKey Encrypter/Decrypter** role for the specified CryptoKey.

#### Key Components in the Error:
- **Service Account**: `service-[NUMERIC_ID]@gcp-sa-pubsub.iam.gserviceaccount.com`
- **CryptoKey Resource**: 
  - Project: `[PROJECT_ID]`
  - Location: `[LOCATION]` (e.g., `europe-west1`)
  - Key Ring: `[KEY_RING]`
  - CryptoKey: `[CRYPTO_KEY]`
- **Missing Role**: `roles/cloudkms.cryptoKeyEncrypterDecrypter`

Without this role, Cloud Pub/Sub cannot perform encryption or decryption using the CMEK.

---

## Solution

To resolve the issue, grant the **Cloud KMS CryptoKey Encrypter/Decrypter** role to the Pub/Sub service account for the specified CryptoKey.

### Step 1: Identify the Service Account
The service account mentioned in the error typically has the format: service-[NUMERIC_ID]@gcp-sa-pubsub.iam.gserviceaccount.com

This service account is automatically created by Google Cloud to manage Pub/Sub operations.
---
### Step 2: Grant the Necessary Role

#### ** Using the Google Cloud Console**
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
   - **Role**: `Cloud KMS CryptoKey Encrypter/Decrypter`.
6. Save the changes.

---
After granting the role, Cloud Pub/Sub should be able to access the specified CMEK for encryption and decryption operations. You can now retry the operation that triggered the error. You should deploy the resources again to ensure that the changes take effect.
When the deployment is successful, you can verify that the Pub/Sub client can now access the CMEK without any issues.



