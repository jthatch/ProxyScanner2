#!/bin/bash

# Process-related #
# The number of jobs to run with GNU parallel at a time:
# make sure that you provide a soft,hard setting for nofile in /etc/security/limits.conf 
# to allow (eg: 1024000) and set ulimit -n 1024000 before running this script to ensure 
# the upper limit of file handles is well above anything we can reasonably substantiate.
# (on a system with 20 cores + 20 threads and 96GB of memory). This number applies mostly 
# to a curl workload making GET/HEAD requests:

export PARALLEL_FORK=500

export PARALLEL_NICENESS="-5"

export PARALLEL_JOB_NICENESS="-19"

# Backoff/retry Parameters #
## The number of times parallel should retry the command on after a
## non-zero exit status: (NOTE: not as good as curl --retry it seems to wait all before taking 
## another $PARALLEL_FORK, maybe an option to disable that )

export PARALLEL_RETRY_COUNT=0

## CURL (presumably S/ACK) timeout but the docs don't really say 
## https://curl.haxx.se/libcurl/c/CURLOPT_CONNECTTIMEOUT.html

export CURL_CONNECT_TIMEOUT=1

## The maximum amount of time curl may run:

export CURL_OVERALL_TIME_ALLOWED=5

## The number of times curl should retry for transient and server 500 errors
## recieved from the proxy:

export CURL_RETRY_COUNT=2 

## The amount of time for curl to wait between retries: 

export CURL_RETRY_DELAY=0

# Misc Options #
## Misc GNU Parallel Options

export MISC_PARALLEL_OPTS="--eta"

# Directories #
## Parallel uses the $TMPDIR var and is quite I/O heavy given high job counts so I 
## reccomend it above anything else, but by default I use ramdisk for as much as 
## possible. Default designates the base PROXY_SCANNER_WORK_DIR to live on /dev/shm as well. 
## This can be safely changed although I would also specify /dev/shm at least for 
## the TMPDIR. Just added PROXY_SCANNER_HOME_DIR as a place for "somewhat" 
## persistent storage. 

export PROXY_SCANNER_HOME_DIR=${HOME}/ProxyScanner

export PROXY_SCANNER_WORK_DIR=/dev/shm/proxy_scan
export TMPDIR=${PROXY_SCANNER_WORK_DIR}/tmp

export HTTP_RESULT_DIR=${PROXY_SCANNER_WORK_DIR}/http_checked
export HTTP_CONNECT_RESULT_DIR=${PROXY_SCANNER_WORK_DIR}/http_connect_checked

export SOCKS4_RESULT_DIR=${PROXY_SCANNER_WORK_DIR}/socks4_checked
export SOCKS5_RESULT_DIR=${PROXY_SCANNER_WORK_DIR}/socks5_checked

export OLD_FILES=${PROXY_SCANNER_HOME_DIR}/old_proxy_test_results

export COOKIE_JARS=${PROXY_SCANNER_HOME_DIR}/cookie_jars

export PARALLEL_JOB_LOGS=${PROXY_SCANNER_HOME_DIR}/job_logs

## Misc curl options
## --tcp-nodelay: Since  7.50.2,  curl sets this option by default and
## you need to explicitly switch it off if you don't want it on:
## --tcp-fastopen (TFO): https://en.wikipedia.org/wiki/TCP_Fast_Open
## --fail (HTTP): Fail silently (no output at all) on server errors.
## This is mostly done to better enable scripts etc to better
## deal with failed attempts. In normal cases when an HTTP server
## fails to deliver a  document, it returns an HTML document stating
## so (which often also describes why and more). This flag will
## prevent curl from outputting that and return error 22

export MISC_CURL_OPTS="-s --fail --tcp-nodelay --max-redirs 4 --tcp-fastopen"

## Use the pseudorandom (non-blocking) number generator over other options
## such as EGD, or /dev/random when initiating a TLS session. Certificates in the request path
## are still verified unless -k is specified. This should improve the connection
## rate but that still needs to be confirmed:

export MISC_CURL_OPTS=" ${MISC_CURL_OPTS} --random-file /dev/urandom"

# Executables #
# TODO: netcat should be netcat-openbsd 
# TODO: check if installed, all

export PARALLEL_BIN=$(which parallel)
export CURL_BIN=$(which curl)
export JQ_BIN=$(which jq)
export XZCAT_BIN=$(which xzcat)
export NETCAT_BIN=$(which nc) 
export ENV_BIN=$(which env)
export BASH_BIN=$(which bash)

## Create directories if they don't exist yet:

function create_proxy_scanner_directories() {
  mkdir -p $HTTP_CONNECT_RESULT_DIR \
    $HTTP_RESULT_DIR                \
    $TMPDIR                         \
    $SOCKS4_RESULT_DIR              \
    $SOCKS5_RESULT_DIR              \
    $PARALLEL_JOB_LOGS              \
    $OLD_FILES
}

## zero out previous results prior to beginning new checks but maintain the file for 
## logging purposes:

function truncate_stale_result_files() { 
  find $HTTP_CONNECT_RESULT_DIR \
    $HTTP_RESULT_DIR            \
    $SOCKS4_RESULT_DIR          \
    $SOCKS5_RESULT_DIR          \
    -type f | parallel          \
    -j $PARALLEL_FORK           \
    $MISC_PARALLEL_OPTS         \
    truncate -s 0 {}
}

## Create seed files or just modify access time of existing because otherwise 
## if they haven't been provided the scanner will attempt to access a 
## file that doesn't exist: (in other words this is a routine intended to run
## each time the script is started. These files are intended to be a user maintained 
## list of everything that has ever been scanned or passed in from scrapers. A lot 
## of proxies are repeat offenders and the dead shall rise. 

touch $OLD_FILES/http.seed

# Datestamp format to use for log files #

export DATESTAMP_FORMAT="%T"

# Checker Functions #

## HTTP/1.1 HEAD request against microsoft.com using the proxy intended to be verified 
## for usability. This is a cheap and effective test that will always yield a 302 
## redirect to HTTPS (thus this serves as an elementry verification that CONNECT works
## as well, however many proxies will only allow CONNECT for HTTPS (443) exclusively. 
## The target of the redirect should always yield a 'Server' header value of 'Kestrel' 
## unless this test has become outdated, therefore all results can be verified by 
## (ex: grep -r "Kestrel" $HTTP_RESULT_DIR/ ) which should yield output that looks
## like this: <ipaddress>:<port>:Server: Kestrel

function http_microsoft_head_cmd() {
  nice -n $PARALLEL_JOB_NICENESS $CURL_BIN \
  $MISC_CURL_OPTS                          \
  --retry $CURL_RETRY_COUNT                \
  --connect-timeout $CURL_CONNECT_TIMEOUT  \
  -m $CURL_OVERALL_TIME_ALLOWED            \
  --proxy http://$1:$2                     \
  -L                                       \
  --cookie-jar $COOKIE_JARS/$1:$2          \
  -I http://microsoft.com                  \
  -o $HTTP_RESULT_DIR/$1:$2

} ; export -f http_microsoft_head_cmd # export for parallel call? 

# the actual parallel call for http_head
function http_microsoft_head() {
  cat $1                                                                      \
    | tr ':' ' '                                                              \
    | nice -n $PARALLEL_NICENESS $PARALLEL_BIN                                \
    --colsep ' '                                                              \
    --joblog $PARALLEL_JOB_LOGS/$(date +"${DATESTAMP_FORMAT}").log            \
    $MISC_PARALLEL_OPTS                                                       \
    -j $PARALLEL_FORK                                                         \
    http_microsoft_head_cmd "{1}" "{2}"
}

function extract_microsoft_results() { 
  grep -r "Kestrel" $HTTP_RESULT_DIR                                                  \
    | sed 's/:Server: Kestrel//g'                                                     \
    | shuf | tr ':' ' '                                                               \
    | cat -n                                                                          \
    | awk '{print "set server http_and_https_be/http-proxy-"$1 " addr "$2" port "$3}' \
    | sudo nc -U /mnt/export/netcrave_docker/var/run/haproxy/haproxy_admin.sock 
}

# Extraction phase #

## Our internal history extractor
# commented out for now but later will be uncommented when everything else is finished

# http_microsoft_head <(xzcat $OLD_FILES/http.*.xz)

# extractors are just pseudo modules that yield a hostname:port pair 
for extractor in $(find extractors/ -type f -name "*.extractor.sh"); do
  # env -i removes a lot of stuff but all of the vars that were exported from this environment
  # are missing now which is probably ok but still trying to think of a reason why I would 
  # want them to be since the current design is to inject  everything into here and none of the
  # extractor scripts are intended to be ran outside of here, but another injector could be added
  # later that injects this environment into the other if necessary, then that data can be cached
  # here for another module or extractor to pick up with a cookie and without the injector having to
  # be much more complex than this. For now this keeps the import simple enough that I can tag/rename
  # all functions found when $ext is eval'd with extractor_<hash_id>_the_rest_of_the_function_name

  # for use in heredoc: source <(cat ./$extractor)  #| sed -s 's/^function /function __/g')
  file_hash=$(sha256sum $extractor | awk '{print $1}' | tr -d '\n' | head -c 12)
  ext=$($ENV_BIN -i $BASH_BIN --noprofile --norc <<xxx | sed s/"^[a-zA-Z0-9_-].* \(\)$"/"extractor_"$file_hash"_\1\0/g"
    set -a 
    source <(cat ./$extractor)  
    set +a 
    declare -f
xxx
  )

  # for now just making sure not to redeclare anything
  source <(echo -e "#!/bin/bash\n " ; echo "${ext}" )

done

declare -f # ok that works, and all of the extractor functions should work

# I'm not sure how I want to do this yet, ideally I would just
# call the methods as they were previously delineated, I think
# I will delineate them with _extractor when they're injected
# (previous loop), but I need to figure out how to stomp the other
# unwanted functions that are getting slurped (clearMT, ml )
# for x in $(declare -F | grep "extractor"); do
#     echo $x;
# done

# Result verification phase #



