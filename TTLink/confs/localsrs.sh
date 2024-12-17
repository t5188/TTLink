#!/system/bin/sh
scripts=$(realpath $0)
scripts_dir=$(dirname ${scripts})
parent_dir=$(dirname ${scripts_dir})
# Determines a path that can be used for relative path references.
cd ${scripts_dir}

# Color Definition
red="\033[31m"
green="\033[32m"
yellow="\033[33m"
blue="\033[34m"

export PATH="/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:$PATH"

Bin="${parent_dir}/binary/sing-box"

sitename=(bing bing@cn category-ads-all cn discord facebook geolocation-!cn geolocation-cn github google google@cn microsoft microsoft@cn netease netflix openai private reddit steam telegram tencent tld-cn tumblr twitter youtube)

ipname=(cn tw hk telegram)

[ ! -d "./rules" ] && mkdir ./rules

DownloadGeoSrs() {
for site_name in "${sitename[@]}"; do
  curl -L --progress-bar -o geosite-"${site_name}".srs https://srs.acstudycn.eu.org/geosite/${site_name}.srs
if [ $? -eq 0 ]; then
    # 如果成功，执行 echo 命令
    echo -e "${green}geosite-${site_name}.srs下载完毕${normal}"
else
    # 如果失败，输出错误信息
    echo "下载失败，请检查网络或 URL 是否正确。"
fi
config_content+="      {
        \"type\": \"local\",
        \"tag\": \"geosite-${site_name}\",
        \"format\": \"binary\",
        \"path\": \"../confs/rules/geosite-${site_name}.srs\"
      },\n"
done

for ip_name in "${ipname[@]}"; do
  curl -L --progress-bar -o geoip-"${ip_name}".srs https://srs.acstudycn.eu.org/geoip/${ip_name}.srs
if [ $? -eq 0 ]; then
    # 如果成功，执行 echo 命令
    echo -e "${green}geoip-${ip_name}.srs下载完毕${normal}"
else
    # 如果失败，输出错误信息
    echo "下载失败，请检查网络或 URL 是否正确。"
fi
config_content+="      {
        \"type\": \"local\",
        \"tag\": \"geoip-${ip_name}\",
        \"format\": \"binary\",
        \"path\": \"../confs/rules/geoip-${ip_name}.srs\"
      },\n"
done

config_content=${config_content%,\\n}
echo "    \"rule_set\": [\n$config_content\n    ]," > template.json
echo -e "${red}使用template.json文件内容粘贴到配置文件对应位置即可。${normal}"
}

DownloadGeoDb() {
# determine whether to download database files
if [ -e "./rules/geoip.db" ] && [ -e "./rules/geosite.db" ]; then
    echo "两个文件同时存在，不需要下载"
    mv -f ./rules/geo*.db ./
else
    echo "两个文件不同时存在，重新下载"
    curl -L --progress-bar -o geosite.db https://srs.acstudycn.eu.org/geosite.db
    curl -L --progress-bar -o geoip.db https://srs.acstudycn.eu.org/geoip.db
fi
}

# create configuration file
MakeSrsByBox() {
for site_name in "${sitename[@]}"; do
  ${Bin} geosite -c geosite.db export ${site_name}
  echo geosite-${site_name}.srs
  ${Bin} rule-set compile -o geosite-${site_name}.srs geosite-${site_name}.json
  rm geosite-${site_name}.json
config_content+="      {
        \"type\": \"local\",
        \"tag\": \"geosite-${site_name}\",
        \"format\": \"binary\",
        \"path\": \"../confs/rules/geosite-${site_name}.srs\"
      },\n"
done
for ip_name in "${ipname[@]}"; do
  ${Bin} geoip -c geoip.db export ${ip_name}
  echo geoip-${ip_name}.srs
  ${Bin} rule-set compile -o geoip-${ip_name}.srs geoip-${ip_name}.json
  rm geoip-${ip_name}.json
config_content+="      {
        \"type\": \"local\",
        \"tag\": \"geoip-${ip_name}\",
        \"format\": \"binary\",
        \"path\": \"../confs/rules/geoip-${ip_name}.srs\"
      },\n"
done
# file output
config_content=${config_content%,\\n}
echo "    \"rule_set\": [\n$config_content\n    ]," > template.json
  ${Bin} geosite -c geosite.db list > geosite.list
  ${Bin} geoip -c geoip.db list > geoip.list
echo -e "${green}使用template.json文件内容粘贴到配置文件对应位置即可。${normal}"
}

DownloadMakeMove() {
  echo "请选择一个下载操作："
  select option in "DownloadGeoDb" "DownloadGeoSrs" "退出"
  do
    case $option in
      "DownloadGeoDb")
        echo -e "你选择了下载 GeoDb，正在下载...${green}"
        DownloadGeoDb
        if [ $? -eq 0 ]; then
          MakeSrsByBox
        else
          echo "GeoDb 下载失败，跳过 MakeSrsByBox"
        fi
        break
        ;;
      "DownloadGeoSrs")
        echo -e "你选择了下载 GeoSrs，正在下载...${green}"
        DownloadGeoSrs
        break
        ;;
      "退出")
        echo "退出程序。"
        break
        ;;
      *)
        echo "无效选择，请重新选择。"
        ;;
    esac
  done
  mv -f ./*.srs ./rules/ >/dev/null 2>&1
  mv -f ./geo*.* ./rules/ >/dev/null 2>&1
  mv -f ./template.json ./rules >/dev/null 2>&1
}

DownloadMakeMove

# srsmaeker.sh