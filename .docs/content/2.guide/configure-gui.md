# Personalize Admin GUI

You can personalize the interface and tables of the GUI by serving a static JSON configuration file. For this, head to the `parameters.tfvars` file, and paste your JSON configuration here:

```hcl
static = {
  gui_configuration = { # GUI config here... } 
}
```

You can download your configuration via the `Settings` page of the GUI, in the **Export your data** section. Then, you just have to copy and paste the JSON provided to you by the application. The configuration will only work for the `gui_configuration` key.

Users can still modify and save their local applications. It will not change the server configuration.
