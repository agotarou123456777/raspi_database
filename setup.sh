#!/bin/bash

echo "welcom to Raspberry Pi Setting!"

set -e

os_name=$(lsb_release -si)
if [ ${os_name} == "Ubuntu" ] || [ ${os_name} == "Raspbian" ]; then
    echo "your operation system is ${os_name}"

else
    echo "your operation system is ${os_name}"
    echo "please use Ubuntu or Rasbian-OS"
    echo "bye."
    exit 1

fi


echo "directory exist confim ..."
root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
echo "root directory is set : ${root_dir}"
setup_dir="${root_dir}/setup"
echo "setup directory is set : ${setup_dir}"
work_dir="${root_dir}/work"
echo "work  directory is set : ${work_dir}"

if [ -d "${setup_dir}" ] && [ -d "${root_dir}" ] && [ -d "${work_dir}" ]; then
    echo "directory exist confirmed !"
else
    echo "directory don't exist !"
    echo "please confirm directory place !"
    echo "bye."
    exit 1
fi


echo "setup script exist confim ..."
setup_script_path="${setup_dir}/setup.sh"
database_create_py="${setup_dir}/database_creation.py"
echo "setup.sh is set : ${setup_script_path}"
echo "database_create.py is set : ${database_create_py}"

if [ -f "$setup_script_path" ] && [ -f "$database_create_py" ]; then
    echo "file exist confimed !"
else
    echo "files don't exist !"
    echo "please confirm file place !"
    echo "bye."
    exit 1
fi

read -p "Do you want to set proxy to .bashrc? (y(Default) / n)" answer
if [ ${answer} == "yes" ] || [ ${answer} == "y" ]; then
    echo "This is setting proxy server."
    read -p "Please enter proxy ID (example : 220800022) -> " proxy_id

    read -p "Please enter proxy PASSWORD -> " proxy_pass 

    echo "Please enter proxy address and port" 
    read -p "expample : 192.168.0.0:8080 -> " proxy_address
    echo "Hello, ${proxy_id}!"
    echo "Proxy server is set to ${proxy_address}"


    echo "# This is setup.bash settings=========================================" >> ~/.bashrc
    echo "export HTTP_PROXY=http://${proxy_id}:${proxy_pass}@${proxy_address}/" >> ~/.bashrc
    echo "export HTTPS_PROXY=http://${proxy_id}:${proxy_pass}@${proxy_address}/" >> ~/.bashrc

    echo "git config --global http.proxy http://${proxy_id}:${proxy_pass}@${proxy_address}" >> ~/.bashrc
    echo "git config --global https.proxy http://${proxy_id}:${proxy_pass}@${proxy_address}" >> ~/.bashrc
    
    echo "alias rundb=\"bash ${work_dir}/${os_name}/run.sh\"" >> ~/.bashrc
    echo "# This is setup.bash settings=========================================" >> ~/.bashrc
    
    echo "# This is setup.bash settings" | sudo tee /etc/apt/apt.conf >> /dev/null
    echo "Acquire::http::Proxy \"http://${proxy_id}:${proxy_pass}@${proxy_address}\";" | sudo tee -a /etc/apt/apt.conf > /dev/null
    echo "Acquire::https::Proxy \"http://${proxy_id}:${proxy_pass}@${proxy_address}\";" | sudo tee -a /etc/apt/apt.conf > /dev/null
    echo "/etc/apt/apt.conf is set ... Done !"
    cat /etc/apt/apt.conf

    source ~/.bashrc

elif [ ${answer} == "no" ] || [ ${answer} == "n" ]; then
    echo "Proxy setting is not used."

else
    echo "Invalid input. Please enter 'y(yes)' or 'n(no)'."
    exit 1
fi


echo "Software Update at First ..."
sudo apt update && sudo apt upgrade -y
echo "Done !"


echo "Software basic package install ..."
sudo apt install -y ssh chrony 
sudo apt install -y vim-gtk3 gedit
sudo apt install -y python3-pip git curl wget
sudo apt install -y ibus-mozc mozc-utils-gui
sudo apt install -y mosquitto mosquitto-clients
sudo apt install -y gedit
echo "Done !"


# ftpセッティング
sudo apt install -y vsftpd
sudo cp -rf /etc/vsftpd.conf /etc/_vsftpd.conf
cat ${setup_dir}/ftpd_setup.txt | sudo tee /etc/vsftpd.conf > /dev/null
echo "${USER}" | sudo tee /etc/vsftpd.chroot_list > /dev/null


if [ ${os_name} == "Ubuntu" ]; then
    echo "your operation system is ${os_name}."

    # データベース(mysql)とhpMyAdmin用のパッケージインストール
    sudo apt install -y mysql-server mysql-client
    sudo apt install -y php8.1 apache2
    sudo apt install -y phpmyadmin

    # requirement.txtからパッケージインストール
    pip3 install -r ${setup_dir}/requirement.txt


elif [ ${os_name} == "Raspbian" ]; then
    echo "your operation system is ${os_name}."

    #データベース(mysql)とhpMyAdmin用のパッケージインストール
    sudo apt install -y mariadb-server mariadb-client
    sudo apt install -y php8.2 apache2
    sudo apt install -y phpmyadmin

    # 仮想環境を作成
    venv_dir=".pidbenv"
    PY_VENV=$root_dir/$venv_dir
    if [ ! -d "$PY_VENV" ]; then
        echo "Creating virtual environment."
        python3 -m venv "$PY_VENV"
    fi

    # 仮想環境をアクティベート
    echo "Activating virtual environment."
    source "$PY_VENV/bin/activate"

    # パッケージをインストール
    echo "Installing packages from $requirement_txt_path ."
    pip install -r $requirement_txt_path

    # 仮想環境のデアクティベート
    echo "Deactivating virtual environment."
    deactivate

    echo "Done."

else
    echo "your operation system is ${os_name}"
    echo "please use Ubuntu or Rasbian-OS"
    echo "bye."
    exit 1
fi



echo "Package install is Finished !"
echo "Please reboot and execute database_setup.sh ."
