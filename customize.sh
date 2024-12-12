#!/system/bin/sh

SKIPUNZIP=1
ASH_STANDALONE=1
unzip_path="/data/adb"

# Define the paths of source folder and the destination folder
source_folder="/data/adb/TTLink"
destination_folder="/data/adb/TTLink$(date +%Y%m%d_%H%M%S)"

unzip -j -o "$ZIPFILE" 'CHANGELOG.md' -d $MODPATH >&2
cat $MODPATH/CHANGELOG.md
rm -f "$MODPATH/CHANGELOG.md"

# Check if the source folder exists
if [ -d "$source_folder" ]; then
    # If the source folder exists, execute the move operation
    mv "$source_folder" "$destination_folder"
    ui_print "- 正在备份已有文件"
    # Delete old folders and update them
    rm -rf "$source_folder"
else
    # If the source folder does not exist, output initial installation information 
    ui_print "- 正在初始安装"
fi

# Set up service directory and clean old installations
if [ -d "/data/adb/modules/TTLink" ]; then
  rm -rf "/data/adb/modules/TTLink"
  ui_print "- 旧模块已删除"
fi

ui_print "- 正在释放文件"
unzip -o "$ZIPFILE" 'TTLink/*' -d $unzip_path >&2
unzip -o "$ZIPFILE" 'webroot/*' -d "$MODPATH" >&2
unzip -j -o "$ZIPFILE" 'TTLink.sh' -d /data/adb/service.d >&2
unzip -j -o "$ZIPFILE" 'uninstall.sh' -d $MODPATH >&2
unzip -j -o "$ZIPFILE" "action.sh" -d $MODPATH >&2
unzip -j -o "$ZIPFILE" "module.prop" -d $MODPATH >&2
unzip -j -o "$ZIPFILE" "system.prop" -d $MODPATH >&2
ui_print "- 正在设置权限"
set_perm_recursive $MODPATH 0 0 0755 0644
set_perm_recursive /data/adb/TTLink/ 0 3005 0755 0755
set_perm_recursive /data/adb/TTLink/scripts/ 0 3005 0755 0700
set_perm /data/adb/service.d/TTLink.sh 0 0 0755
set_perm $MODPATH/uninstall.sh 0 0 0755
set_perm $MODPATH/action.sh 0 0 0755
set_perm /data/adb/TTLink/scripts/ 0 0 0755
ui_print "- 完成权限设置"
ui_print "- 还原配置文件"

# Customize module name based on environment
if [ "$KSU" = "true" ]; then
  sed -i "s/name=.*/name=TTLink for KernelSU/g" $MODPATH/module.prop
elif [ "$APATCH" = "true" ]; then
  sed -i "s/name=.*/name=TTLink for APatch/g" $MODPATH/module.prop
else
  sed -i "s/name=.*/name=TTLink for Magisk/g" $MODPATH/module.prop
fi

largest_folder=$(find /data/adb -maxdepth 1 -type d -name 'TTLink[0-9]*' | sed 's/.*TTLink//' | sed 's/_//g' | sort -nr | head -n 1)

if [ -n "$largest_folder" ]; then
  for folder in /data/adb/TTLink*; do
    clean_name=$(echo "$folder" | sed 's/.*TTLink//' | sed 's/_//g')
    if [ "$clean_name" = "$largest_folder" ]; then
      ui_print "- Found folder: $folder"
      if [ -d "$folder/confs" ]; then
        cp -rf "$folder/confs/"* /data/adb/TTLink/confs/
        ui_print "- Copied contents of $folder/confs to /data/adb/TTLink/confs/"
        cp -rf "$folder/confx/"* /data/adb/TTLink/confx/
        ui_print "- Copied contents of $folder/confx to /data/adb/TTLink/confx/"
        ui_print "- 成功还原配置文件"
      fi
      break
    fi
  done
else
  ui_print "- 首次安装，无备份配置可还原"
fi

ui_print "- enjoy!"
