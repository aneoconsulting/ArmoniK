# Table of contents

1. [Install WSL 2](#install-wsl-2)
2. [Enable SystemD on WSL with Genie](#enable-systemd-on-wsl-with-genie)

# Install WSL 2

The following steps to install WSL are listed below and can be used to install Linux on any version of Windows 10.

## 1. Enable Windows Subsystem for Linux

You must first enable "Windows Subsystem for Linux" optional feature before installing any Linux distributions on
Windows. Open **PowerShell as Administrator** and run:

```bash
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
```

## 2. Enable virtual machine feature

Before installing WSL 2, you must enable the Virtual Machine Platform optional feature. Your machine will require
virtualization capabilities to use this feature.

Open **PowerShell as Administrator** and run:

```bash
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

**Restart your machine** to complete the WSL install and update to WSL 2.

## 3. Download the Linux kernel update package

1. Download the latest package: WSL2 Linux kernel update package for x64 machines
2. Run the update package downloaded in the previous step. (**Double-click** to run - you will be prompted for elevated
   permissions, select `yes` to approve this installation.)

Once the installation is complete, move on to the next step - setting WSL 2 as your default version when installing new
Linux distributions.

## 4. Set WSL 2 as your default version

**Open PowerShell** and run this command to set WSL 2 as the default version when installing a new Linux distribution:

```bash
wsl --set-default-version 2
```

## 5. Install your Linux distribution of choice

1. Open the Microsoft Store and select your favorite Linux distribution (preferably Ubuntu 20.04 LTS).
2. From the distribution's page, select "Get". The first time you launch a newly installed Linux distribution, a console
   window will open, and you'll be asked to wait for a minute or two for files to de-compress and be stored on your PC.
   All future launches should take less than a second.

You will then need to create a user account and password for your new Linux distribution.

# Enable SystemD on WSL with Genie

Kubernetes (and docker) needs ***SystemD*** to work. For this, you need to
install [Genie](https://github.com/arkane-systems/genie).

## 1. Install Genie

Within **WSL**:

```bash
cd /tmp
wget --content-disposition "https://gist.githubusercontent.com/djfdyuruiry/6720faa3f9fc59bfdf6284ee1f41f950/raw/952347f805045ba0e6ef7868b18f4a9a8dd2e47a/install-sg.sh"
chmod +x install-sg.sh
./install-sg.sh
rm install-sg.sh
```

If ever you did not install Ubuntu 20.04, you would need to modify the downloaded script `install-sg.sh` and
change `UBUNTU_VERSION` before `install-sg.sh`.

It is preferable to disable some services:

```bash
sudo systemctl disable getty@tty1.service multipathd.service multipathd.socket ssh.service
sudo systemctl mask systemd-remount-fs.service
```

Then within **Powershell**:

```bash
wsl --shutdown
wsl genie -s
```

## 2. Start a Genie session

Now that Genie is installed, you need to run `wsl genie -s` to start a session. The first session started will launch
Genie and create a dedicated namespace (this should take a few seconds). Then, all sessions started with `wsl genie -s`
will live in that namespace, where **systemD** is running, as PID 1.

***Warning:*** Starting a session with `wsl` alone will not create the session within the Genie namespace, and thus
services like docker or kubernetes will not behave as expected.

## 3. Configure Genie

If you want to have access to Windows tools from within Genie (like `code`), you have to set `clone-path` to `true`. On
Ubuntu 20.04, the path might not be set properly, even with `clone-path=true`. In that case, you would to add the
following command to your `.bashrc`:

```bash
# This is a temporary hack until the following bug is fixed:
# https://github.com/arkane-systems/genie/issues/201
if [ "${INSIDE_GENIE:-0}" != 0 ] \
    && cat /etc/genie.ini | grep --quiet '^clone-path=true' \
    && ! echo "$PATH" | grep --quiet '/WINDOWS/system32' \
    && [ -f /run/genie.path ]
then
    echo "[DEBUG] Add content of '/run/genie.path' to PATH."
    PATH="$PATH:$(cat /run/genie.path)"
fi
```

### [Return to Quick install on localhost](../../quick-deploy/localhost/README.md)

### [Return to Quick install on AWS](../../quick-deploy/aws/README.md)

### [Return to Main page](../../README.md)