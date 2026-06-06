# Fluig Community Container Platform

## 🚀 Objetivo
O **Fluig Community Container** é um projeto focado em modernizar a execução da plataforma TOTVS Fluig utilizando uma arquitetura Docker modular, leve e de fácil manutenção. O objetivo principal é facilitar a criação de ambientes de desenvolvimento, estudo e homologação, removendo a complexidade das instalações manuais tradicionais.

## ✨ Principais Diferenciais
- **Modularidade Total:** Ative ou desative os módulos de Indexação (Solr) e Real-time (Node.js) de forma independente via variáveis `ENABLE_SOLR` e `ENABLE_REALTIME` no `.env`.
- **Auto-Instalação:** O `entrypoint.sh` executa a instalação silenciosa do Fluig automaticamente na primeira inicialização, incluindo download do driver JDBC e patching do `standalone.xml`.
- **Persistência Completa:** Todos os dados do banco e arquivos do GED (Volume) são preservados através de volumes Docker.
- **Configuração via .env:** Todo o ambiente (portas, senhas, memória, pools) é gerenciado em um único arquivo de variáveis de ambiente.

## 🏗️ Arquitetura
A solução é composta por quatro containers principais:

1. **fluig:** Servidor de aplicação Wildfly/JBoss executando o núcleo da plataforma (BPM, ECM, GED, APIs).
2. **fluig-db:** Instância MySQL 8.0 dedicada para persistência de dados.
3. **fluig-indexer (Opcional):** Servidor Solr dedicado para serviços de busca e indexação.
4. **fluig-realtime (Opcional):** Runtime Node.js para notificações e atualizações em tempo real.
5. **fluig-mail:** Instância Mailpit para atuar como servidor SMTP "catch-all" para envio e teste local de e-mails do Fluig sem disparos para o mundo externo.

---

## 🛠️ Stack Tecnológica
- **SO Base:** Ubuntu 24.04 LTS
- **Banco de Dados:** MySQL 8.0 (charset `utf8`, collation `utf8_general_ci`)
- **Runtime:** JDK 11 (incluído no instalador Voyager)
- **Orquestração:** Docker Compose v2

## 📁 Estrutura do Projeto
```text
fluig-community-container/
├── docker/
│   ├── .env                       # Central de configurações (portas, senhas, memória, módulos)
│   ├── docker-compose.yml         # Orquestração completa (App + DB)
│   ├── Dockerfile                 # Imagem base Ubuntu 24.04 + dependências
│   ├── up.sh                      # Script de conveniência para subir o ambiente
│   └── scripts/
│   └── scripts/
│       ├── entrypoint.sh          # Orquestrador central de boot do contêiner
│       ├── install.conf.template  # Template dinâmico para instalação silenciosa
│       └── lib/                   # Scripts modulares de inicialização
│           ├── database.sh        # Verificação do banco e driver JDBC
│           ├── installer.sh       # Configuração e execução do instalador
│           ├── jboss.sh           # Boot do JBoss/Wildfly
│           ├── realtime.sh        # Boot do Node.js Realtime
│           ├── solr.sh            # Boot seguro e configuração do Solr
│           └── xml.sh             # Patches no standalone.xml do Wildfly
├── docs/
│   ├── RUNBOOK.md                 # Guia operacional e troubleshooting
│   ├── INSTALLATION_LINUX.md      # Guia de instalação bare-metal
│   └── README_DOCKER.md           # Detalhes técnicos da configuração Docker
├── installer-package/             # Coloque aqui o instalador descompactado
└── README.md                      # Este documento
```

## ⚡ Quick Start
```bash
# 1. Descompacte o instalador do Fluig na pasta installer-package/
# 2. Configure o .env (módulos ENABLE_SOLR e ENABLE_REALTIME controlam Solr e Node.js)
cd docker

# 3. Suba o ambiente
docker compose up -d --build

# 4. Acompanhe a instalação
docker logs -f fluig

# 5. Acesse no navegador
# http://localhost:8080/portal

# 6. Acesse os testes de E-mail (Mailpit Inbox)
# http://localhost:8025/
```

## 📝 Documentação Adicional
- **[RUNBOOK.md](docs/RUNBOOK.md):** Guia passo a passo de operação, backup e troubleshooting.
- **[WCMADMIN_CONFIG.md](docs/WCMADMIN_CONFIG.md):** Guia passo a passo para configurar os módulos (E-mail, Solr e Realtime) no painel administrativo.
- **[INSTALLATION_LINUX.md](docs/INSTALLATION_LINUX.md):** Guia de referência para instalação em bare-metal (Linux tradicional).
- **[README_DOCKER.md](docs/README_DOCKER.md):** Detalhes técnicos da configuração Docker e do `entrypoint.sh`.

---
> [!WARNING]
> Este projeto é voltado para uso em **Desenvolvimento** e **Estudo**. Para ambientes de produção, certifique-se de seguir as diretrizes oficiais de segurança e escalabilidade da TOTVS.
