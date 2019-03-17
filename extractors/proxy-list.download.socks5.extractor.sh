#!/bin/bash 

function proxy_list_dot_download_scrape_socks5_extractor() {

  curl 'https://www.proxy-list.download/api/v0/get?l=en&t=socks5' \
    -H 'Referer: https://www.proxy-list.download/SOCKS5' \
    -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.109 Safari/537.36' \
    --compressed \
    | jq -r '.[] | .LISTA | .[] | .IP + ":" + .PORT'
}
 