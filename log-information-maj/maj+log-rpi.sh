#!/bin/bash

# Vérification de la présence du fichier de configuration
if [ ! -f "$HOME/.config/webhook_url" ]; then
    echo "Erreur : Le fichier de configuration pour le webhook est manquant."
    exit 1
fi

# Récupérer l'URL du Webhook depuis le fichier de configuration
WEBHOOK_URL=$(cat "$HOME/.config/webhook_url")

# Fonction pour envoyer des messages via Discord de manière sécurisée
send_message() {
    local message=$1
    local machine_name=$2
    # Éviter les injections de commandes en encodant les caractères spéciaux
    local safe_message=$(echo "$message" | sed 's/"/\\"/g' | sed "s/\$/\\\$/g")
    curl -X POST -H "Content-Type: application/json" \
         -d "{\"content\": \"[${machine_name}] ${safe_message}\"}" \
         "$WEBHOOK_URL"
}

# Fonction pour effectuer les mises à jour
perform_update() {
    send_message "🔄 Début de la mise à jour sur ${MACHINE_NAME}..." "$MACHINE_NAME"

    # Mise à jour Raspberry Pi avec sudo, tout en vérifiant l'exécution des commandes
    sudo apt update
    local apt_update_exit_code=$?
    if [ $apt_update_exit_code -ne 0 ]; then
        send_message ":x: Erreur lors de la mise à jour de la liste des paquets sur ${MACHINE_NAME}." "$MACHINE_NAME"
        return $apt_update_exit_code
    fi

    sudo apt -y upgrade
    local apt_upgrade_exit_code=$?
    if [ $apt_upgrade_exit_code -eq 0 ]; then
        send_message ":white_check_mark: Les mises à jour ont réussi sur ${MACHINE_NAME}." "$MACHINE_NAME"
    else
        send_message ":x: Erreur de mise à jour sur ${MACHINE_NAME}." "$MACHINE_NAME"
    fi
}

# Nom de la machine
MACHINE_NAME=$(hostname)

# Appel de la fonction de mise à jour
perform_update
