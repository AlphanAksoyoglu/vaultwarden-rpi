#!/bin/bash

RED='\033[0;31m'       
GREEN='\033[0;32m'     
YELLOW='\033[0;33m'    
CYAN='\033[0;36m'      
RESET='\033[0m'        
CHECKM='\u2714'


log() { echo -e "${YELLOW}[INSTALLER_MSG] $*${RESET}" 
}
warn() { echo -e "${RED}[INSTALLER_MSG] $*${RESET}"
}
ask() { echo -e "${CYAN}[INSTALLER_MSG] $*${RESET}"
}
all_good() { echo -e "${GREEN}[INSTALLER_MSG] $* ${CHECKM} ${RESET}"
}

_setArgs(){
  while [ "${1:-}" != "" ]; do
    case "$1" in
      "--init")
        init=true
        ;;
      "--install")
        install=true
        ;;
    esac
    shift
  done
}

confirm() {
    local default_value=$1
    while true; do
        ask "$2 (Y/n):"
        read  answer
        case $answer in
            [Yy] ) return 0;;
            [Nn] ) return 1;;
            "" ) return "$default_value";;
            * ) warn "Please answer Y/y or N/n";;
        esac
    done
}

confirm_num() {
    local default_value=$1
    while true; do
        ask "$2:"
        read answer
        case $answer in
            1 ) return 0;;
            2 ) return 1;;
            "" ) return;;
            * ) warn "Please enter 1 or 2";;
        esac
    done
}

export_choices() {
    echo "SERVICES_HOME=$SERVICES_HOME" > install_vars
    echo "include_cloudflare=$include_cloudflare" >> install_vars
    echo "include_duckdns=$include_duckdns" >> install_vars
    echo "include_tailscale=$include_tailscale" >> install_vars
    echo "include_backup=$include_backup" >> install_vars
    echo "include_iptables=$include_iptables" >> install_vars
}

import_choices() {
    source ./install_vars
    export SERVICES_HOME=$SERVICES_HOME
}

set_config() {

    paths=(
    "$SERVICES_HOME/backup/configs/.msmtprc"
    "$SERVICES_HOME/backup/configs/backup_cron"
    "$SERVICES_HOME/backup/processors/backup.env"
    "$SERVICES_HOME/caddy/caddy.env"
    "$SERVICES_HOME/caddy/Caddyfile"
    "$SERVICES_HOME/vaultwarden/vaultwarden.env"
    "$SERVICES_HOME/tailscale/tailscale.env"
    "$SERVICES_HOME/utils/vaultwarden-docker.service"
    "$SERVICES_HOME/utils/revert_ip_tables.sh"
    "$SERVICES_HOME/utils/set_ip_tables.sh"
    "$SERVICES_HOME/docker-compose.yml"
    "$SERVICES_HOME/utils/dnsmasq.conf"
    "$SERVICES_HOME/utils/config.conf"
    )

    for file in "${paths[@]}"; do
        if [ "$include_duckdns" = true ]; then
            sed -i '/^## IF DUCKDNS/,/^## FI DUCKDNS/{//!s/^#\([^#]\)/\1/}' "$file"
        else
            sed -i '/^## IF DUCKDNS/,/^## FI DUCKDNS/{//!s/^\([^#]\)/#&/}' "$file"
        fi
        
        if [ "$include_tailscale" = true ]; then
            sed -i '/^## IF TAILSCALE/,/^## FI TAILSCALE/{//!s/^#\([^#]\)/\1/}' "$file"
        else
            sed -i '/^## IF TAILSCALE/,/^## FI TAILSCALE/{//!s/^\([^#]\)/#&/}' "$file"
        fi
        
        if [ "$include_cloudflare" = true ]; then
            sed -i '/^## IF CLOUDFLARE/,/^## FI CLOUDFLARE/{//!s/^#\([^#]\)/\1/}' "$file"
        else
            sed -i '/^## IF CLOUDFLARE/,/^## FI CLOUDFLARE/{//!s/^\([^#]\)/#&/}' "$file"
        fi
        
        if [ "$include_backup" = true ]; then
            sed -i '/^## IF BACKUP/,/^## FI BACKUP/{//!s/^#\([^#]\)/\1/}' "$file"
        else
            sed -i '/^## IF BACKUP/,/^## FI BACKUP/{//!s/^\([^#]\)/#&/}' "$file"
        fi
        
        if [ "$include_iptables" = true ]; then
            sed -i '/^## IF IPTABLES/,/^## FI IPTABLES/{//!s/^#\([^#]\)/\1/}' "$file"
        else
            sed -i '/^## IF IPTABLES/,/^## FI IPTABLES/{//!s/^\([^#]\)/#&/}' "$file"
        fi
        
        if [ "$include_iptables" = true ] && [ "$include_tailscale" = true ]; then
            sed -i '/^## IF IPTABLES AND TAILSCALE/,/^## FI IPTABLES AND TAILSCALE/{//!s/^#\([^#]\)/\1/}' "$file"
        else
            sed -i '/^## IF IPTABLES AND TAILSCALE/,/^## FI IPTABLES AND TAILSCALE/{//!s/^\([^#]\)/#&/}' "$file"
        fi
    done

}

init() {

    default_services_home="$HOME/vaultwarden_raspberrypi"
    # true means cloudflare, ugly ugly....
    default_dns=true
    default_tailscale=true
    default_backup=true
    default_iptables=true

    log "This step will initialize the config file according to your choices"
    log "After this step please go through the README and fill out every field"
    log "That needs to be filled in ${SERVICES_HOME}/utils/config.conf"
    echo 
    echo

    ask "Enter your services path (root folder of this repo...)"
    ask "(Default: $default_services_home):"
    read services_home
    services_home="${services_home:-$default_services_home}"
    export SERVICES_HOME=$services_home

    echo

    ask "Enter your DNS Solution of choice" 
    ask "1)Cloudflare (Default) or 2)Duckdns"
    if confirm_num $include_cloudflare; then
        include_cloudflare=$default_dns
        include_duckdns=false
    else
        include_cloudflare=false
        include_duckdns=true
    fi

    echo 

    if confirm $default_tailscale "Do you want to use Tailscale?"; then
        include_tailscale=$default_tailscale
    else
        include_tailscale=false
    fi

    echo

    if confirm $default_backup "Do you want to use Backups?"; then
        include_backup=$default_backup
    else
        include_backup=false
    fi

    echo
    
    if confirm $default_iptables "Do you want to use Firewall (UFW) and IPTABLES?"; then
        include_iptables=$default_iptables
    else
        include_iptables=false
    fi

    log "Here are your selections"
    echo "SERVICES_HOME=$SERVICES_HOME"
    echo "include_cloudflare=$include_cloudflare"
    echo "include_duckdns=$include_duckdns"
    echo "include_tailscale=$include_tailscale"
    echo "include_backup=$include_backup"
    echo "include_iptables=$include_iptables"

    export_choices

    log "Now modifying config file according to your settings"

    set_config

    all_good "All set.."
    log "Please go through the README and fill out all the fields in ${SERVICES_HOME}/utils/config.conf"
    log "please call this script with --install flag to complete installation"
}

check_docker_packages() {
    
    for package in "${docker_packages[@]}"; do
        if ! dpkg -s "$package" >/dev/null 2>&1; then
            missing_docker_packages+=("$package")
        fi
    done

    for package in "${gpg_packages[@]}"; do
        if ! dpkg -s "$package" >/dev/null 2>&1; then
            missing_gpg_packages+=("$package")
        fi
    done
}

install_missing_docker_packages() {

    log "We will be apply the following changes:"
    log "1) Install ca-certificates, curl, gnupg if missing"
    log "2) Add Docker's Official GPG key"
    log "3) Add Docker repo to Apt Sources"
    log "4) Update apt"
    log "5) Install ${missing_docker_packages[*]} if missing"
    
    if confirm true "Do you wish to proceed?"; then

        #Add Docker's official GPG key:
        if [ ${#missing_gpg_packages[@]} -gt 0 ]; then
        
            log "Installing ${missing_gpg_packages[*]}"

            sudo apt update
            sudo apt install -y ca-certificates curl gnupg
            
            all_good "Installed ${missing_gpg_packages[*]}"
        
        else

            all_good "ca-certificates, curl, gnupg already installed"
        
        fi

        if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
            
            log "Adding Docker's Official GPG key"
            sudo install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            sudo chmod a+r /etc/apt/keyrings/docker.gpg
            all_good "Added Docker's Official GPG key"
        
        else
            
            all_good "Docker's Official GPG key is already added"
        
        fi


        if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
            
            log "Addding Docker Repo to Apt Sources"
            
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
            $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            all_good "Added Docker Repo to Apt Sources"
        
        else
            
            all_good "Docker repository entry already exists."
        
        fi
        
        if [ ${#missing_docker_packages[@]} -gt 0 ]; then
        
            log "Now installing ${missing_docker_packages[*]}"
            
            sudo apt update
            sudo apt install -y "${missing_docker_packages[@]}"
            
            all_good "All Done! Finished with Docker Installation"
        
        else
            
            all_good "Docker Packages already installed"

        fi

    else
        
        warn "Not proceeding with Docker Installation"
        return 1
    fi
}

add_user_to_docker_group() {
    if groups "$USER" | grep -q "\bdocker\b"; then
        all_good "USER:$USER already a member of docker group"
        return 0
    else
        log "Adding USER:$USER to docker group"
        sudo usermod -aG docker "$USER"
        return 0
    fi
}

install_docker(){


    log "Checking if all is good with Docker and Docker Compose ..."
    
    docker_packages=("docker-ce" "docker-ce-cli" "containerd.io" "docker-buildx-plugin" "docker-compose-plugin")
    gpg_packages=("ca-certificates" "curl" "gnupg")
    missing_docker_packages=()
    missing_gpg_packages=()
    
    check_docker_packages

    if [ ${#missing_docker_packages[@]} -eq 0 ]; then
        
        all_good "All Docker related packages are installed."
    
    else
        
        warn "Missing Docker-related packages:"
        warn "${missing_docker_packages[@]}"
        warn "${missing_gpg_packages[@]}"

        install_missing_docker_packages
    
    fi

    log "Checking if USER:$USER is in docker group"

    if ! groups "$USER" | grep -q "\bdocker\b"; then
        
        echo
        
        warn "User not in docker group"
        
        if confirm 0 "Do you want to add USER:$USER to docker group?"; then
            
            sudo usermod -aG docker "$USER"
            all_good "Added USER:$USER to docker group"
        
        else
            
            warn "Will not add USER:$USER to docker group"
        
        fi
    
    else
        
        all_good "User is already in the docker group. Skipping."
    
    fi

}

set_environment_files () {
    if [ "$include_iptables" = true ]; then
        python env_set.py "process_iptables"
    else
        python env_set.py
    fi
}

install_modules() {

    import_choices

    echo "These settings were chosen in init state..."

    echo "SERVICES_HOME=$SERVICES_HOME"
    echo "include_cloudflare=$include_cloudflare"
    echo "include_duckdns=$include_duckdns"
    echo "include_tailscale=$include_tailscale"
    echo "include_backup=$include_backup"
    echo "include_iptables=$include_iptables"

    if confirm 0 "Have you filled everything in the config file and wish to continue with these options?"; then
        log "Proceeding.."
    else
        warn "Ok exiting..."
        exit 0
    fi
  
    if confirm 0 "Do you have Docker an Docker Compose installed, and added the User:$USER to the docker group"; then
        log "Skipping Docker Installation..."
    else
        log "Proceeding to Install Docker..."
        install_docker
    fi

    echo
    log "Setting environment vars"
    echo

    set_environment_files

    if [ "$include_tailscale" = true ]; then

        log "Since you will be using Tailscale, we need to:" 
        log "1) Start the tailscale container"
        log "2) Create certificates for caddy"
        log "3) Install dnsmasq"
        log "4) Read the tailscale ip and use it in our dnsmasq.conf"

        if confirm true "Do you wish to proceed with these changes?"; then
        

            log "1) Starting Docker for the Initial Run"
            sudo docker compose -f "$SERVICES_HOME"/docker-compose.yml up tailscale -d
            source "$SERVICES_HOME/caddy/caddy.env"
            log "Creating Certificates"
            sudo docker exec tailscaled tailscale --socket /tmp/tailscaled.sock cert "$TAILSCALE_DOMAIN_NOPROT"
            log "Retrieving Tailscale IP"
            sudo docker exec tailscaled sh -c "tailscale ip --4 > /tmp/tailscale_ip"
            log "Shutting down the container"
            sudo docker compose -f "$SERVICES_HOME"/docker-compose.yml down tailscale


            ip_file="$SERVICES_HOME/tailscale/tmp/tailscale_ip"
        
            read -r tailscale_ip < "$ip_file"
            
            log "Writing Tailscale IP to config.conf and dnsmasq.conf"
            config_file="$SERVICES_HOME/utils/config.conf"
            dnsmasq_file="$SERVICES_HOME/utils/dnsmasq.conf"
            sed -i "s/^TAILSCALE_IP_RASPBERRY_PI=.*/TAILSCALE_IP_RASPBERRY_PI=$tailscale_ip/" "$config_file"
            sed -i "s/^\(address=\/[^\/]*\/\)/\1${tailscale_ip}/" "$dnsmasq_file"

            ask "If all has been successfull here, and your Tailscale client it permanently authenticated"
            ask "You should delete your authorization key and comment out TS_AUTHKEY"
            if confirm true "Do you want to comment out TS_AUTHKEY"; then
                log "Tailscale should now be permanently authenticated, commenting out TS_AUTHKEY"

                tailscale_env_file="$SERVICES_HOME/tailscale/tailscale.env"

                if grep -q "TS_AUTHKEY" "$tailscale_env_file" && ! grep -q "#TS_AUTHKEY" "$tailscale_env_file"; then

                    sed -i 's/TS_AUTHKEY:/#TS_AUTHKEY:/' "$tailscale_env_file"
                fi
            
            else 
                warn "Leaving TS_AUTHKEY as it is"
            fi

            log "Setting up and enabling dnsmasq"

            if dpkg -s dnsmasq &> /dev/null; then

                warn "dnsmasq is already installed, backing up dnsmasq.conf -> dnsmasq.conf.bak"
                if [ -f "/etc/dnsmasq.conf" ]; then
                    sudo cp "/etc/dnsmasq.conf" "/etc/dnsmasq.conf.bak"
                    warn "overwriting dnsmasq.conf, please manually merge with dnsmasq.conf.bak"
                    sudo cp "$SERVICES_HOME"/utils/dnsmasq.conf /etc/dnsmasq.conf
                fi

            else
                sudo apt install -y dnsmasq
                sudo cp "$SERVICES_HOME"/utils/dnsmasq.conf /etc/dnsmasq.conf
                log "Enabling dnsmasq service"
                sudo systemctl enable dnsmasq
            fi

            all_good "All done with Tailscale and dnsmasq"
        else
            warn "Skipping Tailscale configuration..."
        fi

    fi

    if [ "$include_iptables" = true ]; then
        log "You selected to use IPTABLES and UFW Firewall, we will"
        log "1) Install UFW"
        log "2) Setup UFW to deny all incoming requests, except for port 22"
        log "3) Setup IPTABLES rules such that:"
        log "   * Local IPs you allowed will be allowed"
        log "   * Tailsclae IPs you allowed will be allowed"
        log "   to access the DOCKER network"
        log "   Everything else, and MAC Addresses you chose to explicitly block"
        log "   will be blocked from the DOCKER network"

        if confirm true "Do you wish to proceed?"; then

            if dpkg -s ufw &> /dev/null; then
                log "UFW already installed..."
            else
                log "Installing UFW"
                sudo apt install -y ufw
            fi
            
            log "Setting up UFW rules"
            sudo ufw default deny incoming
            sudo ufw allow 22
            log "Enabling UFW"
            sudo ufw enable
            all_good "All done with UFW"
            log "Setting up iptables"

            if [ -e "$SERVICES_HOME/utils/iptables.bak" ]; then
                log "Loading iptables backup..."
                sudo bash -c "iptables-restore < '$SERVICES_HOME/utils/iptables.bak'"
            else
                log "Creating iptables backup..."
                sudo bash -c "iptables-save > '$SERVICES_HOME/utils/iptables.bak'"
            fi



            chmod +x "$SERVICES_HOME"/utils/set_ip_tables.sh
            sudo bash "$SERVICES_HOME"/utils/set_ip_tables.sh

            if dpkg -s iptables-persistent &> /dev/null; then
                log "iptables-persistent already installed, re-sving rules.."
                sudo bash -c "iptables-save > /etc/iptables/rules.v4"
            else

                log "Installing iptables-persistent"
                warn "Please select *yes* when you are asked to save the iptables rules"
                sudo apt install -y iptables-persistent
                
            fi

            log "Enabling iptables-persistent"
            sudo systemctl enable netfilter-persistent

            all_good "All done with IPTABLES"
        else
            warn "Skipping UFW and IPTABLES installation"
        fi
    fi

    log "Creating and enabling the Vaultwarden Service"
    warn "For the first run, you might want to execute"
    warn "sudo docker compose up -d"
    warn "from $SERVICES_HOME"
    warn "As pulling and building the initial containers might take a while"

    sudo cp "$SERVICES_HOME"/utils/vaultwarden-docker.service /etc/systemd/system
    sudo systemctl enable vaultwarden-docker.service

    all_good "All Done with Installation"
    all_good "the Vaultwarden Service will be automatically started after you reboot your machine"

}


invalid_options() {
  echo "Please pass --init or --install as arguments"
}

# Main script
main() {
  _setArgs "$@"

  if [ "$init" = "true" ]; then
    init
  elif [ "$install" = "true" ]; then
    install_modules
  else
    invalid_options
  fi
}


main "$@"
