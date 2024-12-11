#!/system/bin/sh
clear
scripts=$(realpath $0)
scripts_dir=$(dirname ${scripts})
module_dir="/data/adb/modules/TTLink"
parent_dir=$(dirname ${scripts_dir})
# source files
source "${scripts_dir}/settings.ini"
source "${scripts_dir}/TTLink.service"
# Determines a path that can be used for relative path references.
cd ${scripts_dir}

proxy_service() {
    if [ ! -f "${module_dir}/disable" ]; then
        log Info "Module Enabled"
        log Info "Start TTLink"
        ${scripts_dir}/TTLink.service enable >/dev/null 2>&1 &&
        ${scripts_dir}/TTLink.service description >/dev/null 2>&1
    else
        log Warn "Module Disabled"
        log Info "Module Disabled" >${parent_dir}/log/run.log
    fi
}

start_inotifyd() {
    PIDs=($(busybox pidof inotifyd)) # Environment variables are required.
    for PID in "${PIDs[@]}"; do
        if grep -q "${scripts_dir}/TTLink.inotify" "/proc/$PID/cmdline"; then
            return
        fi
    done
    inotifyd "${scripts_dir}/TTLink.inotify" "${module_dir}" >/dev/null 2>&1 &
}

proxy_service
start_inotifyd

# start.sh
