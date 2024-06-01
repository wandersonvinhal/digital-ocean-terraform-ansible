# Automação de Infraestrutura na Digital Ocean com GitHub Actions

Este projeto demonstra como automatizar a criação e destruição de infraestrutura na Digital Ocean utilizando GitHub Actions, Terraform e Ansible.

## Visão Geral

A automação realiza as seguintes tarefas:
- Criação e destruição de infraestrutura na Digital Ocean usando Terraform.
- Validação da variável `DESTROY_INFRA` para garantir que contenha valores válidos.
- Inicialização e aplicação do Terraform.
- Execução de playbooks Ansible para configurar os servidores.
- Geração automática do arquivo `hosts` do Ansible usando o output do Terraform.
- Execução automática do fluxo de trabalho em qualquer commit na branch `main`.
- Persistência do state do Terraform em um banco de dados PostgreSQL na nuvem.

## Infraestrutura Criada

A infraestrutura provisionada inclui:
- Máquinas Virtuais (VMs)
- Chaves SSH
- Firewall

## Pré-requisitos

Antes de configurar e executar esta automação, certifique-se de ter o seguinte:

- Conta na Digital Ocean.
- Banco de dados PostgreSQL para armazenar o state do Terraform.
- Repositório no GitHub configurado com GitHub Actions.
- **Chaves SSH:** As chaves pública e privada devem ser criadas e seus conteúdos armazenados como segredos no GitHub. As chaves são necessárias para acesso seguro aos servidores. Você pode configurar as chaves SSH seguindo as instruções da [Documentação do GitHub](https://docs.github.com/pt/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent).
- **Segredos no GitHub:** Configure os seguintes segredos no seu repositório do GitHub:
  - `DO_TOKEN`: Token de acesso da Digital Ocean.
  - `PG_CONN_STR`: String de conexão para o banco de dados PostgreSQL.
  - `PRIVATE_KEY`: Chave SSH privada.
  - `PUBLIC_KEY`: Chave SSH pública.

## Configuração

1. **Configurar Segredos no GitHub:**
   - `DO_TOKEN`: Token de acesso da Digital Ocean.
   - `PG_CONN_STR`: String de conexão para o banco de dados PostgreSQL.
   - `PRIVATE_KEY`: Chave SSH privada.
   - `PUBLIC_KEY`: Chave SSH pública.

2. **Variáveis no GitHub Actions:**
   - `DESTROY_INFRA`: Defina como `true` para destruir a infraestrutura, ou `false` para criar.

## Estrutura do Workflow

Aqui está a estrutura do workflow do GitHub Actions (`.github/workflows/main.yml`):

```yaml
name: Criação de Infra na Digital Ocean

on:
  push:
    branches:
      - main

jobs:
  deploy_iaac:
    runs-on: ubuntu-latest
    env:
      DESTROY_INFRA: ${{ vars.DESTROY_INFRA }}
    steps:
      - name: Validando variável DESTROY_INFRA
        if: ${{ env.DESTROY_INFRA != 'true' && env.DESTROY_INFRA != 'false' }}
        run: |
          echo "A variável deve conter o valor true ou false"
          echo "Setar o valor em 'Actions secrets and variables'"
          exit 1
          
      - name: Download dos artefatos
        uses: actions/checkout@v4.1.5

      - name: Terraform Init
        run: terraform init -backend-config="conn_str=${{ secrets.PG_CONN_STR }}"

      - name: Terraform Validate
        run: terraform validate
        
      - name: Terraform Apply/Destroy
        run: |
          if [ "${{ env.DESTROY_INFRA }}" != "true" ]; then
            terraform apply --auto-approve -var do_token=${{ secrets.DO_TOKEN }}
          elif [ "${{ env.DESTROY_INFRA }}" == "true" ]; then
            terraform destroy --auto-approve -var do_token=${{ secrets.DO_TOKEN }}
          fi
          
      - name: Configuração do arquivo ansible.cfg
        if: ${{ env.DESTROY_INFRA != 'true' }}
        run: |
            cat > ansible.cfg <<EOF
            [defaults]
            host_key_checking = False
            EOF

      - name: Executando o ansible-playbook
        if: ${{ env.DESTROY_INFRA != 'true' }}
        run: |
          ansible-playbook -i ansible/hosts playbook-install-nginx.yaml

