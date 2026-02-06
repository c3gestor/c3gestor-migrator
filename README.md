# C3Gestor Migrator

Biblioteca Delphi para versionamento e execução de migrações de banco de dados do C3Gestor ERP.

## 📋 Descrição

`C3Gestor.Migrator` é uma biblioteca reutilizável que centraliza a lógica de execução de scripts SQL em forma de migrações, permitindo manter as alterações de banco de dados versionadas e organizadas.

## 🚀 Como Instalar no Seu Projeto Principal

### Pré-requisitos
- Projeto com **Boss Package Manager** configurado
- Delphi 10.0 ou superior

### Passos de Instalação

1. **Navegue até a pasta do seu projeto ERP Principal:**
   ```bash
   cd "C:\seu\caminho\do\projeto\principal"
   ```

2. **Execute o comando de instalação:**
   ```bash
   boss install github.com/c3gestor-erp/c3gestor-migrator
   ```

O Boss vai:
- ✅ Baixar a biblioteca
- ✅ Configurar os caminhos de busca (Library Path) automaticamente
- ✅ Atualizar o arquivo `boss.json`

## 💡 Como Usar no DataModule do C3Gestor

### 1. Importe a unidade no DataModule

```delphi
uses
  C3Gestor.Migrator;
```

### 2. Implemente a inicialização das migrações

```delphi
procedure TdmPrincipal.DataModuleCreate(Sender: TObject);
var
  LMigrator: TC3Migrator;
begin
  LMigrator := TC3Migrator.Create(FDConnection1);
  try
    // Executa todos os scripts SQL na pasta 'sql'
    LMigrator.Execute(ExtractFilePath(ParamStr(0)) + 'sql');
  finally
    LMigrator.Free;
  end;
end;
```

### 3. Organize os arquivos de migração

Crie uma pasta `sql` no diretório do seu executável com os scripts de migração:

```
seu-projeto/
├── sql/
│   ├── 001_criar_tabela_usuarios.sql
│   ├── 002_adicionar_coluna_email.sql
│   └── 003_criar_indices.sql
└── seu_projeto.exe
```

## 🔄 Fluxo de Trabalho

### Quando você precisa fazer uma alteração no banco de dados:

1. **No projeto `c3gestor-migrator`:**
   - Crie um novo arquivo SQL na pasta de migrações
   - Faça commit: `git commit -m "Add migration: descrição"`
   - Faça push: `git push`

2. **No projeto principal:**
   - Atualize a biblioteca: `boss update`
   - Os novos scripts serão executados automaticamente na próxima inicialização

### Vantagens desta abordagem:

✨ **Migrations versionadas** - Histórico completo de alterações  
🔧 **Correções centralizadas** - Se encontrar um erro, corrija uma vez e use em todo lugar  
🔄 **Atualizações fáceis** - Basta rodar `boss update` para trazer as mudanças  
📦 **Reutilizável** - Qualquer projeto ERP principal pode usar a mesma biblioteca  
🛡️ **Seguro** - Controle de versão integrado com Git  

## 📁 Estrutura do Projeto

```
c3gestor-migrator/
├── src/
│   └── C3Gestor.Migrator.pas   # Implementação principal
├── boss.json                    # Configuração do Boss Package Manager
├── boss-lock.json              # Lock file de dependências
└── README.md                   # Este arquivo
```

## 🔧 Classe Principal: TC3Migrator

### Construtor
```delphi
constructor Create(AConnection: TFDConnection);
```
Cria uma nova instância do migrator com a conexão ao banco de dados.

### Método Principal
```delphi
procedure Execute(APath: string);
```
Executa todos os arquivos `.sql` encontrados no caminho especificado.

## 📝 Exemplo Completo

```delphi
unit dmPrincipal;

interface

uses
  System.SysUtils, System.Classes,
  FireDAC.Comp.Client,
  C3Gestor.Migrator;

type
  TdmPrincipal = class(TDataModule)
    FDConnection1: TFDConnection;
    procedure DataModuleCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  dmPrincipal: TdmPrincipal;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TdmPrincipal.DataModuleCreate(Sender: TObject);
var
  LMigrator: TC3Migrator;
  LSqlPath: string;
begin
  // Define o caminho da pasta com os scripts SQL
  LSqlPath := ExtractFilePath(ParamStr(0)) + 'sql';

  // Cria e executa as migrações
  LMigrator := TC3Migrator.Create(FDConnection1);
  try
    LMigrator.Execute(LSqlPath);
  finally
    LMigrator.Free;
  end;
end;

end.
```

## ❓ FAQ

**P: O que acontece se um script SQL falhar?**  
R: A execução é interrompida e um erro é levantado. Os scripts anteriores já executados não são revertidos (sem transação automática).

**P: Posso usar em várias projetos?**  
R: Sim! Esse é o objetivo. Instale em todos os projetos que precisam das mesmas migrações.

**P: Como atualizar a biblioteca?**  
R: Execute `boss update` no seu projeto principal.

**P: Posso manter migrações específicas por projeto?**  
R: Sim, você pode ter migrações globais nesta biblioteca e migrações específicas em cada projeto principal.

## 🤝 Contribuindo

Para fazer alterações na biblioteca:

1. Clone o repositório
2. Faça suas alterações
3. Teste no projeto principal
4. Commit e push: `git push`
5. Atualize outros projetos com `boss update`

## 📄 Licença

MIT

---

**Desenvolvido para C3Gestor ERP**
