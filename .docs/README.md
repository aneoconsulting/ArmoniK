# ArmoniK Docs

Docs for ArmoniK

## Installation

> Be aware to be at the root of the repository

```bash
python -m venv .venv-doc
```

Then activate the virtual environment:

```bash
source .venv-doc/bin/activate
```

And install dependencies:

```bash
pip install -r .docs/requirements.txt
```

## Usage

To build the docs locally, run the following command:

```bash
sphinx-build -M html .docs build
```

Outputs can be found in `build/html/index.html`.
