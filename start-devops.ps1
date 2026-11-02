$ErrorActionPreference = "Stop"

$projectRoot = $PSScriptRoot
$vagrantDirectory = Join-Path $projectRoot "vagrant"

Push-Location $vagrantDirectory
try {
    & vagrant up
    if ($LASTEXITCODE -ne 0) {
        throw "vagrant up zakończył się błędem (kod $LASTEXITCODE)."
    }
}
finally {
    Pop-Location
}

$wslRoot = (& wsl.exe wslpath -a $projectRoot).Trim()
if ($LASTEXITCODE -ne 0 -or -not $wslRoot) {
    throw "Nie udało się ustalić ścieżki projektu w WSL."
}

$wslCommand = @"
set -e
mkdir -p "`$HOME/devops"
cp -a '$wslRoot/ansible' "`$HOME/devops/"
cp -a '$wslRoot/app' "`$HOME/devops/"
chmod -R go-w "`$HOME/devops"
source "`$HOME/.venvs/ansible217/bin/activate"
cd "`$HOME/devops/ansible"
ansible-galaxy collection install -r requirements.yml
ansible-playbook -i inventory.ini playbook.yml
"@

& wsl.exe -- bash -lc $wslCommand
if ($LASTEXITCODE -ne 0) {
    throw "Wdrożenie Ansible w WSL nie powiodło się (kod $LASTEXITCODE)."
}

Write-Host "Aplikacja powinna być dostępna pod http://localhost:8080"
