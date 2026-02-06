unit C3Gestor.Migrator;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Comp.Client, FireDAC.Comp.Script, 
  System.IOUtils, Data.DB;

type
  TC3Migrator = class
  private
    FConn: TFDConnection;
    FScript: TFDScript;
    procedure CreateMigrationTable;
    function AlreadyExecuted(const AScriptName: string): Boolean;
    procedure MarkAsExecuted(const AScriptName: string);
  public
    constructor Create(AConn: TFDConnection);
    destructor Destroy; override;
    procedure Execute(const AScriptsPath: string);
  end;

implementation

constructor TC3Migrator.Create(AConn: TFDConnection);
begin
  FConn := AConn;
  FScript := TFDScript.Create(nil);
  FScript.Connection := FConn;
end;

procedure TC3Migrator.CreateMigrationTable;
begin
  // Script para criar a tabela caso não exista (Padrão para SQL ANSI/Postgres)
  FConn.ExecSQL('CREATE TABLE IF NOT EXISTS migrations (' +
                'id SERIAL PRIMARY KEY, ' +
                'migration_name VARCHAR(255) NOT NULL, ' +
                'executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
end;

function TC3Migrator.AlreadyExecuted(const AScriptName: string): Boolean;
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FConn;
    LQuery.SQL.Text := 'SELECT COUNT(*) FROM migrations WHERE migration_name = :name';
    LQuery.ParamByName('name').AsString := AScriptName;
    LQuery.Open;
    Result := LQuery.Fields[0].AsInteger > 0;
  finally
    LQuery.Free;
  end;
end;

procedure TC3Migrator.MarkAsExecuted(const AScriptName: string);
begin
  FConn.ExecSQL('INSERT INTO migrations (migration_name) VALUES (:name)', [AScriptName]);
end;

procedure TC3Migrator.Execute(const AScriptsPath: string);
var
  LFile: string;
  LFiles: TArray<string>;
begin
  CreateMigrationTable;
  LFiles := TDirectory.GetFiles(AScriptsPath, '*.sql');
  TArray.Sort<string>(LFiles); // Garante a ordem cronológica (V1, V2...)

  for LFile in LFiles do
  begin
    if not AlreadyExecuted(ExtractFileName(LFile)) then
    begin
      FConn.StartTransaction;
      try
        FScript.SQL.LoadFromFile(LFile);
        FScript.ExecuteAll;
        MarkAsExecuted(ExtractFileName(LFile));
        FConn.Commit;
      except
        FConn.Rollback;
        raise Exception.Create('Falha na migration: ' + LFile);
      end;
    end;
  end;
end;

destructor TC3Migrator.Destroy;
begin
  FScript.Free;
  inherited;
end;

end.