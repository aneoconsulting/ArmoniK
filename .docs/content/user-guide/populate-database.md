# Populate database

This guide will explain you how you can populate your ArmoniK database with **fake data**.



```{note}


This guide is useful for the [Admin GUI](https://github.com/aneoconsulting/ArmoniK.Admin.GUI) or for testing purpose.

```

## Prerequisites

You need to have a running ArmoniK cluster. If you don't have one, please follow the [Getting Started](../getting-started/installation/local.md) guide.

## Functioning

In order to easily populate, we use [MongoDB scripts](https://www.mongodb.com/docs/mongodb-shell/write-scripts/) along the [@faker-js/faker](https://www.npmjs.com/package/@faker-js/faker) library.

This method allows use to write JavaScript scripts to populate database without having to write dump files manually and insert them with the `mongoimport` command.



```{note}


Data are generated randomly, so you can run the script multiple times to generate different data.

```

### Install dependencies

1. Go to `./tools/mongodb/scripts`.
2. Install dependencies:

    ```sh
    npm install
    ```

### Run scripts

1. Return to the root directory of the project.
2. Run the following command:

    ```sh
    ./tools/mongodb/<script-name>.sh
    ```



```{note}


You can also use these scripts directly from the mongodb directory.

```



```{warning}


If you can't run the script, you may need to give execution rights to the script:

```sh
chmod +x ./tools/mongodb/<script-name>.sh
```


```

### Available scripts

| Script name                           | Description                                                                         |
|---------------------------------------|-------------------------------------------------------------------------------------|
| `export-all`                          | Export all collections in the `.database` folder.                                   |
| `clean-all`                           | Clean all collections. **Be careful!**                                              |
| `generate-partitions`                 | Generate 100 partitions                                                             |
| `generate-sessions`                   | Generate 100 sessions                                                               |
| `generate-session-with-related-tasks` | Generate 1 session and 100 related tasks                                            |
| `generate-tasks`                      | Generate 100 tasks                                                                  |
| `generate-results`                    | Generate 100 results                                                                |
| `generate-real-world-run`             | Generate 1 partition, 1 session, 1 application and 1 000 tasks with related results |



```{note}


To generate applications, you must generate tasks.

```

## Going further

The section is only needed if you can't find your joy with current scripts.

We provide a strong base of utils scripts to write your own script.

First, you can check [current scripts](https://github.com/aneoconsulting/ArmoniK/tree/main/tools/mongodb) to see how it works.

Then, you can read the MongoDB documentation to learn how to write your own script.

Finally, we recommend you to use [execute-script.sh](https://github.com/aneoconsulting/ArmoniK/blob/main/tools/mongodb/execute-script.sh) to have the correct setup.

### Writing your own script

1. Create a file in the `mongodb` folder. Please name it with the following pattern: `<action>-<collection>.sh`.
2. Use the following command:

    ```sh
    # Get the directory of the script to create relative links
    DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
    # Description: <description with only a couple of words>
    "$DIR/utils/execute-script.sh" <script-name>
    ```

3. Create your JavaScript script in the `scripts` folder. Please name it with the following pattern: `<action>-<collection>.js`. (Same name as the file created in step 1)
4. Write your script. You can use the [@faker-js/faker](https://www.npmjs.com/package/@faker-js/faker) library to generate fake data.
5. _Voilà_! You're good to go!

Of course, you are free to write use other script and to combine them. But **each script must have a single purpose** (for maintenance purpose, e.g. create a user, create an application, create a task, ...).
