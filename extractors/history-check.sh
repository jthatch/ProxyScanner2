#!/bin/bash


check_history () {
    ## Our internal history extractor
    # commented out for now but later will be uncommented when everything else is finished
    for x in $(find $OLD_FILES/ -type f -name "*.xz"); do
        console_log "processing seed.... ${x}"
        http_microsoft_head <(xzcat ${x})
    done
}
