#!/bin/bash

# Get the directory of the script
base_dir=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
script_path="$base_dir/scripts"
systemd_unit_path="$base_dir/systemd"

echo "Setting up Kubernetes Backup System..."
echo "Setting execute permissions for scripts..."
chmod +x "$script_path"/*

echo "Creating symlinks for scripts in /usr/local/bin/..."
for script in "$script_path"/*; do
    script_name=$(basename "$script")
    sudo ln -sf "$script" "/usr/local/bin/$script_name"
    echo "Symlink created for $script_name"
done

echo "Deploying systemd service and timer files..."
sudo cp "$systemd_unit_path"/* /etc/systemd/system/

echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

echo "Enabling and starting systemd timers..."
for timer_file in "$systemd_unit_path"/*.timer; do
    timer_name=$(basename "$timer_file")
    sudo systemctl enable --now "${timer_name%.timer}.timer"
done

echo "Systemd timers have been enabled. Current status:"
sudo systemctl list-timers --all

echo "Setup complete."
