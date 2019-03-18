#!/bin/bash
# set -a indicates we want the environment and functions declared here to be exported when starting
# new environments. This is necessary for parallel to be able to call functions defined here
# and in extractors / plugins that are loaded

set -a

# Load configuration variables, also persistent with set -a

source config.vars

unset HTTP_PROXY
unset HTTPS_PROXY

if [[ "${VERBOSE}" -eq 1 ]]; then
    set -x
    MISC_PARALLEL_OPTS="${MISC_PARALLEL_OPTS} --eta"
fi

declare -A FUNCNAMES_MAPPING

function create_proxy_scanner_directories() {
  mkdir -p $HTTP_CONNECT_RESULT_DIR \
    $HTTP_RESULT_DIR                \
    $TMPDIR                         \
    $SOCKS4_RESULT_DIR              \
    $SOCKS5_RESULT_DIR              \
    $PARALLEL_JOB_LOGS              \
    $OLD_FILES
}

## zero out previous results prior to beginning new checks but maintain the file for 
## logging purposes:

function truncate_stale_result_files() { 
  find $HTTP_CONNECT_RESULT_DIR \
    $HTTP_RESULT_DIR            \
    $SOCKS4_RESULT_DIR          \
    $SOCKS5_RESULT_DIR          \
    -type f | parallel          \
    -j $PARALLEL_FORK           \
    $MISC_PARALLEL_OPTS         \
    truncate -s 0 {}
}

# Checker Functions #

function console_log() {
    if [[ "$VERBOSE" -eq 1 ]]; then
        echo "";
        echo $1;
    fi
}

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

function ctrl_c() {
    console_log "control-c pressed, exiting cleanly"
    exit 0
}

function convert_names() {
    for x in {extractors,plugins}; do
        for y in $(ls -1 $x/); do
            contents=$(cat $x/$y)
            file_hash=$(sha256sum $x/$y | awk '{print $1}' | tr -d '\n' | head -c 12)
            names=$(echo $contents | grep -ohP "[a-zA-z0-9_]+\s*+\(\)" | tr '\0' ' '  | awk '{print $1}' | tr -d '(' | tr -d ')')
            for z in $names; do
                FUNCNAMES_MAPPING[$z]=$(echo "${x}_${file_hash}_${z}")
            done
        done
    done
}

function inject_scripts() {
    convert_names
    for x in {extractors,plugins}; do
        for script in $(find $x/ -type f -name "*.sh"); do
            file_hash=$(sha256sum $script | awk '{print $1}' | tr -d '\n' | head -c 12)
            ext="${ext}
                "$($ENV_BIN -i $BASH_BIN --noprofile --norc <<xxx
                 set -a
                 source <(cat ./$script)  
                 set +a
                 declare -f
xxx
               )
        done

        for K in "${!FUNCNAMES_MAPPING[@]}"; do
            ext=$(echo "${ext}" | sed "s/\<${K}\>/${FUNCNAMES_MAPPING[$K]}/g")
        done

        source <(echo "#!/bin/bash
                      ${ext}" )

    done
}

console_log "ProxyScanner2 starting: press control-c to abort..."

console_log "Loading plugins and extractors..."

inject_scripts

if [[ "$VERBOSE" -eq 1 ]]; then
    declare -F;
fi

console_log "Creating directories..."

create_proxy_scanner_directories

console_log "Truncating stale files..."

#truncate_stale_result_files

console_log " Starting ETL phase..."

# Extraction phase #

# extractors are just pseudo modules that yield a hostname:port pair 

# declare -f # ok that works, and all of the extractor functions should work
# start running the extractors

for x in $(declare -F | tr ' ' '\n' | grep "extractors_" ); do
    eval "${x}";
done
