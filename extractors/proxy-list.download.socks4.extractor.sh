#!/bin/bash

function socks4_microsoft_head() {
    nice -n $PARALLEL_JOB_NICENESS $CURL_BIN                                                             \
         $MISC_CURL_OPTS                                                                                 \
         --retry $CURL_RETRY_COUNT                                                                       \
         --connect-timeout $CURL_CONNECT_TIMEOUT                                                         \
         -L                                                                                              \
         --cookie-jar $COOKIE_JARS/proxy-list.download                                                   \
         'https://www.proxy-list.download/api/v0/get?l=en&t=socks4'                                      \
        | jq -r '.[] | .LISTA | .[] | .IP + ":" + .PORT'                                                 \
        | tr ':' ' '                                                                                     \
        | nice -n $PARALLEL_NICENESS $PARALLEL_BIN                                                       \
               --colsep ' '                                                                              \
               --joblog $PARALLEL_JOB_LOGS/$(date +"${DATESTAMP_FORMAT}").proxy-list.download.socks4.log \
               $MISC_PARALLEL_OPTS                                                                       \
               -j $PARALLEL_FORK                                                                         \
               socks4_microsoft_head_cmd "{1}" "{2}"
}
