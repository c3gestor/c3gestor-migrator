unit C3Gestor.Migrator;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, 
  FireDAC.Comp.Client, FireDAC.Comp.Script, System.IOUtils, Data.DB,
  Winapi.Windows;

type
  TC3Migrator = class
  private
    FConn: TFDConnection;
    FScript: TFDScript;
    procedure CreateMigrationTable;
    function AlreadyExecuted(const AScriptName: string): Boolean;
    procedure MarkAsExecuted(const AScriptName: string);
    procedure ExecuteScript(const AScriptName, AScriptSQL: string);
  public
    constructor Create(AConn: TFDConnection);
    destructor Destroy; override;
    procedure Execute(const AScriptsPath: string);
    procedure ExecuteFromResources(const AResourcePrefix: string = 'MIGRATION_');
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

procedure TC3Migrator.ExecuteScript(const AScriptName, AScriptSQL: string);
begin
  if not AlreadyExecuted(AScriptName) then
  begin
    FConn.StartTransaction;
    try
      FScript.SQLScripts.Clear;
      with FScript.SQLScripts.Add do
        SQL.Text := AScriptSQL;
      FScript.ExecuteAll;
      MarkAsExecuted(AScriptName);
      FConn.Commit;
    except
      FConn.Rollback;
      raise Exception.Create('Falha na migration: ' + AScriptName);
    end;
  end;
end;

procedure TC3Migrator.Execute(const AScriptsPath: string);
var
  LFile: string;
  LFiles: TArray<string>;
  LScriptSQL: TStringList;
begin
  CreateMigrationTable;
  LFiles := TDirectory.GetFiles(AScriptsPath, '*.sql');
  TArray.Sort<string>(LFiles); // Garante a ordem cronológica (V1, V2...)

  LScriptSQL := TStringList.Create;
  try
    for LFile in LFiles do
    begin
      LScriptSQL.LoadFromFile(LFile);
      ExecuteScript(ExtractFileName(LFile), LScriptSQL.Text);
    end;
  finally
    LScriptSQL.Free;
  end;
end;

procedure TC3Migrator.ExecuteFromResources(const AResourcePrefix: string);
var
  LResourceStream: TResourceStream;
  LScriptSQL: TStringList;
  LResourceName: string;
  I: Integer;
begin
  CreateMigrationTable;
  
  LScriptSQL := TStringList.Create;
  try
    I := 1;
    // Tenta carregar resources sequencialmente: MIGRATION_001, MIGRATION_002, etc.
    while True do
    begin
      LResourceName := Format('%s%s', [AResourcePrefix, FormatFloat('000', I)]);
      
      // Tenta encontrar o resource
      if FindResource(HInstance, PChar(LResourceName), RT_RCDATA) = 0 then
        Break; // Não encontrou mais resources
        
      LResourceStream := TResourceStream.Create(HInstance, LResourceName, RT_RCDATA);
      try
        LScriptSQL.LoadFromStream(LResourceStream);
        ExecuteScript(LResourceName + '.sql', LScriptSQL.Text);
      finally
        LResourceStream.Free;
      end;
      
      Inc(I);
    end;
  finally
    LScriptSQL.Free;
  end;
end;

destructor TC3Migrator.Destroy;
begin
  FScript.Free;
  inherited;
end;

end.