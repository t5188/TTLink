#!/system/bin/sh
cd ${0%/*} # current working directory
# source files
source "$(pwd)/settings.ini"
source "$(pwd)/TTLink.service"

proxy_service() {
  if [[ ! -f "${module_dir}/disable" ]]; then
    log Info "Module Enabled"
    log Info "Start TTLink"
    $(pwd)/TTLink.service enable >/dev/null 2>&1
  else
    log Warn "Module Disabled"
    log Info "Module Disabled" >${parent_dir}/log/run.log
  fi
}

net_inotifyd() {
  while [[ ! -f /data/misc/net/rt_tables ]]; do
    sleep 3
  done

  net_dir="/data/misc/net"

  for PID in "${PIDs[@]}"; do
    if grep -q "$(pwd)/net.inotify" "/proc/$PID/cmdline"; then
      return
    fi
  done
  inotifyd "$(pwd)/net.inotify" "${net_dir}" >/dev/null 2>&1 &
}

start_inotifyd() {
  PIDs=($(busybox pidof inotifyd)) # Environment variables are required.
  net_inotifyd
  for PID in "${PIDs[@]}"; do
    if grep -q "$(pwd)/TTLink.inotify" "/proc/$PID/cmdline"; then
      return
    fi
  done
  inotifyd "$(pwd)/TTLink.inotify" "${module_dir}" >/dev/null 2>&1 &
}

proxy_service
start_inotifyd

# start.sh
