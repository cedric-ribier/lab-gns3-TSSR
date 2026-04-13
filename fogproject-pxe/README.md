# FOGProject — Capture et déploiement PXE

Solution open-source de déploiement d'images système via PXE.  
Capture d'une image Windows 11 masterisée et déploiement automatique sur nouvelles machines.

Guide complet de l'installation [FOGProject](https://github.com/cedric-ribier/install-guides/tree/af2a331a99b0f81e1fa2d9fb5f92e5764481f1e3/fogproject)


---

## Objectifs

- Déployer un serveur FOG Project sur Debian
- Capturer une image Windows 11 préparée en mode Audit + Sysprep
- Déployer automatiquement l'image sur de nouvelles machines via PXE
- Remplacer MDT par une solution open-source maintenable

---

## Environnement

| Machine | Rôle | Ressources | Réseau |
|---|---|---|---|
| pfSense | Routeur / DHCP / PXE | 1 vCPU — 2 Go RAM — 16 Go | WAN (NAT/Bridge) + LAN interne |
| Debian — Serveur FOG | FOG + TFTP/PXE + NFS | 2 vCPU — 4 Go RAM — 120 Go | LAN — IP fixe |
| Debian — Bureau | Administration FOG | 2 vCPU — 4 Go RAM — 40 Go | LAN |
| Windows 11 — Modèle | Capture de l'image | 2 vCPU — 4 Go RAM — 80 Go | LAN — boot PXE |
| Windows 11 — Cible | Déploiement | 2 vCPU — 4 Go RAM — 80 Go | LAN — boot PXE |

**Réseau LAN** : `10.0.80.0/24` — Gateway pfSense `10.0.80.254`  
**Serveur FOG** : `10.0.80.1` — IP fixe

---

## Topologie

```
[WAN — NAT/Bridge]
        |
    pfSense (DHCP + PXE)
    LAN 10.0.80.254
        |
    LAN 10.0.80.0/24
    ┌───┴──────────────────┐
    |                      |
Serveur FOG           Debian Bureau
10.0.80.1             (administration)
    |
    ├── PC Modèle WIN11 (capture)
    └── PC Cible WIN11 (déploiement)
```

> Schéma disponible dans [`screenshots/`](https://github.com/cedric-ribier/install-guides/tree/af2a331a99b0f81e1fa2d9fb5f92e5764481f1e3/fogproject/screenshots)

---

## A. Déploiement de pfSense

1. Créer une VM pfSense avec deux interfaces :
   - `WAN` — NAT ou Bridge de l'hyperviseur
   - `LAN` — Réseau interne `10.0.80.0/24`
2. Installer pfSense
3. Activer le serveur DHCP sur le LAN interne
4. Configurer les options PXE — FOG gère le PXE via `ipxe.pxe`

---

## B. Installation du serveur Debian (FOG)

```bash
# Création d'une VM Debian minimaliste — IP fixe obligatoire
# Mise à jour du système
sudo apt update && sudo apt upgrade -y
```

---

## C. Installation de FOG Project

```bash
# Cloner le dépôt officiel
git clone https://github.com/FOGProject/fogproject.git

# Lancer le script d'installation
cd fogproject/bin
sudo ./installfog.sh
```

Choix lors de l'installation :
- Type : **Installation Standard**
- Interface réseau : sélectionner la bonne interface (ex. `ens33`)
- Questions DHCP : répondre **NON** à chaque question — pfSense gère le DHCP

---

## D. Déploiement de la base de données

Depuis le navigateur sur la machine Debian bureau :

```
http://<IP_FOG>/fog/management
```

Valider la création automatique de la base de données via l'assistant web.

---

## E. Première connexion et préparation

1. Se connecter à l'interface FOG Web UI
2. Télécharger l'agent FOG depuis le dossier partagé — à destination des postes Windows à enregistrer

---

## F. Création de l'image dans FOG

Dans l'interface FOG : `Images → Create New Image`

| Paramètre | Valeur |
|---|---|
| OS | Windows Other (4) |
| Image Type | Single Disk - Resizable |
| Image Manager | Partclone Gzip |
| Image Path | `images/PosteCreativeFusion` |

---

## G. Préparation du système modèle Windows 11

### Installation du système

- Pas de clé produit
- Édition : Windows 11 Pro
- Partitionnement : supprimer toutes les partitions existantes — laisser Windows recréer automatiquement

### Passage en mode Audit

À l'écran de configuration régionale — **ne pas cliquer** :

```
Ctrl + Shift + F3
```

Windows redémarre en mode Audit.

### Configuration en mode Audit

- Fermer systématiquement la fenêtre Sysprep — ne jamais l'utiliser directement depuis cette fenêtre
- Installer les applications souhaitées : `7-Zip`, `Firefox`, `FOG Client`

### Installation du FOG Client

1. Ouvrir le dossier partagé contenant `SmartInstaller`
2. Exécuter en administrateur
3. Renseigner l'adresse du serveur FOG
4. Désactiver FOG Tray

### Sysprep

```
Generalize → Shutdown → OOBE
```

---

## H. Enregistrement de la machine dans FOG

1. Modifier l'ordre de boot — PXE en premier
2. Booter la VM en PXE
3. Choisir : **Perform Full Host Registration and Inventory**
4. Renseigner le nom de la machine et l'ID de l'image à associer

---

## I. Capture de l'image

### Côté FOG Web

```
Hosts → List All Hosts → sélectionner la machine → Capture
```

### Côté machine Windows

1. Booter en PXE
2. La capture démarre automatiquement via Partclone
3. L'image est envoyée au serveur FOG

```
Starting to clone device (/dev/sda1) to image (/tmp/pigz1)
Storage Location: 10.0.60.7:/images/dev/
File system: NTFS
Device size: 13.7 GB = 3396168 Blocks
```

> Capture de la progression disponible dans [`screenshots/`](https://github.com/cedric-ribier/install-guides/tree/af2a331a99b0f81e1fa2d9fb5f92e5764481f1e3/fogproject/screenshots)

---

## J. Déploiement sur une nouvelle machine

### Création de la VM cible

1. Créer une VM vide aux mêmes caractéristiques que le modèle
2. Booter en PXE
3. Enregistrer via : **Perform Full Host Registration and Inventory**

### Affectation de l'image

```
FOG Web → Hosts → associer l'image capturée à la nouvelle machine
```

### Lancement du déploiement

```
Tasks → Deploy
```

Booter la machine en PXE — le déploiement s'exécute automatiquement.

---

## K. Vérifications post-déploiement

- Windows 11 démarre correctement
- Applications correctement déployées (Firefox, 7-Zip…)
- FOG Client opérationnel sur le poste déployé

> Capture du bureau Windows déployé disponible dans [`screenshots/`](./screenshots/)

---

## Sources

- [FOGProject — Documentation officielle](https://docs.fogproject.org/en/latest/installation/server/install-fog-server/)
- [GitHub FOGProject](https://github.com/FOGProject/fogproject)

---

> Réalisé seul dans un environnement VirtualBox isolé — 5 VMs interconnectées  
> Dernière mise à jour : avril 2026
