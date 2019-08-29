### Functions

```
function appendToPATH {
  case ":$PATH:" in
    *":$1:"*) :;; # already there
    *) PATH="$1:$PATH";; # or PATH="$PATH:$1"
  esac
}

function prependToPATH {
  case ":$PATH:" in
    *":$1:"*) :;; # already there
    *) PATH="$PATH:$1";; # or PATH="$PATH:$1"
  esac
}

# Returns a color according to running/suspended jobs.
function job_color()
{
    if [ $(jobs -s | wc -l) -gt "0" ]; then
        echo -en ${BRed}
    elif [ $(jobs -r | wc -l) -gt "0" ] ; then
        echo -en ${BCyan}
    fi
}

# Returns a color according to free disk space in $PWD.
function disk_color()
{
    if [ ! -w "${PWD}" ] ; then
        echo -en ${Red}
        # No 'write' privilege in the current directory.
    elif [ -s "${PWD}" ] ; then
        local used=$(command df -P "$PWD" |
                   awk 'END {print $5} {sub(/%/,"")}')
        if [ ${used} -gt 95 ]; then
            echo -en ${ALERT}           # Disk almost full (>95%).
        elif [ ${used} -gt 90 ]; then
            echo -en ${BRed}            # Free disk space almost gone.
        else
            echo -en ${Green}           # Free disk space is ok.
        fi
    else
        echo -en ${Cyan}
        # Current directory is size '0' (like /proc, /sys etc).
    fi
}

NCPU=$(grep -c ^processor /proc/cpuinfo)    # Number of CPUs
SLOAD=$(( 100*${NCPU} ))        # Small load
MLOAD=$(( 200*${NCPU} ))        # Medium load
XLOAD=$(( 400*${NCPU} ))        # Xlarge load

# Returns system load as percentage, i.e., '40' rather than '0.40)'.
function load()
{
    local SYSLOAD=$(cut -d " " -f1 /proc/loadavg | tr -d '.')
    # System load of the current host.
    echo $((10#$SYSLOAD))       # Convert to decimal.
}

# Returns a color indicating system load.
function load_color()
{
    local SYSLOAD=$(load)
    if [ ${SYSLOAD} -gt ${XLOAD} ]; then
        echo -en ${ALERT}
    elif [ ${SYSLOAD} -gt ${MLOAD} ]; then
        echo -en ${Red}
    elif [ ${SYSLOAD} -gt ${SLOAD} ]; then
        echo -en ${BRed}
    else
        echo -en ${Green}
    fi
}

update() {
    echo "Updating machine"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # OSX
        brew update && brew upgrade
    else
        if [[ `cat /etc/issue` == *"Ubuntu"* ]]; then
            # Ubuntu
            sudo apt-get update && sudo apt-get upgrade
        else
            # RHEL/Amazon Linux
            sudo yum update -y
        fi
    fi
}

before() {
    BASE_DIR="$(dirname "${BASH_SOURCE[0]}")"

    pushd $BASE_DIR > /dev/null
}

after() {
    popd > /dev/null
}

# Run a singel unit test
function bbut() {
  if [ -z "$1" ]; then
    brazil-build unit-tests
  else
    files=$(find . -name "$1.java")
    class=$(sed -n "s/^package \(.*\);/\1.$1/p" "$files" 2>/dev/null)
    if [ -z "$class" ]; then
      echo "Test class $1.java not found - make sure it's below your current location in the directory structure."
    elif [ -z "$2" ]; then
      brazil-build single-unit-test -DtestClass="$class"
    else
      brazil-build single-unit-test -DtestClass="$class" -DtestMethods="$2"
    fi
  fi
}

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Utility command to run a command and kill it (sending SIGKILL) after a timeout
timeout () {
    [ "${1:-}" = "-h" -o "${1:-}" = "--help" ] && { printf "USAGE: timeout [--no-msg] <delay-in-deconds> <cmd>\n  <cmd> can start with 'exec' to avoid creating a new process\n" ; return ; }
    local no_msg=false; [ "${1:-}" = "--no-msg" ] && { no_msg=true ; shift ; }
    local s=${1:?'Missing timeout parameters'} ; shift
    ( pid=$(sh -c 'echo $PPID')
      ( $no_msg || echo "Command launched with a ${s}s timeout. To let it live: kill $(sh -c 'echo $PPID')"
        sleep $s
        kill -9 $pid 2>/dev/null || true
      ) & "${@:?'Missing timeout command'}"
    )
}

export PATH=
path=(
       ~/bin
       ~/usr/bin
       /usr/kerberos/bin
       /apollo/env/SDETools/bin
       $ENV_IMPROVEMENT_ROOT/bin
       /usr/local/bin
       /usr/bin
       /bin
       /usr/sbin
       /sbin
       /usr/local/sbin
       /apollo/bin
       /apollo/sbin
       /apollo/env/ApolloCommandLine/bin
     )

# Cd up some number of folders. Example: up 5
up () {
    set -A ud
    ud[1+${1-1}]=
        cd ${(j:../:)ud}
}

```

### Preferences

```
Skip mandatory microsoft account login step requirement from OneNote.
sudo /usr/bin/defaults write /Library/Preferences/com.microsoft.onenote.mac.plist FirstRunExperienceCompletedO15 -bool true
sudo /usr/bin/defaults write /Library/Preferences/com.microsoft.onenote.mac.plist kSubUIAppCompletedFirstRunSetup1507 -bool true
```