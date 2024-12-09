#!/system/bin/sh
clear
scripts=$(realpath $0)
scripts_dir=$(dirname ${scripts})
module_dir="/data/adb/modules/TTLink"
# Determines a path that can be used for relative path references.

source "${scripts_dir}/settings.ini"
source "${scripts_dir}/TTLink_tproxy.service"
source "${scripts_dir}/TTLink_tun.service"

cd ${scripts_dir}

# Environment variable settings
export PATH="/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:$PATH"

proxy_service() {
    if [ ! -f "${module_dir}/disable" ]; then
        log Info "Module Enabled"
        log Info "Start TTLink"
        if [ "${network_mode}" = "tproxy" ]; then
            ${scripts_dir}/TTLink_tproxy.service enable > /dev/null 2>&1 && \
            ${scripts_dir}/TTLink_tproxy.service description > /dev/null 2>&1
        else
            ${scripts_dir}/TTLink_tun.service enable > /dev/null 2>&1 && \
            ${scripts_dir}/TTLink_tun.service description > /dev/null 2>&1
        fi
    else
        log Warn "Module Disabled"
        log Info "Module Disabled" > ${scripts_dir}/run.log
    fi
}

start_inotifyd() {
    PIDs=($(busybox pidof inotifyd))
    for PID in "${PIDs[@]}"; do
        if grep -q "${scripts_dir}/TTLink.inotify" "/proc/$PID/cmdline"; then
            return
        fi
    done
    inotifyd "${scripts_dir}/TTLink.inotify" "${module_dir}" > /dev/null 2>&1 &
}

proxy_service
start_inotifyd

# start.sh
