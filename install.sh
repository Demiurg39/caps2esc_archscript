#!/bin/bash

# Функция для проверки установки пакетов
check_packages() {
    packages=("interception-tools" "interception-caps2esc")
    for package in "${packages[@]}"; do
        if pacman -Qi $package &>/dev/null; then
            echo "$package уже установлен."
        else
            echo "$package не установлен. Устанавливаю..."
            sudo pacman -S $package
        fi
    done
}

# Функция для установки и настройки caps2esc
setup_caps2esc() {
    # Проверка и установка необходимых пакетов
    check_packages

    # Создание директории для конфигурации
    sudo mkdir -p /etc/interception/udevmon.d

    # Создание конфигурационного файла caps2esc.yaml
    sudo bash -c 'cat << EOF > /etc/interception/udevmon.d/caps2esc.yaml
- JOB: "intercept -g \$DEVNODE | caps2esc -m 0 | uinput -d \$DEVNODE"
  DEVICE:
    EVENTS:
      EV_KEY: [KEY_CAPSLOCK, KEY_LEFTCTRL]
EOF'
}

# Функция для создания и запуска службы systemd
create_systemd_service() {
    sudo bash -c 'cat << EOF > /etc/systemd/system/udevmon.service
[Unit]
Description=udevmon interception tools
After=network.target

[Service]
ExecStart=/usr/bin/udevmon -c /etc/interception/udevmon.d/caps2esc.yaml
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF'

    # Включение и запуск службы
    sudo systemctl enable udevmon
    sudo systemctl start udevmon
    echo "systemd service created and started."
}

# Обработка аргументов командной строки
if [[ "$1" == "setup" ]]; then
    setup_caps2esc
    sudo udevmon -c /etc/interception/udevmon.d/caps2esc.yaml
    echo "Caps2Esc setup and running."
elif [[ "$1" == "service" ]]; then
    setup_caps2esc
    create_systemd_service
    echo "Caps2Esc setup and systemd service created."
else
    echo "Usage: $0 {setup|service}"
    echo "  setup   - Setup and run Caps2Esc without creating a systemd service."
    echo "  service - Setup Caps2Esc and create a systemd service for autostart."
fi
