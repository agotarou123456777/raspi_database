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

# 新しいrootパスワードとユーザー情報を設定
read -p "Do you want to set root password? (y(Default) / n)" answer
answer="${answer:-y}"
if [ "${answer}" == "yes" ] || [ "${answer}" == "y" ]; then
    read -p "Please enter New root password for database ." root_pass
    echo

    # rootユーザーのパスワードを設定
    sudo mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${root_pass}';
FLUSH PRIVILEGES;
EOF

elif [ "${answer}" == "no" ] || [ "${answer}" == "n" ]; then
    read -p "Please enter current root password for database ." root_pass

else
    echo "Invalid input. Please enter 'y(yes)' or 'n(no)'."
    exit 1
fi

# 新しいユーザーを作成し、パスワードを設定して権限を付与
read -p "Do you want to create new user for database? (y(Default) / n)" answer
answer="${answer:-y}"
if [ "${answer}" == "yes" ] || [ "${answer}" == "y" ]; then
    read -p "Please enter New user name ." new_user_name
    read -p "Please enter New user's password ." new_user_pass

sudo mysql -u root -p"${root_pass}" <<EOF
CREATE USER '${new_user_name}'@'localhost' IDENTIFIED BY '${new_user_pass}';
FLUSH PRIVILEGES;
GRANT ALL PRIVILEGES ON *.* TO '${new_user_name}'@'localhost' WITH GRANT OPTION;
EOF

elif [ "${answer}" == "no" ] || [ "${answer}" == "n" ]; then
    echo "New user is not created ."

else
    echo "Invalid input. Please enter 'y(yes)' or 'n(no)'."
    exit 1
fi



if [ ${os_name} == "Ubuntu" ]; then
    # DB作成scriptを実行
    python3 ${database_create_py} ${root_pass} ${setup_dir}/DBsetting

elif [[ ${os_name} == "Raspbian" ]]; then

    # 仮想環境がなければ作成
    venv_dir=".pidbenv"
    py_venv=${root_dir}/${venv_dir}
    if [ ! -d "${py_venv}" ]; then
        echo "Creating virtual environment."
        python3 -m venv "${py_venv}"
    fi

    # 仮想環境をアクティベート
    echo "Activating virtual environment."
    source "${py_venv}/bin/activate"
    
    # DB作成scriptを実行
    python3 ${database_create_py} ${root_pass} ${setup_dir}/DBsetting

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
