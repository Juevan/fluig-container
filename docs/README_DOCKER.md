# Fluig Community Container — Detalhes Técnicos

## Arquitetura

Dois containers orquestrados por um único `docker-compose.yml`:

| Container | Imagem | Função |
|---|---|---|
| `fluig` | Ubuntu 24.04 (customizado) | WildFly/JBoss + Solr + Node.js |
| `fluig-db` | mysql:8.0 | Persistência de dados |

Solr e Node.js rodam **dentro do container `fluig`**, controlados pelas variáveis `INSTALL_SOLR` e `INSTALL_NODE` no `.env`.

### Rede e Volumes

```
fluig-net (bridge)
  ├── fluig      ←→ fluig-app-data (/opt/totvs/fluig)
  └── fluig-db   ←→ fluig-db-data  (/var/lib/mysql)
```

---

## O que o `entrypoint.sh` faz

Executado a cada boot do container:

1. **Aguarda o MySQL** via TCP check antes de prosseguir
2. **Baixa o driver JDBC** (MySQL ou PostgreSQL) se necessário
3. **Gera `install.conf`** substituindo variáveis de ambiente no template
4. **Instalação silenciosa** — só executa se `standalone.xml` não existe ou `FLUIG_UPDATE=true`
5. **Patches no `standalone.xml`:**
   - Bind `<any-address/>` para aceitar conexões externas
   - Força porta HTTP `8080`
   - Substitui placeholders de SMTP
6. **Solr:** cria `/etc/default/fluig_Indexer.in.sh` com `SOLR_SECURITY_MANAGER_ENABLED=false` e `allowPaths=*`, inicia na porta `8983` e cria o core `0` se necessário
7. **JBoss** em background com bind `0.0.0.0`
8. **Node.js Realtime** após JBoss estar pronto (socket.io em `:7070`, Express em `:8888`)
9. **`tail -f`** nos logs do JBoss para manter o container vivo

---

## Portas

| Porta | Serviço |
|---|---|
| `8080` | Fluig HTTP (JBoss) |
| `8443` | Fluig HTTPS |
| `8983` | Solr Admin |
| `8888` | Node.js Express (notificações JBoss → Node) |
| `7070` | Node.js WebSocket/socket.io (browser → Node) |
| `3306` | MySQL |

---

## Persistência

| Volume | Conteúdo |
|---|---|
| `fluig-app-data` | Binários, configurações e GED do Fluig |
| `fluig-db-data` | Dados do MySQL |

> [!CAUTION]
> `docker compose down -v` remove ambos os volumes permanentemente.

---

## Configuração do Solr (Nota técnica)

O Fluig armazena os índices em `/opt/totvs/fluig/repository/...`, que fica fora do `SOLR_HOME`. O Solr 9.x bloqueia isso por padrão via SecurityManager. A solução implementada:

```bash
# /etc/default/fluig_Indexer.in.sh (criado automaticamente pelo entrypoint)
SOLR_SECURITY_MANAGER_ENABLED=false
SOLR_OPTS="$SOLR_OPTS -Dsolr.allowPaths=*"
```
