#!/bin/bash

# Variables d'environnement
WEBHOOK_URL="$DISCORD_WEBHOOK_URL"
SSH_KEY="$SSH_KEY_PATH"
BACKUP_DIR="$BACKUP_DIR_PATH"
RASPBERRIES_CONFIG="$RASPBERRIES_CONFIG_PATH"
REMOTE_HOST="$REMOTE_HOST_IP"
REMOTE_USER="$REMOTE_USER_NAME"
REMOTE_KEY_PATH="$REMOTE_KEY_PATH"
LOCAL_BACKUP_DIR="$LOCAL_BACKUP_DIR_PATH"
CONTAINER_ASTERISK="asterisk"
CONTAINER_AGENTDVR="AgentDVR-Server"

# Fonction pour envoyer des messages via Discord
send_message() {
    local message=$1
    local machine_name=$2
    curl -X POST -H "Content-Type: application/json" \
         -d "{\"content\": \"[${machine_name}] ${message}\"}" \
         $WEBHOOK_URL
}

# Fonction pour effectuer les mises à jour
perform_update() {
    send_message "🔄 Début de la mise à jour sur ${MACHINE_NAME}..." "$MACHINE_NAME"
    dnf -y update
    if [ $? -eq 0 ]; then
        send_message ":white_check_mark: Les mises à jour ont réussi sur ${MACHINE_NAME}." "$MACHINE_NAME"
    else
        send_message ":x: Erreur de mise à jour sur ${MACHINE_NAME}." "$MACHINE_NAME"
    fi
}

# Fonction pour envoyer un message au webhook Discord
send_message_to_discord() {
    local message=$1
    curl -X POST -H "Content-Type: application/json" \
        -d "{\"content\": \"$message\"}" \
        "$WEBHOOK_URL"
}

# Fonction pour sauvegarder un Raspberry Pi
backup_raspberry() {
    local ip=$1
    local user=$2
    local port=$3
    local start_time=$(date +%s)
    local backup_file="${BACKUP_DIR}/rpi_backup_${ip}_$(date +%Y-%m-%d).img"
    local script_name="backup_rpi.sh"
    mkdir -p "$BACKUP_DIR"
    echo "Démarrage de la sauvegarde pour $ip..."
    ssh -i "$SSH_KEY" -p "$port" "$user@$ip" "sudo dd if=/dev/mmcblk0 bs=4M" | dd of="$backup_file" bs=4M status=progress
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    if [ $? -eq 0 ]; then
        local status="succès"
        local message=":white_check_mark: **$script_name**: La sauvegarde a réussi pour $ip en $duration secondes. Fichier: $backup_file"
    else
        local status="échec"
        local message=":x: **$script_name**: La sauvegarde a échoué pour $ip après $duration secondes. Vérifiez les logs."
    fi
    send_message_to_discord "$message"
}

# Fonction pour supprimer les sauvegardes anciennes de plus de 4 mois
cleanup_old_backups() {
    echo "Suppression des fichiers de sauvegarde vieux de plus de 4 mois dans $BACKUP_DIR..."
    find "$BACKUP_DIR" -type f -name "*.img" -mtime +120 -exec rm -f {} \;
    if [ $? -eq 0 ]; then
        local message=":recycle: **backup_rpi.sh**: Nettoyage terminé. Les fichiers de sauvegarde vieux de plus de 4 mois ont été supprimés."
    else
        local message=":x: **backup_rpi.sh**: Échec du nettoyage des anciens fichiers de sauvegarde."
    fi
    send_message_to_discord "$message"
}

# Fonction pour faire la sauvegarde du conteneur Docker
backup_container() {
    local container_name=$1
    local backup_dir=$2
    local backup_file="${backup_dir}/${container_name}_backup_${DATE}.tar.gz"
    echo "Démarrage de la sauvegarde pour ${container_name}..."
    start_time=$(date +%s)
    sudo docker export $container_name | gzip > $backup_file
    if [ $? -eq 0 ]; then
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        send_message_to_discord ":white_check_mark: **Backup réussi** pour **${container_name}** : Fichier sauvegardé : \`${backup_file}\` | Durée : \`${duration}s\`"
    else
        send_message_to_discord ":x: **Échec du backup** pour **${container_name}**"
    fi
}

# Fonction pour supprimer les sauvegardes anciennes de plus de 4 mois
clean_old_backups() {
    echo "Vérification des sauvegardes anciennes..."
    find $LOCAL_BACKUP_DIR -type f -name "*.tar.gz" -mtime +7 -exec rm -f {} \;
    echo "Suppression des sauvegardes de plus de 7 jours terminée."
}

# Sauvegarde des Raspberry Pi
if [ -f "$RASPBERRIES_CONFIG" ]; then
    while IFS=' ' read -r ip user port; do
        backup_raspberry "$ip" "$user" "$port"
    done < "$RASPBERRIES_CONFIG"
else
    echo "Erreur: Le fichier de configuration des Raspberry Pi est manquant ou inaccessible."
    exit 1
fi

# Sauvegarde des conteneurs Docker
DATE=$(date +'%Y-%m-%d_%H-%M-%S')

# Sauvegarde du conteneur local "AgentDVR-Server"
backup_container $CONTAINER_AGENTDVR $LOCAL_BACKUP_DIR

# Sauvegarde du conteneur distant "asterisk"
echo "Connexion à $REMOTE_HOST pour la sauvegarde du conteneur $CONTAINER_ASTERISK..."
start_time=$(date +%s)
ssh -i $REMOTE_KEY_PATH $REMOTE_USER@$REMOTE_HOST "docker export $CONTAINER_ASTERISK | gzip" > "${LOCAL_BACKUP_DIR}/${CONTAINER_ASTERISK}_backup_${DATE}.tar.gz"
if [ $? -eq 0 ]; then
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    send_message_to_discord ":white_check_mark: **Backup réussi** pour **${CONTAINER_ASTERISK}** sur **${REMOTE_HOST}**"
else
    send_message_to_discord ":x: **Échec du backup** pour **${CONTAINER_ASTERISK}** sur **${REMOTE_HOST}**"
fi

# Nettoyage des anciennes sauvegardes
cleanup_old_backups
clean_old_backups

# Mise à jour de la machine
MACHINE_NAME=$(hostname)
perform_update

# Fin du script
send_message_to_discord ":white_check_mark: **Sauvegarde et mise à jour terminées pour tous les systèmes.**"
echo "Toutes les sauvegardes et la mise à jour sont terminées."
