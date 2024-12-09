#!/system/bin/sh
clear

# 获取脚本的绝对路径和模块路径
scripts=$(realpath $0)
scripts_dir=$(dirname ${scripts})
parent_dir=$(dirname ${scripts_dir})
module_dir="/data/adb/modules/TTLink"
settings_file=${scripts_dir}/settings.ini
json_dir="${parent_dir}/confs"  # 假设 JSON 文件存放在此目录下
yq=${parent_dir}/binary/yq

# 颜色定义
green="\033[32m"
red="\033[31m"
normal="\033[0m"

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

# 检查是否存在任何 JSON 文件
if [ ! -n "$(find $json_dir -name "*.json" -print -quit)" ]; then
    echo -e "${red}未找到任何 JSON 文件，无法继续${normal}"
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

# 循环，直到 sing-box 和 xray 两个进程都不再运行，或者超过 5 秒
while true; do
    # 检查 sing-box 和 xray 进程是否正在运行
    if ! pgrep -x "sing-box" > /dev/null && ! pgrep -x "xray" > /dev/null; then
        echo "Both sing-box and xray are not running. Breaking the loop."
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
            # 更新 settings.ini 中的代理模式
            sed -i "s/^network_mode=.*/network_mode=tproxy/" $settings_file
            # 遍历文件夹中的 JSON 文件，直到找到第一个包含 inbounds 字段的文件
            for json_file in "$json_dir"/*.json; do
                # 检查文件中是否包含 inbounds 字段
                if $yq 'has("inbounds")' "$json_file"; then
                    echo "正在修改文件: $json_file"
                    $yq '.inbounds = [] | .inbounds += [{
                        "type": "tproxy",
                        "tag": "tproxy-in",
                        "listen": "::",
                        "listen_port": 1536,
                        "sniff": true,
                        "sniff_override_destination": true
                    }]' -i --output-format=json "$json_file"
                    break  # 找到第一个符合条件的文件后退出循环
                fi
            done
            break
            ;;

        "tun")
            echo -e "${green}您选择的代理方式是: tun${normal}"
            # 更新 settings.ini 中的代理模式
            sed -i "s/^network_mode=.*/network_mode=tun/" $settings_file
            # 遍历文件夹中的 JSON 文件，直到找到第一个包含 inbounds 字段的文件
            for json_file in "$json_dir"/*.json; do
                # 检查文件中是否包含 inbounds 字段
                if $yq 'has("inbounds")' "$json_file"; then
                    echo "正在修改文件: $json_file"
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
                    }]' -i --output-format=json "$json_file"
                    break  # 找到第一个符合条件的文件后退出循环
                fi
            done
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
