#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
GREY='\033[0;37m'
NC='\033[0m' # No Color

DATE=$(date +%Y%m%d%H%M%S%Z)

kube_config_file="${HOME}/.kube/config"
backup_folder="/data/k8s/backup"
sleep_duration=1 # Configurable sleep duration to avoid rate limiting on the API server. Adjust if needed.

if [ ! -f "$kube_config_file" ]; then
  echo -e "${RED}Kube config file not found: ${YELLOW}$kube_config_file${NC}"
  exit 1
fi

function backup_resources() {
    local cluster_name=$1
    local namespaced=$2
    local resource_list=$(kubectl api-resources --namespaced=$namespaced --verbs=list -o name)
    for resource in $resource_list; do
        local file_path="$backup_folder/$DATE/$cluster_name/$resource.yaml"
        echo -e "Backup ${GREEN}$resource ${NC}in ${YELLOW}$file_path${NC}"
        if [ "$namespaced" == "true" ]; then
            kubectl get "$resource" -A --show-kind --ignore-not-found -o yaml > "$file_path" || { echo -e "${RED}Failed to backup $resource for ${YELLOW}$cluster_name${NC}"; continue; }
        else
            kubectl get "$resource" --show-kind --ignore-not-found -o yaml > "$file_path" || { echo -e "${RED}Failed to backup $resource for ${YELLOW}$cluster_name${NC}"; continue; }
        fi
        sleep $sleep_duration
    done
}

# Extract cluster names using kubectl
cluster_names=$(kubectl config get-contexts --output=name | cut -d '/' -f 2)

for cluster_name in $cluster_names; do
  echo -e "${GREEN}Cluster Name: ${YELLOW}$cluster_name${NC}"
  if kubectl config use-context "$cluster_name"; then
      # Check if the cluster is reachable
      if kubectl get nodes >/dev/null 2>&1; then
          mkdir -p "$backup_folder/$cluster_name-$DATE" || { echo -e "${RED}Failed to create directory for ${YELLOW}$cluster_name${NC}"; continue; }
          backup_resources "$cluster_name" false # Backup cluster wide resources
          backup_resources "$cluster_name" true # Backup namespaced resources
      else
          echo -e "${RED}Failed to connect to the cluster: ${YELLOW}$cluster_name${NC}"
      fi
  else
      echo -e "${RED}Failed to switch context to ${YELLOW}$cluster_name${NC}"
  fi
done

echo "Done"
