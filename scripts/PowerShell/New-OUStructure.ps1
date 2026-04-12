Import-Module ActiveDirectory

# Racine des OUs User
$rootOU = "OU=User,OU=CreativeFusion,DC=CreativeFusion-Studios,DC=eu"

# Liste des OUs metiers existantes
$departements = @(
                    "Compta"
                    "Design_Animation"
                    "Direction_G\'e9n\'e9ral"
                    "Info"
                    "RH"
)

# Nom du site a ajouter
$site = "Lyon"

foreach ($dept in $departements) {

                                    # OU parent : OU=Compta, OU=Design_Animation, etc.
                                    $parentOU = "OU=$dept,$rootOU"

                                    # Verifie si l'OU parent existe
                                    if (-not (Get-ADOrganizationalUnit -LDAPFilter "(ou=$dept)" -SearchBase $rootOU -ErrorAction SilentlyContinue)) {
                                                                                                                                                    Write-Host "L'OU parent $dept n'existe pas, creation..." -ForegroundColor Yellow
                                                                                                                                                    New-ADOrganizationalUnit -Name $dept -Path $rootOU
                                                                                                                                                    }

                                    # Nom de l'OU enfant pour le site
                                    $newSiteOU = "$\{dept\}_$\{site\}"

                                    # Creation OU du site
                                    New-ADOrganizationalUnit -Name $newSiteOU -Path $parentOU -ErrorAction SilentlyContinue\

                                    Write-Host "Cree : $newSiteOU dans $parentOU" -ForegroundColor Green\
                                }
