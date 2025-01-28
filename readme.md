
# Scripts de Monitoring pour mon Réseau Local

Ce dépôt contient un ensemble de scripts Bash conçus pour surveiller et maintenir l'environnement de mon réseau local. Ces scripts automatisent des tâches telles que la mise à jour des systèmes, la sauvegarde des appareils Raspberry Pi, la surveillance des conteneurs Docker, et l'envoi d'alertes aux canaux Discord.

## Fonctionnalités

- **Mises à jour système** : Automatise le processus de mise à jour des systèmes AlmaLinux ou Raspberry Pi.
- **Sauvegarde** : Sauvegarde la cartes sd de mes Raspberry Pi et de mes conteneurs Docker, et envoie des notifications de succès ou d'échec à un webhook Discord.
- **Nettoyage** : Supprime automatiquement les fichiers de sauvegarde plus anciens qu'une durée spécifiée (4 mois).
- **Surveillance** : Mises à jour périodiques et notifications de statut pour chaque système.
- **Notifications Discord** : Envoie des mises à jour en temps réel à un canal Discord pour chaque tâche réussie ou échouée.

## Instructions d'Installation

1. Clonez ce dépôt sur votre système local :
   ```bash
   git clone https://github.com/votre-nom-utilisateur/monitoring-scripts
   ```

2. Modifiez les scripts pour définir votre configuration personnelle, tels que :
   - URL du webhook Discord
   - Clés SSH et détails utilisateur pour les sauvegardes Raspberry Pi
   - Noms des conteneurs Docker et paramètres de l'hôte distant

3. Assurez-vous que les dépendances nécessaires sont installées (par exemple, `curl`, `docker`, `ssh`, `dd`, etc.).

4. Planifiez ou exécutez les scripts selon vos besoins (par exemple, via des tâches cron pour une exécution automatisée).

## Exemple d'utilisation

Pour effectuer une mise à jour sur un système AlmaLinux et recevoir une notification :

```bash
./maj+log-rpi.sh ou ./maj+log-alma9.sh
```

Cela lancera un processus de mise à jour et enverra un message à votre webhook Discord avec le résultat.

Pour sauvegarder la carte sd d'un Raspberry Pi :

```bash
./backup-carte-sd-rpi.sh
```

Pour sauvegarder un conteneur Docker :

```bash
./backup-docker-local.sh
```

## Remarque

Tous les scripts doivent être exécutés avec les privilèges appropriés. Assurez-vous que votre utilisateur a les permissions nécessaires pour exécuter les commandes `sudo`, `docker` et effectuer les sauvegardes.
