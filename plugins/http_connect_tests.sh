#!/bin/bash

check_ftp() {
    nice -n $PARALLEL_JOB_NICENESS $CURL_BIN      \
         $MISC_CURL_OPTS                          \
         --retry $CURL_RETRY_COUNT                \
         --connect-timeout $CURL_CONNECT_TIMEOUT  \
         -m $CURL_OVERALL_TIME_ALLOWED            \
         --proxy http://$1:$2                     \
         -L                                       \
         --cookie-jar $COOKIE_JARS/$1:$2          \
         -D- ftp://ftp.oregonstate.edu            \
         -o $HTTP_CONNECT_RESULT_DIR/$1:$2
}
