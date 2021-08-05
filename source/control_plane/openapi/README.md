# OpenAPI usage
We used OpenAPI and OpenAPITools to define and generate SDK for the HTTP interface of the HTC grid.
## Usage
Generate all artifacts
### Generate the python client side SDK
From this folder:
```shell
make python-package
```
### Generate the C# (core .NET 5.0) client side package
From this folder:
```shell
make csharp-api-package
```
### Generate the C# (core .NET 5.0) server side package 
From this folder:
```shell
make csharp-server-package
```