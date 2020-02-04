#!/bin/bash

# UniFi Controller 5.12.35 auto installation script.
# OS       | List of supported Distributions/OS
#
#          | Ubuntu Precise Pangolin ( 12.04 )
#          | Ubuntu Trusty Tahr ( 14.04 )
#          | Ubuntu Xenial Xerus ( 16.04 )
#          | Ubuntu Bionic Beaver ( 18.04 )
#          | Ubuntu Cosmic Cuttlefish ( 18.10 )
#          | Ubuntu Disco Dingo  ( 19.04 )
#          | Ubuntu Eoan Ermine  ( 19.10 )
#          | Debian Jessie ( 8 )
#          | Debian Stretch ( 9 )
#          | Debian Buster ( 10 )
#          | Debian Bullseye ( 11 )
#          | Linux Mint 13 ( Maya )
#          | Linux Mint 17 ( Qiana | Rebecca | Rafaela | Rosa )
#          | Linux Mint 18 ( Sarah | Serena | Sonya | Sylvia )
#          | Linux Mint 19 ( Tara | Tessa | Tina | Tricia )
#          | MX Linux 18 ( Continuum )
#          | Parrot OS
#
# Version  | 4.4.9
# Author   | Glenn Rietveld
# Email    | glennrietveld8@hotmail.nl
# Website  | https://GlennR.nl

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                           Color Codes                                                                                           #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

RESET='\033[0m'
#GRAY='\033[0;37m'
#WHITE='\033[1;37m'
GRAY_R='\033[39m'
WHITE_R='\033[39m'
RED='\033[1;31m' # Light Red.
GREEN='\033[1;32m' # Light Green.
#BOLD='\e[1m'

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                           Start Checks                                                                                          #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

# Check for root (SUDO).
if [[ "$EUID" -ne 0 ]]; then
  clear
  clear
  echo -e "${RED}#########################################################################${RESET}"
  echo ""
  echo -e "${WHITE_R}#${RESET} The script need to be run as root..."
  echo ""
  echo ""
  echo -e "${WHITE_R}#${RESET} For Ubuntu based systems run the command below to login as root"
  echo -e "${GREEN}#${RESET} sudo -i"
  echo ""
  echo -e "${WHITE_R}#${RESET} For Debian based systems run the command below to login as root"
  echo -e "${GREEN}#${RESET} su"
  echo ""
  echo ""
  exit 1
fi

abort() {
  if [[ -f /tmp/EUS/services/stopped_list && -s /tmp/EUS/services/stopped_list ]]; then
    while read -r service; do
      echo -e "\\n${WHITE_R}#${RESET} Starting ${service}.."
      systemctl start "${service}" && echo -e "${GREEN}#${RESET} Successfully started ${service}!" || echo -e "${RED}#${RESET} Failed to start ${service}!"
    done < /tmp/EUS/services/stopped_list
  fi
  if [[ "${set_lc_all}" == 'true' ]]; then unset LC_ALL; fi
  echo ""
  echo ""
  echo -e "${RED}#########################################################################${RESET}"
  echo ""
  echo -e "${WHITE_R}#${RESET} An error occurred. Aborting script..."
  echo -e "${WHITE_R}#${RESET} Please contact Glenn R. (AmazedMender16) on the Community Forums!"
  echo ""
  echo ""
  exit 1
}

header() {
  clear
  echo -e "${GREEN}#########################################################################${RESET}"
  echo ""
}

header_red() {
  clear
  echo -e "${RED}#########################################################################${RESET}"
  echo ""
}

start_script() {
  clear
  header
  cat << "EOF"

  _______________ ___  _________  .___                 __         .__  .__   
  \_   _____/    |   \/   _____/  |   | ____   _______/  |______  |  | |  |  
   |    __)_|    |   /\_____  \   |   |/    \ /  ___/\   __\__  \ |  | |  |  
   |        \    |  / /        \  |   |   |  \\___ \  |  |  / __ \|  |_|  |__
  /_______  /______/ /_______  /  |___|___|  /____  > |__| (____  /____/____/
          \/                 \/            \/     \/            \/           

    Easy UniFi Install Script!
EOF
  echo -e "\\n${WHITE_R}#${RESET} Starting the Easy UniFi Install Script.."
  echo -e "${WHITE_R}#${RESET} Thank you for using my Easy UniFi Install Script :-)\\n\\n"
  sleep 2
}
start_script

if ! env | grep "LC_ALL\\|LANG" | grep -iq "en_US\\|C.UTF-8"; then
  clear && clear
  echo -e "${GREEN}#########################################################################${RESET}\\n"
  echo -e "${WHITE_R}#${RESET} Your language is not set to English ( en_US ), the script will temporarily set the language to English."
  echo -e "${WHITE_R}#${RESET} Information: This is done to prevent issues in the script.."
  export LC_ALL=C &> /dev/null
  set_lc_all=true
  sleep 3
fi

while [ -n "$1" ]; do
  case "$1" in
  -skip) script_option_skip=true;; # Skip script removal and repository question
  esac
  shift
done

if [[ "$(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "downloads-distro.mongodb.org")" -gt 0 ]]; then
  grep -riIl "downloads-distro.mongodb.org" /etc/apt/ &>> /tmp/EUS/repository/dead_mongodb_repository
  while read -r glennr_mongo_repo; do
    sed -i '/downloads-distro.mongodb.org/d' "${glennr_mongo_repo}" 2> /dev/null
	if ! [[ -s "${glennr_mongo_repo}" ]]; then
      rm --force "${glennr_mongo_repo}" 2> /dev/null
    fi
  done < /tmp/EUS/repository/dead_mongodb_repository
  rm --force /tmp/EUS/repository/dead_mongodb_repository
fi

if apt-key list 2>/dev/null | grep mongodb -B1 | grep -iq "expired:"; then
  wget -qO - https://www.mongodb.org/static/pgp/server-3.4.asc | apt-key add - &> /dev/null
fi

run_apt_get_update() {
  if ! [[ -d /tmp/EUS/keys ]]; then mkdir -p /tmp/EUS/keys; fi
  if ! [[ -f /tmp/EUS/keys/missing_keys && -s /tmp/EUS/keys/missing_keys ]]; then
    apt-get update 2>&1 | tee /tmp/EUS/keys/apt_update
    grep -o 'NO_PUBKEY.*' /tmp/EUS/keys/apt_update | sed 's/NO_PUBKEY //g' | tr ' ' '\n' | awk '!a[$0]++' &> /tmp/EUS/keys/missing_keys
  fi
  if [[ -f /tmp/EUS/keys/missing_keys && -s /tmp/EUS/keys/missing_keys ]]; then
    clear
    header
    echo -e "${WHITE_R}#${RESET} Some keys are missing.. The script will try to add the missing keys."
    echo -e "\\n${WHITE_R}----${RESET}\\n"
    while read -r key; do
      echo -e "${WHITE_R}#${RESET} Key ${key} is missing.. adding!"
      http_proxy=$(env | grep -i "http.*Proxy" | cut -d'=' -f2 | sed 's/[";]//g')
      if [[ -n "$http_proxy" ]]; then
        apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy="${http_proxy}" --recv-keys "$key" &> /dev/null && echo -e "${WHITE_R}#${RESET} Successfully added key ${key}!\\n" || echo -e "${WHITE_R}#${RESET} Failed to add key ${key}!\\n"
      elif [[ -f /etc/apt/apt.conf ]]; then
        apt_http_proxy=$(grep "http.*Proxy" /etc/apt/apt.conf | awk '{print $2}' | sed 's/[";]//g')
        if [[ -n "${apt_http_proxy}" ]]; then
          apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy="${apt_http_proxy}" --recv-keys "$key" &> /dev/null && echo -e "${WHITE_R}#${RESET} Successfully added key ${key}!\\n" || echo -e "${WHITE_R}#${RESET} Failed to add key ${key}!\\n"
        fi
      else
        apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv "$key" &> /dev/null && echo -e "${WHITE_R}#${RESET} Successfully added key ${key}!\\n" || echo -e "${WHITE_R}#${RESET} Failed to add key ${key}!\\n"
      fi
      sleep 1
    done < /tmp/EUS/keys/missing_keys
    rm --force /tmp/EUS/keys/missing_keys
    rm --force /tmp/EUS/keys/apt_update
    clear
    header
    echo -e "${WHITE_R}#${RESET} Running apt-get update again.\\n\\n"
    sleep 2
    apt-get update &> /tmp/EUS/keys/apt_update
    if grep -qo 'NO_PUBKEY.*' /tmp/EUS/keys/apt_update; then
      run_apt_get_update
    fi
  fi
}

cancel_script() {
  if [[ "${set_lc_all}" == 'true' ]]; then unset LC_ALL &> /dev/null; fi
  clear
  header
  echo -e "${WHITE_R}#${RESET} Cancelling the script!"
  echo ""
  echo ""
  exit 0
}

http_proxy_found() {
  clear
  header
  echo -e "${GREEN}#${RESET} HTTP Proxy found. | ${WHITE_R}${http_proxy}${RESET}"
  echo ""
  echo ""
}

remove_yourself() {
  if [[ "${set_lc_all}" == 'true' ]]; then unset LC_ALL &> /dev/null; fi
  if [[ "${delete_script}" == 'true' || "${script_option_skip}" == 'true' ]]; then
    if [[ -e "$0" ]]; then
      rm --force "$0" 2> /dev/null
    fi
  fi
}

christmass_new_year() {
  date_d=$(date '+%d')
  date_m=$(date '+%m')
  if [[ "${date_m}" == '12' && "${date_d}" -ge '18' && "${date_d}" -lt '26' ]]; then
    echo -e "\\n${WHITE_R}----${RESET}\\n"
    echo -e "${WHITE_R}#${RESET} GlennR wishes you a Merry Christmas! May you be blessed with health and happiness!"
    christmas_message=true
  fi
  if [[ "${date_m}" == '12' && "${date_d}" -ge '24' && "${date_d}" -le '30' ]]; then
    if [[ "${christmas_message}" != 'true' ]]; then echo -e "\\n${WHITE_R}----${RESET}\\n"; fi
    if [[ "${christmas_message}" == 'true' ]]; then echo -e ""; fi
    date_y=$(date -d "+1 year" +"%Y")
    echo -e "${WHITE_R}#${RESET} HAPPY NEW YEAR ${date_y}"
    echo -e "${WHITE_R}#${RESET} May the new year turn all your dreams into reality and all your efforts into great achievements!"
    new_year_message=true
  elif [[ "${date_m}" == '12' && "${date_d}" == '31' ]]; then
    if [[ "${christmas_message}" != 'true' ]]; then echo -e "\\n${WHITE_R}----${RESET}\\n"; fi
    if [[ "${christmas_message}" == 'true' ]]; then echo -e ""; fi
    date_y=$(date -d "+1 year" +"%Y")
    echo -e "${WHITE_R}#${RESET} HAPPY NEW YEAR ${date_y}"
    echo -e "${WHITE_R}#${RESET} Tomorrow, is the first blank page of a 365 page book. Write a good one!"
    new_year_message=true
  fi
  if [[ "${date_m}" == '1' && "${date_d}" -le '5' ]]; then
    if [[ "${christmas_message}" != 'true' ]]; then echo -e "\\n${WHITE_R}----${RESET}\\n"; fi
    if [[ "${christmas_message}" == 'true' ]]; then echo -e ""; fi
    date_y=$(date '+%Y')
    echo -e "${WHITE_R}#${RESET} HAPPY NEW YEAR ${date_y}"
    echo -e "${WHITE_R}#${RESET} May this new year all your dreams turn into reality and all your efforts into great achievements"
    new_year_message=true
  fi
}

author() {
  christmass_new_year
  if [[ "${new_year_message}" == 'true' || "${christmas_message}" == 'true' ]]; then echo -e "\\n${WHITE_R}----${RESET}\\n"; fi
  echo -e "${WHITE_R}#${RESET} ${GRAY_R}Author   |  ${WHITE_R}Glenn R.${RESET}"
  echo -e "${WHITE_R}#${RESET} ${GRAY_R}Email    |  ${WHITE_R}glennrietveld8@hotmail.nl${RESET}"
  echo -e "${WHITE_R}#${RESET} ${GRAY_R}Website  |  ${WHITE_R}https://GlennR.nl${RESET}"
  echo -e "\\n\\n"
}

# Get distro.
if [[ -z "$(command -v lsb_release)" ]]; then
  if [[ -f "/etc/os-release" ]]; then
    if grep -iq VERSION_CODENAME /etc/os-release; then
      os_codename=$(grep VERSION_CODENAME /etc/os-release | sed 's/VERSION_CODENAME//g' | tr -d '="' | tr '[:upper:]' '[:lower:]')
    elif ! grep -iq VERSION_CODENAME /etc/os-release; then
      os_codename=$(grep PRETTY_NAME /etc/os-release | sed 's/PRETTY_NAME=//g' | tr -d '="' | awk '{print $4}' | sed 's/\((\|)\)//g' | sed 's/\/sid//g' | tr '[:upper:]' '[:lower:]')
      if [[ -z "${os_codename}" ]]; then
        os_codename=$(grep PRETTY_NAME /etc/os-release | sed 's/PRETTY_NAME=//g' | tr -d '="' | awk '{print $3}' | sed 's/\((\|)\)//g' | sed 's/\/sid//g' | tr '[:upper:]' '[:lower:]')
      fi
    fi
  fi
else
  os_codename=$(lsb_release -cs | tr '[:upper:]' '[:lower:]')
  if [[ "${os_codename}" == 'n/a' ]]; then
    os_codename=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
    if [[ "${os_codename}" == 'parrot' ]]; then
      os_codename='buster'
    fi
  fi
fi

if ! [[ "${os_codename}" =~ (precise|maya|trusty|qiana|rebecca|rafaela|rosa|xenial|sarah|serena|sonya|sylvia|bionic|tara|tessa|tina|tricia|cosmic|disco|eoan|jessie|stretch|continuum|buster|bullseye) ]]; then
  clear
  header_red
  echo -e "${WHITE_R}#${RESET} This script is not made for your OS.."
  echo -e "${WHITE_R}#${RESET} Feel free to contact Glenn R. (AmazedMender16) on the Community Forums if you need help with installing your UniFi Network Controller."
  echo -e ""
  echo -e "OS_CODENAME = ${os_codename}"
  echo -e ""
  echo -e ""
  exit 1
fi

if ! grep -iq '^127.0.0.1.*localhost' /etc/hosts; then
  clear
  header_red
  echo -e "${WHITE_R}#${RESET} '127.0.0.1   localhost' does not exist in your /etc/hosts file."
  echo -e "${WHITE_R}#${RESET} You will most likely see controller startup issues if it doesn't exist.."
  echo ""
  echo ""
  echo ""
  read -rp $'\033[39m#\033[0m Do you want to add "127.0.0.1   localhost" to your /etc/hosts file? (Y/n) ' yes_no
  case "$yes_no" in
      [Yy]*|"")
          echo -e "${WHITE_R}----${RESET}"
          echo ""
          echo -e "${WHITE_R}#${RESET} Adding '127.0.0.1       localhost' to /etc/hosts"
          sed  -i '1i # ------------------------------' /etc/hosts
          sed  -i '1i 127.0.0.1       localhost' /etc/hosts
          sed  -i '1i # Added by GlennR EUS script' /etc/hosts && echo -e "${WHITE_R}#${RESET} Done.."
          echo ""
          echo ""
          sleep 3;;
      [Nn]*) ;;
  esac
fi

if [[ $(echo "${PATH}" | grep -c "/sbin") -eq 0 ]]; then
  #PATH=/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/sbin:/usr/local/bin
  #PATH=$PATH:/usr/sbin
  PATH="$PATH:/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/sbin:/usr/local/bin"
fi

if ! [[ -d /etc/apt/sources.list.d ]]; then mkdir -p /etc/apt/sources.list.d; fi
if ! [[ -d /tmp/EUS/keys ]]; then mkdir -p /tmp/EUS/keys; fi

# Check if UniFi is already installed.
if dpkg -l | grep "unifi " | grep -q "^ii"; then
  clear
  header
  echo ""
  echo -e "${WHITE_R}#${RESET} UniFi is already installed on your system!${RESET}"
  echo -e "${WHITE_R}#${RESET} You can use my Easy Update Script to update your controller.${RESET}"
  echo ""
  echo ""
  read -rp $'\033[39m#\033[0m Would you like to download and run my Easy Update Script? (Y/n) ' yes_no
  case "$yes_no" in
      [Yy]*|"")
        rm --force "$0" 2> /dev/null
        wget https://get.glennr.nl/unifi/update/unifi-update.sh && bash unifi-update.sh; exit 0;;
      [Nn]*) exit 0;;
  esac
fi

dpkg_locked_message() {
  clear
  header_red
  echo -e "${WHITE_R}#${RESET} dpkg is locked.. Waiting for other software managers to finish!"
  echo -e "${WHITE_R}#${RESET} If this is everlasting please contact Glenn R. (AmazedMender16) on the Community Forums!"
  echo ""
  echo ""
  sleep 5
  if [[ -z "$dpkg_wait" ]]; then
    echo "glennr_lock_active" >> /tmp/glennr_lock
  fi
}

dpkg_locked_60_message() {
  clear
  header
  echo -e "${WHITE_R}#${RESET} dpkg is already locked for 60 seconds..."
  echo -e "${WHITE_R}#${RESET} Would you like to force remove the lock?"
  echo ""
  echo ""
  echo ""
}

# Check if dpkg is locked
if dpkg -l psmisc 2> /dev/null | awk '{print $1}' | grep -iq "^ii"; then
  while fuser /var/lib/dpkg/lock /var/lib/apt/lists/lock /var/cache/apt/archives/lock >/dev/null 2>&1; do
    dpkg_locked_message
    if [[ $(grep -c "glennr_lock_active" /tmp/glennr_lock) -ge 12 ]]; then
      rm --force /tmp/glennr_lock 2> /dev/null
      dpkg_locked_60_message
      if [[ "${script_option_skip}" != 'true' ]]; then
        read -rp $'\033[39m#\033[0m Do you want to proceed with removing the lock? (Y/n) ' yes_no
        case "$yes_no" in
            [Yy]*|"")
              killall apt apt-get 2> /dev/null
              rm --force /var/lib/apt/lists/lock 2> /dev/null
              rm --force /var/cache/apt/archives/lock 2> /dev/null
              rm --force /var/lib/dpkg/lock* 2> /dev/null
              dpkg --configure -a 2> /dev/null
              apt-get install --fix-broken -y 2> /dev/null
              clear
              clear;;
            [Nn]*) dpkg_wait=true;;
        esac
      else
        killall apt apt-get 2> /dev/null
        rm --force /var/lib/apt/lists/lock 2> /dev/null
        rm --force /var/cache/apt/archives/lock 2> /dev/null
        rm --force /var/lib/dpkg/lock* 2> /dev/null
        dpkg --configure -a 2> /dev/null
        apt-get install --fix-broken -y 2> /dev/null
        clear
        clear
      fi
    fi
  done;
else
  dpkg -i /dev/null 2> /tmp/glennr_dpkg_lock; if grep -q "locked.* another" /tmp/glennr_dpkg_lock; then dpkg_locked=true; rm --force /tmp/glennr_dpkg_lock 2> /dev/null; fi
  while [[ "${dpkg_locked}" == 'true'  ]]; do
    unset dpkg_locked
    dpkg_locked_message
    if [[ $(grep -c "glennr_lock_active" /tmp/glennr_lock) -ge 12 ]]; then
      rm --force /tmp/glennr_lock 2> /dev/null
      dpkg_locked_60_message
      if [[ "${script_option_skip}" != 'true' ]]; then
        read -rp $'\033[39m#\033[0m Do you want to proceed with force removing the lock? (Y/n) ' yes_no
        case "$yes_no" in
            [Yy]*|"")
              pgrep "apt" >> /tmp/EUS/apt/apt
              while read -r glennr_apt; do
                kill -9 "$glennr_apt" 2> /dev/null
              done < /tmp/EUS/apt/apt
              rm --force /tmp/glennr_apt 2> /dev/null
              rm --force /var/lib/apt/lists/lock 2> /dev/null
              rm --force /var/cache/apt/archives/lock 2> /dev/null
              rm --force /var/lib/dpkg/lock* 2> /dev/null
              dpkg --configure -a 2> /dev/null
              apt-get install --fix-broken -y 2> /dev/null
              clear
              clear;;
            [Nn]*) dpkg_wait=true;;
        esac
      else
        pgrep "apt" >> /tmp/EUS/apt/apt
        while read -r glennr_apt; do
          kill -9 "$glennr_apt" 2> /dev/null
        done < /tmp/EUS/apt/apt
        rm --force /tmp/glennr_apt 2> /dev/null
        rm --force /var/lib/apt/lists/lock 2> /dev/null
        rm --force /var/cache/apt/archives/lock 2> /dev/null
        rm --force /var/lib/dpkg/lock* 2> /dev/null
        dpkg --configure -a 2> /dev/null
        apt-get install --fix-broken -y 2> /dev/null
        clear
        clear
      fi
    fi
    dpkg -i /dev/null 2> /tmp/glennr_dpkg_lock; if grep -q "locked.* another" /tmp/glennr_dpkg_lock; then dpkg_locked=true; rm --force /tmp/glennr_dpkg_lock 2> /dev/null; fi
  done;
  rm --force /tmp/glennr_dpkg_lock 2> /dev/null
fi

script_online_version_dots=$(curl https://get.glennr.nl/unifi/install/unifi-5.12.35.sh -s | grep "# Version" | head -n 1 | awk '{print $4}')
script_local_version_dots=$(grep "# Version" "$0" | head -n 1 | awk '{print $4}')
script_online_version="${script_online_version_dots//./}"
script_local_version="${script_local_version_dots//./}"

# Script version check.
if [[ "${script_online_version::3}" -gt "${script_local_version::3}" ]]; then
  clear
  header_red
  echo -e "${WHITE_R}#${RESET} You're currently running script version ${script_local_version_dots} while ${script_online_version_dots} is the latest!"
  echo -e "${WHITE_R}#${RESET} Downloading and executing version ${script_online_version_dots} of the Easy Installation Script.."
  echo ""
  echo ""
  sleep 3
  rm --force "$0" 2> /dev/null
  rm --force unifi-5.12.35.sh 2> /dev/null
  wget https://get.glennr.nl/unifi/install/unifi-5.12.35.sh && bash unifi-5.12.35.sh; exit 0
fi

armhf_recommendation() {
  print_architecture=$(dpkg --print-architecture)
  check_cloudkey=$(uname -a | awk '{print $2}')
  if [[ "${print_architecture}" == 'armhf' && "${check_cloudkey}" != "UniFi-CloudKey" ]]; then
    clear
    header_red
    echo -e "${WHITE_R}#${RESET} Your installation might fail, please consider getting a Cloud Key Gen2 or go with a VPS at OVH/DO/AWS."
    if [[ "${os_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan) ]]; then
      echo -e "${WHITE_R}#${RESET} You could try using Debian Stretch before going with a UCK G2 ( PLUS ) or VPS"
    fi
    echo ""
    echo -e "${WHITE_R}#${RESET} UniFi Cloud Key Gen2       | https://store.ui.com/products/unifi-cloud-key-gen2"
    echo -e "${WHITE_R}#${RESET} UniFi Cloud Key Gen2 Plus  | https://store.ui.com/products/unifi-cloudkey-gen2-plus"
    echo ""
    echo ""
    sleep 20
  fi
}

armhf_recommendation

if uname -a | awk '{print $2}' | grep -iq "cloudkey\\|uck"; then
  eus_dir='/srv/EUS'
else
  eus_dir='/usr/lib/EUS'
fi

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                        Required Packages                                                                                        #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

# Install needed packages if not installed
clear
header
echo -e "${WHITE_R}#${RESET} Checking if all required packages are installed!"
echo ""
echo ""
run_apt_get_update
if ! dpkg -l sudo 2> /dev/null | awk '{print $1}' | grep -iq "^ii"; then
  if ! apt-get install sudo -y; then
    if [[ "${os_codename}" =~ (precise|maya) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ precise-security main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ precise-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ trusty-security main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ trusty-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ xenial-security main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ xenial-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (bionic|tara|tessa|tina|tricia) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu bionic main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu bionic main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "cosmic" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu cosmic main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu cosmic main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "disco" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu disco main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu disco main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "eoan" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu eoan main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu eoan main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "jessie" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian jessie main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian jessie main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (stretch|continuum) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian stretch main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian stretch main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "buster" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian buster main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian buster main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "bullseye" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian bullseye main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian bullseye main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    run_apt_get_update
    apt-get install sudo -y || abort
  fi
fi
if ! dpkg -l lsb-release 2> /dev/null | awk '{print $1}' | grep -iq "^ii"; then
  if ! apt-get install lsb-release -y; then
    if [[ "${os_codename}" =~ (precise|maya) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu precise main universe") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu precise main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu trusty main universe") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu trusty main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu xenial main universe") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu xenial main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (bionic|tara|tessa|tina|tricia) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu bionic main universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu bionic main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "cosmic" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu cosmic main universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu cosmic main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "disco" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu disco main universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu disco main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "eoan" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu eoan main universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu eoan main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "jessie" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian jessie main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian jessie main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (stretch|continuum) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian stretch main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian stretch main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "buster" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian buster main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian buster main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "bullseye" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian bullseye main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian bullseye main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    run_apt_get_update
    apt-get install lsb-release -y || abort
  fi
fi
if ! dpkg -l net-tools 2> /dev/null | awk '{print $1}' | grep -iq "^ii"; then
  if ! apt-get install net-tools -y; then
    if [[ "${os_codename}" =~ (precise|maya) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ precise main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ precise main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu trusty main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu trusty main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu xenial main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu xenial main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (bionic|tara|tessa|tina|tricia) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu bionic main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu bionic main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "cosmic" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu cosmic main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu cosmic main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "disco" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu disco main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu disco main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "eoan" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu eoan main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu eoan main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "jessie" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian jessie main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian jessie main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (stretch|continuum) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian stretch main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian stretch main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "buster" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian buster main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian buster main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "bullseye" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian bullseye main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian bullseye main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    run_apt_get_update
    apt-get install net-tools -y || abort
  fi
fi
if ! dpkg -l apt-transport-https 2> /dev/null | awk '{print $1}' | grep -iq "^ii"; then
  if ! apt-get install apt-transport-https -y; then
    if [[ "${os_codename}" =~ (precise|maya) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu precise-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu precise-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu trusty-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu trusty-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu xenial-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu xenial-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (bionic|tara|tessa|tina|tricia) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu bionic-security main universe") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu bionic-security main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "cosmic" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu cosmic-security main universe") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu cosmic-security main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "disco" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu disco main universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu disco main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "eoan" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu eoan main universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu eoan main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "jessie" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.debian.org/debian-security jessie/updates main") -eq 0 ]]; then
        echo deb http://security.debian.org/debian-security jessie/updates main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (stretch|continuum) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian stretch main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian stretch main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "buster" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian buster main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian buster main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "bullseye" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian bullseye main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian bullseye main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    run_apt_get_update
    apt-get install apt-transport-https -y || abort
  fi
fi
if ! dpkg -l software-properties-common 2> /dev/null | awk '{print $1}' | grep -iq "^ii"; then
  if ! apt-get install software-properties-common -y; then
    if [[ "${os_codename}" =~ (precise|maya) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu precise-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu precise-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu trusty main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu trusty main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu xenial main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu xenial main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (bionic|tara|tessa|tina|tricia) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu bionic main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu bionic main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "cosmic" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu cosmic main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu cosmic main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "disco" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu disco main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu disco main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "eoan" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu eoan main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu eoan main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "jessie" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian jessie main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian jessie main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (stretch|continuum) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian stretch main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian stretch main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "buster" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian buster main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian buster main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "bullseye" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian bullseye main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian bullseye main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    run_apt_get_update
    apt-get install software-properties-common -y || abort
  fi
fi
if ! dpkg -l curl 2> /dev/null | awk '{print $1}' | grep -iq "^ii"; then
  if ! apt-get install curl -y; then
    if [[ "${os_codename}" =~ (precise|maya) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu precise-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu precise-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu trusty-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu trusty-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu xenial-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu xenial-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (bionic|tara|tessa|tina|tricia) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu bionic-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu bionic-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "cosmic" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu cosmic-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu cosmic-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "disco" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu disco main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu disco main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "eoan" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu eoan main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu eoan main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "jessie" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.debian.org/debian-security jessie/updates main") -eq 0 ]]; then
        echo deb http://security.debian.org/debian-security jessie/updates main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (stretch|continuum) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian stretch main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian stretch main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "buster" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian buster main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian buster main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "bullseye" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian bullseye main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian bullseye main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    run_apt_get_update
    apt-get install curl -y || abort
  fi
fi
if ! dpkg -l dirmngr 2> /dev/null | awk '{print $1}' | grep -iq "^ii"; then
  if ! apt-get install dirmngr -y; then
    if [[ "${os_codename}" =~ (precise|maya) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ precise universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ precise universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ precise main restricted") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ precise main restricted >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ trusty universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ trusty universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ trusty main restricted") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ trusty main restricted >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu xenial-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu xenial-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ xenial main restricted") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ xenial main restricted >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (bionic|tara|tessa|tina|tricia) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu bionic-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu bionic-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ bionic main restricted") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ bionic main restricted >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "cosmic" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu cosmic-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu cosmic-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ cosmic main restricted") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ cosmic main restricted >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "disco" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu disco-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu disco-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ disco main restricted") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ disco main restricted >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "eoan" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu eoan-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu eoan-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ eoan main restricted") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ eoan main restricted >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "jessie" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian/ jessie main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian/ jessie main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (stretch|continuum) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian/ stretch main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian/ stretch main >>/etc/apt/sources.list.d/glennr-install-script.list || abor
      fi
    elif [[ "${os_codename}" == "buster" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian/ buster main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian/ buster main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "bullseye" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian/ bullseye main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian/ bullseye main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    run_apt_get_update
    apt-get install dirmngr -y || abort
  fi
fi
if ! dpkg -l wget 2> /dev/null | awk '{print $1}' | grep -iq "^ii"; then
  if ! apt-get install wget -y; then
    if [[ "${os_codename}" =~ (precise|maya) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu precise-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu precise-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu trusty-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu trusty-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu xenial-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu xenial-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (bionic|tara|tessa|tina|tricia) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu bionic-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu bionic-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "cosmic" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu cosmic-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu cosmic-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "disco" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu disco main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu disco main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "eoan" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu eoan main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu eoan main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "jessie" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.debian.org/debian-security jessie/updates main") -eq 0 ]]; then
        echo deb http://security.debian.org/debian-security jessie/updates main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (stretch|continuum) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian stretch main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian stretch main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "buster" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian buster main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian buster main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "bullseye" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian bullseye main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian bullseye main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    run_apt_get_update
    apt-get install wget -y || abort
  fi
fi
if ! dpkg -l netcat 2> /dev/null | awk '{print $1}' | grep -iq "^ii"; then
  if ! apt-get install netcat -y; then
    if [[ "${os_codename}" =~ (precise|maya) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ precise universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ precise universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ trusty universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ trusty universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ xenial universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ xenial universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (bionic|tara|tessa|tina|tricia) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ bionic universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ bionic universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "cosmic" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ cosmic universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ cosmic universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "disco" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ disco universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ disco universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "eoan" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ eoan universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ eoan universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "jessie" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian jessie main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian jessie main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (stretch|continuum) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian stretch main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian stretch main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "buster" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian buster main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian buster main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "bullseye" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian bullseye main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian bullseye main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    run_apt_get_update
    apt-get install netcat -y || abort
  fi
  netcat_installed=true
fi
if ! dpkg -l haveged 2> /dev/null | awk '{print $1}' | grep -iq "^ii"; then
  if ! apt-get install haveged -y; then
    if [[ "${os_codename}" =~ (precise|maya) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ precise universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ precise universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ trusty universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ trusty universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ xenial universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ xenial universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (bionic|tara|tessa|tina|tricia) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ bionic universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ bionic universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "cosmic" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ cosmic universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ cosmic universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "disco" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ disco universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ disco universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "eoan" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ eoan universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ eoan universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "jessie" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian jessie main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian jessie main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (stretch|continuum) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian stretch main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian stretch main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "buster" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian buster main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian buster main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "bullseye" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian bullseye main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian bullseye main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    run_apt_get_update
    apt-get install haveged -y || abort
  fi
fi
if ! dpkg -l psmisc 2> /dev/null | awk '{print $1}' | grep -iq "^ii"; then
  if ! apt-get install psmisc -y; then
    if [[ "${os_codename}" =~ (precise|maya) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ precise-updates main restricted") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ precise-updates main restricted >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu trusty main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu trusty main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu xenial main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu xenial main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (bionic|tara|tessa|tina|tricia) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu bionic main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu bionic main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "cosmic" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu cosmic main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu cosmic main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "disco" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu disco main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu disco main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "eoan" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu eoan main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu eoan main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "jessie" ]]; then
     if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian jessie main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian jessie main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (stretch|continuum) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian stretch main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian stretch main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "buster" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian buster main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian buster main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "bullseye" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian bullseye main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian bullseye main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    run_apt_get_update
    apt-get install psmisc -y || abort
  fi
fi
if ! dpkg -l gnupg 2> /dev/null | awk '{print $1}' | grep -iq "^ii"; then
  if ! apt-get install gnupg -y; then
    if [[ "${os_codename}" =~ (precise|maya) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu precise-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu precise-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu trusty-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu trusty-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu xenial-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu xenial-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (bionic|tara|tessa|tina|tricia) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu bionic-security main universe") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu bionic-security main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "cosmic" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu cosmic-security main universe") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu cosmic-security main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "disco" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu disco main universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu disco main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "eoan" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu eoan main universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu eoan main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "jessie" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian jessie main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian jessie main  >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" =~ (stretch|continuum) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian stretch main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian stretch main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "buster" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian buster main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian buster main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${os_codename}" == "bullseye" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian bullseye main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian bullseye main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    run_apt_get_update
    apt-get install gnupg -y || abort
  fi
fi

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                            Variables                                                                                            #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

MONGODB_ORG_SERVER=$(dpkg -l | grep "^ii" | grep "mongodb-org-server" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//g')
MONGODB_ORG_MONGOS=$(dpkg -l | grep "^ii" | grep "mongodb-org-mongos" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//g')
MONGODB_ORG_SHELL=$(dpkg -l | grep "^ii" | grep "mongodb-org-shell" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//g')
MONGODB_ORG_TOOLS=$(dpkg -l | grep "^ii" | grep "mongodb-org-tools" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//g')
MONGODB_ORG=$(dpkg -l | grep "^ii" | grep "mongodb-org" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//g')
MONGODB_SERVER=$(dpkg -l | grep "^ii" | grep "mongodb-server" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//g')
MONGODB_CLIENTS=$(dpkg -l | grep "^ii" | grep "mongodb-clients" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//g')
MONGODB_SERVER_CORE=$(dpkg -l | grep "^ii" | grep "mongodb-server-core" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//g')
MONGO_TOOLS=$(dpkg -l | grep "^ii" | grep "mongo-tools" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//g')
#
system_memory=$(awk '/MemTotal/ {printf( "%.0f\n", $2 / 1024 / 1024)}' /proc/meminfo)
system_swap=$(awk '/SwapTotal/ {printf( "%.0f\n", $2 / 1024 / 1024)}' /proc/meminfo)
#system_free_disk_space=$(df -h / | grep "/" | awk '{print $4}' | sed 's/G//')
system_free_disk_space=$(df -k / | awk '{print $4}' | tail -n1)
#
#SERVER_IP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -1)
#SERVER_IP=$(/sbin/ifconfig | grep 'inet ' | grep -v '127.0.0.1' | head -n1 | awk '{print $2}' | head -1 | sed 's/.*://')
SERVER_IP=$(ip addr | grep -A8 -m1 MULTICAST | grep -m1 inet | cut -d' ' -f6 | cut -d'/' -f1)
if [[ -z "${SERVER_IP}" ]]; then SERVER_IP=$(hostname -I | head -n 1 | awk '{ print $NF; }'); fi
PUBLIC_SERVER_IP=$(curl https://ip.glennr.nl/ -s)
architecture=$(dpkg --print-architecture)
os_codename=$(lsb_release -cs | tr '[:upper:]' '[:lower:]')
if [[ "${os_codename}" == 'n/a' ]]; then
  os_codename=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
  if [[ "${os_codename}" == 'parrot' ]]; then
    os_codename='buster'
  fi
fi
#
#JAVA8=$(dpkg -l | grep -c "openjdk-8-jre-headless\\|oracle-java8-installer")
mongodb_server_installed=$(dpkg -l | grep "^ii" | grep -c "mongodb-server\\|mongodb-org-server")
mongodb_version=$(dpkg -l | grep "mongodb-server\|mongodb-org-server" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//' | sed 's/\.//g')

unsupported_java_installed=''
openjdk_8_installed=''
remote_controller=''
debian_64_mongo=''
openjdk_repo=''
debian_32_run_fix=''
unifi_dependencies=''
mongodb_key_fail=''
port_8080_in_use=''
port_8080_pid=''
port_8080_service=''
port_8443_in_use=''
port_8443_pid=''
port_8443_service=''

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                             Checks                                                                                              #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

if [ "${system_free_disk_space}" -lt "5000000" ]; then
  clear
  header_red
  echo -e "${WHITE_R}#${RESET} Free disk space is below 5GB.. Please expand the disk size!"
  echo -e "${WHITE_R}#${RESET} I recommend expanding to atleast 10GB"
  echo ""
  echo ""
  if [[ "${script_option_skip}" != 'true' ]]; then
    read -rp "Do you want to proceed at your own risk? (Y/n)" yes_no
    case "$yes_no" in
        [Yy]*|"") ;;
        [Nn]*) cancel_script;;
    esac
  else
    cancel_script
  fi
fi


# MongoDB version check.
if [[ "${MONGODB_ORG_SERVER}" > "3.4.999" || "${MONGODB_ORG_MONGOS}" > "3.4.999" || "${MONGODB_ORG_SHELL}" > "3.4.999" || "${MONGODB_ORG_TOOLS}" > "3.4.999" || "${MONGODB_ORG}" > "3.4.999" || "${MONGODB_SERVER}" > "3.4.999" || "${MONGODB_CLIENTS}" > "3.4.999" || "${MONGODB_SERVER_CORE}" > "3.4.999" || "${MONGO_TOOLS}" > "3.4.999" ]]; then
  clear
  header_red
  echo -e "${WHITE_R}#${RESET} UniFi does not support MongoDB 3.6 or newer.."
  echo -e "${WHITE_R}#${RESET} Do you want to uninstall the unsupported MongoDB version?"
  echo ""
  echo -e "${WHITE_R}#${RESET} This will also uninstall any other package depending on MongoDB!"
  echo -e "${WHITE_R}#${RESET} I highly recommend creating a backup/snapshot of your machine/VM"
  echo ""
  echo ""
  echo ""
  read -rp "Do you want to proceed with uninstalling MongoDB? (Y/n)" yes_no
  case "$yes_no" in
      [Yy]*|"")
        clear
        header
        echo -e "${WHITE_R}#${RESET} Uninstalling MongoDB!"
        if dpkg -l | grep "unifi " | grep -q "^ii"; then
          echo -e "${WHITE_R}#${RESET} Removing UniFi to keep system files!"
        fi
        if dpkg -l | grep "unifi-video" | grep -q "^ii"; then
          echo -e "${WHITE_R}#${RESET} Removing UniFi-Video to keep system files!"
        fi
        echo ""
        echo ""
        echo ""
        sleep 3
        rm /etc/apt/sources.list.d/mongo*.list
        if dpkg -l | grep "unifi " | grep -q "^ii"; then
          dpkg --remove --force-remove-reinstreq unifi || abort
        fi
        if dpkg -l | grep "unifi-video" | grep -q "^ii"; then
          dpkg --remove --force-remove-reinstreq unifi-video || abort
        fi
        if ! apt-get purge mongo* -y; then
          clear
          header_red
          echo -e "${WHITE_R}#${RESET} Failed to uninstall MongoDB!"
          echo -e "${WHITE_R}#${RESET} Uninstalling MongoDB with different actions!"
          echo ""
          echo ""
          echo ""
          sleep 2
          apt-get --fix-broken install -y || apt-get install -f -y
          apt-get autoremove -y
          if dpkg -l mongodb-org 2> /dev/null | awk '{print $1}' | grep -iq "^ii"; then
            dpkg --remove --force-remove-reinstreq mongodb-org || abort
          fi
          if dpkg -l mongodb-org-tools 2> /dev/null | awk '{print $1}' | grep -iq "^ii"; then
            dpkg --remove --force-remove-reinstreq mongodb-org-tools || abort
          fi
          if dpkg -l mongodb-org-server 2> /dev/null | awk '{print $1}' | grep -iq "^ii"; then
            dpkg --remove --force-remove-reinstreq mongodb-org-server || abort
          fi
          if dpkg -l mongodb-org-mongos 2> /dev/null | awk '{print $1}' | grep -iq "^ii"; then
            dpkg --remove --force-remove-reinstreq mongodb-org-mongos || abort
          fi
          if dpkg -l mongodb-org-shell 2> /dev/null | awk '{print $1}' | grep -iq "^ii"; then
            dpkg --remove --force-remove-reinstreq mongodb-org-shell || abort
          fi
          if dpkg -l mongodb-server 2> /dev/null | awk '{print $1}' | grep -iq "^ii"; then
            dpkg --remove --force-remove-reinstreq mongodb-server || abort
          fi
          if dpkg -l mongodb-clients 2> /dev/null | awk '{print $1}' | grep -iq "^ii"; then
            dpkg --remove --force-remove-reinstreq mongodb-clients || abort
          fi
          if dpkg -l mongodb-server-core 2> /dev/null | awk '{print $1}' | grep -iq "^ii"; then
            dpkg --remove --force-remove-reinstreq mongodb-server-core || abort
          fi
          if dpkg -l mongo-tools 2> /dev/null | awk '{print $1}' | grep -iq "^ii"; then
            dpkg --remove --force-remove-reinstreq mongo-tools || abort
          fi
        fi
        apt-get autoremove -y || abort
        apt-get clean -y || abort;;
      [Nn]*) cancel_script;;
  esac
fi

# Memory and Swap file.
if [[ "${system_swap}" == "0" && "${system_memory}" -lt "2" ]]; then
  clear
  header_red
  echo -e "${WHITE_R}#${RESET} System memory is lower than recommended!"
  echo -e "${WHITE_R}#${RESET} Creating swap file."
  echo ""
  echo ""
  sleep 2
  if [[ "${system_free_disk_space}" -ge "10000000" ]]; then
    echo -e "${WHITE_R}---${RESET}"
    echo ""
    echo -e "${WHITE_R}#${RESET} You have more than 10GB of free disk space!"
    echo -e "${WHITE_R}#${RESET} We are creating a 2GB swap file!"
    echo ""
    dd if=/dev/zero of=/swapfile bs=2048 count=1048576 &>/dev/null
    chmod 600 /swapfile &>/dev/null
    mkswap /swapfile &>/dev/null
    swapon /swapfile &>/dev/null
    echo "/swapfile swap swap defaults 0 0" | tee -a /etc/fstab &>/dev/null
  elif [[ "${system_free_disk_space}" -ge "5000000" ]]; then
    echo -e "${WHITE_R}---${RESET}"
    echo ""
    echo -e "${WHITE_R}#${RESET} You have more than 5GB of free disk space."
    echo -e "${WHITE_R}#${RESET} We are creating a 1GB swap file.."
    echo ""
    dd if=/dev/zero of=/swapfile bs=1024 count=1048576 &>/dev/null
    chmod 600 /swapfile &>/dev/null
    mkswap /swapfile &>/dev/null
    swapon /swapfile &>/dev/null
    echo "/swapfile swap swap defaults 0 0" | tee -a /etc/fstab &>/dev/null
  elif [[ "${system_free_disk_space}" -ge "4000000" ]]; then
    echo -e "${WHITE_R}---${RESET}"
    echo ""
    echo -e "${WHITE_R}#${RESET} You have more than 4GB of free disk space."
    echo -e "${WHITE_R}#${RESET} We are creating a 256MB swap file.."
    echo ""
    dd if=/dev/zero of=/swapfile bs=256 count=1048576 &>/dev/null
    chmod 600 /swapfile &>/dev/null
    mkswap /swapfile &>/dev/null
    swapon /swapfile &>/dev/null
    echo "/swapfile swap swap defaults 0 0" | tee -a /etc/fstab &>/dev/null
  elif [[ "${system_free_disk_space}" -lt "4000000" ]]; then
    echo -e "${WHITE_R}---${RESET}"
    echo ""
    echo -e "${WHITE_R}#${RESET} Your free disk space is extremely low!"
    echo -e "${WHITE_R}#${RESET} There is not enough free disk space to create a swap file.."
    echo ""
    echo -e "${WHITE_R}#${RESET} I highly recommend upgrading the system memory to atleast 2GB and expanding the disk space!"
    echo -e "${WHITE_R}#${RESET} The script will continue the script at your own risk.."
    echo ""
   sleep 10
  fi
else
  clear
  header
  echo -e "${WHITE_R}#${RESET} A swap file already exists!"
  echo ""
  echo ""
  sleep 2
fi

if [[ -d /tmp/EUS/services ]]; then
  cat /tmp/EUS/services/stopped_list &>> /tmp/EUS/services/stopped_services
  find /tmp/EUS/services/ -type f -printf "%f\\n" | sed 's/ //g' | sed '/file_list/d' | sed '/stopped_services/d' &> /tmp/EUS/services/file_list
  while read -r file; do
    rm --force "/tmp/EUS/services/${file}" &> /dev/null
  done < /tmp/EUS/services/file_list
  rm --force /tmp/EUS/services/file_list &> /dev/null
fi

if netstat -tulpn | grep -q ":8080\\b"; then
  port_8080_pid=$(netstat -tulpn | grep ":8080\\b" | awk '{print $7}' | sed 's/[/].*//g' | head -n1)
  port_8080_service=$(head -n1 "/proc/${port_8080_pid}/comm")
  # shellcheck disable=SC2012
  if [[ "$(ls -l "/proc/${port_8080_pid}/exe" 2> /dev/null | awk '{print $3}')" != "unifi" ]]; then
    port_8080_in_use=true
    if ! [[ -d /tmp/EUS/services ]]; then mkdir -p /tmp/EUS/services; fi
    echo -e "${port_8080_service}" &>> /tmp/EUS/services/list
    echo -e "${port_8080_pid}" &>> /tmp/EUS/services/pid_list
  fi
fi
if netstat -tulpn | grep -q ":8443\\b"; then
  port_8443_pid=$(netstat -tulpn | grep ":8443\\b" | awk '{print $7}' | sed 's/[/].*//g' | head -n1)
  port_8443_service=$(head -n1 "/proc/${port_8443_pid}/comm")
  # shellcheck disable=SC2012
  if [[ "$(ls -l "/proc/${port_8443_pid}/exe" 2> /dev/null | awk '{print $3}')" != "unifi" ]]; then
    port_8443_in_use=true
    if ! [[ -d /tmp/EUS/services ]]; then mkdir -p /tmp/EUS/services; fi
    echo -e "${port_8443_service}" &>> /tmp/EUS/services/list
    echo -e "${port_8443_pid}" &>> /tmp/EUS/services/pid_list
  fi
fi

check_port() {
  if ! [[ "${port}" =~ ${reg} ]]; then
    clear
    header_red
    echo -e "${WHITE_R}#${RESET} '${port}' is not a valid format, please only use numbers ( 0-9 )" && sleep 3
    change_default_ports
  elif [[ "${port}" -le "1024" || "${port}" -gt "65535" ]]; then
    clear
    header_red
    echo -e "${WHITE_R}#${RESET} '${port}' needs to be between 1025 and 65535.." && sleep 3
    change_default_ports
  else
    if netstat -tulpn | grep -q ":${port}\\b"; then
      clear
      header_red
      echo -e "${WHITE_R}#${RESET} '${port}' Is already in use by another process.." && sleep 3
      change_default_ports
    elif grep "${port}" /tmp/EUS/services/new_ports 2> /dev/null; then
      clear
      header_red
      echo -e "${WHITE_R}#${RESET} '${port}' will already be used for the UniFi Network Controller.." && sleep 3
      change_default_ports
    elif [[ "${change_unifi_ports}" == 'true' && "${port}" == "${port_number}" ]]; then
      clear
      header_red
      echo -e "${WHITE_R}#${RESET} '${port}' Is already used by the service we stopped.." && sleep 3
      change_default_ports
    else
      echo -e "${WHITE_R}#${RESET} '${port}' Is available, we will use this for the ${port_usage}.."
      echo -e "${port_number}" &>> /tmp/EUS/services/success_port_change
      echo -e "${port}" &>> /tmp/EUS/services/new_ports
    fi
  fi
}

change_default_ports() {
  if [[ "${port_8080_in_use}" == 'true' ]] && ! grep "8080" /tmp/EUS/services/success_port_change 2> /dev/null; then
    port_usage="Device Inform"
    port_number="8080"
    reg='^[0-9]'
    echo -e "\\n${WHITE_R}----${RESET}\\n\\n${WHITE_R}#${RESET} Changing the default Device Inform port.."
	if [[ "${script_option_skip}" != 'true' ]]; then
      read -n 5 -rp $'\033[39m#\033[0m Device Inform Port | \033[39m' port
    else
      netstat -tulpn  &> /tmp/EUS/services/netstat
      if ! grep -q ":8081\\b" /tmp/EUS/services/netstat; then
        port="8081"
      elif ! grep -q ":8082\\b" /tmp/EUS/services/netstat; then
        port="8082"
      elif ! grep -q ":8083\\b" /tmp/EUS/services/netstat; then
        port="8083"
      elif ! grep -q ":8084\\b" /tmp/EUS/services/netstat; then
        port="8084"
      fi
    fi
    check_port
    if ! grep "^unifi.http.port=" /usr/lib/unifi/data/system.properties; then echo -e "unifi.http.port=${port}" &>> /usr/lib/unifi/data/system.properties && echo -e "${GREEN}#${RESET} Successfully changed the Device Inform port to '${port}'!"; else echo -e "${RED}#${RESET} Failed to change the Device Inform port."; fi
  fi
  if [[ "${port_8443_in_use}" == 'true' ]] && ! grep "8443" /tmp/EUS/services/success_port_change 2> /dev/null; then
    port_usage="Management Dashboard"
    port_number="8443"
    reg='^[0-9]'
    echo -e "\\n${WHITE_R}----${RESET}\\n\\n${WHITE_R}#${RESET} Changing the default Controller Dashboard port.."
	if [[ "${script_option_skip}" != 'true' ]]; then
      read -n 5 -rp $'\033[39m#\033[0m Controller Dashboard Port | \033[39m' port
    else
      netstat -tulpn  &> /tmp/EUS/services/netstat
      if ! grep -q ":1443\\b" /tmp/EUS/services/netstat; then
        port="1443"
      elif ! grep -q ":2443\\b" /tmp/EUS/services/netstat; then
        port="2443"
      elif ! grep -q ":3443\\b" /tmp/EUS/services/netstat; then
        port="3443"
      elif ! grep -q ":4443\\b" /tmp/EUS/services/netstat; then
        port="4443"
      fi
    fi
    check_port
    if ! grep "^unifi.https.port=" /usr/lib/unifi/data/system.properties; then echo -e "unifi.https.port=${port}" &>> /usr/lib/unifi/data/system.properties && echo -e "${GREEN}#${RESET} Successfully changed the Management Dashboard port to '${port}'!"; else echo -e "${RED}#${RESET} Failed to change the Management Dashboard port."; fi
  fi
  sleep 3
  if [[ -f /tmp/EUS/services/success_port_change && -s /tmp/EUS/services/success_port_change ]]; then
    clear
    header
    echo -e "${WHITE_R}#${RESET} Starting the UniFi Network Controller.."
    systemctl start unifi
    if systemctl status unifi | grep -iq "Active: active (running)"; then
      echo -e "${GREEN}#${RESET} Successfully started the UniFi Network Controller!"
    else
      echo -e "${RED}#${RESET} Failed to start the UniFi Network Controller." && abort
    fi
    sleep 3
  fi
  if [[ "${change_unifi_ports}" != 'false' ]]; then
    while read -r service; do
      echo -e "\\n${WHITE_R}#${RESET} Starting ${service}.."
      systemctl start "${service}" && echo -e "${GREEN}#${RESET} Successfully started ${service}!" || echo -e "${RED}#${RESET} Failed to start ${service}!"
    done < /tmp/EUS/services/stopped_list
    sleep 3
  fi
}

if [[ "${port_8080_in_use}" == 'true' || "${port_8443_in_use}" == 'true' ]]; then
  cp /tmp/EUS/services/pid_list /tmp/EUS/services/pid_list_tmp && awk '!a[$0]++' < /tmp/EUS/services/pid_list_tmp &> /tmp/EUS/services/pid_list && rm --force /tmp/EUS/services/pid_list_tmp
  cp /tmp/EUS/services/list /tmp/EUS/services/list_tmp && awk '!a[$0]++' < /tmp/EUS/services/list_tmp &> /tmp/EUS/services/list && rm --force /tmp/EUS/services/list_tmp
  clear
  header_red
  echo -e "${RED}#${RESET} The following service(s) is/are running on a port that the UniFi Network Controller wants to use as well.."
  while read -r service; do echo -e "${RED}-${RESET} ${service}"; done < /tmp/EUS/services/list
  echo ""
  if [[ "${script_option_skip}" != 'true' ]]; then
    read -rp $'\033[39m#\033[0m Do you want to let the script change the default UniFi Network Controller port(s)? (Y/n) ' yes_no
  else
    echo -e "${WHITE_R}#${RESET} Script will change the default UniFi Controller Ports.."
    sleep 2
  fi
  case "$yes_no" in
      [Yy]*|"") change_unifi_ports=true;;
      [Nn]*) change_unifi_ports=false && echo -e "\\n${WHITE_R}----${RESET}\\n\\n${RED}#${RESET} The script will keep the services stopped, you need to manually change the conflicting ports of these services and then start them again..";;
  esac
  if [[ "${script_option_skip}" != 'true' ]]; then
    read -rp $'\033[39m#\033[0m Can we temporarily stop the service(s)? (Y/n) ' yes_no
  else
    echo -e "${WHITE_R}#${RESET} Temporarily stopping the services.."
    sleep 2
  fi
  case "$yes_no" in
      [Yy]*|"")
        echo -e "\\n${WHITE_R}----${RESET}\\n"
        while read -r service; do
          echo -e "${WHITE_R}#${RESET} Trying to stop ${service}..."
          systemctl stop "${service}" 2> /dev/null && echo -e "${service}" &>> /tmp/EUS/services/stopped_list
          if grep -iq "${service}" /tmp/EUS/services/stopped_list; then echo -e "${GREEN}#${RESET} Successfully stopped ${service}!"; else echo -e "${RED}#${RESET} Failed to stop ${service}.." && echo -e "${service}" &>> /tmp/EUS/services/stopped_failed_list; fi
        done < /tmp/EUS/services/list
        sleep 2
        if [[ -f /tmp/EUS/services/stopped_failed_list && -s /tmp/EUS/services/stopped_failed_list ]]; then
          echo -e "\\n${WHITE_R}----${RESET}\\n"
          echo -e "${RED}#${RESET} The script failed to stop the following service(s).."
          while read -r service; do echo -e "${RED}-${RESET} ${service}"; done < /tmp/EUS/services/stopped_failed_list
          echo -e "${RED}#${RESET} We can try to kill the PID(s) of these services(s) but the script won't be able to start the service(s) again after completion.."
          if [[ "${script_option_skip}" != 'true' ]]; then
            read -rp $'\033[39m#\033[0m Can we proceed with killing the PID? (y/N) ' yes_no
          else
            echo -e "${WHITE_R}#${RESET} Killing the PID(s).."
            sleep 2
          fi
          case "$yes_no" in
              [Yy]*)
                echo -e "\\n${WHITE_R}----${RESET}\\n"
                while read -r pid; do
                  echo -e "${WHITE_R}#${RESET} Trying to kill ${pid}..."
                  kill -9 "${pid}" 2> /dev/null && echo -e "${pid}" &>> /tmp/EUS/services/killed_pid_list
                  if grep -iq "${pid}" /tmp/EUS/services/killed_pid_list; then echo -e "${GREEN}#${RESET} Successfully killed PID ${pid}!"; else echo -e "${RED}#${RESET} Failed to kill PID ${pid}.." && echo -e "${pid}" &>> /tmp/EUS/services/failed_killed_pid_list; fi
                done < /tmp/EUS/services/pid_list
                sleep 2
                if [[ -f /tmp/EUS/services/failed_killed_pid_list && -s /tmp/EUS/services/failed_killed_pid_list ]]; then
                  while read -r failed_pid; do
                    echo -e "${RED}-${RESET} PID ${failed_pid}..."
                  done < /tmp/EUS/services/failed_killed_pid_list
                  echo -e "${RED}#${RESET} You will have to change the following default post(s) yourself after the installation completed.."
                  if [[ "${port_8080_in_use}" == 'true' ]]; then
                    echo -e "${RED}-${RESET} 8080 ( Device Inform )"
                  fi
                  if [[ "${port_8443_in_use}" == 'true' ]]; then
                    echo -e "${RED}-${RESET} 8443 ( Management Dashboard )"
                  fi
                  sleep 5
                fi;;
              [Nn]*|"") ;;
          esac
        fi
        sleep 2;;
      [Nn]*)
        clear
        header_red
        echo -e "${RED}#${RESET} Continuing your UniFi Network Controller install."
        echo -e "${RED}#${RESET} Please be aware that your controller won't be able to start.."
        sleep 5;;
  esac
fi

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                  Ask to keep script or delete                                                                                   #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

script_removal() {
  header
  read -rp $'\033[39m#\033[0m Do you want to keep the script on your system after completion? (Y/n) ' yes_no
  case "$yes_no" in
      [Yy]*|"") ;;
      [Nn]*) delete_script=true;;
  esac
}

if [[ "${script_option_skip}" != 'true' ]]; then
  script_removal
fi

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                 Installation Script starts here                                                                                 #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

apt_mongodb_check() {
  run_apt_get_update
  MONGODB_ORG_CACHE=$(apt-cache madison mongodb-org | awk '{print $3}' | sort -V | tail -n 1 | sed 's/\.//g')
  MONGODB_CACHE=$(apt-cache madison mongodb | awk '{print $3}' | sort -V | tail -n 1 | sed 's/-.*//' | sed 's/.*://' | sed 's/\.//g')
  MONGO_TOOLS_CACHE=$(apt-cache madison mongo-tools | awk '{print $3}' | sort -V | tail -n 1 | sed 's/-.*//' | sed 's/.*://' | sed 's/\.//g')
}

set_hold_mongodb_org=''
set_hold_mongodb=''
set_hold_mongo_tools=''

clear
header
echo -e "${WHITE_R}#${RESET} Getting the latest patches for your machine!"
echo ""
echo ""
echo ""
sleep 2
apt_mongodb_check
if [[ "${MONGODB_ORG_CACHE::2}" -gt "34" ]]; then
  if [[ $(dpkg --get-selections | grep "mongodb-org" | awk '{print $2}' | grep -c "install") -ne 0 ]]; then
    echo "mongodb-org hold" | dpkg --set-selections 2> /dev/null || abort
    echo "mongodb-org-mongos hold" | dpkg --set-selections 2> /dev/null || abort
    echo "mongodb-org-server hold" | dpkg --set-selections 2> /dev/null || abort
    echo "mongodb-org-shell hold" | dpkg --set-selections 2> /dev/null || abort
    echo "mongodb-org-tools hold" | dpkg --set-selections 2> /dev/null || abort
    set_hold_mongodb_org=true
  fi
fi
if [[ "${MONGODB_CACHE::2}" -gt "34" ]]; then
  if [[ $(dpkg --get-selections | grep "mongodb-server" | awk '{print $2}' | grep -c "install") -ne 0 ]]; then
    echo "mongodb hold" | dpkg --set-selections 2> /dev/null || abort
    echo "mongodb-server hold" | dpkg --set-selections 2> /dev/null || abort
    echo "mongodb-server-core hold" | dpkg --set-selections 2> /dev/null || abort
    echo "mongodb-clients hold" | dpkg --set-selections 2> /dev/null || abort
    set_hold_mongodb=true
  fi
fi
if [[ "${MONGO_TOOLS_CACHE::2}" -gt "34" ]]; then
  if [[ $(dpkg --get-selections | grep "mongo-tools" | awk '{print $2}' | grep -c "install") -ne 0 ]]; then
    echo "mongo-tools hold" | dpkg --set-selections 2> /dev/null || abort
    set_hold_mongo_tools=true
  fi
fi
run_apt_get_update
DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' upgrade || abort
DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' dist-upgrade || abort
apt-get autoremove -y || abort
apt-get autoclean -y || abort
if [[ "${set_hold_mongodb_org}" == 'true' ]]; then
  echo "mongodb-org install" | dpkg --set-selections 2> /dev/null || abort
  echo "mongodb-org-mongos install" | dpkg --set-selections 2> /dev/null || abort
  echo "mongodb-org-server install" | dpkg --set-selections 2> /dev/null || abort
  echo "mongodb-org-shell install" | dpkg --set-selections 2> /dev/null || abort
  echo "mongodb-org-tools install" | dpkg --set-selections 2> /dev/null || abort
fi
if [[ "${set_hold_mongodb}" == 'true' ]]; then
  echo "mongodb install" | dpkg --set-selections 2> /dev/null || abort
  echo "mongodb-server install" | dpkg --set-selections 2> /dev/null || abort
  echo "mongodb-server-core install" | dpkg --set-selections 2> /dev/null || abort
  echo "mongodb-clients install" | dpkg --set-selections 2> /dev/null || abort
fi
if [[ "${set_hold_mongo_tools}" == 'true' ]]; then
  echo "mongo-tools install" | dpkg --set-selections 2> /dev/null || abort
fi

# MongoDB check
mongodb_server_installed=$(dpkg -l | grep "^ii" | grep -c "mongodb-server\\|mongodb-org-server")

ubuntu_32_mongo() {
  clear
  header
  echo -e "${WHITE_R}#${RESET} 32 bit system detected!"
  echo -e "${WHITE_R}#${RESET} Installing MongoDB for 32 bit systems!"
  echo ""
  echo ""
  echo ""
  sleep 2
}

debian_32_mongo() {
  debian_32_run_fix=true
  clear
  header
  echo -e "${WHITE_R}#${RESET} 32 bit system detected!"
  echo -e "${WHITE_R}#${RESET} Skipping MongoDB installation!"
  echo ""
  echo ""
  echo ""
  sleep 2
}

mongodb_26_key() {
  echo "7F0CEB10" &>> /tmp/EUS/keys/missing_keys
  run_apt_get_update
  if [[ "${mongodb_key_fail}" == "true" ]]; then
    wget -qO - https://www.mongodb.org/static/pgp/server-2.6.asc | apt-key add - || abort
  fi
}

mongodb_34_key() {
  #echo "0C49F3730359A14518585931BC711F9BA15703C6" &>> /tmp/EUS/keys/missing_keys
  #run_apt_get_update
  #if [[ $mongodb_key_fail == "true" ]]; then
  wget -qO - https://www.mongodb.org/static/pgp/server-3.4.asc | apt-key add - || abort
  #fi
}

if [[ "${os_codename}" =~ (disco|eoan) && "${architecture}" =~ (amd64|arm64) ]]; then
  clear
  header
  echo -e "${WHITE_R}#${RESET} Installing a required package.."
  echo ""
  echo ""
  echo ""
  sleep 2
  libssl_temp="$(mktemp --tmpdir=/tmp libssl1.0.2_XXXXX.deb)" || abort
  if [[ "${architecture}" == "amd64" ]]; then
    wget -O "$libssl_temp" 'http://security.ubuntu.com/ubuntu/pool/main/o/openssl1.0/libssl1.0.0_1.0.2n-1ubuntu5.3_amd64.deb' || abort
  fi
  if [[ "${architecture}" == "arm64" ]]; then
    wget -O "$libssl_temp" 'https://launchpad.net/ubuntu/+source/openssl1.0/1.0.2n-1ubuntu5/+build/14503127/+files/libssl1.0.0_1.0.2n-1ubuntu5_arm64.deb' || abort
  fi
  dpkg -i "$libssl_temp"
  rm --force "$libssl_temp" 2> /dev/null
fi

clear
header
echo -e "${WHITE_R}#${RESET} The latest patches are installed on your system!"
echo -e "${WHITE_R}#${RESET} Installing MongoDB..."
echo ""
echo ""
echo ""
sleep 2
if ! [[ "${mongodb_server_installed}" -eq 1 ]]; then
  if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "mongodb.org") -gt 0 ]]; then
    grep -riIl "mongodb.org" /etc/apt/ >> /tmp/EIS_mongodb_repositories
    while read -r EUS_repositories; do
      sed -i '/mongodb.org/d' "${EUS_repositories}" 2> /dev/null
      if ! [[ -s "${EUS_repositories}" ]]; then
        rm --force "${EUS_repositories}" 2> /dev/null
      fi
    done < /tmp/EIS_mongodb_repositories
    rm --force /tmp/EIS_mongodb_repositories 2> /dev/null
  fi
  if [[ "${os_codename}" =~ (precise|maya|trusty|qiana|rebecca|rafaela|rosa|xenial|sarah|serena|sonya|sylvia) && ! "${architecture}" =~ (amd64|arm64) ]]; then
    ubuntu_32_mongo
    #mongodb_26_key
    if ! apt-get install -y mongodb-server mongodb-clients; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -P -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu xenial main universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu xenial main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
        run_apt_get_update
      fi
	  if ! apt-get install -y mongodb-server mongodb-clients; then
        apt-get install -f
        apt-get install -y mongodb-server mongodb-clients || abort
      fi
    fi
  elif [[ "${os_codename}" =~ (bionic|tara|tessa|tina|tricia|disco|eoan) && "${architecture}" == "i386" ]]; then
    ubuntu_32_mongo
    libssl_temp="$(mktemp --tmpdir=/tmp libssl1.0.2_XXXXX.deb)" || abort
    wget -O "$libssl_temp" 'http://ftp.nl.debian.org/debian/pool/main/o/openssl1.0/libssl1.0.2_1.0.2s-1~deb9u1_i386.deb' || abort
    dpkg -i "$libssl_temp"
    rm --force "$libssl_temp" 2> /dev/null
    if [[ "${os_codename}" =~ (disco|eoan) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -P -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu bionic main universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu bionic main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
        run_apt_get_update
      fi
    fi
    apt-get install -y libboost-chrono1.62.0 libboost-filesystem1.62.0 libboost-program-options1.62.0 libboost-regex1.62.0 libboost-system1.62.0 libboost-thread1.62.0 libgoogle-perftools4 libpcap0.8 libpcrecpp0v5 libsnappy1v5 libstemmer0d libyaml-cpp0.5v5
    mongo_tools_temp="$(mktemp --tmpdir=/tmp mongo_tools-3.2.22_XXXXX.deb)" || abort
    wget -O "$mongo_tools_temp" 'http://ftp.nl.debian.org/debian/pool/main/m/mongo-tools/mongo-tools_3.2.11-1+b2_i386.deb' || abort
    dpkg -i "$mongo_tools_temp"
    rm --force "$mongo_tools_temp" 2> /dev/null
    mongodb_clients_temp="$(mktemp --tmpdir=/tmp mongodb_clients-3.2.22_XXXXX.deb)" || abort
    wget -O "$mongodb_clients_temp" 'http://ftp.nl.debian.org/debian/pool/main/m/mongodb/mongodb-clients_3.2.11-2+deb9u1_i386.deb' || abort
    dpkg -i "$mongodb_clients_temp"
    rm --force "$mongodb_clients_temp" 2> /dev/null
    mongodb_server_temp="$(mktemp --tmpdir=/tmp mongodb_clients-3.2.22_XXXXX.deb)" || abort
    wget -O "$mongodb_server_temp" 'http://ftp.nl.debian.org/debian/pool/main/m/mongodb/mongodb-server_3.2.11-2+deb9u1_i386.deb' || abort
    dpkg -i "$mongodb_server_temp"
    rm --force "$mongodb_server_temp" 2> /dev/null
  elif [[ "${os_codename}" =~ (precise|maya) && "${architecture}" =~ (amd64|arm64) ]]; then
    mongodb_34_key
    echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu precise/mongodb-org/3.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.4.list
    run_apt_get_update
    apt-get install -y mongodb-org || abort
  elif [[ "${os_codename}" =~ (trusty|qiana|rebecca|rafaela|rosa) && "${architecture}" =~ (amd64|arm64) ]]; then
    mongodb_34_key
    echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.4.list
    run_apt_get_update
    apt-get install -y mongodb-org || abort
  elif [[ "${os_codename}" =~ (xenial|bionic|cosmic|disco|eoan|sarah|serena|sonya|sylvia|tara|tessa|tina|tricia) && "${architecture}" =~ (amd64|arm64) ]]; then
    mongodb_34_key
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.4.list || abort
    run_apt_get_update
    apt-get install -y mongodb-org || abort
  elif [[ "${os_codename}" =~ (jessie|stretch|continuum|buster|bullseye) ]]; then
    if [[ ! "${architecture}" =~ (amd64|arm64) ]]; then
      debian_32_mongo
    fi
    if [[ "${os_codename}" == "jessie" && "${architecture}" =~ (amd64|arm64) ]]; then
      echo "deb https://repo.mongodb.org/apt/debian jessie/mongodb-org/3.4 main" | tee /etc/apt/sources.list.d/mongodb-org-3.4.list || abort
      debian_64_mongo=install
    elif [[ "${os_codename}" =~ (stretch|continuum|buster|bullseye) && "${architecture}" =~ (amd64|arm64) ]]; then
      echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.4.list || abort
      libssl_temp="$(mktemp --tmpdir=/tmp libssl1.0.2_XXXXX.deb)" || abort
      if [[ "${architecture}" == "amd64" ]]; then
        wget -O "$libssl_temp" 'http://security.ubuntu.com/ubuntu/pool/main/o/openssl1.0/libssl1.0.0_1.0.2n-1ubuntu5.3_amd64.deb' || abort
      fi
      if [[ "${architecture}" == "arm64" ]]; then
        wget -O "$libssl_temp" 'https://launchpad.net/ubuntu/+source/openssl1.0/1.0.2n-1ubuntu5/+build/14503127/+files/libssl1.0.0_1.0.2n-1ubuntu5_arm64.deb' || abort
      fi
      dpkg -i "$libssl_temp"
      rm --force "$libssl_temp" 2> /dev/null
      debian_64_mongo=install
    fi
    if [ "${debian_64_mongo}" == 'install' ]; then
      mongodb_34_key
      run_apt_get_update
      apt-get install -y mongodb-org || abort
    fi
  else
    header_red
    echo -e "${RED}#${RESET} The script is unable to grab your OS ( or does not support it )"
    echo "${architecture}"
    echo "${os_codename}"
    abort
  fi
else
  clear
  header
  echo -e "${WHITE_R}#${RESET} MongoDB is already installed..."
  echo ""
  echo ""
  echo ""
  sleep 2
fi

if [[ "${architecture}" == "armhf" ]]; then
  clear
  header
  echo -e "${WHITE_R}#${RESET} Trying to use raspbian repo to install MongoDB..."
  echo ""
  echo ""
  echo 'deb http://archive.raspbian.org/raspbian stretch main contrib non-free rpi' | tee /etc/apt/sources.list.d/glennr_armhf.list
  wget https://archive.raspbian.org/raspbian.public.key -O - | apt-key add -
  run_apt_get_update
  apt-get install -y mongodb-server mongodb-clients || apt-get install -f || abort
  if ! dpkg -l | grep "^ii" | grep "mongodb-server"; then
    echo -e "${RED}#${RESET} mongodb-server failed to install.." && abort
  fi
  if ! dpkg -l | grep "^ii" | grep "mongodb-clients"; then
    echo -e "${RED}#${RESET} mongodb-clients failed to install.." && abort
  fi
fi

clear
header
echo -e "${WHITE_R}#${RESET} MongoDB has been installed successfully!"
echo -e "${WHITE_R}#${RESET} Installing OpenJDK 8..."
echo ""
echo ""
echo ""
sleep 2
openjdk_version=$(dpkg -l | grep "^ii" | grep "openjdk-8" | awk '{print $3}' | grep "^8u" | sed 's/-.*//g' | sed 's/8u//g' | grep -o '[[:digit:]]*' | sort -V | tail -n 1)
if [[ "${openjdk_version}" -lt "131" ]]; then
  old_openjdk_version=true
fi
if ! dpkg -l | grep "^ii" | grep -iq "openjdk-8" || [[ "${old_openjdk_version}" == 'true' ]]; then
  if [[ "${os_codename}" =~ (precise|maya) ]]; then
    if ! apt-get install openjdk-8-jre-headless -y || [[ "${old_openjdk_version}" == 'true' ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ppa.launchpad.net/openjdk-r/ppa/ubuntu precise main") -eq 0 ]]; then
        echo deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu precise main >> /etc/apt/sources.list.d/glennr-install-script.list || abort
        openjdk_repo=true
      fi
    fi
  elif [[ "${os_codename}" =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
    if ! apt-get install openjdk-8-jre-headless -y || [[ "${old_openjdk_version}" == 'true' ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ppa.launchpad.net/openjdk-r/ppa/ubuntu trusty main") -eq 0 ]]; then
        echo deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu trusty main >> /etc/apt/sources.list.d/glennr-install-script.list || abort
        openjdk_repo=true
      fi
    fi
  elif [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia) ]]; then
    if ! apt-get install openjdk-8-jre-headless -y || [[ "${old_openjdk_version}" == 'true' ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ppa.launchpad.net/openjdk-r/ppa/ubuntu[/]* xenial main") -eq 0 ]]; then
        echo deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu xenial main >> /etc/apt/sources.list.d/glennr-install-script.list || abort
        openjdk_repo=true
      fi
    fi
  elif [[ "${os_codename}" =~ (bionic|tara|tessa|tina|tricia) ]]; then
    if ! apt-get install openjdk-8-jre-headless -y || [[ "${old_openjdk_version}" == 'true' ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ppa.launchpad.net/openjdk-r/ppa/ubuntu[/]* bionic main") -eq 0 ]]; then
        echo deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu bionic main >> /etc/apt/sources.list.d/glennr-install-script.list || abort
        openjdk_repo=true
      fi
    fi
  elif [[ "${os_codename}" == "cosmic" ]]; then
    if ! apt-get install openjdk-8-jre-headless -y || [[ "${old_openjdk_version}" == 'true' ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ppa.launchpad.net/openjdk-r/ppa/ubuntu[/]* cosmic main") -eq 0 ]]; then
        echo deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu cosmic main >> /etc/apt/sources.list.d/glennr-install-script.list || abort
        openjdk_repo=true
      fi
    fi
  elif [[ "${os_codename}" =~ (disco|eoan) ]]; then
    if ! apt-get install openjdk-8-jre-headless -y || [[ "${old_openjdk_version}" == 'true' ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu[/]* bionic-security main universe") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu bionic-security main universe >> /etc/apt/sources.list.d/glennr-install-script.list || abort
        openjdk_repo=true
      fi
    fi
  elif [[ "${os_codename}" == "jessie" ]]; then
    if ! apt-get install -t jessie-backports openjdk-8-jre-headless ca-certificates-java -y || [[ "${old_openjdk_version}" == 'true' ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -P -c "^deb http[s]*://archive.debian.org/debian[/]* jessie-backports main") -eq 0 ]]; then
        echo deb http://archive.debian.org/debian jessie-backports main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
        http_proxy=$(env | grep -i "http.*Proxy" | cut -d'=' -f2 | sed 's/[";]//g')
        if [[ -n "$http_proxy" ]]; then
          apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy="${http_proxy}" --recv-keys 8B48AD6246925553 7638D0442B90D010 || abort
        elif [[ -f /etc/apt/apt.conf ]]; then
          apt_http_proxy=$(grep "http.*Proxy" /etc/apt/apt.conf | awk '{print $2}' | sed 's/[";]//g')
          if [[ -n "${apt_http_proxy}" ]]; then
            apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy="${apt_http_proxy}" --recv-keys 8B48AD6246925553 7638D0442B90D010 || abort
          fi
        else
          apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 8B48AD6246925553 7638D0442B90D010 || abort
        fi
        apt-get update -o Acquire::Check-Valid-Until=false
        apt-get install -t jessie-backports openjdk-8-jre-headless ca-certificates-java -y || abort
        sed -i '/jessie-backports/d' /etc/apt/sources.list.d/glennr-install-script.list
      fi
    fi
  elif [[ "${os_codename}" =~ (stretch|continuum) ]]; then
    if ! apt-get install openjdk-8-jre-headless -y || [[ "${old_openjdk_version}" == 'true' ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ppa.launchpad.net/openjdk-r/ppa/ubuntu[/]* xenial main") -eq 0 ]]; then
        echo deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu xenial main >> /etc/apt/sources.list.d/glennr-install-script.list || abort
        openjdk_repo=true
      fi
    fi
  elif [[ "${os_codename}" =~ (buster|bullseye) ]]; then
    if ! apt-get install openjdk-8-jre-headless -y || [[ "${old_openjdk_version}" == 'true' ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.nl.debian.org/debian[/]* stretch main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian stretch main >> /etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
  else
    header_red
    echo -e "${RED}#${RESET} The script is unable to grab your OS ( or does not support it )"
    echo "${architecture}"
    echo "${os_codename}"
    abort
  fi
  if [[ "${openjdk_repo}" == 'true' ]]; then
    echo "EB9B1D8886F44E2A" &>> /tmp/EUS/keys/missing_keys
  fi
  run_apt_get_update
  apt-get install openjdk-8-jre-headless -y || abort
else
  clear
  header
  echo -e "${WHITE_R}#${RESET} OpenJDK/Oracle JAVA 8 is already installed..."
  echo ""
  echo ""
  echo ""
  sleep 2
fi

if dpkg -l | grep "^ii" | grep -iq "openjdk-8"; then
  openjdk_8_installed=true
fi
if dpkg -l | grep "^ii" | grep -i "openjdk-.*-\\|oracle-java.*" | grep -vq "openjdk-8\\|oracle-java8"; then
  unsupported_java_installed=true
fi

if [[ "${openjdk_8_installed}" == 'true' && "${unsupported_java_installed}" == 'true' && "${script_option_skip}" != 'true' ]]; then
  clear
  header_red
  echo -e "${WHITE_R}#${RESET} Unsupported JAVA version(s) are detected, do you want to uninstall them?"
  echo -e "${WHITE_R}#${RESET} This may remove packages that depend on these java versions."
  read -rp $'\033[39m#\033[0m Do you want to proceed with uninstalling the unsupported JAVA version(s)? (y/N) ' yes_no
  case "$yes_no" in
       [Yy]*)
          rm --force /tmp/EUS/java/* &> /dev/null
          mkdir -p /tmp/EUS/java/ &> /dev/null
          mkdir -p "${eus_dir}/logs/" &> /dev/null
          if [[ -f "${eus_dir}/logs/java_uninstall.log" ]]; then
            java_uninstall_log_size=$(du -sc ${eus_dir}/logs/java_uninstall.log | grep total$ | awk '{print $1}')
            if [[ "${java_uninstall_log_size}" -gt '50' ]]; then
              tail -n100 "${eus_dir}/logs/java_uninstall.log" &> "${eus_dir}/logs/java_uninstall_tmp.log"
              cp "${eus_dir}/logs/java_uninstall_tmp.log" "${eus_dir}/logs/java_uninstall.log"; rm --force "${eus_dir}/logs/java_uninstall_tmp.log" &> /dev/null
            fi
          fi
          clear
          header
          echo -e "${WHITE_R}#${RESET} Uninstalling unsupported JAVA versions..."
          echo -e "\\n${WHITE_R}----${RESET}\\n"
          sleep 3
          dpkg -l | grep "^ii" | awk '/openjdk-.*/{print $2}' | cut -d':' -f1 | grep -v "openjdk-8" &>> /tmp/EUS/java/unsupported_java_list_tmp
          dpkg -l | grep "^ii" | awk '/oracle-java.*/{print $2}' | cut -d':' -f1 | grep -v "oracle-java8" &>> /tmp/EUS/java/unsupported_java_list_tmp
          awk '!a[$0]++' /tmp/EUS/java/unsupported_java_list_tmp >> /tmp/EUS/java/unsupported_java_list; rm --force /tmp/EUS/java/unsupported_java_list_tmp 2> /dev/null
          echo -e "\\n------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/java_uninstall.log"
          while read -r package; do
            apt-get remove "${package}" -y &>> "${eus_dir}/logs/java_uninstall.log" && echo -e "${WHITE_R}#${RESET} Successfully removed ${package}." || echo -e "${WHITE_R}#${RESET} Failed to remove ${package}."
          done < /tmp/EUS/java/unsupported_java_list
          rm --force /tmp/EUS/java/unsupported_java_list &> /dev/null
          echo -e "\\n";;
       [Nn]*|"") ;;
  esac
fi

if dpkg -l | grep "^ii" | grep -iq "openjdk-8"; then
  update_java_alternatives=$(update-java-alternatives --list | grep "^java-1.8.*openjdk" | awk '{print $1}' | head -n1)
  if [[ -n "${update_java_alternatives}" ]]; then
    update-java-alternatives --set "${update_java_alternatives}" &> /dev/null
  fi
  update_alternatives=$(update-alternatives --list java | grep "java-8-openjdk" | awk '{print $1}' | head -n1)
  if [[ -n "${update_alternatives}" ]]; then
    update-alternatives --set java "${update_alternatives}" &> /dev/null
  fi
  clear
  header
  echo -e "${WHITE_R}#${RESET} Updating the ca-certificates..." && sleep 2
  rm /etc/ssl/certs/java/cacerts 2> /dev/null
  update-ca-certificates -f &> /dev/null && echo -e "${GREEN}#${RESET} Successfully updated the ca-certificates\\n" && sleep 2
fi

if dpkg -l | grep "^ii" | grep -iq "openjdk-8"; then
  java_home_readlink="JAVA_HOME=$( readlink -f "$( command -v java )" | sed "s:bin/.*$::" )"
  if [[ -f /etc/default/unifi ]]; then
    current_java_home=$(grep "^JAVA_HOME" /etc/default/unifi)
    if [[ -n "${java_home_readlink}" ]]; then
      if [[ "${current_java_home}" != "${java_home_readlink}" ]]; then
        sed -i 's/^JAVA_HOME/#JAVA_HOME/' /etc/default/unifi
        echo "${java_home_readlink}" >> /etc/default/unifi
      fi
    fi
  else
    current_java_home=$(grep "^JAVA_HOME" /etc/environment)
    if [[ -n "${java_home_readlink}" ]]; then
      if [[ "${current_java_home}" != "${java_home_readlink}" ]]; then
        sed -i 's/^JAVA_HOME/#JAVA_HOME/' /etc/environment
        echo "${java_home_readlink}" >> /etc/environment
        # shellcheck disable=SC1091
        source /etc/environment
      fi
    fi
  fi
fi

clear
header
echo -e "${WHITE_R}#${RESET} OpenJDK 8 has been installed successfully!"
echo -e "${WHITE_R}#${RESET} Installing UniFi Dependencies..."
echo ""
echo ""
echo ""
sleep 2
run_apt_get_update
if [[ "${os_codename}" =~ (precise|maya|trusty|qiana|rebecca|rafaela|rosa|xenial|sarah|serena|sonya|sylvia|bionic|tara|tessa|tina|tricia|cosmic|disco|eoan|stretch|continuum|buster|bullseye) ]]; then
  apt-get install binutils ca-certificates-java java-common -y || unifi_dependencies=fail
  apt-get install jsvc libcommons-daemon-java -y || unifi_dependencies=fail
elif [[ "${os_codename}" == 'jessie' ]]; then
  apt-get install binutils ca-certificates-java java-common -y --force-yes || unifi_dependencies=fail
  apt-get install jsvc libcommons-daemon-java -y --force-yes || unifi_dependencies=fail
fi
if [[ "${unifi_dependencies}" == 'fail' ]]; then
  if [[ "${os_codename}" =~ (precise|maya) ]]; then
    if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -P -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu precise main universe") -eq 0 ]]; then
      echo deb http://nl.archive.ubuntu.com/ubuntu precise main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
    fi
  elif [[ "${os_codename}" =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
    if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -P -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu trusty main universe") -eq 0 ]]; then
      echo deb http://nl.archive.ubuntu.com/ubuntu trusty main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
    fi
  elif [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia) ]]; then
    if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -P -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu xenial main universe") -eq 0 ]]; then
      echo deb http://nl.archive.ubuntu.com/ubuntu xenial main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
    fi
  elif [[ "${os_codename}" =~ (bionic|tara|tessa|tina|tricia) ]]; then
    if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -P -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu bionic main universe") -eq 0 ]]; then
      echo deb http://nl.archive.ubuntu.com/ubuntu bionic main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
    fi
  elif [[ "${os_codename}" == "cosmic" ]]; then
    if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -P -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu cosmic main universe") -eq 0 ]]; then
      echo deb http://nl.archive.ubuntu.com/ubuntu cosmic main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
    fi
  elif [[ "${os_codename}" == "disco" ]]; then
    if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -P -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu disco main universe") -eq 0 ]]; then
      echo deb http://nl.archive.ubuntu.com/ubuntu disco main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
    fi
  elif [[ "${os_codename}" == "eoan" ]]; then
    if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -P -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu eoan main universe") -eq 0 ]]; then
      echo deb http://nl.archive.ubuntu.com/ubuntu eoan main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
    fi
  elif [[ "${os_codename}" == "jessie" ]]; then
    if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -P -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian jessie main") -eq 0 ]]; then
      echo deb http://ftp.nl.debian.org/debian jessie main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
    fi
  elif [[ "${os_codename}" =~ (stretch|continuum) ]]; then
    if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -P -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian stretch main") -eq 0 ]]; then
      echo deb http://ftp.nl.debian.org/debian stretch main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
    fi
  elif [[ "${os_codename}" == "buster" ]]; then
    if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -P -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian buster main") -eq 0 ]]; then
      echo deb http://ftp.nl.debian.org/debian buster main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
    fi
  elif [[ "${os_codename}" == "bullseye" ]]; then
    if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -P -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian bullseye main") -eq 0 ]]; then
      echo deb http://ftp.nl.debian.org/debian bullseye main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
    fi
  fi
  if [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia|bionic|tara|tessa|tina|tricia|cosmic|disco|eoan|stretch|continuum|buster|bullseye) ]]; then
    run_apt_get_update
    apt-get install binutils ca-certificates-java java-common -y || abort
    apt-get install jsvc libcommons-daemon-java -y || abort
  elif [[ "${os_codename}" == 'jessie' ]]; then
    run_apt_get_update
    apt-get install binutils ca-certificates-java java-common -y --force-yes || abort
    apt-get install jsvc libcommons-daemon-java -y --force-yes || abort
  fi
fi

clear
header
echo -e "${WHITE_R}#${RESET} UniFi dependencies has been installed successfully!"
echo -e "${WHITE_R}#${RESET} Installing your UniFi Network Controller ( ${WHITE_R}5.12.35${RESET} )..."
echo ""
echo ""
echo ""
sleep 2
unifi_temp="$(mktemp --tmpdir=/tmp unifi_sysvinit_all_5.12.35_XXX.deb)"
wget -O "$unifi_temp" 'https://dl.ui.com/unifi/5.12.35/unifi_sysvinit_all.deb' || abort
dpkg -i "$unifi_temp"
if [[ "${debian_32_run_fix}" == 'true' ]]; then
  clear
  header
  echo -e "${WHITE_R}#${RESET} Fixing broken UniFi install..."
  echo ""
  echo ""
  echo ""
  apt-get --fix-broken install -y || abort
fi
rm --force "$unifi_temp" 2> /dev/null
service unifi start || abort

dash_port=$(grep "unifi.https.port" /usr/lib/unifi/data/system.properties 2> /dev/null | cut -d'=' -f2 | tail -n1)
info_port=$(grep "unifi.http.port" /usr/lib/unifi/data/system.properties 2> /dev/null | cut -d'=' -f2 | tail -n1)
if [[ -z "${dash_port}" ]]; then dash_port="8443"; fi
if [[ -z "${info_port}" ]]; then info_port="8080"; fi

if [[ "${change_unifi_ports}" == 'true' ]]; then
  if [[ -f /usr/lib/unifi/data/system.properties && -s /usr/lib/unifi/data/system.properties ]]; then
    clear
    header
    echo -e "${WHITE_R}#${RESET} system.properties file got created!"
    echo -e "${WHITE_R}#${RESET} Stopping the UniFi Network Controller.."
    systemctl stop unifi && echo -e "${GREEN}#${RESET} Successfully stopped the UniFi Network Controller!" || echo -e "${RED}#${RESET} Failed to stop the UniFi Network Controller."
    sleep 2
    change_default_ports
  else
    while sleep 3; do
      if [[ -f /usr/lib/unifi/data/system.properties && -s /usr/lib/unifi/data/system.properties ]]; then
        echo -e "${WHITE_R}#${RESET} system.properties got created!"
        echo -e "${WHITE_R}#${RESET} Stopping the UniFi Network Controller.."
        systemctl stop unifi && echo -e "${GREEN}#${RESET} Successfully stopped the UniFi Network Controller!" || echo -e "${RED}#${RESET} Failed to stop the UniFi Network Controller."
        sleep 2
        change_default_ports
        break
      else
        clear
        header_red
        echo -e "${WHITE_R}#${RESET} system.properties file is not there yet.." && sleep 2
      fi
    done
  fi
fi

# Check if MongoDB service is enabled
if ! [[ "${os_codename}" =~ (precise|maya|trusty|qiana|rebecca|rafaela|rosa) ]]; then
  if [ "${mongodb_version::2}" -ge '26' ]; then
    SERVICE_MONGODB=$(systemctl is-enabled mongod)
    if [ "$SERVICE_MONGODB" = 'disabled' ]; then
      systemctl enable mongod 2>/dev/null || { echo -e "${RED}#${RESET} Failed to enable service | MongoDB"; sleep 3; }
    fi
  else
    SERVICE_MONGODB=$(systemctl is-enabled mongodb)
    if [ "$SERVICE_MONGODB" = 'disabled' ]; then
      systemctl enable mongodb 2>/dev/null || { echo -e "${RED}#${RESET} Failed to enable service | MongoDB"; sleep 3; }
    fi
  fi
  # Check if UniFi service is enabled
  SERVICE_UNIFI=$(systemctl is-enabled unifi)
  if [ "$SERVICE_UNIFI" = 'disabled' ]; then
    systemctl enable unifi 2>/dev/null || { echo -e "${RED}#${RESET} Failed to enable service | UniFi"; sleep 3; }
  fi
fi

if [[ "${script_option_skip}" != 'true' ]]; then
  clear
  header
  echo -e "${WHITE_R}#${RESET} Would you like to update the UniFi Network Controller via APT?"
  echo ""
  echo ""
  read -rp $'\033[39m#\033[0m Do you want the script to add the source list file? (Y/n) ' yes_no
  case "$yes_no" in
      [Yy]*|"")
        clear
        header
        echo -e "${WHITE_R}#${RESET} Adding source list..."
        echo ""
        echo ""
        echo ""
        sleep 3
        sed -i '/unifi/d' /etc/apt/sources.list
        rm --force /etc/apt/sources.list.d/100-ubnt-unifi.list 2> /dev/null
        if ! wget -O /etc/apt/trusted.gpg.d/unifi-repo.gpg https://dl.ui.com/unifi/unifi-repo.gpg; then
          echo "06E85760C0A52C50" &>> /tmp/EUS/keys/missing_keys
        fi
        echo 'deb https://www.ui.com/downloads/unifi/debian unifi-5.12 ubiquiti' | tee /etc/apt/sources.list.d/100-ubnt-unifi.list
        run_apt_get_update;;
      [Nn]*) ;;
  esac
fi

if dpkg -l ufw | grep -q "^ii"; then
  if ufw status verbose | awk '/^Status:/{print $2}' | grep -xq "active"; then
    clear
    header
    echo -e "${WHITE_R}#${RESET} Uncomplicated Firewall ( UFW ) seems to be active."
    echo -e "${WHITE_R}#${RESET} Checking if all required ports are added!"
    rm -rf /tmp/EUS/ports/* &> /dev/null
    mkdir -p /tmp/EUS/ports/ &> /dev/null
    ssh_port=$(awk '/Port/{print $2}' /etc/ssh/sshd_config | head -n1)
    unifi_ports=(3478/udp "${info_port}"/tcp "${dash_port}"/tcp 8880/tcp 8843/tcp 6789/tcp)
    echo -e "3478/udp\\n${info_port}/tcp\\n${dash_port}/tcp\\n8880/tcp\\n8843/tcp\\n6789/tcp" &>> /tmp/EUS/ports/all_ports
    echo -e "${ssh_port}" &>> /tmp/EUS/ports/all_ports
    ufw status verbose &>> /tmp/EUS/ports/ufw_list
    while read -r port; do
      port_number_only=$(echo "${port}" | cut -d'/' -f1)
      # shellcheck disable=SC1117
      if ! grep "^${port_number_only}\b\\|^${port}\b" /tmp/EUS/ports/ufw_list | grep -iq "ALLOW IN"; then
        required_port_missing=true
      fi
      # shellcheck disable=SC1117
      if ! grep -v "(v6)" /tmp/EUS/ports/ufw_list | grep "^${port_number_only}\b\\|^${port}\b" | grep -iq "ALLOW IN"; then
        required_port_missing=true
      fi
    done < /tmp/EUS/ports/all_ports
    if [[ "${required_port_missing}" == 'true' ]]; then
      echo -e "\\n${WHITE_R}----${RESET}\\n\\n"
      echo -e "${WHITE_R}#${RESET} We are missing required ports.."
      if [[ "${script_option_skip}" != 'true' ]]; then
        read -rp $'\033[39m#\033[0m Do you want to add the required ports for your UniFi Network Controller? (Y/n) ' yes_no
      else
        echo -e "${WHITE_R}#${RESET} Adding required UniFi ports.."
        sleep 2
      fi
      case "${yes_no}" in
         [Yy]*|"")
            echo -e "\\n${WHITE_R}----${RESET}\\n\\n"
            for port in "${unifi_ports[@]}"; do
              port_number=$(echo "${port}" | cut -d'/' -f1)
              ufw allow "${port}" &> "/tmp/EUS/ports/${port_number}"
              if [[ -f "/tmp/EUS/ports/${port_number}" && -s "/tmp/EUS/ports/${port_number}" ]]; then
                if grep -iq "added" "/tmp/EUS/ports/${port_number}"; then
                  echo -e "${WHITE_R}#${RESET} Successfully added port ${port} to UFW."
                fi
                if grep -iq "skipping" "/tmp/EUS/ports/${port_number}"; then
                  echo -e "${WHITE_R}#${RESET} Port ${port} was already added to UFW."
                fi
              fi
            done
            if [[ -f /etc/ssh/sshd_config && -s /etc/ssh/sshd_config ]]; then
              if ! ufw status verbose | grep -v "(v6)" | grep "${ssh_port}" | grep -iq "ALLOW IN"; then
                echo -e "\\n${WHITE_R}----${RESET}\\n\\n${WHITE_R}#${RESET} Your SSH port ( ${ssh_port} ) doesn't seem to be in your UFW list.."
                if [[ "${script_option_skip}" != 'true' ]]; then
                  read -rp $'\033[39m#\033[0m Do you want to add your SSH port to the UFW list? (Y/n) ' yes_no
                else
                  echo -e "${WHITE_R}#${RESET} Adding port ${ssh_port}.."
                  sleep 2
                fi
                case "${yes_no}" in
                   [Yy]*|"")
                      echo -e "\\n${WHITE_R}----${RESET}\\n"
                      ufw allow "${ssh_port}" &> "/tmp/EUS/ports/${ssh_port}"
                      if [[ -f "/tmp/EUS/ports/${ssh_port}" && -s "/tmp/EUS/ports/${ssh_port}" ]]; then
                        if grep -iq "added" "/tmp/EUS/ports/${ssh_port}"; then
                          echo -e "${WHITE_R}#${RESET} Successfully added port ${ssh_port} to UFW."
                        fi
                        if grep -iq "skipping" "/tmp/EUS/ports/${ssh_port}"; then
                          echo -e "${WHITE_R}#${RESET} Port ${ssh_port} was already added to UFW."
                        fi
                      fi;;
                   [Nn]*|*) ;;
                esac
              fi
            fi;;
         [Nn]*|*) ;;
      esac
    else
      echo -e "\\n${WHITE_R}----${RESET}\\n\\n${WHITE_R}#${RESET} All required ports already exist!"
    fi
    echo -e "\\n\\n" && sleep 2
  fi
fi

if [[ -z "${SERVER_IP}" ]]; then
  SERVER_IP=$(ip addr | grep -A8 -m1 MULTICAST | grep -m1 inet | cut -d' ' -f6 | cut -d'/' -f1)
fi

# Check if controller is reachable via public IP.
timeout 1 nc -zv "${PUBLIC_SERVER_IP}" "${dash_port}" &> /dev/null && remote_controller=true

if [[ "${remote_controller}" == 'true' && "${script_option_skip}" != 'true' ]]; then
  clear
  header
  le_script=true
  echo -e "${WHITE_R}#${RESET} Your controller seems to be exposed to the internet. ( port 8443 is open )"
  echo -e "${WHITE_R}#${RESET} It's recommend to secure your controller with a SSL certficate."
  echo ""
  echo -e "${WHITE_R}#${RESET} Requirements:"
  echo -e "${WHITE_R}-${RESET} A domain name and A record pointing to the controller."
  echo -e "${WHITE_R}-${RESET} Port 80 needs to be open ( port forwarded )"
  echo ""
  echo ""
  echo ""
  read -rp $'\033[39m#\033[0m Do you want to download and execute my Easy Lets Encrypt Script? (Y/n) ' yes_no
  case "$yes_no" in
      [Yy]*|"")
          rm --force unifi-lets-encrypt.sh &> /dev/null; wget https://get.glennr.nl/unifi/extra/unifi-lets-encrypt.sh && bash unifi-lets-encrypt.sh --install-script;;
      [Nn]*) ;;
  esac
fi

if [[ "${netcat_installed}" == 'true' ]]; then
  clear
  header
  echo -e "${WHITE_R}#${RESET} The script installed netcat, we do not need this anymore."
  echo -e "${WHITE_R}#${RESET} Uninstalling netcat..."
  apt-get purge netcat -y &> /dev/null && echo -e "\\n${WHITE_R}#${RESET} Successfully uninstalled netcat." || echo -e "\\n${WHITE_R}#${RESET} Failed to uninstall netcat."
  sleep 2
fi

if dpkg -l | grep "unifi " | grep -q "^ii"; then
  inform_port=$(grep "^unifi.http.port" /usr/lib/unifi/data/system.properties | cut -d'=' -f2 | tail -n1)
  dashboard_port=$(grep "^unifi.https.port" /usr/lib/unifi/data/system.properties | cut -d'=' -f2 | tail -n1)
  clear
  header
  echo ""
  echo -e "${GREEN}#${RESET} UniFi Network Controller 5.12.35 has been installed successfully"
  if [[ "${remote_controller}" = 'true' ]]; then
    echo -e "${GREEN}#${RESET} Your controller address: ${WHITE_R}https://$PUBLIC_SERVER_IP:${dash_port}${RESET}"
    if [[ "${le_script}" == 'true' ]]; then
      if [[ -d /usr/lib/EUS/ ]]; then
        if [[ -f /usr/lib/EUS/server_fqdn_install && -s /usr/lib/EUS/server_fqdn_install ]]; then
          controller_fqdn_le=$(tail -n1 /usr/lib/EUS/server_fqdn_install)
          rm --force /usr/lib/EUS/server_fqdn_install &> /dev/null
        fi
      elif [[ -d /srv/EUS/ ]]; then
        if [[ -f /srv/EUS/server_fqdn_install && -s /srv/EUS/server_fqdn_install ]]; then
          controller_fqdn_le=$(tail -n1 /srv/EUS/server_fqdn_install)
          rm --force /srv/EUS/server_fqdn_install &> /dev/null
        fi
      fi
      if [[ -n "${controller_fqdn_le}" ]]; then
        echo -e "${GREEN}#${RESET} Your controller FQDN: ${WHITE_R}https://$controller_fqdn_le:${dash_port}${RESET}"
      fi
    fi
  else
    echo -e "${GREEN}#${RESET} Your controller address: ${WHITE_R}https://$SERVER_IP:${dash_port}${RESET}"
  fi
  echo ""
  echo ""
  if [[ "${os_codename}" =~ (precise|maya|trusty|qiana|rebecca|rafaela|rosa) ]]; then
    service unifi status | grep -q running && echo -e "${GREEN}#${RESET} UniFi is active ( running )" || echo -e "${RED}#${RESET} UniFi failed to start... Please contact Glenn R. (AmazedMender16) on the Community Forums!"
  else
    systemctl is-active -q unifi && echo -e "${GREEN}#${RESET} UniFi is active ( running )" || echo -e "${RED}#${RESET} UniFi failed to start... Please contact Glenn R. (AmazedMender16) on the Community Forums!"
  fi
  if [[ "${change_unifi_ports}" == 'true' ]]; then
    echo -e "\\n${WHITE_R}---- ${RED}NOTE${WHITE_R} ----${RESET}\\n\\n${WHITE_R}#${RESET} Your default controller port(s) have changed!\\n"
    if [[ -n "${inform_port}" ]]; then
      echo -e "${WHITE_R}#${RESET} Device Inform port: ${inform_port}"
    fi
    if [[ -n "${dashboard_port}" ]]; then
      echo -e "${WHITE_R}#${RESET} Management Dashboard port: ${dashboard_port}"
    fi
    echo -e "\\n${WHITE_R}--------------${RESET}\\n"
  else
    if [[ "${port_8080_in_use}" == 'true' && "${port_8443_in_use}" == 'true' && "${port_8080_pid}" == "${port_8443_pid}" ]]; then
      echo -e "\\n${RED}#${RESET} Port ${info_port} and ${dash_port} is already in use by another process ( PID ${port_8080_pid} ), your UniFi Network Controll will most likely not start.."
      echo -e "${RED}#${RESET} Disable the service that is using port ${info_port} and ${dash_port} ( ${port_8080_service} ) or kill the process with the command below"
      echo -e "${RED}#${RESET} sudo kill -9 ${port_8080_pid}\\n"
    else
      if [[ "${port_8080_in_use}" == 'true' ]]; then
        echo -e "\\n${RED}#${RESET} Port ${info_port} is already in use by another process ( PID ${port_8080_pid} ), your UniFi Network Controll will most likely not start.."
        echo -e "${RED}#${RESET} Disable the service that is using port ${info_port} ( ${port_8080_service} ) or kill the process with the command below"
        echo -e "${RED}#${RESET} sudo kill -9 ${port_8080_pid}\\n"
      fi
      if [[ "${port_8443_in_use}" == 'true' ]]; then
        echo -e "\\n${RED}#${RESET} Port ${dash_port} is already in use by another process ( PID ${port_8443_pid} ), your UniFi Network Controll will most likely not start.."
        echo -e "${RED}#${RESET} Disable the service that is using port ${dash_port} ( ${port_8443_service} ) or kill the process with the command below"
        echo -e "${RED}#${RESET} sudo kill -9 ${port_8443_pid}\\n"
      fi
    fi
  fi
  echo -e "\\n"
  author
  remove_yourself
else
  clear
  header_red
  echo -e "\\n${RED}#${RESET} Failed to successfully install UniFi Network Controller 5.12.35"
  echo -e "${RED}#${RESET} Please contact Glenn R. (AmazedMender16) on the Community Forums!${RESET}"
  echo -e "\\n"
  remove_yourself
fi
