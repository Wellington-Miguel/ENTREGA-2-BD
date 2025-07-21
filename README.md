# Sistema de Gestão de Pesquisa - Projeto de Banco de Dados (MATA60)

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-025E8C?style=for-the-badge&logo=sql&logoColor=white)

## 📖 Sobre o Projeto

Este repositório contém a implementação de um banco de dados para um **Sistema de Gestão de Atividades de Pesquisa**, desenvolvido como projeto para a disciplina **MATA60 - Banco de Dados** da Universidade Federal da Bahia (UFBA), sob a orientação do Prof. Robespierre Pita.

O objetivo do projeto é modelar, implementar e otimizar um banco de dados relacional em **PostgreSQL** capaz de gerenciar entidades complexas como pesquisadores, projetos, financiamentos, publicações e equipamentos, aplicando conceitos avançados de banco de dados para garantir performance, segurança e integridade.

---

## ✨ Funcionalidades e Conceitos Implementados

O projeto foi dividido em duas entregas, cobrindo desde a modelagem básica até a implementação de rotinas avançadas:

### Entrega 1: Modelagem, Implantação e Otimização

* **Modelagem Relacional:** Definição do esquema de dados, seguindo a notação de Peter Chen e aplicando o padrão de nomenclatura **DataSUS/MAD2**.
* **Implementação DDL e DML:** Scripts para criação da estrutura (`CREATE TABLE`) e povoamento (`INSERT INTO`) do banco de dados.
* **Consultas de Desempenho:** Elaboração de 20 consultas analíticas (10 intermediárias e 10 avançadas) para testar o desempenho do banco.
* **Plano de Indexação:** Criação estratégica de índices (`CREATE INDEX`) para otimizar a execução das consultas, com foco em chaves estrangeiras e colunas de filtragem.

### Entrega 2: Rotinas, Privacidade e Preservação de Dados

* **Stored Procedures:** Criação de procedimentos armazenados (`PROCEDURE`) para encapsular lógicas de negócio complexas, como o cadastro de um novo pesquisador ou a inscrição em um evento, garantindo a execução atômica e segura das operações.
* **Materialized Views:** Implementação de visões materializadas (`MATERIALIZED VIEW`) para pré-calcular e armazenar os resultados de consultas analíticas pesadas, garantindo que os dashboards carreguem de forma instantânea.
* **Transações:** Uso de controle transacional implícito e explícito para garantir a integridade dos dados em operações críticas, como a descontinuidade de um projeto, assegurando que as operações sejam completadas com sucesso ou totalmente revertidas.
* **Políticas de Privacidade e Segurança:** Implementação de um sistema de controle de acesso baseado em papéis (`ROLES`) para diferentes perfis de usuário (gestor, coordenador, auditor), com permissões granulares e mascaramento de dados sensíveis.
* **Política de Backup e Recuperação:** Definição de uma estratégia de backup incremental baseada em **Point-in-Time Recovery (PITR)**, utilizando backups base (`pg_basebackup`) e arquivamento de logs de transação (WALs).

---

## 🛠️ Tecnologias Utilizadas

* **SGBD:** PostgreSQL
* **Linguagem:** SQL (padrão ANSI com extensões do PostgreSQL)
* **Ferramentas:** DBeaver, pgAdmin

---

## 📂 Estrutura do Repositório

* `ENTREGA 1/`: Contém os scripts e artefatos da primeira fase do projeto.
    * `script_completo_E1.sql`: Script SQL com DDL, DML, consultas e índices da Entrega 1.
* `ENTREGA 2/`: Contém os scripts e artefatos da segunda fase do projeto.
    * `Artefato_1.sql`: Código da Stored Procedure e Materialized View para a tela de cadastro de pesquisador.
    * `Artefato_2.sql`: Código da Stored Procedure e Materialized View para a tela de inscrição em evento.
    * `Artefato_3.sql`: Código das 4 Materialized Views e da Stored Procedure transacional para o dashboard estratégico.
    * `Artefato_4.sql`: Código das 6 Materialized Views e da Stored Procedure de atualização para o dashboard operacional.
    * `Politicas.sql`: Script para criação dos papéis (`ROLES`) e da `VIEW` de mascaramento de dados.

---

## 🚀 Como Executar o Projeto

Para configurar e executar o banco de dados localmente, siga os passos abaixo.

### Pré-requisitos

* Ter o **PostgreSQL** instalado e em execução na sua máquina.
* Ter uma ferramenta de cliente SQL, como **DBeaver** ou **pgAdmin**.

### Passos para Configuração

1.  **Crie o Banco de Dados:**
    ```sql
    CREATE DATABASE gestao_pesquisa;
    ```
2.  **Conecte-se** ao banco de dados recém-criado na sua ferramenta de preferência.

3.  **Execute os Scripts da Entrega 1:**
    * Abra e execute o conteúdo do arquivo `ENTREGA 2/estrutura.sql`. Isso criará todas as tabelas, inserirá os dados de exemplo e criará os índices de performance.

4.  **Execute os Scripts da Entrega 2 (na ordem):**
    * Execute o `ENTREGA 2/artefato_1.sql`.
    * Execute o `ENTREGA 2/artefato_2.sql`.
    * Execute o `ENTREGA 2/artefato_3.sql`.
    * Execute o `ENTREGA 2/artefato_4.sql`.
    * Execute o `ENTREGA 2/privacidade.sql`.

Após esses passos, o banco de dados estará totalmente configurado, populado e com todas as rotinas e políticas de segurança prontas para uso.

---

## 👨‍💻 Autor

* **Wellington Miguel de Jesus Silva**
* **GitHub:** [@Wellington-Miguel](https://github.com/Wellington-Miguel)

---

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.
