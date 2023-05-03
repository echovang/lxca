#!/bin/bash

if ! command -v docker >/dev/null 2>&1; then
    echo "Docker is not installed. Would you like to install it? (y/n)"
    read -r install_docker

    if [ "$install_docker" = "y" ] || [ "$install_docker" = "Y" ]; then
        sudo apt-get update
        sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg

        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg

        echo \
        "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        sudo apt-get update
        sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        
        sudo groupadd docker
        sudo usermod -aG docker $USER
    else
        echo "Skipping Docker installation."
    fi
else
    echo "Docker is already installed."
fi

if ! command -v docker-compose >/dev/null 2>&1; then
    echo "Docker Compose is not installed. Would you like to install it? (y/n)"
    read -r install_docker_compose

    if [ "$install_docker_compose" = "y" ] || [ "$install_docker_compose" = "Y" ]; then
        sudo curl -SL https://github.com/docker/compose/releases/download/v2.17.2/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    else
        echo "Skipping Docker Compose installation."
    fi
else
    echo "Docker Compose is already installed."
fi

echo "Downloading Docker Compose YAML file."
wget https://github.com/echovang/lxca/raw/main/docker-compose.yml

interfaces=$(ip -o link show | awk -F': ' '{print $2}')
echo "Network Interfaces:"
echo "$interfaces"

network_name="mymacvlan"
network_driver="macvlan"

existing_network=$(docker network ls --filter "name=${network_name}" --filter "driver=${network_driver}" -q)

if [ -z "$existing_network" ]; then
    read -p "Enter the parent network interface (e.g., eth0): " parent_interface
    read -p "Enter the subnet for the macvlan network (e.g., 192.168.1.0/24): " subnet
    read -p "Enter the gateway for the macvlan network (e.g., 192.168.1.1): " gateway

    echo "Creating a new macvlan network named '${network_name}'"
    docker network create -d macvlan --subnet="$subnet" --gateway="$gateway" -o parent="$parent_interface" "$network_name"
else
    echo "A macvlan network named '${network_name}' already exists."
fi

read -p "Enter the LXCA container name: " CONTAINER_NAME
read -p "Enter the IP adress: " ADDRESS
read -p "Enter the Docker macvlan network name: " NETWORKNAME

echo "CONTAINER_NAME=${CONTAINER_NAME}" > .env
echo "ADDRESS=${ADDRESS}" >> .env
echo "NETWORKNAME=${NETWORKNAME}" >> .env

echo "The container .env file has been created."

# Image location https://datacentersupport.lenovo.com/us/en/solutions/lnvo-lxcaupd
IMAGE_URL="https://download.lenovo.com/servers/mig/2023/02/27/56998/lnvgy_sw_lxca_container_264-4.0.0_anyos_noarch.tar.gz"

FILE_NAME="lnvgy_sw_lxca_container_264-4.0.0_anyos_noarch.tar.gz"

IMAGE_NAME="lenovo/lxca"
IMAGE_TAG="4.0.0-264"

if ! command -v docker &> /dev/null; then
    echo "Docker not found. Please install Docker and try again."
    exit 1
fi

if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^$IMAGE_NAME:$IMAGE_TAG\$"; then
    echo "Docker image $IMAGE_NAME:$IMAGE_TAG already exists. Skipping download and load."
else
    echo "Downloading the image file..."
    curl -O $IMAGE_URL

    echo "Loading the image file into Docker..."
    docker load -i $FILE_NAME

    echo "Cleaning up the downloaded file..."
    rm $FILE_NAME
fi

if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose not found. Please install Docker Compose and try again."
    exit 1
fi

echo "Creating LXCA Container..."
COMPOSE_HTTP_TIMEOUT=300 docker-compose -p ${CONTAINER_NAME} --env-file=.env up -d

echo "Done."
echo "Please allow a few minutes for LXCA to start"
echo "Access LXCA on https://${ADDRESS}"
