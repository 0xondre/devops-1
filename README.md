# Notes App

Projekt uruchamia prostą aplikację do notatek na trzech maszynach Vagranta:

| Rola | Adres VM | Usługi |
| --- | --- | --- |
| db | `192.168.56.10` | PostgreSQL |
| backend | `192.168.56.11` | Flask + Gunicorn |
| frontend | `192.168.56.12` | Angular + Nginx |

## Uruchomienie

Po jednorazowym przygotowaniu Packera, Vagranta i środowiska Ansible w WSL, całość uruchom z katalogu projektu jedną komendą:

```powershell
.\start-devops.ps1
```

Skrypt uruchamia VM-ki, synchronizuje katalogi `ansible` i `app` do WSL, instaluje wymaganą kolekcję i wykonuje playbook.

### 1. Uruchom maszyny w PowerShellu

Jeśli box `packer/ubuntu-base.box` już istnieje, przejdź do katalogu `vagrant` i wykonaj:

```powershell
cd C:\Users\user01\programowanie\devops\vagrant
vagrant up
```

Jeśli maszyny są już utworzone, `vagrant reload` zastosuje zmiany z Vagrantfile.

### 2. Przygotuj Ansible w WSL

Ansible uruchamiaj w katalogu Linux WSL, a nie bezpośrednio w `/mnt/c`, bo Windowsowy mount jest oznaczany jako zapisywalny dla wszystkich. Skopiuj tylko katalogi potrzebne do wdrożenia:

```bash
sudo apt update
sudo apt install -y python3-venv sshpass
mkdir -p ~/devops
cp -a /mnt/c/Users/user01/programowanie/devops/ansible ~/devops/
cp -a /mnt/c/Users/user01/programowanie/devops/app ~/devops/
python3 -m venv ~/.venvs/ansible217
source ~/.venvs/ansible217/bin/activate
python -m pip install --upgrade pip
python -m pip install 'ansible-core>=2.17,<2.18'
cd ~/devops/ansible
ansible-galaxy collection install -r requirements.yml
```

### 3. Wdróż aplikację

Wciąż w `~/devops/ansible`, uruchom:

```bash
ansible-playbook playbook.yml
```

Playbook konfiguruje bazę i dostęp sieciowy dla backendu, instaluje usługę Flask/Gunicorn, buduje frontend Angular i konfiguruje Nginx.

Zapora UFW jest włączana na wszystkich trzech VM. Ruch przychodzący jest domyślnie blokowany, a wychodzący dozwolony. Wyjątki to SSH (22) na każdej VM, PostgreSQL (5432) tylko z backendu, backend (5000) z frontendu i sieci NAT Vagranta oraz HTTP (80) na frontendzie. Dzięki wyjątkowi dla NAT nadal działa lokalny adres API `http://localhost:8000`. Przekierowania Vagranta są związane z `127.0.0.1` hosta.

Stan reguł po wdrożeniu sprawdzisz z katalogu `ansible`: `ansible all -b -a "ufw status verbose"`.

### 4. Otwórz aplikację

- Frontend: <http://localhost:8080>
- API health: <http://localhost:8000/api/health>

Oczekiwana odpowiedź API: `{"database":"up","status":"ok"}`.

## Ponowne wdrożenie zmian

Po edycji plików skopiuj ponownie `app` do WSL i uruchom `ansible-playbook playbook.yml`. Maszyny wyłączysz poleceniem `vagrant halt` z katalogu `vagrant`.

## Hasła laboratoryjne

W przykładzie używane jest hasło `zmien_mnie` dla użytkownika bazy `notes_user`. Zmień je jednocześnie w `ansible/playbook.yml` oraz w konfiguracji backendu przed użyciem poza lokalnym środowiskiem ćwiczeniowym.
