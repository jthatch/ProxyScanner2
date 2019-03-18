#!/bin/bash

check_history () {
    ## Our internal history extractor
    # commented out for now but later will be uncommented when everything else is finished
    for x in $($FIND_BIN $OLD_FILES/ -type f -name "*.xz"); do
        $XZCAT_BIN $x                                                                           \
            | $NICE_BIN -n $PARALLEL_NICENESS $PARALLEL_BIN                                     \
                   --colsep ' '                                                                 \
                   --joblog $PARALLEL_JOB_LOGS/$(date +"${DATESTAMP_FORMAT}").history-check.log \
                   $MISC_PARALLEL_OPTS                                                          \
                   -j $PARALLEL_FORK                                                            \
                   http_microsoft_head_cmd "{1}" "{2}"
    done
}
