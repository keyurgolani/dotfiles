yes y | ssh-keygen -f ~/.ssh/id_rsa -q -t rsa -N '' > /dev/null

touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress;
PROD=$(softwareupdate -l |
 grep "\*.*Command Line.*$(sw_vers -productVersion|awk -F. '{print $1"."$2}')" |
 head -n 1 | awk -F"*" '{print $2}' |
 sed -e 's/^ *//' |
 tr -d '\n')
softwareupdate -i "$PROD" --verbose
rm /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress