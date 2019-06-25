## Gain and maintain `sudo` access upfront

- TODO: Add it to bootstrap.sh and test that it is required at all and it works

```
#################################
# Obtain and Maintain Sudo		#
#################################

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until `bootstrap.sh` has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
```