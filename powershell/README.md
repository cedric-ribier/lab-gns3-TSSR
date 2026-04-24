# Scripts PowerShell — Lab TSSR

Scripts PowerShell développés dans le cadre du lab TSSR CreativeFusion Studios.  
Couvrent l'automatisation Active Directory, la gestion réseau et les GPO.

---

## Scripts réalisés

### New-OUStructure.ps1

Création automatique des OUs d'un nouveau site à partir de la structure existante.  
Respecte l'arborescence AGDLP — ajoute les OUs du nouveau site en suivant le même modèle que les OUs Paris.

**Contexte** : ouverture de la succursale de Lyon — les OUs `Compta_Lyon`, `Info_Lyon`, `RH_Lyon` etc. sont créées automatiquement depuis la structure Paris existante.

```powershell
# Crée les OUs du site Lyon sur le modèle Paris
.\New-OUStructure.ps1 -Site "Lyon"
```

---

### New-ADUsersFromExcel.ps1

Création automatique des comptes utilisateurs AD depuis un fichier Excel alimenté par les RH.  
Génère un fichier de réponse avec les comptes créés et les mots de passe temporaires.

**Contexte** : automatisation de la création des comptes lors des arrivées — le service RH remplit le fichier Excel, le script s'exécute automatiquement via le planificateur de tâches à 12h00 et 19h30.

```powershell
# Exécution manuelle
.\New-ADUsersFromExcel.ps1

# En production — compte de service svc_auto_ad
# Planificateur de tâches : 12h00 et 19h30
```

**Compte de service** : `svc_auto_ad` dans `OU=Compte_services` — délégations minimales, principe du moindre privilège.

---

### Set-NetworkDHCP.ps1

Force la carte réseau en mode DHCP — déployé via GPO au démarrage de l'ordinateur.

**Contexte** : certains utilisateurs configurent une adresse IP statique sur leur poste, ce qui empêche la connexion au domaine. La GPO exécute ce script au démarrage pour corriger automatiquement la configuration réseau.

```powershell
# Déployé via GPO — Configuration ordinateur
# Chemin GPO : Configuration ordinateur → Paramètres Windows → Scripts → Démarrage
.\Set-NetworkDHCP.ps1
```

---

## Planificateur de tâches — New-ADUsersFromExcel

| Paramètre | Valeur |
|---|---|
| Compte d'exécution | `svc_auto_ad` |
| Déclencheur 1 | Tous les jours à 12h00 |
| Déclencheur 2 | Tous les jours à 19h30 |
| Script | `C:\srv-ad\scripts\New-ADUsersFromExcel.ps1` |
| Politique d'exécution | `RemoteSigned` |

> Capture du planificateur disponible dans [`screenshots/`](./screenshots/)

---

## Politique d'exécution

```powershell
# Vérifier la politique actuelle
Get-ExecutionPolicy

# Autoriser les scripts locaux
Set-ExecutionPolicy RemoteSigned -Scope LocalMachine
```

---

## Repo dédié

Les scripts complets sont également disponibles dans le repo [`Powershell-scripts`](https://github.com/cedric-ribier/Powershell-scripts) avec leur documentation détaillée et l'en-tête standard.

---

> Scripts testés sur Windows Server 2022 — domaine CreativeFusion-Studios.eu  
> Dernière mise à jour : avril 2026
