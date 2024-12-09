#!/system/bin/sh
clear
scripts=$(realpath $0)
scripts_dir=$(dirname ${scripts})
module_dir="/data/adb/modules/TTLink"
# Determines a path that can be used for relative path references.

settings_file=${scripts_dir}/settings.ini

green="\033[32m"
red="\033[31m"
normal="\033[0m"

if [ ! -f "${module_dir}/disable" ]; then
    touch "${module_dir}/disable"
    echo -e "${red}代理软件暂时关闭，稍后自动开启${normal}"
else
    echo -e "${red}代理软件未开启，稍后自动开启${normal}"
fi


# 获取当前配置的代理模式
network_mode=$(grep -E '^network_mode=' $settings_file | cut -d'=' -f2)

echo -e "${green}当前代理方式是: ${network_mode}${normal}"

while true; do
    echo "请选择代理方式："
    select mode in "tproxy" "tun" "退出"; do
        if [ -n "${mode}" ]; then
            # 将选择的代理方式赋值给 network_mode
            network_mode="${mode}"
            echo -e "${green}您选择的代理方式是: ${network_mode}${normal}"
            
            # 使用 sed 替换 settings.ini 中的 network_mode 值
            sed -i "s/^network_mode=.*/network_mode=${network_mode}/" $settings_file
            
            echo -e "${green}settings.ini 文件中的代理方式已更新为: ${normal}"
            break 2  # 退出外层循环
        else
            echo -e "${red}输入无效，请重新选择${normal}"
        fi
    done
done