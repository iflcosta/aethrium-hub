import os
import mysql.connector

# Caminho da pasta de migrações
migrations_path = r"c:\baiakthunder\data\migrations"

# Pega todos os arquivos .lua e extrai o número
versions = []
for fname in os.listdir(migrations_path):
    if fname.endswith(".lua"):
        try:
            num = int(fname.replace(".lua", ""))
            versions.append(num)
        except ValueError:
            pass

latest_version = max(versions) if versions else None

if latest_version:
    print(f"Última versão encontrada: {latest_version}")

    # Conexão MySQL (ajuste host, user, password e database)
    conn = mysql.connector.connect(
        host="localhost",
        user="root",
        password="6652827",
        database="forgotten"
    )
    cur = conn.cursor()

    # Atualiza o db_version
    cur.execute(
        "UPDATE server_config SET value = %s WHERE config = 'db_version'",
        (str(latest_version),)
    )
    conn.commit()
    conn.close()

    print(f"db_version atualizado para {latest_version}")
else:
    print("Nenhum arquivo de migração encontrado.")
