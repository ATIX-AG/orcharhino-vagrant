# orcharhino-vagrant

This Vagrant project provisions orcharhino (https://orcharhino.com) automatically, using Vagrant, an EL 7 box and a shell script.
For more information you should have a look at (https://docs.orcharhino.com).

## Prerequisites

1. Vagrant with either VirtualBox or KVM.
2. The [vagrant-env](https://github.com/gosuri/vagrant-env) plugin is optional but
makes configuration much easier
3. an orcharhino activation key

## Getting started

1. Clone this repository `git clone ...`
2. Change into the `abc` directory
3. modify the Vagrant file according your needs
   1. choose a base os (centos7 (default), oracle7 and rhel7 are supported)
   2. choose an installation method (full, default (default), webgui)
     - full: install a full blown orcharhino with all features enabled
     - default: install a default configuration based on base os selection
     - webgui: start the webgui installer for manual configuration
   3. add your orcharhino activation key (can be also done vie commandline)
4. Run `[OR_ACTIVATIOB_KEY=<YOUR_ACTIVATION_KEY>] vagrant up`
   1. The first time you run this it will provision everything and will take a while. Ensure you have a good internet connection as the scripts will update the VM to the latest via `yum`.
   2. The installation can be customized, if desired (see [Configuration](#configuration)).
5. Connect to the database (see [Connecting to Oracle](#connecting-to-oracle))
6. You can shut down the VM via the usual `vagrant halt` and then start it up again via `vagrant up`

## Configuration

The `Vagrantfile` can be used _as-is_, without any additional configuration. However, there are several parameters you can set to tailor the installation to your needs.

### How to configure

There are three ways to set parameters:

1. Update the `Vagrantfile`. This is straightforward; the downside is that you will lose changes when you update this repository.
2. Use environment variables. It might be difficult to remember the parameters used when the VM was instantiated.
3. Use the `.env`/`.env.local` files (requires
[vagrant-env](https://github.com/gosuri/vagrant-env) plugin). You can configure your installation by editing the `.env` file, but `.env` will be overwritten on updates, so it's better to make a copy of `.env` called `.env.local`, then make changes in `.env.local`. The `.env.local` file won't be overwritten when you update this repository and it won't mark your Git tree as changed (you won't accidentally commit your local configuration!).

Parameters are considered in the following order (first one wins):

1. Environment variables
2. `.env.local` (if it exists and the  [vagrant-env](https://github.com/gosuri/vagrant-env) plugin is installed)
3. `.env` (if the [vagrant-env](https://github.com/gosuri/vagrant-env) plugin is installed)
4. `Vagrantfile` definitions

### VM parameters

* `BASE_OS` (default: `centos7`): host operating system to be used
  * supported values: `centos7`, `oracle7` and `rhel7` 
* `VM_NAME` (default: `orcharhino-vagrant`): VM name.
* `DOMAIN_NAME` (default: `example.com`): domain name.
* `VM_MEMORY` (default: `8192`): memory for the VM.
* `VM_SYSTEM_TIMEZONE` (default: host time zone (if possible)): VM time zone.
  * The system time zone is used by the database for SYSDATE/SYSTIMESTAMP.
  * The guest time zone will be set to the host time zone when the host time zone is a full hour offset from GMT.
  * When the host time zone isn't a full hour offset from GMT (e.g., in India and parts of Australia), the guest time zone will be set to UTC.
  * You can specify a different time zone using a time zone name (e.g., "America/Los_Angeles") or an offset from GMT (e.g., "Etc/GMT-2"). For more information on specifying time zones, see [List of tz database time zones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).

### orcharhino parameters

* `OR_ACTIVATION_KEY`: activation key to register to ACC
* `OR_ADMIN_PASSWORD` (default: `changeme`): Administrator password
* `OR_ADMIN_EMAIL` (default: `admin@example.com`): Administrator's email address
* `OR_ORGANIZATION` (default: `DEMO`): Name of first organization
* `OR_LOCATION` (default: `DEMO`): Name of first location
* `OR_ENABLE_TFTP`(default: `false`): enable tftp 

## modification

if you need some modification you can put your scripts into ./userscripts/pre.d/
These scripts will be executed before the installation process starts.

## Optional plugins

When installed, this Vagrant project will make use of the following third party Vagrant plugins:

* [vagrant-env](https://github.com/gosuri/vagrant-env): loads environment
variables from .env files;
* [vagrant-proxyconf](https://github.com/tmatilai/vagrant-proxyconf): set
proxies in the guest VM if you need to access the Internet through a proxy. See
the plugin documentation for configuration.

To install Vagrant plugins run:

```shell
vagrant plugin install <name>...
```

## Other info

* If you need to, you can connect to the virtual machine via `vagrant ssh`.
* You can `sudo -i` to switch to the root user.
* On the guest OS, the directory `/vagrant` is a shared folder and maps to wherever you have this file checked out.
