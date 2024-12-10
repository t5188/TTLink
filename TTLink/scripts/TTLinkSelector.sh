#!/system/bin/sh
clear

# 获取脚本的绝对路径和模块路径
scripts=$(realpath $0)
scripts_dir=$(dirname ${scripts})
parent_dir=$(dirname ${scripts_dir})
module_dir="/data/adb/modules/TTLink"
settings_file=${scripts_dir}/settings.ini
source ${scripts_dir}/settings.ini

# 检查 yq 是否存在
if [ ! -f "$yq" ]; then
    echo -e "${red}yq 工具未找到，请确保路径正确或安装 yq${normal}"
    exit 1
fi

# 检查 settings.ini 文件是否存在
if [ ! -f "$settings_file" ]; then
    echo -e "${red}settings.ini 文件不存在，无法继续${normal}"
    exit 1
fi

# 检查 box_config.json 文件是否存在
if [ ! -f "$box_config_file" ]; then
    echo -e "${red}box_config.json 文件不存在，无法继续${normal}"
    exit 1
fi

# 代理模块禁用状态检查
if [ ! -f "${module_dir}/disable" ]; then
    touch "${module_dir}/disable"
    echo -e "${red}代理软件暂时关闭，稍后自动开启${normal}"
else
    echo -e "${red}代理软件未开启，稍后自动开启${normal}"
fi

# 记录开始时间
start_time=$(date +%s)

# 循环，直到 sing-box 和 xray 两个进程都不再运行，或者超过 10 秒
while true; do
    # 检查 sing-box 和 xray 进程是否正在运行
    if ! pgrep -x "sing-box" >/dev/null && ! pgrep -x "xray" >/dev/null; then
        echo "${red}Both sing-box and xray are not running. Breaking the loop.${normal}"
        break
    fi

    # 获取当前时间
    current_time=$(date +%s)

    # 计算已过时间
    elapsed_time=$((current_time - start_time))

    # 如果超过 10 秒，强制退出
    if [ $elapsed_time -ge 10 ]; then
        echo "Timeout reached (10 seconds). Forcefully breaking the loop."
        break
    fi

    # 等待 1 秒后继续检查
    sleep 1
done

# 获取当前配置的代理模式
network_mode=$(grep -E '^network_mode=' $settings_file | cut -d'=' -f2)
echo -e "${green}当前代理方式是: ${network_mode}${normal}"

# 选择代理模式
echo "请选择代理方式："
select mode in "tproxy" "tun" "退出"; do
    case $mode in
    "tproxy")
        echo -e "${green}您选择的代理方式是: tproxy${normal}"
        sed -i 's/^network_mode=.*/network_mode="tproxy"/' "$settings_file"
        break
        ;;
    "tun")
        echo -e "${green}您选择的代理方式是: tun${normal}"
        sed -i 's/^network_mode=.*/network_mode="tun"/' "$settings_file"
        break
        ;;
    "退出")
        echo -e "${green}退出程序${normal}"
        break
        ;;
    *)
        echo -e "${red}输入无效，请重新选择${normal}"
        ;;
    esac
done

# 确保代理软件再次启用
rm -f "${module_dir}/disable"

# TTLinkSelector.sh
