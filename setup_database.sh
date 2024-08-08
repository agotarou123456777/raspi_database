#!/bin/bash


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
database_create_py="$setup_dir/database_creation.py"

echo "Using script is $setup_script_path"
echo "Root  directory is $root_dir"
echo "Setup directory is $setup_dir"
echo "Work  directory is $work_dir"

sudo apt update

# 新しいrootパスワードとユーザー情報を設定
echo "Do you want to set root password? (y(Default) / n)"
read answer
if [[ "$answer" == "yes" || "$answer" == "y" ]]; then
    echo "Please enter New root password for database ."
    read root_pass
    ROOT_PASSWORD="$root_pass"

# rootユーザーのパスワードを設定
sudo mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '$ROOT_PASSWORD';
FLUSH PRIVILEGES;
EXIT;
EOF

elif [[ "$answer" == "no" || "$answer" == "n" ]]; then
    echo "Please enter current root password for database ."
    read root_pass
    ROOT_PASSWORD="$root_pass"

else
    echo "Invalid input. Please enter 'y(yes)' or 'n(no)'."
    exit 1
fi

# 新しいユーザーを作成し、パスワードを設定して権限を付与
echo "Do you want to create new user for database? (y(Default) / n)"
read answer
if [[ "$answer" == "yes" || "$answer" == "y" ]]; then
    echo "Please enter New user name ."
    read user_name
    NEW_USER="$root_pass"
    echo "Please enter New user's password ."
    read user_pass
    NEW_USER_PASSWORD="$user_pass"

sudo mysql -u root -p"$ROOT_PASSWORD" <<EOF
CREATE USER '$NEW_USER'@'localhost' IDENTIFIED BY '$NEW_USER_PASSWORD';
FLUSH PRIVILEGES;
GRANT ALL PRIVILEGES ON *.* TO '$NEW_USER'@'localhost' WITH GRANT OPTION;
EXIT;
EOF

elif [[ "$answer" == "no" || "$answer" == "n" ]]; then
    echo "New user is not created ."

else
    echo "Invalid input. Please enter 'y(yes)' or 'n(no)'."
    exit 1
fi



if [[ $os_name == "Ubuntu" ]]; then

    # DB作成scriptを実行
    python3 $database_create_py $root_pass $setup_dir/DBsetting

elif [[ $os_name == "Raspbian" ]]; then

    # 仮想環境がなければ作成
    venv_dir=".pidbenv"
    PY_VENV=$root_dir/$venv_dir
    if [ ! -d "$PY_VENV" ]; then
        echo "Creating virtual environment."
        python3 -m venv "$PY_VENV"
    fi

    # 仮想環境をアクティベート
    echo "Activating virtual environment."
    source "$PY_VENV/bin/activate"
    
    # DB作成scriptを実行
    python3 $database_create_py $root_pass $setup_dir/DBsetting

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