
# Scripts de Monitoring pour mon Réseau Local

Ce dépôt contient un ensemble de scripts Bash conçus pour surveiller et maintenir l'environnement de mon réseau local. Ces scripts automatisent des tâches telles que la mise à jour des systèmes, la sauvegarde des appareils Raspberry Pi, la surveillance des conteneurs Docker, et l'envoi d'alertes aux canaux Discord.

## Fonctionnalités

- **Mises à jour système** : Automatise le processus de mise à jour des systèmes AlmaLinux ou Raspberry Pi.
- **Sauvegarde** : Sauvegarde la carte SD de mes Raspberry Pi et de mes conteneurs Docker, et envoie des notifications de succès ou d'échec à un webhook Discord.
- **Nettoyage** : Supprime automatiquement les fichiers de sauvegarde plus anciens qu'une durée spécifiée (4 mois).
- **Surveillance** : Mises à jour périodiques et notifications de statut pour chaque système.
- **Notifications Discord** : Envoie des mises à jour en temps réel à un canal Discord pour chaque tâche réussie ou échouée.
- **Webhook Service** : Chaque serveur exécute un service qui envoie les mises à jour de statut à Discord via un webhook.

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

5. **Service webhook** : Chaque serveur doit exécuter un service ou un cron job qui enverra les informations de statut à Discord via un webhook. Exemple de commande pour lancer ce service sur chaque serveur :
   ```bash
   ./service-webhook.sh
   ```

## Exemple d'utilisation

Pour effectuer une mise à jour sur un système AlmaLinux et recevoir une notification :
```bash
./maj+log-rpi.sh ou ./maj+log-alma9.sh
```
Cela lancera un processus de mise à jour et enverra un message à votre webhook Discord avec le résultat.

Pour sauvegarder la carte SD d'un Raspberry Pi :
```bash
./backup-carte-sd-rpi.sh
```

Pour sauvegarder un conteneur Docker :
```bash
./backup-docker-local.sh
```

### Exemple de message webhook Discord :
Un message typique envoyé par le service webhook à Discord pourrait ressembler à ceci :

```
[Nom_de_machine] 🔄 Début de la mise à jour...
[Nom_de_machine] ✅ La mise à jour a réussi ! Temps écoulé : 3 minutes
```

## Remarque

Tous les scripts doivent être exécutés avec les privilèges appropriés. Assurez-vous que votre utilisateur a les permissions nécessaires pour exécuter les commandes `sudo`, `docker` et effectuer les sauvegardes.
