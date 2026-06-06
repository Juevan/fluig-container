# Guia de Instalação TOTVS Fluig 2.0 (Voyager) - Linux

Este documento detalha os passos para a instalação do TOTVS Fluig **Versão 2.0 (Voyager)** em ambiente **Ubuntu**, utilizando **MySQL** como banco de dados.

> [!NOTE]
> Este guia é uma referência para instalação **bare-metal** (sem Docker). Para a instalação containerizada, consulte o [RUNBOOK.md](RUNBOOK.md).

## 1. Pré-requisitos de Sistema

### Hardware (Mínimo recomendado)
- **CPU:** 4 núcleos ou mais.
- **RAM:** 8GB (mínimo), 16GB+ (recomendado para produção).
- **Disco:** 50GB para instalação + espaço para o Volume (arquivos).

### Software
- **Java:** JDK 11 (incluído no instalador Voyager na pasta `jdk-64`).
- **Banco de Dados:** MySQL 8.0.
- **SO:** Ubuntu 20.04, 22.04 ou **24.04 LTS**.

---

### Configurações de Ambiente (Ubuntu)
- **Hostname:** Configure o hostname do servidor no arquivo `/etc/hosts`.
- **UTF-8:** O Ubuntu deve usar UTF-8. Verifique com `locale` e adicione `export LC_ALL=en_US.utf8` ao seu `.bashrc`.
- **Sistema de Arquivos:** Use **Ext4**.

### Ajuste de Limites (ulimit)
1. Edite o arquivo `/etc/sysctl.conf` e adicione:
   ```text
   fs.file-max=65536
   ```
   Aplique com `sudo sysctl -p`.

2. Edite o arquivo `/etc/security/limits.conf` e adicione os limites para o usuário do Fluig (ex: `fluig`):
   ```text
   fluig soft nofile 65536
   fluig hard nofile 65536
   fluig soft nproc 65000
   fluig hard nproc 65000
   ```

### Instalação de Bibliotecas
Para Ubuntu 20.04 e 22.04:
```bash
sudo apt-get install libaio1 unzip curl libx11-6 libxext6 libxrender1 libxt6 libfontconfig1 libfreetype6
```

Para Ubuntu 24.04:
```bash
sudo apt-get install libaio1t64 unzip curl libx11-6 libxext6 libxrender1 libxt6 libfontconfig1 libfreetype6
```

---

## 2. Preparação do Banco de Dados (MySQL 8.0)

No Ubuntu, instale o MySQL:
```bash
sudo apt update
sudo apt install mysql-server
```

Acesse o console do MySQL e execute os seguintes comandos:

```sql
-- Criar o banco de dados com charset UTF8
CREATE DATABASE fluig CHARACTER SET utf8 COLLATE utf8_general_ci;

-- Criar usuário para o Fluig
CREATE USER 'fluig'@'%' IDENTIFIED BY 'sua_senha_aqui';

-- Conceder privilégios
GRANT ALL PRIVILEGES ON fluig.* TO 'fluig'@'%';
FLUSH PRIVILEGES;
```

### Configuração Obrigatória do MySQL
Edite o arquivo `/etc/mysql/mysql.conf.d/mysqld.cnf` e adicione:
```ini
[mysqld]
lower_case_table_names=1
character-set-server=utf8
collation-server=utf8_general_ci
default-authentication-plugin=mysql_native_password
```

Reinicie o serviço:
```bash
sudo systemctl restart mysql
```

> [!WARNING]
> O parâmetro `lower_case_table_names=1` **deve** ser definido antes da criação do banco. Alterar esse valor após a inicialização pode corromper os dados.

---

## 3. Instalação do Fluig 2.0

1. **Localização:** Os arquivos de instalação estão no diretório:
   `FLUIG-2.0.0-260505-LINUX64/`
2. **Permissões:** Conceda permissão de execução ao script:
   ```bash
   chmod +x FLUIG-2.0.0-260505-LINUX64/fluig-installer-64.sh
   ```
3. **Execução:** Execute o instalador a partir da raiz do diretório descompactado:
   ```bash
   cd FLUIG-2.0.0-260505-LINUX64/
   sudo ./fluig-installer-64.sh
   ```
4. **Propriedade:** Após a instalação, garanta que o usuário do serviço seja o dono da pasta destino:
   ```bash
   sudo chown -R fluig:fluig /opt/totvs/fluig
   ```
5. **Configurações no Console:**
   - **Diretório de Instalação:** Ex: `/opt/totvs/fluig`
   - **Diretório de Volume:** Ex: `/opt/totvs/fluig/volume`
   - **Dados do Banco:**
     - **Tipo:** MySQL
     - **URL JDBC:** `jdbc:mysql://localhost:3306/fluig`
     - **Usuário/Senha:** conforme criados no passo 2.

---

## 4. Configuração do Serviço (Systemd)

Para garantir que o Fluig inicie automaticamente, crie o arquivo `/etc/systemd/system/fluig.service`:

```ini
[Unit]
Description=TOTVS Fluig Platform
After=network.target mysql.service

[Service]
Type=forking
User=fluig
Group=fluig
ExecStart=/opt/totvs/fluig/appserver/bin/standalone.sh -b 0.0.0.0
PIDFile=/opt/totvs/fluig/appserver/standalone/tmp/standalone.pid
Restart=always

[Install]
WantedBy=multi-user.target
```

Ative e inicie o serviço:
```bash
sudo systemctl daemon-reload
sudo systemctl enable fluig
sudo systemctl start fluig
```

---

## 5. Acesso Inicial

Após o serviço subir (pode levar alguns minutos na primeira execução), acesse via navegador:

- **URL:** `http://<IP_DO_SERVIDOR>:8080/portal`
- **Configuração de Licença:** Siga as instruções em tela para conectar ao License Server.
- **Usuário Admin:** Crie o usuário administrador inicial conforme solicitado.

---

## 6. Instalação Distribuída (Módulos Separados)

Em ambientes de alta performance ou alta disponibilidade (Cluster), os módulos do Fluig podem ser instalados em servidores distintos.

### Componentes que podem ser separados:
- **App Server:** O núcleo da aplicação.
- **Solr Server:** Servidor de indexação e busca.
- **Real-time Server (Node.js):** Notificações e eventos sociais.
- **Database Server:** Servidor de banco de dados.
- **Volume:** Diretório de arquivos (deve ser um **NFS** ou storage compartilhado em setups distribuídos).

### Portas de Comunicação (Firewall)
Certifique-se de que as seguintes portas estejam abertas entre os servidores:
- **8080 / 8443:** Fluig App (HTTP/HTTPS)
- **8983:** Solr Indexing
- **8888:** Real-time (Node.js)
- **7070:** Chat / Messaging
- **3306:** MySQL

---
> [!TIP]
> Em instalações distribuídas, o uso de um **NFS (v4)** é altamente recomendado para o diretório de Volume, garantindo consistência entre os nós.
