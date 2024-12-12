# Whanos project

## Setup (Debian VPS)

### Setup a Debian 12 VPS with:

- sudo
- python3

### Setup your localhost:
- Install `ansible` locally:
```bash
sudo apt install ansible
```
- Clone the repository locally:
```bash
git clone $REPO_NAME
```
- Setup ansible vault password:
```bash
# Replace with your vault password:
echo "your_ansible_vault_passwd" > /tmp/.vault_pass
export ANSIBLE_VAULT_PASSWORD_FILE=/tmp/.vault_pass
```
- If you want to use our inventory, execute:
```bash
cp ansible/inventory.example.yml ansible/inventory.yml
```
- Setup your variables:
```bash
cp ansible/group_vars/all.example.yml ansible/group_vars/all.yml

# Fill in the variables with your values:
vim ansible/group_vars/all.yml
# Encrypt the file:
ansible-vault encrypt ansible/group_vars/all.yml
```
- Run the playbook locally:
```bash
ansible-playbook -i ansible/inventory.yml ansible/playbook.yml
```