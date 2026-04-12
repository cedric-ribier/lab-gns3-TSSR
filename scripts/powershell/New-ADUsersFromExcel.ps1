Import-Module ActiveDirectory
Import-Module ImportExcel
Add-Type -AssemblyName System.Web
cls
# === PARAMETRES ===============================================================

$ExcelInput  = "C:\Windows\SYSVOL\sysvol\CreativeFusion-Studios.eu\Dossier_partage\Partage_RH\Utilisateur_Automatique\FichierRH_Utilisateur.xlsx"
$ExcelOutput = "C:\Windows\SYSVOL\sysvol\CreativeFusion-Studios.eu\Dossier_partage\Partage_RH\Nouveau_Utilisateur.xlsx"
$RootOU      = "OU=User,OU=CreativeFusion,DC=CreativeFusion-Studios,DC=eu"


# === Suppression accents ======================================================

function Remove-Accents {
                        param([string]$text)
                        $normalized = $text.Normalize([Text.NormalizationForm]::FormD)
                        $chars = $normalized.ToCharArray() | Where-Object { [Globalization.CharUnicodeInfo]::GetUnicodeCategory($_) -ne 'NonSpacingMark' }
                        return (-join $chars).Normalize([Text.NormalizationForm]::FormC) 
                        }


# Transforme Dept/Site en jetons pour le nom de groupe selon ta nomenclature
function Get-DeptTokenForGroup {
                                param([string]$DeptOU)
                                switch ($DeptOU) {
                                                    "Design_Animation"   { return "Design" }           # ↔ GS-Users-Design-<Site>
                                                    "Direction_Général"  { return "DG" }               # ↔ GS-Users-DG-<Site>
                                                    default              { return $DeptOU }            # Compta, Info, RH...
                                                }
                                }


# Construit le nom du groupe selon ton format
function Format-GroupName {
                            param([string]$DeptToken, [string]$Site)
                            # On supprime les accents pour éviter des CN exotiques
                            $dept = Remove-Accents($DeptToken)
                            $site = Remove-Accents($Site)
                            return "GS-Users-$dept-$site"
                        }

 
# === Lecture Excel RH ==========================================================

$Users = Import-Excel -Path $ExcelInput
$ExportList = @()

foreach ($u in $Users) {

                        $First = $u.FirstName.Trim()
                        $Last  = $u.LastName.Trim()
                        $Dept  = $u.Department.Trim()
                        $Site  = $u.Site.Trim()

                        # Départements convertis
                        switch ($Dept.ToLower()) {
                                                    "rh"        { $DeptOU = "RH" }
                                                    "info"      { $DeptOU = "Info" }
                                                    "compta"    { $DeptOU = "Compta" }
                                                    "design"    { $DeptOU = "Design_Animation" }
                                                    "dg"        { $DeptOU = "Direction_Général" }
                                                    default     { $DeptOU = $Dept }
                                                  }

                        # === Vérification / création OU ===========================================

                        $OU_Dept = "OU=$DeptOU,$RootOU"
                        if (-not (Get-ADOrganizationalUnit -LDAPFilter "(ou=$DeptOU)" -SearchBase $RootOU -ErrorAction SilentlyContinue)) {
                                                                                                                                            New-ADOrganizationalUnit -Name $DeptOU -Path $RootOU
                                                                                                                                           }

                        $OU_SiteName = "${DeptOU}_${Site}"
                        $OU_Site = "OU=$OU_SiteName,$OU_Dept"
                        if (-not (Get-ADOrganizationalUnit -LDAPFilter "(ou=$OU_SiteName)" -SearchBase $OU_Dept -ErrorAction SilentlyContinue)) {
                                                                                                                                                    New-ADOrganizationalUnit -Name $OU_SiteName -Path $OU_Dept
                                                                                                                                                 }

                        # === SAM = prenom.nom sans accents ========================================

                        $FirstClean = Remove-Accents($First).ToLower()
                        $LastClean  = Remove-Accents($Last).ToLower()

                        $SAM = "$FirstClean.$LastClean"


                        $UPN = "$SAM@creativefusion-studios.eu"

                        # === Si utilisateur existe → ignore ======================================

                        $UtilisateurExiste = Get-ADUser -Filter {UserPrincipalName -eq $UPN} -ErrorAction SilentlyContinue
                        if (!$UtilisateurExiste) {

                                                        # === Mot de passe sécurisé ====================================================

                                                        $Password =  [System.Web.Security.Membership]::GeneratePassword(16,3)
                                                        $SecurePwd = ConvertTo-SecureString $Password -AsPlainText -Force

                                                        # === Création utilisateur AD ===============================================

                                                        New-ADUser `
                                                            -Name "$First $Last" `
                                                            -GivenName $First `
                                                            -Surname $Last `
                                                            -SamAccountName $SAM `
                                                            -UserPrincipalName $UPN `
                                                            -Path $OU_Site `
                                                            -AccountPassword $SecurePwd `
                                                            -Enabled $true `
                                                            -ChangePasswordAtLogon $true 
                                                       

                                                     # === Ajouter au groupe de sécurité (création automatique limitée à l'OU du site) ===
                                                    # Nomenclature attendue : GS-Users-<DeptToken>-<Site>
                                                    # Exemple pour OU=Compta_Lyon : CN=GS-Users-Compta-Lyon,OU=Compta_Lyon,OU=Compta,...

                                                    #   S'appuie sur tes fonctions déjà définies :
                                                    #   - Remove-Accents
                                                    #   - Get-DeptTokenForGroup  (mappe "Design_Animation"->"Design", "Direction_Général"->"DG", etc.)
                                                    #   - Format-GroupName       (retire accents et construit "GS-Users-<DeptToken>-<Site>")

                                                    $DeptToken = Get-DeptTokenForGroup -DeptOU $DeptOU
                                                    $GroupName = Format-GroupName -DeptToken $DeptToken -Site $Site

                                                    # Recherche STRICTE dans l'OU du site 
                                                    try {
                                                        $Group = Get-ADGroup -LDAPFilter "(cn=$GroupName)" `
                                                                             -SearchBase $OU_Site `
                                                                             -SearchScope OneLevel `
                                                                             -ErrorAction Stop
                                                        } catch {
                                                                    $Group = $null
                                                                }

                                                    # Si le groupe n'existe pas dans l'OU du site → on le crée dans CETTE OU uniquement
                                                    if (-not $Group) {
                                                                            try {
                                                                                    $Group = New-ADGroup `
                                                                                        -Name $GroupName `
                                                                                        -SamAccountName $GroupName `
                                                                                        -GroupScope Global `
                                                                                        -GroupCategory Security `
                                                                                        -Path $OU_Site `
                                                                                        -ErrorAction Stop

                                                                                    Write-Host "Groupe créé dans l'OU du site : $($Group.DistinguishedName)" -ForegroundColor Yellow
                                                                                } catch {
                                                                                            Write-Error "Échec création groupe $GroupName dans $OU_Site : $($_.Exception.Message)"
                                                                                            # interrompre la création utilisateur si le groupe n'a pas pu être créé :
                                                                                            # Remove-ADUser -Identity $SAM -Confirm:$false
                                                                                            # continue
                                                                                        }
                                                                    }

                                                    # À ce stade, le groupe existe dans l'OU du site → on ajoute le membre
                                                    if ($Group) {
                                                                    try {
                                                                            Add-ADGroupMember -Identity $Group.DistinguishedName -Members $SAM -ErrorAction Stop
                                                                            Write-Host "Utilisateur $SAM ajouté au groupe $($Group.Name) (OU site)." -ForegroundColor Green
                                                                        } catch {
                                                                                    Write-Warning "Échec ajout $SAM → $($Group.Name) : $($_.Exception.Message)"
                                                                                }
                                                                }

                                                    # === Envoi vers partage RH ================================================

                                                    # Chemin du partage réseau RH 
                                                    $SharePath = "C:\Windows\SYSVOL\sysvol\CreativeFusion-Studios.eu\Dossier_partage\Partage_RH\"

                                                    # Création du dossier s'il n'existe pas
                                                    if (-not (Test-Path $SharePath)) {
                                                                                        New-Item -ItemType Directory -Path $SharePath -Force | Out-Null
                                                                                    }

                                                    # Génération nom de fichier avec date dd-MM-yyyy
                                                    $DateStamp = (Get-Date -Format "dd-MM-yyyy_HHmm")
                                                    $DestFile  = Join-Path $SharePath ("Nouveaux_Utilisateurs_" + $DateStamp + ".xlsx")

                                                    # === Export pour RH ========================================================

                                                        $ExportList += [PSCustomObject]@{
                                                                                            FirstName  = $First
                                                                                            LastName   = $Last
                                                                                            SAMAccount = $SAM
                                                                                            UPN        = $UPN
                                                                                            Password   = $Password
                                                                                            Department = $Dept
                                                                                            Site       = $Site
                                                                                            OU_Path    = $OU_Site
                                                                                            Group      = $GroupName
                                                                                        }
                                                } else { 
                                                        Write-Host "Utilisateur : $SAM deja existant" -ForegroundColor Green
                                                        }
                        }

                    $ExportList | Export-Excel -Path $DestFile -AutoSize -FreezeTopRow

                    Write-Host "Fichier envoyé au partage RH : $DestFile" -ForegroundColor Green

                    # === Vidage du fichier RH ============================

                    # Sauvegarde de sécurité avant nettoyage
                    $BackupStamp = (Get-Date -Format "dd-MM-yyyy_HHmm")
                    $ExcelBackup = [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($ExcelInput),
                                                            ("FichierRH_Utilisateur_backup_" + $BackupStamp + ".xlsx"))
                    Copy-Item -Path $ExcelInput -Destination $ExcelBackup -Force

                    # Recharge pour déterminer dynamiquement le nombre de lignes à effacer

                    $pkg = Open-ExcelPackage -Path $ExcelInput 
                    $ws  = $pkg.Workbook.Worksheets[1]

                    if ($ws.Dimension -and $ws.Dimension.End.Row -gt 1) {

                                                                            $ws.DeleteRow(2, $ws.Dimension.End.Row - 1)

                                                                            Close-ExcelPackage -ExcelPackage $pkg -SaveAs $ExcelInput
                                                                            Write-Host "Fichier RH nettoyé (A$startRow:D$endRow vidé)." -ForegroundColor Yellow
                                                                        }
                    else {
                            Close-ExcelPackage -ExcelPackage $pkg
                            Write-Host "Aucune donnée RH à nettoyer (feuille vide ou introuvable)." -ForegroundColor DarkYellow

                        }
