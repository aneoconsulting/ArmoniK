# Differentiate environments

It's important to be able to differentiate environments, to be able to rapidly identify which environment you are working on. This is especially important when you are working on multiple environments at the same time to avoid confusion and mistakes.

In order to achieve this differentiation, we serve a file called `environment.json` that you can access at `/static/environment.json`.

::alert{type="info"}
In the [Admin GUI](https://github.com/aneoconsulting/ArmoniK.Admin.GUI), we use this file to display the environment name and version in the top middle.
::

## Content of the `environment.json` file

This file contains the following keys:

```json
{
  "name": "<string>",
  "description": "<string>",
  "color": "<string>",
  "version": "<string>"
}
```

::alert{type="info"}
You can use any valide CSS color in the `color` key. [Read more about CSS colors](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value).
::

## Personalize the `environment.json` file

You can personalize the content of the file but you need to keep the `name`, `description`, `color` and `version` keys. If you change the name of the keys, the [Admin GUI](https://github.com/aneoconsulting/ArmoniK.Admin.GUI) will not be able to read the file.

In your `parameters.tfvars` (in `armonik` layer or in the `all-in-one`), you can update the `environment.description` key to serve different content for each environment.

```hcl
environment_description = {
  name  = "aws-dev"
  version = "0.1.0"
  description = "AWS environment"
  color = "#80ff80"
}
```
