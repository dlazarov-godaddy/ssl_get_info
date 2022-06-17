#!/usr/local/bin/zsh

# Prevent manipulation of the input field separator
IFS='
        '
# Ensure that secure search path is inherited by sub-processes
OLDPATH="$PATH"

PATH=/bin:/usr/bin:/usr/sbin
export PATH

# domain file
INPUT="$1"
OUTPUT="/tmp/ssl_results.txt"
LOG_ERROR="/tmp/ssl_error.log"

# Function to provide usage help
usage() {
  # Display the usage and exit.
  echo "Usage: ${0} this script requires a file  with a list of domains." >&2
  echo " FILE   Use FILE for the list of servers.." >&2
  exit 1
}

# Function to get ssl certificate data
get_ssl_data () {
  for domain in $(cat $INPUT); do \
   for ip in $(dig  $domain | grep "\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}" |  \
     head -n1 | awk '{print $5}' | sed '/^$/d'); do \
     echo | openssl s_client -showcerts -servername $domain -connect $ip:443 > /dev/null  |  \
     openssl x509 -inform  pem -noout -serial -dates | \
     grep -E 'serial|notAfter'   &&
     echo "$domain is pointed to: $ip $ssl_data"
  done
done
}

if [[ "${#}" -ne 1 ]]
then
  usage
  exit 1
fi

if [[ -e $INPUT ]]
then
  get_ssl_data 1> $OUTPUT 2> $LOG_ERROR
  year=$(date | awk '{print $4}' )
  renewal_due=$(grep -A 1 -B 1 $year $OUTPUT)
  echo
  echo
  echo "SSL Certificates that expire in 2022" >&2
  echo
  echo
  printf "'\033[1;33m $renewal_due"
  echo
  echo "SSL Certificates that expire this month" >&2
  echo
  warning_renewal=$(date | awk '{print $3}')
  expire_warning=$( grep -E -A 1  '$month|$year'  $OUTPUT)
  grep 2023 $OUTPUT
  echo
  printf "'\033[0;31m $expire_warning"
  echo
else
   echo "The file $INPUT does not exist."
   exit 2
fi

exit 0
