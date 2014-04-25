# vim: ts=4 sts=4 et

# ----- Define colors ------------------------------------------------------->
# Reset
Color_Off="[0m"       # Text Reset

# Regular Colors
Black="[0;30m"        # Black
Red="[0;31m"          # Red
Green="[0;32m"        # Green
Yellow="[0;33m"       # Yellow
Blue="[0;34m"         # Blue
Purple="[0;35m"       # Purple
Cyan="[0;36m"         # Cyan
White="[0;37m"        # White

# Bold
BBlack="[1;30m"       # Black
BRed="[1;31m"         # Red
BGreen="[1;32m"       # Green
BYellow="[1;33m"      # Yellow
BBlue="[1;34m"        # Blue
BPurple="[1;35m"      # Purple
BCyan="[1;36m"        # Cyan
BWhite="[1;37m"       # White

# Underline
UBlack="[4;30m"       # Black
URed="[4;31m"         # Red
UGreen="[4;32m"       # Green
UYellow="[4;33m"      # Yellow
UBlue="[4;34m"        # Blue
UPurple="[4;35m"      # Purple
UCyan="[4;36m"        # Cyan
UWhite="[4;37m"       # White

# Background
On_Black="[40m"       # Black
On_Red="[41m"         # Red
On_Green="[42m"       # Green
On_Yellow="[43m"      # Yellow
On_Blue="[44m"        # Blue
On_Purple="[45m"      # Purple
On_Cyan="[46m"        # Cyan
On_White="[47m"       # White

# High Intensity
IBlack="[0;90m"       # Black
IRed="[0;91m"         # Red
IGreen="[0;92m"       # Green
IYellow="[0;93m"      # Yellow
IBlue="[0;94m"        # Blue
IPurple="[0;95m"      # Purple
ICyan="[0;96m"        # Cyan
IWhite="[0;97m"       # White

# Bold High Intensity
BIBlack="[1;90m"      # Black
BIRed="[1;91m"        # Red
BIGreen="[1;92m"      # Green
BIYellow="[1;93m"     # Yellow
BIBlue="[1;94m"       # Blue
BIPurple="[1;95m"     # Purple
BICyan="[1;96m"       # Cyan
BIWhite="[1;97m"      # White

# High Intensity backgrounds
On_IBlack="[0;100m"   # Black
On_IRed="[0;101m"     # Red
On_IGreen="[0;102m"   # Green
On_IYellow="[0;103m"  # Yellow
On_IBlue="[0;104m"    # Blue
On_IPurple="[0;105m"  # Purple
On_ICyan="[0;106m"    # Cyan
On_IWhite="[0;107m"   # White


if [ `hostname` = 'arched' ]; then
    HOSTCOLOR="[38;5;202m"
else
    HOSTCOLOR="[38;5;198m"
fi

if [ `id -u` = '0' ]; then
    USERCOLOR="[38;5;196m"
else
    USERCOLOR="[38;5;33m"
fi
# <---- Define colors --------------------------------------------------------


export VIRTUAL_ENV_DISABLE_PROMPT=1  # We handle our own PS1
export USER_VC_PROMPT=$'\033[1;30m on \033[38;5;27m%n\033[00m:\033[38;5;214m%b\033[0;32m'


# Disable posix mode which disallows dashes in function names
set +o posix

# ----- Some required functions definitions --------------------------------->
user-last-command-failed() {
    code=$?
    if [ $code != 0 ]; then
        echo -n $'\033[1;37m exited \033[0;31m'
        echo -n $code
        echo -n $'\033[0;37m'
    fi
}

user-background-jobs() {
    if [ -x ~/bin/background-running-jobs ]; then
        jobs | ~/bin/background-running-jobs --text-color='[1;30m' --job-color='[0;36m' --pre-space
    fi
}

current-virtualenv() {
  if [ x$VIRTUAL_ENV != x ]; then
      if [[ $VIRTUAL_ENV == *.virtualenvs/* ]]; then
          ENV_NAME=`basename "${VIRTUAL_ENV}"`
      else
          folder=`dirname "${VIRTUAL_ENV}"`
          ENV_NAME=`basename "$folder"`
      fi
      echo -n $'\033[1;30m workon \033[0;31m'
      echo -n $ENV_NAME
      echo -n $'\033[00m'
  fi
}

user-vcprompt() {
    ~/bin/vcprompt -f "$USER_VC_PROMPT"
}
# <---- Some required functions definitions ----------------------------------


# Enable posix mode which disallows dashes in function names
set -o posix


export USER_BASEPROMPT='\e${USERCOLOR}\u \
\e${BBlack}@\e${Color_Off} \e${HOSTCOLOR}\h \
\e${Color_Off}\e${BBlack}in \e[38;5;35m\w\
`user-last-command-failed`\
\e${Color_Off}`user-vcprompt`\
`user-background-jobs`\
`current-virtualenv`\
\e${Color_Off}'
export PS1="\[\033[G\]${USER_BASEPROMPT}
$ "
