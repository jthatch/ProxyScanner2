# Extending
Adding a new proxy source is really easy. You just need to make a file and put a function in it that enumerates a list of handler://hostname:port pairs. for example: 

`
- http://63.225.191.41:8000
- socks4://206.125.168.65:3128
- socks5a://75.146.55.254:8080
`

and store the file in the `extractors/` directory. When ProxyScanner2 is started and it's reached the extraction phase your extractor will be automatically loaded by the
dependency injector built into ProxyScanner2. Here's an example of an extractor (proxy-list.download.socks5 )

```
#!/bin/bash 

function proxy_list_dot_download_scrape_socks5() {

  curl 'https://www.proxy-list.download/api/v0/get?l=en&t=socks5' \
    -H 'Referer: https://www.proxy-list.download/SOCKS5' \
    --compressed \
    | jq -r '.[] | .LISTA | .[] | "socks5://" + .IP + ":" + .PORT'
}
```

Extractors are also loaded and versioned (currently hash based on file contents) by the injection framework. The names are changed according to their context and presumed version: 

```
extractor_51c337d6a877_proxy_list_dot_download_scrape_socks5 () 
{ 
    curl 'https://www.proxy-list.download/api/v0/get?l=en&t=socks5' -H 'Referer: https://www.proxy-list.download/SOCKS5' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.109 Safari/537.36' --compressed | jq -r '.[] | .LISTA | .[] | .IP + ":" + .PORT'
}
extractor_d5b269f1abf5_proxy_list_dot_download_socks4 () 
{ 
    curl 'https://www.proxy-list.download/api/v0/get?l=en&t=socks4' -H 'Referer: https://www.proxy-list.download/SOCKS4' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.109 Safari/537.36' --compressed | jq -r '.[] | .LISTA | .[] | .IP + ":" + .PORT'
}

```

And since your code is being run in the ProxyScanner's environment your script and access the entire operational context. Here's a list of what is coming for this project: 

- A DSL/limted API is in the works to make implementing new extractors easy and effective 

- Sandboxed operational context versioning per-extractor and a simple API for creating user-defined phases: for module <-> extractor or extractor <-> extractor interoperability. 

- Dockerfile and docker-compose.yml 

# Contributors 

- exclusive access to contributor-supported seed sharing 
- access to my private library of extractors 
- unlimited access to HAProxy.

## What are seeds 
lists of proxies collected and maintained over a period of time which have earned their reputation for being reliable. ProxyScanner2 is able to process hundreds of requests per second very
efficiently mostly using GNU Parallel and CURL. A list of ~100K proxies will finish in 5-7 minutes (FORK=500, 200MBps and >=200ms latency to the internet.) 
