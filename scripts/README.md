# Scripts

Collection de scripts d'administration et d'automatisation développés dans le cadre du lab TSSR — CreativeFusion Studios.  
Organisés par langage et par domaine d'application.

---

## Structure

```
scripts/
├── powershell/     Scripts d'administration Windows — Active Directory, réseau, GPO
├── cisco/          Scripts et configurations Cisco IOS — équipements réseau
└── bash/           Scripts d'administration Linux — Debian, services, automatisation
```

---

## Powershell

| Script | Description | Statut |
|---|---|---|
| [`New-OUStructure.ps1`](./powershell/New-OUStructure.ps1) | Création automatique des OUs AD par site | ✅ |
| [`New-ADUsersFromExcel.ps1`](./powershell/New-ADUsersFromExcel.ps1) | Création des comptes AD depuis fichier Excel RH | ✅ |
| [`Set-NetworkDHCP.ps1`](./powershell/Set-NetworkDHCP.ps1) | Forcer carte réseau en DHCP via GPO | ✅ |

---

## Cisco

| Script | Description | Statut |
|---|---|---|
| [`configuration-base-equipement.txt`](./cisco/configuration-base-equipement.txt) | Configuration de base des équipements Cisco — routeurs et switches | ✅ |
| [`vlan-setup.txt`](./cisco/vlan-setup.txt) | Configuration compléte des switchs Cisco, site distant | ✅ |

---

## Bash

| Script | Description | Statut |
|---|---|---|
| — | Scripts à venir — Phase 4 du lab GNS3 Security | ⏳ À venir |

---

> Tous les scripts sont testés dans un environnement GNS3 virtualisé.  
> Dernière mise à jour : avril 2026
