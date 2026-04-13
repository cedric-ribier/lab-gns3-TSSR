# Active Directory — CreativeFusion Studios

Déploiement complet d'un environnement Active Directory pour une entreprise multi-sites simulée.  
Réalisé en deux étapes : mise en place initiale dans le cadre de l'ECF, puis évolution pour le Dossier Professionnel TSSR.

---

## Objectifs

- Centraliser les accès utilisateurs sur un domaine unique `CreativeFusion-Studios.eu`
- Structurer l'annuaire selon la méthode **AGDLP** (Accounts → Global groups → Domain Local groups → Permissions)
- Automatiser la création des comptes depuis un fichier Excel RH
- Déployer le serveur DHCP et GLPI avec authentification AD

---

## Environnement

| Composant | Détail |
|---|---|
| Serveur AD | Windows Server 2022 — `PAR-MERLIN-001` |
| Domaine | `CreativeFusion-Studios.eu` |
| Nommage | Conforme RFC1178 |
| Hyperviseur | VirtualBox |
| Simulation réseau | GNS3 |
| Serveur GLPI | Debian 12 — sans interface graphique |
| Postes Clients | Windows 11 - VPCS GNS3|

---

## A. Installation du domaine

Installation du rôle **AD DS** sur Windows Server 2022 et promotion en contrôleur de domaine.

- Domaine : `CreativeFusion-Studios.eu`
- Nommage serveur selon RFC1178 : `PAR-MERLIN-001`
- Adresse IP statique sur le serveur AD/DNS
- DNS intégré à Active Directory

---

## B. Structure des OUs

Arborescence conçue pour la scalabilité multi-sites — chaque service dispose d'une OU par ville.

```
CreativeFusion-Studios.eu
└── CreativeFusion/
    ├── Admin/
    ├── Computeur/
    └── User/
        ├── Compta/
        │   ├── Compta_Paris/
        │   │   ├── [Utilisateurs]
        │   │   ├── GDL-Partage-ComptaParis
        │   │   └── GS-Users-Compta-Paris
        │   └── Compta_Lyon/
        │       ├── [Utilisateurs]
        │       ├── DL-Compta_Lyon
        │       └── GS-Compta_Lyon
        ├── Design_Animation/
        │   ├── Design_Animatio_Paris/
        │   └── Design_Animation_Lyon/
        ├── Direction_Général/
        │   ├── DG_Paris/
        │   └── Direction_Général_Lyon/
        ├── Info/
        ├── RH/
        └── User_reseau/
    └── Compte_services/
        └── svc_auto_ad
```

> Captures d'écran disponibles dans [`screenshots/`](./screenshots/)

---

## C. Politique de mots de passe

| Paramètre | Valeur | Source |
|---|---|---|
| Historique | 24 mots de passe | Recommandation ANSSI |
| Âge maximum | 182 jours | Recommandation CNIL / ANSSI |
| Âge minimum | 1 jour | — |
| Longueur minimale | 12 caractères (users) · 16 caractères (admins) | — |
| Complexité | Activée | — |

---

## D. Étendues DHCP

6 étendues créées sur le serveur AD — une par VLAN de service.  
Contraintes appliquées :
- Passerelle = dernière adresse disponible du réseau (`x.x.x.254`)
- DNS = adresse IP du serveur AD
- Adresse IP du serveur AD en statique

| VLAN | Service | Réseau | Plage DHCP | Gateway | DNS |
|---|---|---|---|---|---|
| 10 | Ressources humaines | `10.0.10.0/24` | `10.0.10.1 – 10.0.10.253` | `10.0.10.254` | IP serveur AD |
| 20 | Comptabilité | `10.0.20.0/24` | `10.0.20.1 – 10.0.20.253` | `10.0.20.254` | IP serveur AD |
| 30 | Informatique | `10.0.30.0/24` | `10.0.30.1 – 10.0.30.253` | `10.0.30.254` | IP serveur AD |
| 40 | Direction générale | `10.0.40.0/24` | `10.0.40.1 – 10.0.40.253` | `10.0.40.254` | IP serveur AD |
| 50 | Design-Animation | `10.0.50.0/24` | `10.0.50.1 – 10.0.50.253` | `10.0.50.254` | IP serveur AD |
| 60 | Serveurs | `10.0.60.0/24` | `10.0.60.1 – 10.0.60.253` | `10.0.60.254` | IP serveur AD |

---

## E. Automatisation — script PowerShell OUs

Script de création automatique des OUs d'un nouveau site à partir de la structure existante.

```powershell
# Exemple d'utilisation — crée les OUs du site Lyon
# sur le même modèle que les OUs Paris existantes
.\New-OUStructure.ps1 -Site "Lyon"
```

Le script récupère les OUs métiers existantes (`Compta_Paris`, `Design_Animation_Paris`…) et génère les OUs correspondantes pour le nouveau site en respectant l'arborescence et la racine.

> Script complet disponible dans [`../powershell/`](https://github.com/cedric-ribier/scripts/powershell) et dans le repo [`Powershell-scripts`](https://github.com/cedric-ribier/Powershell-scripts)


## F. Automatisation — création de comptes utilisateurs

Création automatique des comptes AD depuis un fichier Excel alimenté par les RH.

**Fonctionnement :**

```
Fichier Excel RH  →  Script PowerShell  →  Active Directory
(Partage RH)          (svc_auto_ad)         OUs + Groupes
                                             Fichier de réponse
```

**Compte de service dédié** : `svc_auto_ad` dans `OU=Compte_services`

| Délégation | Périmètre |
|---|---|
| Lecture / écriture | Partage RH |
| Lecture / écriture | `OU=User` — toutes OUs utilisateurs |
| Création utilisateur et groupe | `OU=User` |
| Lecture / écriture | Fichier Excel |

**Planificateur de tâches** : exécution automatique à **12h00** et **19h30**

> Script complet : [`../powershell/Creation_Utilisateurs_Auto.ps1`](../powershell/)

---

## G. GLPI 10.0.10 — authentification Active Directory

Installation de GLPI sur Debian 12 (sans interface graphique) avec authentification centralisée via l'AD.

| Composant | Détail |
|---|---|
| Version GLPI | 10.0.10 |
| OS | Debian 12 |
| IP | Réseau Serveurs `10.0.60.0/24` |
| Authentification | LDAP → `CreativeFusion-Studios.eu` |

---

## H. Évolution — site distant Lyon

Extension de l'infrastructure pour accueillir la succursale de Lyon :

- Création des OUs `_Lyon` via script PowerShell
- Mutation de l'utilisatrice Manon Bonnet : `Info_Paris` → `Info_Lyon`
- Nouveau compte administrateur avec **principe du moindre privilège**
- Suppression des anciens groupes de sécurité, ajout aux nouveaux

---

## Sources

- ANSSI — *Guide d'administration sécurisée des SI sous AD* (octobre 2023)
- [IT-Connect — Active Directory](https://www.it-connect.fr/?s=Active+Directory)
- [Microsoft Learn — Planificateur de tâches](https://learn.microsoft.com/fr-fr/troubleshoot/windows-server/system-management-components/schedule-server-process)

---

> Réalisé seul dans un environnement entièrement virtualisé — GNS3 + VirtualBox + VMware Fusion  
> Dernière mise à jour : avril 2026
