# Lab GNS3 — TSSR · CreativeFusion Studios

> Infrastructure d'entreprise complète simulée dans GNS3 — Active Directory, supervision, sécurité réseau, déploiement et automatisation.

![Status](https://img.shields.io/badge/Status-En_cours-orange?style=flat-square)
![GNS3](https://img.shields.io/badge/GNS3-2.x-blue?style=flat-square)
![Windows Server](https://img.shields.io/badge/Windows_Server-2022-0078D4?style=flat-square)
![Debian](https://img.shields.io/badge/Debian-Trixie_13-A81D33?style=flat-square)
![Cisco](https://img.shields.io/badge/Cisco_IOS-7200_·_IOSvL2-1BA0D7?style=flat-square)

---

## Contexte

Lab réalisé dans le cadre de la formation **Technicien Supérieur Systèmes et Réseaux (TSSR)** chez Studi.  
Le scénario fictif s'appuie sur l'entreprise **CreativeFusion Studios** — groupement de 35 studios européens d'animation ayant fusionné et nécessitant une refonte complète de son système d'information.

Trois chantiers principaux :
- Centralisation des accès via Active Directory
- Segmentation réseau par VLANs
- Sauvegarde et automatisation de l'infrastructure

---

## Environnement technique

| Composant | Technologie |
|---|---|
| Simulation réseau | GNS3 2.x |
| Hyperviseurs | VirtualBox · VMware Fusion |
| Serveur principal | Windows Server 2022 |
| Serveurs Linux | Debian Trixie 13.x |
| Équipements réseau | Cisco 7200 · Cisco IOSvL2 |
| Pare-feu | pfSense |

---

## Projets

| Dossier | Projet | Statut |
|---|---|---|
| [`active-directory/`](./active-directory/) | Active Directory — AD DS, OUs, GPO, DHCP, GLPI | ✅ Réalisé |
| [`vlans-routage/`](./vlans-routage/) | VLANs + routage inter-VLAN + sauvegarde FTP | ✅ Réalisé |
| [`site-distant/`](./site-distant/) | Connexion point-à-point site distant + DHCP centralisé | ✅ Réalisé |
| [`zabbix/`](./zabbix/) | Supervision Zabbix 7.4 — déploiement + agents | ✅ Réalisé |
| [`pfsense-portail-captif/`](./pfsense-portail-captif/) | pfSense — portail captif VLAN invité isolé | ✅ Réalisé |
| [`fogproject-pxe/`](./fogproject-pxe/) | FOGProject — capture et déploiement PXE | ✅ Réalisé |
| [`powershell/`](./powershell/) | Scripts PowerShell — OUs, comptes AD, GPO DHCP | ✅ Réalisé |

---

## Topologie générale

```
[Routeur Internet / WAN]
        |
   Routeur Paris (site principal)
        |
   Switch L3 CœurReseau
        |
   ┌────┴──────────────────────┐
   |                           |
Switch L2                  Switch L2
VLAN 10 — RH               VLAN 20 — Compta
VLAN 30 — Informatique     VLAN 40 — Direction
VLAN 50 — Design/Anim      VLAN 60 — Serveurs
                               |
                           Windows Server 2022
                           AD DS · DNS · DHCP
                               |
                           Debian Trixie
                           Zabbix · GLPI · FOG
```

---

## Plan d'adressage

| VLAN | Service | Réseau | Gateway |
|---|---|---|---|
| 10 | Ressources humaines | `10.0.10.0/24` | `10.0.10.254` |
| 20 | Comptabilité | `10.0.20.0/24` | `10.0.20.254` |
| 30 | Informatique | `10.0.30.0/24` | `10.0.30.254` |
| 40 | Direction générale | `10.0.40.0/24` | `10.0.40.254` |
| 50 | Design-Animation | `10.0.50.0/24` | `10.0.50.254` |
| 60 | Serveurs | `10.0.60.0/24` | `10.0.60.254` |

---

## Structure du repo

```
lab-gns3-tssr/
├── README.md
├── active-directory/
│   ├── README.md
│   └── screenshots/
├── vlans-routage/
│   ├── README.md
│   └── screenshots/
├── site-distant/
│   ├── README.md
│   └── screenshots/
├── zabbix/
│   ├── README.md
│   └── screenshots/
├── pfsense-portail-captif/
│   ├── README.md
│   └── screenshots/
├── fogproject-pxe/
│   ├── README.md
│   └── screenshots/
└── powershell/
    ├── README.md
    ├── New-OUStructure.ps1
    └── New-ADUsersFromExcel.ps1
```

---

## Contexte formation

| | |
|---|---|
| **Formation** | Technicien Supérieur Systèmes et Réseaux (TSSR) |
| **Organisme** | Studi |
| **Période** | Novembre 2025 → Juin 2026 |
| **Modalité** | Parcours de formation |

---

> Réalisations effectuées seul dans un environnement entièrement virtualisé.  
> Dernière mise à jour : avril 2026
