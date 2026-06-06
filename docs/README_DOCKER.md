# Fluig Community Container — Detalhes Técnicos

## Arquitetura

Dois containers orquestrados por um único `docker-compose.yml`:

| Container | Imagem | Função |
|---|---|---|
| `fluig` | Ubuntu 24.04 (customizado) | WildFly/JBoss + Solr + Node.js |
| `fluig-db` | mysql:8.0 | Persistência de dados |

Solr e Node.js rodam **dentro do container `fluig`**, controlados pelas variáveis `ENABLE_SOLR` e `ENABLE_REALTIME` no `.env`.

### Rede e Volumes

```
fluig-net (bridge)
  ├── fluig      ←→ fluig-app-data (/opt/totvs/fluig)
  └── fluig-db   ←→ fluig-db-data  (/var/lib/mysql)
```

---

## O que o `entrypoint.sh` faz

O `entrypoint.sh` é um orquestrador enxuto que delega as responsabilidades de inicialização e configuração para scripts modulares localizados em `/installer/scripts/lib/`:

1. **`database.sh`**: Aguarda a disponibilidade da porta do MySQL e baixa o driver JDBC do MySQL.
2. **`installer.sh`**: Prepara a estrutura de pastas do Fluig, compila o `install.conf` a partir do template usando `envsubst` e dispara o instalador silencioso.
3. **`xml.sh`**: Aplica patches de binding de IP e SMTP no `standalone.xml` do Wildfly e ajusta as permissões de arquivos para o usuário `fluig`.
4. **`solr.sh`**: Inicializa o Solr de forma segura sob o usuário `fluig`, configura o arquivo `/etc/default/fluig_Indexer.in.sh` com as opções de permissão necessárias (`SOLR_SECURITY_MANAGER_ENABLED=false` e `allowPaths=*`) e cria o core `0`.
5. **`jboss.sh`**: Inicia o JBoss/Wildfly em background sob o usuário `fluig` e aguarda até que a porta HTTP responda.
6. **`realtime.sh`**: Configura a porta do chat WebSocket no `package.json` e inicializa o Node.js Realtime sob o usuário `fluig`.

Ao final do fluxo, o orquestrador executa o `tail -f` nos logs do JBoss para manter o contêiner em execução.

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
