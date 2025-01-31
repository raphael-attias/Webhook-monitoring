#!/bin/bash

# Variables d'environnement pour sécurité
WEBHOOK_URL="$DISCORD_WEBHOOK_URL"
SSH_KEY="$SSH_KEY_PATH"
BACKUP_DIR="$BACKUP_DIR_PATH"

# Liste des Raspberry Pi (les informations sensibles doivent être gérées par un fichier sécurisé ou une autre méthode)
RASPBERRIES_CONFIG="$RASPBERRIES_CONFIG_PATH"

send_message() {
    local message=$1
    local machine_name=$2
    curl -X POST -H "Content-Type: application/json" \
         -d "{\"content\": \"[${machine_name}] ${message}\"}" \
         $WEBHOOK_URL
}

perform_update() {
    send_message "🔄 Début de la mise à jour sur ${MACHINE_NAME}..." "$MACHINE_NAME"
    dnf -y update
    if [ $? -eq 0 ]; then
        send_message ":white_check_mark: Les mises à jour ont réussi sur ${MACHINE_NAME}." "$MACHINE_NAME"
    else
        send_message ":x: Erreur de mise à jour sur ${MACHINE_NAME}." "$MACHINE_NAME"
    fi
}

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
        local message=":white_check_mark: **$script_name**: La sauvegarde a réussi pour $ip en $duration secondes. Fichier: $backup_file"
        echo "Sauvegarde réussie pour $ip : $backup_file"
    else
        local message=":x: **$script_name**: La sauvegarde a échoué pour $ip après $duration secondes. Vérifiez les logs."
        echo "Échec de la sauvegarde pour $ip"
    fi
    send_message "$message"
}

cleanup_old_backups() {
    echo "Suppression des fichiers de sauvegarde vieux de plus de 4 mois dans $BACKUP_DIR..."
    find "$BACKUP_DIR" -type f -name "*.img" -mtime +7 -exec rm -f {} \;
    if [ $? -eq 0 ]; then
        local message=":recycle: **backup_rpi.sh**: Nettoyage terminé. Les fichiers de sauvegarde vieux de plus de 7 joursont été supprimés."
        echo "Nettoyage terminé."
    else
        local message=":x: **backup_rpi.sh**: Échec du nettoyage des anciens fichiers de sauvegarde."
        echo "Échec du nettoyage."
    fi
    send_message "$message"
}

# Lecture de la configuration des Raspberry Pi depuis un fichier sécurisé (par exemple un fichier JSON ou CSV)
if [ -f "$RASPBERRIES_CONFIG" ]; then
    while IFS=' ' read -r ip user port; do
        backup_raspberry "$ip" "$user" "$port"
    done < "$RASPBERRIES_CONFIG"
else
    echo "Erreur: Le fichier de configuration des Raspberry Pi est manquant ou inaccessible."
    exit 1
fi

# Nettoyage des anciens fichiers de sauvegarde
cleanup_old_backups

# Mise à jour locale de la machine
MACHINE_NAME=$(hostname)
perform_update

echo "Toutes les sauvegardes sont terminées, et le nettoyage a été effectué."
