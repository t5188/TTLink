#!/system/bin/sh
clear
scripts=$(realpath $0)
scripts_dir=$(dirname ${scripts})
module_dir="/data/adb/modules/TTLink"
# Determines a path that can be used for relative path references.

source "${scripts_dir}/settings.ini"
source "${scripts_dir}/TTLink_tproxy.service"
source "${scripts_dir}/TTLink_tun.service"
sing_config=${parent_dir}/confs/box_config.json
yq=${parent_dir}/binary/yq

cd ${scripts_dir}

# Environment variable settings
export PATH="/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:$PATH"

proxy_service() {
    if [ ! -f "${module_dir}/disable" ]; then
        log Info "Module Enabled"
        log Info "Start TTLink"
        if [ "${network_mode}" = "tproxy" ]; then
            $yq '.inbounds = [] | .inbounds += [{
                "type": "tproxy",
                "tag": "tproxy-in",
                "listen": "::",
                "listen_port": 1536,
                "sniff": true,
                "sniff_override_destination": true
            }]' -i --output-format=json "${sing_config}"
            ${scripts_dir}/TTLink_tproxy.service enable > /dev/null 2>&1 && \
            ${scripts_dir}/TTLink_tproxy.service description > /dev/null 2>&1
        else
            $yq '.inbounds = [] | .inbounds += [{
                "type": "tun",
                "tag": "tun-in",
                "interface_name": "tun0",
                "mtu": 1400,
                "auto_route": true,
                "strict_route": true,
                "endpoint_independent_nat": true,
                "address": [
                    "172.18.0.1/30",
                    "fdfe:dcba:9876::1/126"
                ],
                "route_exclude_address": [
                    "127.0.0.0/16",
                    "fc00::/7",
                    "168.138.170.58/32",
                    "138.2.83.107/32",
                    "146.235.16.222/32",
                    "213.35.97.236/32",
                    "129.150.50.129/32",
                    "146.56.128.39/32",
                    "152.70.244.79/32"
                ],
                "stack": "system",
                "sniff": true,
                "sniff_override_destination": true
            }]' -i --output-format=json "${sing_config}"
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
