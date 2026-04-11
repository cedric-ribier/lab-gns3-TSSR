# Connexion site distant — Lyon

Mise en place d'une connexion point-à-point entre le site principal de Paris et la succursale de Lyon.  
Le serveur DHCP centralisé sur Paris distribue les adresses IP pour l'ensemble des VLANs du site distant.

---

## Objectifs

- Interconnecter le site de Paris et le site de Lyon via un lien point-à-point
- Permettre aux postes du site distant de recevoir une adresse IP depuis le serveur DHCP de Paris
- Appliquer un plan d'adressage cohérent et scalable entre les sites

---

## Environnement

| Composant | Détail |
|---|---|
| Simulation réseau | GNS3 2.2.54 |
| Hyperviseurs | VirtualBox · VMware Fusion |
| Routeurs | Cisco 7200 — `PortParis` · `PorteLyon` |
| Switches | Cisco IOSvL2 |
| Serveur DHCP | Windows Server 2022 — `10.0.60.1` (site Paris) |

---

## A. Plan d'adressage

### Logique d'adressage multi-sites

```
Entreprise   →  10.0.0.0/8
Site         →  10.N°_Site.0.0/16
Service      →  10.Site.VLAN_Service.0/24
```

| Site | VLAN | Service | Réseau | Gateway |
|---|---|---|---|---|
| Paris (site 0) | 10 | RH | `10.0.10.0/24` | `10.0.10.254` |
| Paris (site 0) | 60 | Serveurs | `10.0.60.0/24` | `10.0.60.254` |
| Lyon (site 1) | 10 | RH | `10.1.10.0/24` | `10.1.10.254` |
| Lyon (site 1) | 20 | Compta | `10.1.20.0/24` | `10.1.20.254` |
| Lyon (site 1) | 30 | Info | `10.1.30.0/24` | `10.1.30.254` |
| Lyon (site 1) | 40 | Direction | `10.1.40.0/24` | `10.1.40.254` |
| Lyon (site 1) | 50 | Design-Anim | `10.1.50.0/24` | `10.1.50.254` |
| Lyon (site 1) | 60 | Serveurs | `10.1.60.0/24` | `10.1.60.254` |

### Lien point-à-point inter-sites

| Réseau | RouteurParis | RouteurLyon |
|---|---|---|
| `172.16.0.0/30` | `172.16.0.1` | `172.16.0.2` |

---

## B. Topologie GNS3

```
[Site Paris]                          [Site Lyon]
RouteurParis (10.0.X.X)               RouteurLyon (10.1.X.X)
     |                                      |
     | G1/0 172.16.0.1 ←──/30──→ 172.16.0.2 G1/0
     |                                      |
     | G0/0                                 | G0/0
     |                                      |
Switch IOSvL2 Paris              Switch IOSvL2 Lyon
VLAN 10/20/30/40/50/60           VLAN 10/20/30/40/50/60
     |
VM Windows Server 2022
DHCP centralisé 10.0.60.1
```

> Schéma GNS3 exporté disponible dans [`screenshots/`](./screenshots/)

---

## C. Configuration RouteurParis

### Routes statiques

```cisco
! Route automatiquement ajoutée — lien point-à-point
! 172.16.0.0/30 via interface G1/0

! Route statique vers les sous-réseaux Lyon
RouteurParis(config)# ip route 10.1.0.0 255.255.0.0 172.16.0.2
```

---

## D. Configuration RouteurLyon

### Interfaces et sous-interfaces

```cisco
! Interface vers RouteurParis
RouteurLyon(config)# interface GigabitEthernet1/0
RouteurLyon(config-if)# ip address 172.16.0.2 255.255.255.252
RouteurLyon(config-if)# no shutdown

! Interface trunk vers Switch Lyon — sans adresse IP
RouteurLyon(config)# interface GigabitEthernet0/0
RouteurLyon(config-if)# no ip address
RouteurLyon(config-if)# no shutdown

! Sous-interface VLAN 10
RouteurLyon(config)# interface GigabitEthernet0/0.10
RouteurLyon(config-subif)# encapsulation dot1Q 10
RouteurLyon(config-subif)# ip address 10.1.10.254 255.255.255.0
RouteurLyon(config-subif)# ip helper-address 10.0.60.1
RouteurLyon(config-subif)# no shutdown

! Sous-interface VLAN 20
RouteurLyon(config)# interface GigabitEthernet0/0.20
RouteurLyon(config-subif)# encapsulation dot1Q 20
RouteurLyon(config-subif)# ip address 10.1.20.254 255.255.255.0
RouteurLyon(config-subif)# ip helper-address 10.0.60.1
RouteurLyon(config-subif)# no shutdown

! Répéter pour VLAN 30, 40, 50, 60
```

### Routes statiques

```cisco
! Route par défaut — retour vers Paris
RouteurLyon(config)# ip route 0.0.0.0 0.0.0.0 172.16.0.1

! Route vers les sous-réseaux Paris
RouteurLyon(config)# ip route 10.0.0.0 255.255.0.0 172.16.0.1
```

---

## E. Étendues DHCP — site Lyon

Nouvelles étendues créées sur le serveur DHCP Windows Server 2022 pour chaque VLAN Lyon.

| VLAN | Réseau | Plage | Gateway | DNS |
|---|---|---|---|---|
| 10 | `10.1.10.0/24` | `10.1.10.1 – 10.1.10.253` | `10.1.10.254` | `10.0.60.1` |
| 20 | `10.1.20.0/24` | `10.1.20.1 – 10.1.20.253` | `10.1.20.254` | `10.0.60.1` |
| 30 | `10.1.30.0/24` | `10.1.30.1 – 10.1.30.253` | `10.1.30.254` | `10.0.60.1` |
| 40 | `10.1.40.0/24` | `10.1.40.1 – 10.1.40.253` | `10.1.40.254` | `10.0.60.1` |
| 50 | `10.1.50.0/24` | `10.1.50.1 – 10.1.50.253` | `10.1.50.254` | `10.0.60.1` |
| 60 | `10.1.60.0/24` | `10.1.60.1 – 10.1.60.253` | `10.1.60.254` | `10.0.60.1` |

---

## F. Validation

Le PC1 du site Lyon reçoit une adresse IP dans la bonne étendue via le DHCP centralisé de Paris :

```
PC1> ip dhcp
DORA IP 10.1.20.2/24 GW 10.1.20.254

PC1> show ip all
NAME   IP/MASK        GATEWAY      DNS
PC1    10.1.20.2/24   10.1.20.254  10.0.60.1  10.0.60.1
```

> Captures de validation disponibles dans [`screenshots/`](./screenshots/)

---

## Sources

- [Cisco — Documentation IOS 15.7](https://www.cisco.com/c/en/us/td/docs/ios-xml/ios/15-7m/release/notes/15-7-3-m-rel-notes.html)

---

> Réalisé seul dans GNS3 — routeurs Cisco 7200, switches IOSvL2, VM Windows Server 2022 interconnectés  
> Dernière mise à jour : avril 2026
