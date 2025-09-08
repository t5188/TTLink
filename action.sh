#!/system/bin/sh
# Environment variable settings
export PATH="/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:$PATH"

module_dir="/data/adb/modules/ATTLink"
scripts_dir="/data/adb/TTLink/scripts"

restart_proxy_service() {
  if [ ! -f "${module_dir}/disable" ]; then
    echo "🔁restart TTLink"
    ${scripts_dir}/TTLink.service enable >/dev/null 2>&1
  else
    echo "🥴 module disabled"
    sleep 1
    exit
  fi
}

restart_proxy_service

# action.sh
