#!/bin/bash

## HTTP/1.1 HEAD request against microsoft.com using the proxy intended to be verified
## for usability. This is a cheap and effective test that will always yield a 302 
## redirect to HTTPS (thus this serves as an elementry verification that CONNECT works
## as well, however many proxies will only allow CONNECT for HTTPS (443) exclusively. 
## The target of the redirect should always yield a 'Server' header value of 'Kestrel' 
## unless this test has become outdated, therefore all results can be verified by 
## (ex: grep -r "Kestrel" $HTTP_RESULT_DIR/ ) which should yield output that looks
## like this: <ipaddress>:<port>:Server: Kestrel

function http_microsoft_head_cmd() {
  nice -n $PARALLEL_JOB_NICENESS $CURL_BIN \
  $MISC_CURL_OPTS                          \
  --retry $CURL_RETRY_COUNT                \
  --connect-timeout $CURL_CONNECT_TIMEOUT  \
  -m $CURL_OVERALL_TIME_ALLOWED            \
  --proxy http://$1:$2                     \
  -L                                       \
  --cookie-jar $COOKIE_JARS/$1:$2          \
  -I http://microsoft.com                  \
  -o $HTTP_RESULT_DIR/$1:$2
}

function process_microsoft_results() { 
  grep -r "Kestrel" $HTTP_RESULT_DIR \
      | sed 's/:Server: Kestrel//g'
}
