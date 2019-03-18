#!/bin/bash
function clarketm() {
    nice -n $PARALLEL_JOB_NICENESS $CURL_BIN                                           \
         $MISC_CURL_OPTS                                                               \
         --retry $CURL_RETRY_COUNT                                                     \
         --connect-timeout $CURL_CONNECT_TIMEOUT                                       \
         -L                                                                            \
         --cookie-jar $COOKIE_JARS/githubusercontent.com                               \
         https://raw.githubusercontent.com/clarketm/proxy-list/master/proxy-list.txt   \
        | tail -n +5                                                                   \
        | head -n -1                                                                   \
        | awk '{print $1}'                                                             \
        | tr ':' ' '                                                                   \
        | nice -n $PARALLEL_NICENESS $PARALLEL_BIN                                     \
               --colsep ' '                                                            \
               --joblog $PARALLEL_JOB_LOGS/$(date +"${DATESTAMP_FORMAT}").clarketm.log \
               $MISC_PARALLEL_OPTS                                                     \
               -j $PARALLEL_FORK                                                       \
               http_microsoft_head_cmd "{1}" "{2}"
}
