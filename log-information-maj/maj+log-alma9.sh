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

    # Mise à jour AlmaLinux (sans vérification)
    dnf -y update
    # Capturer le code de sortie et effectuer un traitement d'erreur
    local update_exit_code=$?

    # Envoi du message de succès ou d'échec basé sur le code de sortie
    if [ $update_exit_code -eq 0 ]; then
        send_message ":white_check_mark: Les mises à jour ont réussi sur ${MACHINE_NAME}." "$MACHINE_NAME"
    else
        send_message ":x: Erreur de mise à jour sur ${MACHINE_NAME}. Code d'erreur : $update_exit_code" "$MACHINE_NAME"
    fi
}

# Nom de la machine
MACHINE_NAME=$(hostname)

# Appel de la fonction de mise à jour
perform_update
