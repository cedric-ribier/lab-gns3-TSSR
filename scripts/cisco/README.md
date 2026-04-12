# Scripts Cisco IOS

Configurations et scripts pour équipements Cisco — routeurs 7200 et switches IOSvL2.  
Développés dans le cadre du lab TSSR CreativeFusion Studios sous GNS3.

---

## Équipements ciblés

| Équipement | Modèle | Usage |
|---|---|---|
| Routeur | Cisco 7200 | Routage inter-VLAN, site distant, NAT |
| Switch | Cisco IOSvL2 | VLANs, trunks, SVI |

---

## Scripts

### configuration-base-equipement.txt

Configuration de base appliquée à l'ensemble des équipements réseau du lab.  
Permet un déploiement rapide et homogène sur site.

Inclut :
- Nom d'hôte et bannière
- Configuration SSH sécurisée
- Désactivation des services inutiles
- Utilisateur local avec privilèges
- Sauvegarde vers serveur FTP

```cisco
! Exemple d'utilisation
Router# copy tftp running-config
! ou via script de déploiement automatisé
! Variable $ a adapter
```

---

## En cours d'ajout

| Script | Description | Statut |
|---|---|---|
| [`configuration-base-equipement.txt`](./configuration-base-equipement.txt) | Configuration de base - Switch Routeur Cisco | ✅ |
| [`vlan-setup.txt`](./vlan-setup.txt) | Configuration VLANs et trunks — Switch IOSvL2 | ✅ |
| `router-on-a-stick.txt` | Routage inter-VLAN — sous-interfaces dot1Q | 🔄 En cours |
| `site-distant.txt` | Connexion point-à-point et ip helper-address | 🔄 En cours |

---

> Configurations testées dans GNS3 — images IOS Cisco 7200 et IOSvL2  
> Dernière mise à jour : avril 2026
