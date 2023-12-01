# Kubernetes Backup Scripts

This project contains scripts and systemd units for managing the backup of Kubernetes resources and implementing a retention policy, utilizing systemd timers as a replacement for cron jobs.

## Important Considerations
- **Backup Storage Location**: The backup files are by default stored in `/data/k8s/backup`. You may need to adjust this path within the scripts according to your system's storage configuration.
- **Handling Systemd Path Requirements**: Systemd service units require absolute paths for script execution. Since the location of the cloned repository might vary, we address this challenge by creating symbolic links (symlinks) to the scripts in a fixed system-wide location, `/usr/local/bin/`. This approach allows systemd to reliably locate and execute the scripts, irrespective of where the repository is cloned. Here's how it works:
  - During setup, symlinks to the scripts in the project's `scripts/` directory are created in `/usr/local/bin/`.
  - These symlinks are then referenced in the systemd service files.
  - This method ensures that any updates to the scripts in the repository are immediately reflected system-wide, maintaining consistency and ease of updates.

## About backup-k8s-resources Script
The `backup-k8s-resources.sh` script is designed to automatically discover all your Kubernetes clusters as configured in your kube config. It then proceeds to backup all resources from these clusters. This comprehensive backup includes deployments, services, persistent volumes, and other Kubernetes objects, ensuring a thorough backup of your cluster's state.

## Backup Retention Defaults
The backup retention policy, implemented by `backup-retention.sh`, is configured with the following defaults:
- **Daily Backups**: Retained for 7 days.
- **Weekly Backups**: For the past 5 weeks, one backup per week is kept.
- **Monthly Backups**: For the past 12 months, one backup per month is retained.
These settings help balance between having a reliable backup history and managing storage space effectively.

## Project Structure
- `scripts/`: Contains the backup scripts.
  - `backup-k8s-resources.sh`: Script to backup Kubernetes resources.
  - `backup-retention.sh`: Script to manage backup retention.
- `systemd/`: Contains systemd service and timer unit files.
  - `backup-k8s-resources.service`: Service unit for Kubernetes backup.
  - `backup-k8s-resources.timer`: Timer unit for scheduling the Kubernetes backup.
  - `backup-retention.service`: Service unit for backup retention.
  - `backup-retention.timer`: Timer unit for scheduling the backup retention.
- `setup.sh`: Script to set up and enable systemd timers.
- `tests/`: Contains helper scripts and tools for debugging backup retention.

## Setup Instructions
1. Clone the repository:
```bash
   git clone https://github.com/paulcosma/kube-backup.git
``````
2. Run the setup script:
> This script sets the necessary permissions, deploys the systemd units, reloads the systemd daemon, enables and starts the timers, and displays the status of all timers.
```bash
sudo ./setup.sh
```

## Contributing
Contributions to this project are welcome. Please ensure you follow the existing project structure and coding style.

### License
MIT License

### Issues and Resolutions
#### Environment Variables in Systemd Services
**Problem**: When the `backup-k8s-resources` script was executed as a systemd service on a Proxmox server, it couldn't access the root user's environment variables. This issue was evident when observing the behavior of `echo $HOME` within the script. When run through the systemd service, it output `/` (the root directory) instead of `/root/`, which is the expected output when the script is run directly from the command line as the root user.
**Cause**: Systemd services run in an isolated environment with a minimal set of environment variables for security and consistency. As a result, environment variables like `$HOME` might not reflect the user's usual interactive shell environment. In this case, the script was unable to locate the Kubernetes configuration file (`kubeconfig`) typically found in the root user's home directory, leading to the failure of `kubectl` commands.
**Solution**: To resolve this, the following settings were added to the `[Service]` section of the `backup-k8s-resources.service` file:
```ini
[Service]
User=root
Group=root
```
