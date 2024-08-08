#!/bin/bash

echo "welcom to Raspberry Pi Setting!"

os_name=$(lsb_release -si)
if [[ $os_name == "Ubuntu" || $os_name == "Raspbian" ]]; then
    echo "your operation system is $os_name"

else
    echo "your operation system is $os_name"
    echo "please use Ubuntu or Rasbian-OS"
    echo "bye."
    exit 1

fi


setup_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root_dir="$(dirname "$script_dir")"
work_dir="$(dirname "$script_dir")/work"
setup_script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
requirement_txt_path="$setup_dir/requirement.txt"
current_user="$USER"

echo "Using script is $setup_script_path"
echo "Root  directory is $root_dir"
echo "Setup directory is $setup_dir"
echo "Work  directory is $work_dir"


echo "Do you want to set proxy to .bashrc? (y(Default) / n)"
read answer
if [[ "$answer" == "yes" || "$answer" == "y" ]]; then
    echo "This is setting proxy server."
    echo "Please enter proxy ID (example : 220800022) -> "
    read proxy_id

    echo "Please enter proxy PASSWORD -> "
    read proxy_pass 

    echo "Please enter proxy address and port" 
    echo "expample : 192.168.0.0:8080 -> "
    read proxy_address
    echo "Hello, $user_name!"

    echo "export HTTP_PROXY=http://$proxy_id:$proxy_pass@$proxy_address/" >> ~/.bashrc
    echo "export HTTPS_PROXY=http://$proxy_id:$proxy_pass@$proxy_address/" >> ~/.bashrc

    echo "git config --global http.proxy http://$proxy_id:$proxy_pass@$proxy_address" >> ~/.bashrc
    echo "git config --global https.proxy http://$proxy_id:$proxy_pass@$proxy_address" >> ~/.bashrc

    echo 'Acquire::http::Proxy "http://$proxy_id:$proxy_pass@$proxy_address";' | sudo tee /etc/apt/apt.conf > /dev/null
    echo 'Acquire::https::Proxy "http://$proxy_id:$proxy_pass@$proxy_address";' | sudo tee /etc/apt/apt.conf > /dev/null

    # 起動簡略化のalias
    echo 'alias rundb="bash $work_dir/$os_name/run.sh"' >> ~/.bashrc

    source ~/.bashrc


elif [[ "$answer" == "no" || "$answer" == "n" ]]; then
    echo "Proxy setting is not used."


else
    echo "Invalid input. Please enter 'y(yes)' or 'n(no)'."
    exit 1
fi


echo "Software Update at First ..."
sudo apt update
sudo apt upgrade
echo "Complete!"


if [[ $os_name == "Ubuntu" ]]; then
    echo "your operation system is Ubuntu."
    echo "use script -> setup_ubuntu.sh ."

    #基本パッケージ
    sudo apt install -y ssh vsftpd chrony vim-gtk3 
    sudo apt install -y python3-pip git curl wget
    sudo apt install -y ibus-mozc mozc-utils-gui

    #ftpセッティング
    sudo cp /etc/vsftpd.conf /etc/_vsftpd.conf
    cat ${setup_dir}/ftpd_setup.txt | sudo tee /etc/vsftpd.conf > /dev/null
    echo "$current_user" | sudo tee /etc/vsftpd.chroot_list > /dev/null

    #データベース(mysql)
    sudo apt install mysql-server mysql-client

    #phpMyAdmin用
    sudo apt install php8.1 apache2
    sudo apt install phpmyadmin

    #MQTT用 mosquitto
    sudo apt install mosquitto mosquitto_clients

    # pipがインストールされていることを確認
    sudo apt install -y python3-pip

    # requirement.txtからパッケージインストール
    pip3 install -r ${setup_dir}/requirement.txt


elif [[ $os_name == "Raspbian" ]]; then
    echo "your operation system is Raspbian."
    echo "use script -> setup_ubuntu.sh ."

    #基本パッケージ
    sudo apt install -y ssh vsftpd chrony vim-gtk3 
    sudo apt install -y python3-pip git curl wget
    sudo apt install -y ibus-mozc mozc-utils-gui
    sudo apt install -y gedit

    #ftpセッティング
    sudo cp /etc/vsftpd.conf /etc/_vsftpd.conf
    cat ${setup_dir}/ftpd_setup.txt | sudo tee /etc/vsftpd.conf > /dev/null
    echo "$current_user" | sudo tee /etc/vsftpd.chroot_list > /dev/null

    #データベース(mysql)
    sudo apt install mariadb-server mariadb-client

    #phpMyAdmin用
    sudo apt install php8.2 apache2
    sudo apt install phpmyadmin

    #MQTT用 mosquitto
    sudo apt install mosquitto mosquitto_clients

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
    echo "your operation system is $os_name"
    echo "please use Ubuntu or Rasbian-OS"
    echo "bye."
    exit 1
fi



echo "Package install is Finished !"
echo "Please reboot and execute database_setup.sh ."