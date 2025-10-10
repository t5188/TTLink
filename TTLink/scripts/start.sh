#!/system/bin/sh
cd ${0%/*} # current working directory
# source files
source "./settings.ini"
source "./TTLink.service"

proxy_service() {
  if [[ ! -f "${module_dir}/disable" ]]; then
    log Info "Module Enabled"
    log Info "Start TTLink"
    ./TTLink.service enable >/dev/null 2>&1
  else
    log Warn "Module Disabled"
    log Info "Module Disabled" >../log/run.log
  fi
}

net_inotifyd() {
  while [[ ! -f /data/misc/net/rt_tables ]]; do
    sleep 3
  done

  net_dir="/data/misc/net"

  for PID in "${PIDs[@]}"; do
    if grep -q "./net.inotify" "/proc/$PID/cmdline"; then
      return
    fi
  done
  inotifyd "./net.inotify" "${net_dir}" >/dev/null 2>&1 &
}

start_inotifyd() {
  PIDs=($(busybox pidof inotifyd)) # Environment variables are required.
  net_inotifyd
  for PID in "${PIDs[@]}"; do
    if grep -q "./TTLink.inotify" "/proc/$PID/cmdline"; then
      return
    fi
  done
  inotifyd "./TTLink.inotify" "${module_dir}" >/dev/null 2>&1 &
}

proxy_service
start_inotifyd

# start.sh
