#!/system/bin/sh

scripts_dir="/data/adb/TTLink/scripts"
(
until [ "$(getprop sys.boot_completed)" -eq 1 ]; do
    sleep 3
done

chmod 755 "${scripts_dir}/start.sh"

"${scripts_dir}/start.sh"
) &

# TTLink.sh