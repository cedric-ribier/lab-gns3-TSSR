# PfSense — Portail captif VLAN invité

Mise en place d'un portail captif pfSense pour isoler et contrôler les connexions invités.  
Les périphériques invités accèdent à Internet après authentification, sans pouvoir atteindre le réseau interne.

---

## Objectifs

- Créer un VLAN dédié aux connexions invités — isolé du reste de l'infrastructure
- Rediriger le trafic invité vers pfSense via PBR
- Imposer une authentification avant tout accès Internet
- Bloquer l'accès aux réseaux internes depuis le VLAN invité

---

## Environnement

| Composant | Détail |
|---|---|
| Simulation réseau | GNS3 2.x |
| Pare-feu | pfSense — `8.0.100.1` |
| Routeur | Cisco 7200 |
| Switches | Cisco IOSvL2 |
| DHCP | Windows Server 2022 |
| Client test | VM Windows 11 |

---

## Architecture

```
[Internet]
     |
  pfSense
  8.0.100.1 — Interface GUEST
     |
  Routeur Cisco 7200
  Sous-interface G0/0.70 — 172.16.70.254
     |
  Switch IOSvL2 — VLAN 70 (Invités)
     |
  Poste invité (172.16.70.x/24)
```

---

## A. VLAN 70 — Invités

### Sur les switches IOSvL2

```cisco
! Création du VLAN 70
Switch(config)# vlan 70
Switch(config-vlan)# name Invites

! Attribution des interfaces libres au VLAN invité
Switch(config)# interface GigabitEthernet0/X
Switch(config-if)# switchport mode access
Switch(config-if)# switchport access vlan 70
Switch(config-if)# no shutdown

! Ajout du VLAN 70 au lien trunk
Switch(config)# interface GigabitEthernet0/0
Switch(config-if)# switchport trunk allowed vlan add 70
```

---

## B. Sous-interface routeur — VLAN 70

```cisco
! Sous-interface dédiée au VLAN invité
Router(config)# interface GigabitEthernet0/0.70
Router(config-subif)# encapsulation dot1Q 70
Router(config-subif)# ip address 172.16.70.254 255.255.255.0
Router(config-subif)# ip helper-address 10.0.60.1
Router(config-subif)# no shutdown
```

---

## C. Étendue DHCP — réseau invité

Nouvelle étendue créée sur Windows Server 2022 pour le VLAN 70.

| Paramètre | Valeur |
|---|---|
| Réseau | `172.16.70.0/24` |
| Plage | `172.16.70.1 – 172.16.70.253` |
| Gateway | `172.16.70.254` |
| DNS | `8.0.100.1` (pfSense — capture CP) |

> Pointer le DNS vers pfSense permet au portail captif d'intercepter les requêtes.

---

## D. ACL — trafic VLAN invité

ACL stricts sur la sous-interface G0/0.70 — autorise uniquement DHCP et communication vers pfSense.

```cisco
ip access-list extended ACL-VLAN70-IN
 ! DHCP — distribution d'adresses
 permit udp any any eq 67
 permit udp any any eq 68
 ! Communication vers pfSense
 permit ip 172.16.70.0 0.0.0.255 host 8.0.100.1
 ! Tout le reste bloqué
 deny ip any any

interface GigabitEthernet0/0.70
 ip access-group ACL-VLAN70-IN in
```

---

## E. Interface pfSense — GUEST

Création d'une nouvelle interface pfSense dédiée au trafic invité.

| Paramètre | Valeur |
|---|---|
| Interface | GUEST |
| IP | `8.0.100.1` |
| Rôle | Capture du trafic portail captif |

### Règles pare-feu pfSense

| Règle | Source | Destination | Action |
|---|---|---|---|
| DNS vers pfSense | `172.16.70.0/24` | This Firewall (53 TCP/UDP) | PASS |
| Capture CP | `172.16.70.0/24` | ANY | PASS |
| Blocage réseaux internes | `172.16.70.0/24` | RFC1918 | BLOCK |

---

## F. Configuration du portail captif

```
Services → Captive Portal → + Add
```

| Paramètre | Valeur |
|---|---|
| Zone | `Invité` |
| Interface | GUEST (`8.0.100.1`) |
| Authentification | Base de données locale |
| Connexions multiples | Autorisées |

### Utilisateur dédié

Compte créé dans la base locale pfSense avec uniquement les droits d'accès au portail captif — sans accès à l'interface d'administration.

---

## G. Validation

Test effectué depuis un PC Windows 11 connecté à une interface libre du switch (VLAN 70) :

1. Le PC reçoit une adresse IP dans la plage `172.16.70.x`
2. Ouverture de Firefox — requête vers `google.com`
3. Redirection automatique vers le portail captif pfSense
4. Connexion avec le compte utilisateur dédié
5. Navigation Internet libre après authentification
6. Accès aux réseaux internes bloqué

> Capture du portail captif et de la redirection disponibles dans [`screenshots/`](./screenshots/)

---

## Screenshots à ajouter

| Fichier | Capture |
|---|---|
| `01-vlan70-brief.png` | `show vlan brief` avec VLAN 70 actif |
| `02-dhcp-invite.png` | PC invité ayant reçu une IP dans `172.16.70.x` |
| `03-portail-captif.png` | Page de login pfSense — redirection réussie |
| `04-navigation-ok.png` | Navigation Internet après authentification |

---

> Réalisé seul dans GNS3 — Cisco 7200, IOSvL2, pfSense, Windows Server 2022, Windows 11  
> Dernière mise à jour : avril 2026
