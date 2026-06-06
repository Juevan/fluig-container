# Configuração dos Módulos no Painel WCMAdmin

Este guia orienta passo a passo como realizar a configuração e a ativação dos serviços de **E-mail (SMTP/Mailpit)**, **Busca (Solr/Indexer)** e **Tempo Real (Node.js/Realtime)** dentro do painel de controle do administrador (`wcmadmin`) após o primeiro boot do contêiner.

---

## Acesso ao Painel

1. Acesse o portal no seu navegador: `http://localhost:8080/portal` (ou a porta customizada em `PORT_APP`).
2. Clique em **Login** no canto superior direito.
3. Insira as credenciais do administrador da plataforma:
   * **Usuário:** `wcmadmin`
   * **Senha:** *A senha definida na primeira inicialização da plataforma.*

---

## 1. Configuração de E-mail (SMTP / Mailpit)

Para capturar e-mails de teste localmente usando o Mailpit:

1. No menu lateral esquerdo, navegue até:
   **Painel de Controle** ➔ **WCM** ➔ **Configuração de E-mail**.
2. Preencha as configurações de conexão com a rede interna do Docker:
   * **Servidor (Host):** `mailpit`
   * **Porta:** `1025`
   * **Autenticação:** Desmarcado / Falso
   * **Segurança:** Nenhuma
   * **E-mail do Remetente:** `fluig@localhost`
3. Clique em **Salvar**.

> [!TIP]
> Com esta configuração ativa, qualquer notificação ou e-mail de workflow disparado pelo Fluig será capturado na caixa de entrada local do Mailpit, acessível no navegador em `http://localhost:8025`.

---

## 2. Configuração de Indexação (Solr / Indexer)

Para habilitar a indexação global e a busca de documentos:

1. No menu lateral esquerdo, navegue até:
   **Painel de Controle** ➔ **WCM** ➔ **Configurações do Indexador**.
2. Preencha os parâmetros de conexão do Solr:
   * **Endereço do Servidor:** `http://localhost:8983/solr` (ou a porta customizada em `PORT_SOLR`).
   * **Nome do Core:** `0`
3. Clique em **Testar Conexão** para confirmar a comunicação.
4. Clique em **Salvar**.

---

## 3. Configuração de Tempo Real (Node.js / Realtime)

Para habilitar notificações instantâneas e a funcionalidade de chat:

1. No menu lateral esquerdo, navegue até:
   **Painel de Controle** ➔ **WCM** ➔ **Configurações do Realtime**.
2. Defina as rotas de comunicação:
   * **URL interna para envio de notificações:** `http://127.0.0.1:8888` (Porta Express usada pelo JBoss para enviar notificações ao Node.js).
   * **URL para recebimento de notificações (Pública):** `http://localhost:7070` (Porta WebSocket/Socket.io usada pelo navegador do usuário para se conectar ao Node.js. *Caso acesse o Fluig de outro computador da rede, substitua `localhost` pelo IP ou domínio do servidor host*).
3. Clique em **Salvar**.

---

## 4. Cadastro da Primeira Empresa (Volumes)

Para cadastrar ou editar a primeira empresa e garantir que seus arquivos e documentos (GED) fiquem persistidos e organizados corretamente dentro do volume do Docker:

1. No menu lateral esquerdo, navegue até:
   **Painel de Controle** ➔ **WCM** ➔ **Empresas**.
2. Clique em **Adicionar** (ou edite a empresa padrão existente).
3. No campo **Volume** (ou caminho físico do volume), insira o seguinte diretório:
   ```text
   /opt/totvs/fluig/repository/001
   ```
4. Configure as demais informações necessárias (Código, Nome, URL do Portal) e clique em **Salvar**.

> [!IMPORTANT]
> O caminho `/opt/totvs/fluig/repository/001` garante que os arquivos anexados a processos, documentos e posts fiquem armazenados dentro da pasta `/opt/totvs/fluig/`, que está totalmente mapeada e persistida sob o volume do Docker `fluig-app-data`. Evite usar caminhos fora do diretório de instalação do Fluig.
