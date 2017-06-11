# update-db.sh
Bash script that goes and fetches database from remote host and imports it to the local one.

Script will ask credentials of remote and local systems interactively, but It can be skipped by creating `update-db.conf` file, it can be easily created by copying/moving file `update-db.conf.sample` to `update-db.conf`.

Sample config files includes option to make script work with WordPress and Magento's database so that certain data will be overwritten to work with local system automatically.

### Dependencies
* bash
* openssh
* mysql/mariadb
