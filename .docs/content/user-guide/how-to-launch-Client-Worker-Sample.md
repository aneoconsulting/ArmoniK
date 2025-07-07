
# Testing a Sample via C# Extensions and ArmoniK Deployment


## Prerequisites

1. **Development Environment**
   Ensure you have a C# development environment set up with the .NET SDK installed.

2. **ArmoniK Access**
   The shared folder is : [infrastructure/quick-deploy/localhost/data](https://github.com/aneoconsulting/ArmoniK/tree/main/infrastructure/quick-deploy/localhost/data) accessible in the cloned repository after deployment

3. **C# Extensions**
   Verify that the required C# extensions are available and correctly tagged.

---

## Steps to Test a Sample

### Step 1: Point to the Correct Version of the C# Extensions

1. **Identify the Tag**
   - **If you have pipeline access**: Check the tag produced by your CI/CD pipeline
   - **If you don't have pipeline access**: 
     - Check the [releases page](https://github.com/aneoconsulting/ArmoniK.Extensions.Csharp/releases) for the latest stable version
     - Consult with your team lead or administrator for the recommended tag

2. **Update References**
   In your C# project, update the version so they point to the tag you identified.

### Step 2: Build the Worker

1. **Publish Command**
   In your project directory (e.g. `ArmoniK.Samples`), run:

   ```bash
   dotnet publish -c Release -f net8.0 
   ```

2. **Verify the ZIP**
   After the command finishes, confirm that the `packages` folder contains a ZIP file with your worker.

### Step 3: Copy the ZIP to the Shared Folder

1. **Locate the Shared Folder**
   Navigate to your ArmoniK deployment’s shared folder (commonly `infrastructure/quick-deploy/localhost/data`).

2. **Copy the ZIP**
   Copy the generated ZIP from `./packages` into this shared directory.

### Step 4: Deploy ArmoniK

- Deploy Armonik using 
```
make deploy
```

### Step 5: Get Control Plane IP and Run Tests

1. **Get Control Plane IP**
   Retrieve the control plane IP address
   

2. **Run the Test Script**
   Navigate back to your ArmoniK.Samples directory and execute the test:
   ```bash
   ./unified_api.sh -e http://<CONTROL_PLANE_IP>:5001 -no-copy-dll -r -- addition --nbTask 20
   ```
   
   Replace `<CONTROL_PLANE_IP>` with the IP obtained in the previous step.
3. **Monitor Results**
   Observe the output using Seq to verify that:
   * Tasks are submitted successfully
   * The worker processes tasks as expected
   * Results are returned correctly


## Troubleshooting

* **Deployment Failures**
  Check the ArmoniK deployment logs to pinpoint any issues in bringing up services.

* **Worker Errors**
  If the worker doesn’t behave as expected, inspect its runtime logs and ensure all dependencies were included in the ZIP.


## Example Complete Workflow

Here's a complete example of the workflow:

```bash
# 1. Clean previous data
rm ArmoniK/infrastructure/quick-deploy/localhost/data/*.zip

# 2. Build worker (from ArmoniK.Samples directory)
cd ArmoniK.Samples/Samples/UnifiedAPI/
dotnet publish -c Release -f net6.0

# 3. Copy worker to ArmoniK
sudo cp ArmoniK.Samples.Unified.Worker-v1.0.0-700.zip ArmoniK/infrastructure/quick-deploy/localhost/data/

# 4. Deploy ArmoniK
cd ArmoniK/infrastructure/quick-deploy/localhost/
make deploy

# 5. Get control plane IP and test

cd ArmoniK.Samples/tools/tests
./unified_api.sh -e http://$CONTROL_PLANE_IP:5001 -no-copy-dll -r -- addition --nbTask 20
```
## Conclusion

By following these steps, you’ll be able to build and test a sample worker using C# extensions on an ArmoniK deployment. 
