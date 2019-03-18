#!/bin/bash

function us_proxy() {
    nice -n $PARALLEL_JOB_NICENESS $CURL_BIN                                               \
         $MISC_CURL_OPTS                                                                   \
         --retry $CURL_RETRY_COUNT                                                         \
         --connect-timeout $CURL_CONNECT_TIMEOUT                                           \
         -L                                                                                \
         --cookie-jar $COOKIE_JARS/us-proxy.org                                            \
         https://www.us-proxy.org/                                                         \
        | sed 's/<\/td>/,/g'                                                               \
        | sed 's/<td>/,/g'                                                                 \
        | sed 's/<tr>,/\n/g'                                                               \
        | sed 's/<\/tr>/\n/g'                                                              \
        | grep "<td class='hm'"                                                            \
        | tr ',' ' '                                                                       \
        | awk '{print $1":"$2}'                                                            \
        | tr ':' ' '                                                                       \
        | nice -n $PARALLEL_NICENESS $PARALLEL_BIN                                         \
               --colsep ' '                                                                \
               --joblog $PARALLEL_JOB_LOGS/$(date +"${DATESTAMP_FORMAT}").us-proxy.org.log \
               $MISC_PARALLEL_OPTS                                                         \
               -j $PARALLEL_FORK                                                           \
               http_microsoft_head_cmd "{1}" "{2}"
}
