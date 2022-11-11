# UPGRADE

## 1.7.5 ... 1.8.0

### Varnish dependency updated

The dependency to varnish chart was updated to 1.4.x. 

### VARNISH_SERVER environment variable

Until this version the environment variable `VARNISH_SERVER` was set although varnish was disabled. With the version 
1.7.6 this variable was removed.
