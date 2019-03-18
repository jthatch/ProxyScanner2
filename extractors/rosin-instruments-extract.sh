#!/bin/bash

function extract_rosin_instruments() {
    nice -n $PARALLEL_JOB_NICENESS $CURL_BIN                                                            \
         $MISC_CURL_OPTS                                                                                \
         --retry $CURL_RETRY_COUNT                                                                      \
         --connect-timeout $CURL_CONNECT_TIMEOUT                                                        \
         -L                                                                                             \
         --cookie-jar $COOKIE_JARS/rosininstrument.com                                                  \
         http://tools.rosinstrument.com/proxy/l100.xml                                                  \
         --next                                                                                         \
         $MISC_CURL_OPTS                                                                                \
         --retry $CURL_RETRY_COUNT                                                                      \
         --connect-timeout $CURL_CONNECT_TIMEOUT                                                        \
         -L                                                                                             \
         --cookie-jar $COOKIE_JARS/rosininstrument.com                                                  \
         http://tools.rosinstrument.com/proxy/plab100.xml                                               \
        | grep "title"                                                                                  \
        | tr '>' ' '                                                                                    \
        | tr '<' ' '                                                                                    \
        | awk '{print $2}'                                                                              \
        | tr ':' ' '                                                                                    \
        | nice -n $PARALLEL_NICENESS $PARALLEL_BIN                                                      \
               --colsep ' '                                                                             \
               --joblog $PARALLEL_JOB_LOGS/$(date +"${DATESTAMP_FORMAT}").rosininstruments.log          \
               $MISC_PARALLEL_OPTS                                                                      \
               -j $PARALLEL_FORK                                                                        \
               http_microsoft_head_cmd "{1}" "{2}"
}
