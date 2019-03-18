#!/bin/bash

function socks5_microsoft_head_cmd() {
    nice -n $PARALLEL_JOB_NICENESS $CURL_BIN      \
         $MISC_CURL_OPTS                          \
         --retry $CURL_RETRY_COUNT                \
         --connect-timeout $CURL_CONNECT_TIMEOUT  \
         -m $CURL_OVERALL_TIME_ALLOWED            \
         --preproxy socks5://$1:$2                \
         -L                                       \
         --cookie-jar $COOKIE_JARS/$1:$2          \
         -I http://microsoft.com                  \
         -o $SOCKS5_RESULT_DIR/$1:$2

}

function socks4_microsoft_head_cmd() {
    nice -n $PARALLEL_JOB_NICENESS $CURL_BIN      \
         $MISC_CURL_OPTS                          \
         --retry $CURL_RETRY_COUNT                \
         --connect-timeout $CURL_CONNECT_TIMEOUT  \
         -m $CURL_OVERALL_TIME_ALLOWED            \
         --preproxy socks4://$1:$2                \
         -L                                       \
         --cookie-jar $COOKIE_JARS/$1:$2          \
         -I http://microsoft.com                  \
         -o $SOCKS4_RESULT_DIR/$1:$2

}

