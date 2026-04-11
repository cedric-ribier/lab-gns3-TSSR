# Supervision — Zabbix 7.4

Déploiement d'une solution de supervision complète sur Debian Trixie 13.x.  
Surveillance de l'ensemble de l'infrastructure CreativeFusion Studios avec collecte de métriques via agents Zabbix.

---

## Objectifs

- Déployer Zabbix 7.4 sur un serveur Debian Trixie sans interface graphique
- Superviser l'ensemble des équipements de l'infrastructure
- Collecter et visualiser les métriques via le dashboard web
- Optimiser les performances avec TimescaleDB

---

## Environnement

| Composant | Détail |
|---|---|
| Simulation réseau | GNS3 2.x |
| Hyperviseur | VirtualBox |
| Serveur Zabbix | Debian Trixie 13.x — `par-deadpool-003` |
| IP | `10.0.60.X` — réseau Serveurs |
| Accès | SSH par clé ed25519 depuis poste client |

---

## A. Dimensionnement du serveur

| Ressource | Choix | Justification |
|---|---|---|
| vCPU | 4 | Absorber la charge DB + traitement Zabbix pour ~600 hôtes |
| RAM | 8 à 12 Go | 8 Go minimum réaliste — 12 Go recommandé avec TimescaleDB |
| Stockage | 80 à 120 Go SSD/NVMe | Marge suffisante pour l'historique des métriques |
| OS | Debian Trixie 13.x | Conforme au projet |
| Base de données | PostgreSQL | Recommandé pour Zabbix 7.4 |
| Extension | TimescaleDB | Compression de l'historique — recommandé pour environnements moyens et grands |

Selon Zabbix, une installation small (1000 items) tourne avec 2 vCPU / 8 Go. CreativeFusion Studios (~600 postes) génère un historique plus lourd, plus de triggers et plus d'accès web — d'où le choix de prévoir de la marge pour absorber la charge et anticiper la croissance.

---

## B. Prérequis — configuration de base Debian

```bash
# Mise à jour complète du système
apt update && apt full-upgrade -y

# Installation des paquets utilitaires
apt install -y sudo openssh-server curl wget gnupg lsb-release

# Ajout de l'utilisateur au groupe sudo
usermod -aG sudo $USER
groups $USER

# Vérification SSH
systemctl status ssh
# doit renvoyer : enabled et running

# Récupérer l'adresse IP
ip a
```

---

## C. Accès SSH par clé — sécurisation

### Génération de la clé sur le poste client

```bash
# Sur le poste client (Linux / macOS / Windows OpenSSH)
ssh-keygen -t ed25519 -C "admin@creativefusion-studios.eu"
```

Génère deux fichiers :
- Clé privée : `~/.ssh/id_ed25519` — à importer dans Royal TSX / Xpipe
- Clé publique : `~/.ssh/id_ed25519.pub` — à installer sur le serveur

### Installation de la clé sur le serveur Debian

```bash
# Méthode simple
ssh-copy-id -i ~/.ssh/id_ed25519.pub utilisateur@IP_SERVEUR

# Méthode manuelle
mkdir -p ~/.ssh
chmod 700 ~/.ssh
cat id_ed25519.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### Désactivation de l'authentification par mot de passe

```bash
nano /etc/ssh/sshd_config
```

```ini
PubkeyAuthentication yes
PasswordAuthentication no
PermitRootLogin no
```

```bash
systemctl restart ssh
```

---

## D. Installation de PostgreSQL

```bash
apt install -y postgresql postgresql-contrib
systemctl enable --now postgresql

# Création de l'utilisateur et de la base Zabbix
sudo -u postgres createuser --pwprompt zabbix
sudo -u postgres createdb -O zabbix zabbix
```

---

## E. Installation de Nginx + PHP

```bash
apt install -y nginx php-fpm php-pgsql php-gd php-xml php-bcmath \
    php-ldap php-mbstring php-json php-zip
systemctl enable --now nginx
```

---

## F. Ajout du dépôt Zabbix et installation

```bash
# Téléchargement et ajout du dépôt Zabbix 7.x
wget https://repo.zabbix.com/zabbix/7.0/debian/pool/main/z/zabbix-release/zabbix-release_7.0-1+debian13_all.deb
dpkg -i zabbix-release_7.0-1+debian13_all.deb
apt update

# Installation des composants Zabbix
apt install -y zabbix-server-pgsql zabbix-frontend-php \
    zabbix-nginx-conf zabbix-sql-scripts zabbix-agent
```

---

## G. Installation et activation de TimescaleDB

```bash
# Ajout du dépôt TimescaleDB
wget -qO- https://tsdb.co/install.sh | bash
apt install -y timescaledb-2-postgresql-17

# Configuration PostgreSQL
timescaledb-tune --quiet --yes
systemctl restart postgresql

# Activation de l'extension sur la base Zabbix
sudo -u postgres psql -d zabbix -c "CREATE EXTENSION IF NOT EXISTS timescaledb;"
```

---

## H. Import du schéma Zabbix

```bash
zcat /usr/share/zabbix-sql-scripts/postgresql/server.sql.gz | \
    sudo -u zabbix psql zabbix
```

---

## I. Configuration du serveur Zabbix

```bash
nano /etc/zabbix/zabbix_server.conf
```

```ini
DBHost=localhost
DBName=zabbix
DBUser=zabbix
DBPassword=<mot_de_passe>
```

```bash
systemctl enable --now zabbix-server
```

---

## J. Configuration du frontend Nginx

```bash
nano /etc/zabbix/nginx.conf
```

```nginx
server {
    listen 80;
    server_name zabbix.local;
    root /usr/share/zabbix;
    index index.php;

    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php-fpm.sock;
        fastcgi_index index.php;
        include fastcgi.conf;
    }
}
```

```bash
# Activation de la configuration
ln -s /etc/zabbix/nginx.conf /etc/nginx/conf.d/
systemctl restart nginx php-fpm
```

---

## K. Vérification des services

```bash
systemctl status nginx
systemctl status php-fpm
systemctl status postgresql
systemctl status zabbix-server
systemctl status zabbix-agent
```

---

## L. Accès au dashboard

```
http://IP_SERVEUR/zabbix
```

Configuration initiale via l'assistant web — connexion à PostgreSQL, fuseau horaire `Europe/Paris`.

> Captures du dashboard disponibles dans [`screenshots/`](./screenshots/)

---

## M. Déploiement des agents

```bash
# Sur chaque équipement à superviser
apt install -y zabbix-agent

nano /etc/zabbix/zabbix_agentd.conf
```

```ini
Server=<IP_SERVEUR_ZABBIX>
ServerActive=<IP_SERVEUR_ZABBIX>
Hostname=<NOM_HOTE>
```

```bash
systemctl enable --now zabbix-agent
```

---

## N. Hôtes supervisés

| Hôte | IP | Rôle |
|---|---|---|
| `par-deadpool-003` | `127.0.0.1` | Zabbix Server lui-même |
| `par-merlin-001` | `10.0.60.1` | Windows Server 2022 — AD/DHCP |
| Postes clients | `10.0.X.X` | VPCS / VMs |
| Equipements Réseau | snmp | PorteParis / SWParis |

> Captures du dashboard et liste des hôtes disponibles dans [`screenshots/`](./screenshots/)

---

## Sources

- [Zabbix — Documentation officielle](https://www.zabbix.com/documentation/current/en/manual)
- [Zabbix — Téléchargement Debian 13](https://www.zabbix.com/fr/download?zabbix=7.4&os_distribution=debian&os_version=13&components=server_frontend_agent&db=pgsql&ws=nginx)
- [infotechys.com — TimescaleDB avec Zabbix](https://infotechys.com)

---

> Réalisé seul dans GNS3 — VM Debian Trixie sur VirtualBox  
> Dernière mise à jour : avril 2026
