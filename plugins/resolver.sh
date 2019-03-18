#!/bin/bash

function resolve_host() {
    getent ${GETENT_ARGS} $1 | head -n 1 | awk '{print $1}'
}
