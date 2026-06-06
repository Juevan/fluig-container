# Run Book — Fluig Community Container

## 1. Preparação Inicial

1. Descompacte o instalador do Fluig em `installer-package/` na raiz do projeto
2. Ajuste `docker/.env` com senhas e configurações desejadas
3. Certifique-se de ter Docker + Docker Compose v2 instalados

---

## 2. Comandos Essenciais

```bash
cd docker

bash up.sh               # Subir ambiente (build + start)
docker compose down      # Encerrar (preserva dados)
docker compose down -v   # ⚠️ Reset total (apaga volumes e dados)

docker logs -f fluig     # Acompanhar instalação e boot
docker logs -f fluig-db  # Logs do banco
```

**Acesso após boot:**
- Portal: http://localhost:8080/portal
- Solr Admin: http://localhost:8983

> [!IMPORTANT]
> O primeiro boot demora ~10–20 min (instalação silenciosa). Acompanhe com `docker logs -f fluig` até aparecer `Todos os serviços iniciados.`

---

## 3. Modos de Inicialização (`FLUIG_UPDATE`)

| Valor | Comportamento | Volume `fluig-app-data` | Schema do banco |
|---|---|---|---|
| `false` *(padrão)* | Boot normal, sem instalação | Preservado | Preservado |
| `update` | Aplica patch/nova versão sobre instalação existente | Preservado | Preservado |
| `install` | Instalação limpa do zero | ⚠️ **Apagado e recriado** | Recriado |

### Boot normal (dia a dia)
```bash
# FLUIG_UPDATE=false no .env
bash up.sh
```

### Aplicar patch / nova versão (mantendo dados)
1. Substitua o conteúdo de `installer-package/` pela nova versão
2. No `.env`: `FLUIG_UPDATE=update`
3. `bash up.sh`
4. Após concluir: `FLUIG_UPDATE=false`

### Instalação limpa (reset total dos binários)
1. Substitua `installer-package/` se necessário
2. No `.env`: `FLUIG_UPDATE=install`
3. `bash up.sh`
4. Após concluir: `FLUIG_UPDATE=false`

> [!CAUTION]
> `FLUIG_UPDATE=install` apaga **todos os arquivos do Fluig** no volume (binários, GED, customizações). O banco de dados é preservado pois está em volume separado (`fluig-db-data`).

> [!CAUTION]
> `docker compose down -v` apaga **ambos os volumes** (app + banco). Irreversível.

---

## 4. Backup e Restore

```bash
# Backup do banco
docker exec fluig-db mysqldump -u fluig -pfluig fluig > backup_db.sql

# Restore do banco
cat backup_db.sql | docker exec -i fluig-db mysql -u fluig -pfluig fluig

# Localizar volume do GED no host
docker volume inspect docker_fluig-app-data
```

---

## 5. Troubleshooting

### Solr: "Erro ao comunicar com o Indexer"
O Fluig cria o core `0` com `dataDir` fora do `SOLR_HOME`. O `entrypoint.sh` cria automaticamente `/etc/default/fluig_Indexer.in.sh` com `SOLR_SECURITY_MANAGER_ENABLED=false` e `allowPaths=*` para resolver esse bloqueio do Solr 9.x.

### Realtime: "conexão websocket falhou"
No painel wcmadmin, verifique:
- **URL interna para envio de notificações:** `127.0.0.1:8888` (HTTP Express → JBoss)
- **URL para recebimento de notificações:** `127.0.0.1:7070` (WebSocket/socket.io → browser)

### Fluig não conecta no banco
`DB_HOST` está hardcoded como `db` no compose (nome do serviço). Não é necessário configurar no `.env`.

### Erro de Memória (OOM)
Aumente `JAVA_MIN_HEAP` e `JAVA_MAX_HEAP` no `.env`. Recomendado: mínimo 8 GB de RAM disponível no host.

### Porta 8080 não responde
Verifique se o JBoss subiu corretamente:
```bash
docker exec fluig grep 'socket-binding name="http"' \
    /opt/totvs/fluig/appserver/standalone/configuration/standalone.xml
```

---

## 6. Variáveis de Ambiente (.env)

| Variável | Descrição | Padrão |
|---|---|---|
| `DB_NAME` | Nome do banco | `fluig` |
| `DB_USER` | Usuário do banco | `fluig` |
| `DB_PASSWORD` | Senha do banco | `fluig` |
| `JAVA_MIN_HEAP` | Heap mínima da JVM (MB) | `2048` |
| `JAVA_MAX_HEAP` | Heap máxima da JVM (MB) | `4096` |
| `FLUIG_UPDATE` | Forçar reinstalação no boot | `false` |
| `ENABLE_SOLR` | Habilitar Solr (Indexer) | `true` |
| `ENABLE_REALTIME` | Habilitar Node.js (Realtime) | `true` |
| `ENABLE_MAIL` | Habilitar e-mail (Mailpit) | `true` |
| `PORT_APP` | Porta HTTP do Fluig | `8080` |
| `PORT_SSL` | Porta HTTPS do Fluig | `8443` |
| `PORT_DB` | Porta exposta do MySQL | `3306` |
| `PORT_SOLR` | Porta do Solr | `8983` |
| `PORT_REALTIME` | Porta Express do Node | `8888` |
| `PORT_CHAT` | Porta WebSocket do Node | `7070` |
| `PORT_MAIL_UI` | Porta da interface web do Mailpit | `8025` |

---

## 7. E-mail e Notificações (SMTP / Mailpit)

O ambiente inclui o container `mailpit` (`axllent/mailpit`) configurado para funcionar como um servidor SMTP local de testes ("catch-all"). Isso evita disparos de e-mail indesejados durante o desenvolvimento e captura todas as notificações emitidas pelo Fluig.

**Acesso ao Mailpit:**
- Painel web (Caixa de Entrada): http://localhost:8025

**Como configurar o Fluig para usar o Mailpit:**
Como o ambiente subiu "vanilla" (sem injeção forçada de configurações no banco), você precisa configurar o e-mail no painel do Fluig na primeira execução:

1. Acesse o portal do Fluig (`http://localhost:8080/portal`)
2. Faça login com o usuário administrador (`wcmadmin`)
3. Vá em **Painel de Controle > WCM > Configuração de E-mail**
4. Preencha os dados:
   - **Servidor**: `mailpit`
   - **Porta**: `1025`
   - **Autenticação**: Não
   - **Segurança**: Vazio/Nenhuma
5. Salve as configurações.

Após configurar, qualquer e-mail enviado pelo Fluig (como notificações de processos, recuperação de senha, etc.) será capturado e exibido na caixa de entrada do Mailpit.

---

## 8. Criação de Novas Empresas (Volumes)

Ao criar uma nova "Empresa" no painel (`wcmadmin > WCM > Empresas`), você será solicitado a informar o **Volume Físico** (o local onde os arquivos e documentos daquela empresa serão salvos).

Por padrão, toda a pasta de instalação do Fluig (`/opt/totvs/fluig/`) está mapeada e segura dentro do volume Docker `fluig-app-data`. 

Para garantir que os arquivos da sua nova empresa fiquem devidamente organizados e persistidos, utilize a seguinte estrutura de diretório no momento do cadastro:

```text
/opt/totvs/fluig/repository/wcmdir/wcm/tenants/CODIGO_DA_EMPRESA/volume
```
*(Substitua `CODIGO_DA_EMPRESA` pelo código que você definir, como `TESTE`, por exemplo).*
