# VLANs & Routage inter-VLAN

Segmentation du réseau CreativeFusion Studios en VLANs par service, routage inter-VLAN et sauvegarde des configurations équipements sur serveur FTP.  
Simulé dans GNS3 avec des équipements Cisco virtualisés et des VMs connectées à l'infrastructure.

---

## Objectifs

- Segmenter le réseau selon les services de l'entreprise
- Assurer la communication inter-VLAN via un routeur Cisco (router-on-a-stick)
- Distribuer les adresses IP via le serveur DHCP Windows Server 2022
- Sauvegarder les configurations des équipements réseau sur un serveur FTP

---

## Environnement

| Composant | Détail |
|---|---|
| Simulation réseau | GNS3 2.2.54 |
| Hyperviseurs | VirtualBox · VMware Fusion |
| Routeur | Cisco 7200 |
| Switch | Cisco IOSvL2 |
| Serveur AD/DHCP | Windows Server 2022 — VM VirtualBox |
| Postes clients | VMs VPCS ou Windows |
| Conception initiale | Cisco Packet Tracer (maquette) |

---

## A. Plan des VLANs

| VLAN | Service | Réseau | Gateway | Masque |
|---|---|---|---|---|
| 10 | Ressources humaines | `10.0.10.0` | `10.0.10.254` | `/24` |
| 20 | Comptabilité | `10.0.20.0` | `10.0.20.254` | `/24` |
| 30 | Informatique | `10.0.30.0` | `10.0.30.254` | `/24` |
| 40 | Direction générale | `10.0.40.0` | `10.0.40.254` | `/24` |
| 50 | Design-Animation | `10.0.50.0` | `10.0.50.254` | `/24` |
| 60 | Serveurs | `10.0.60.0` | `10.0.60.254` | `/24` |

---

## B. Topologie GNS3

```
[Routeur Cisco 7200] Gi0/0
          |
          | Trunk (dot1Q)
          |
[Switch Cisco IOSvL2]
  ├── Gi0/1  — VLAN 10 — PC RH
  ├── Gi0/2  — VLAN 20 — PC Compta
  ├── Gi0/3  — VLAN 30 — PC Info
  ├── Gi0/4  — VLAN 40 — PC DG
  ├── Gi0/5  — VLAN 50 — PC Design-Animation
  └── Gi0/6  — VLAN 60 — VM Windows Server 2022 (AD/DHCP/FTP)
```

> Schéma GNS3 exporté disponible dans [`screenshots/`](./cedric-ribier/screenshots/)

---

## C. Configuration Switch IOSvL2

### Création des VLANs

```cisco
Switch> enable
Switch# configure terminal

Switch(config)# vlan 10
Switch(config-vlan)# name RH
Switch(config)# vlan 20
Switch(config-vlan)# name Comptabilite
Switch(config)# vlan 30
Switch(config-vlan)# name Informatique
Switch(config)# vlan 40
Switch(config-vlan)# name Direction
Switch(config)# vlan 50
Switch(config-vlan)# name Design-Animation
Switch(config)# vlan 60
Switch(config-vlan)# name Serveurs
Switch(config-vlan)# exit
```

### Ports d'accès

```cisco
! Exemple VLAN 10 — RH
Switch(config)# interface GigabitEthernet0/1
Switch(config-if)# switchport mode access
Switch(config-if)# switchport access vlan 10
Switch(config-if)# no shutdown
```

### Lien trunk vers le routeur

```cisco
Switch(config)# interface GigabitEthernet0/0
Switch(config-if)# switchport trunk encapsulation dot1q
Switch(config-if)# switchport mode trunk
Switch(config-if)# switchport trunk allowed vlan 10,20,30,40,50,60
Switch(config-if)# no shutdown
```

---

## D. Configuration Routeur 7200 — Router-on-a-Stick

Sous-interfaces sur `GigabitEthernet0/0` — une par VLAN avec encapsulation dot1Q.

```cisco
Router> enable
Router# configure terminal

! Activation de l'interface physique
Router(config)# interface GigabitEthernet0/0
Router(config-if)# no shutdown

! Sous-interface VLAN 10
Router(config)# interface GigabitEthernet0/0.10
Router(config-subif)# encapsulation dot1Q 10
Router(config-subif)# ip address 10.0.10.254 255.255.255.0
Router(config-subif)# ip helper-address 10.0.60.1
Router(config-subif)# no shutdown

! Sous-interface VLAN 20
Router(config)# interface GigabitEthernet0/0.20
Router(config-subif)# encapsulation dot1Q 20
Router(config-subif)# ip address 10.0.20.254 255.255.255.0
Router(config-subif)# ip helper-address 10.0.60.1
Router(config-subif)# no shutdown

! Sous-interface VLAN 30
Router(config)# interface GigabitEthernet0/0.30
Router(config-subif)# encapsulation dot1Q 30
Router(config-subif)# ip address 10.0.30.254 255.255.255.0
Router(config-subif)# ip helper-address 10.0.60.1
Router(config-subif)# no shutdown

! Sous-interface VLAN 40
Router(config)# interface GigabitEthernet0/0.40
Router(config-subif)# encapsulation dot1Q 40
Router(config-subif)# ip address 10.0.40.254 255.255.255.0
Router(config-subif)# ip helper-address 10.0.60.1
Router(config-subif)# no shutdown

! Sous-interface VLAN 50
Router(config)# interface GigabitEthernet0/0.50
Router(config-subif)# encapsulation dot1Q 50
Router(config-subif)# ip address 10.0.50.254 255.255.255.0
Router(config-subif)# ip helper-address 10.0.60.1
Router(config-subif)# no shutdown

! Sous-interface VLAN 60
Router(config)# interface GigabitEthernet0/0.60
Router(config-subif)# encapsulation dot1Q 60
Router(config-subif)# ip address 10.0.60.254 255.255.255.0
Router(config-subif)# no shutdown
```

---

## E. DHCP — distribution par VLAN

Le serveur DHCP Windows Server 2022 (`10.0.60.1`) distribue les adresses pour chaque VLAN.  
Le `ip helper-address` sur chaque sous-interface relaie les requêtes DHCP vers le serveur.

**Validation côté client :**

```
PC> ip dhcp
DORA IP 10.0.10.x/24 GW 10.0.10.254
```

> Captures de validation DHCP disponibles dans [`screenshots/`](./screenshots/)

---

## F. Sauvegarde des configurations — FTP

Sauvegarde de la `running-config` des équipements réseau sur le serveur FTP intégré à Windows Server 2022.

**Serveur FTP** : `10.0.60.1`  
**Compte** : `admin` / `Cisco`

```cisco
! Sauvegarde depuis le routeur
Router# copy running-config ftp
Address or name of remote host? 10.0.60.1
Destination filename? routeur-config.txt

! Sauvegarde depuis le switch
Switch# copy running-config ftp
Address or name of remote host? 10.0.60.1
Destination filename? switch-config.txt
```

> Captures de la sauvegarde FTP disponibles dans [`screenshots/`](./screenshots/)

---

## G. Tests de connectivité inter-VLAN

Validation du routage inter-VLAN par ping entre postes de VLANs différents.

| Source | Destination | Protocole | Attendu | Résultat |
|---|---|---|---|---|
| PC RH `10.0.10.x` | PC Compta `10.0.20.x` | ICMP | ✅ | ⏳ |
| PC Info `10.0.30.x` | PC DG `10.0.40.x` | ICMP | ✅ | ⏳ |
| PC Design `10.0.50.x` | Serveur `10.0.60.x` | ICMP | ✅ | ⏳ |
| PC RH `10.0.10.x` | PC Design `10.0.50.x` | ICMP | ✅ | ⏳ |

> Mettre à jour avec les résultats réels et captures

---

## Sources

- [Cisco — Documentation IOS 15.7](https://www.cisco.com/c/en/us/td/docs/ios-xml/ios/15-7m/release/notes/15-7-3-m-rel-notes.html)

---

> Réalisé seul dans GNS3 — routeurs Cisco 7200, switches IOSvL2, VMs VirtualBox interconnectées  
> Dernière mise à jour : avril 2026
