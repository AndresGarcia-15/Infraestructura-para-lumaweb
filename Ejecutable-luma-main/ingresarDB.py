import os
import sqlite3
import pandas as pd
import psycopg2
from psycopg2 import sql
from dotenv import load_dotenv


def set_up():
    load_dotenv()
    config = {
        "host": os.getenv("DB_HOST"),
        "database": os.getenv("DB_NAME"),
        "user": os.getenv("DB_USER"),
        "password": os.getenv("DB_PASSWORD"),
        "port": os.getenv("DB_PORT"),
    }
    return config



class ingresarDB:

    def __init__(self):
        self.config = set_up()
        try:
            self.sqlite = sqlite3.connect('DATA.db')
            print("Conexión a SQLite establecida.")

            self.pg = psycopg2.connect(
                user=self.config['user'],
                password=self.config['password'],
                host=self.config['host'],
                port=self.config['port'],
                database=self.config['database'],
                sslmode='require'
            )
        except Exception as e:
            print(f"Error al conectar a SQLite: {e}")



    def create_tables(self):

        cursor = self.pg.cursor()

        tables = [
            'eit171', 'eit195', 'eit284', 'eit304', 'hmiigr', 'hmimag'
        ]
        for table in tables:
            try:
                
                df_sqlite = pd.read_sql_query(f'SELECT * FROM {table} WHERE rowid IN (SELECT rowid FROM {table} ORDER BY rowid DESC LIMIT 10) ORDER BY rowid ASC', self.sqlite)
                print(f"Procesando tabla: {table}")

                
                sqlite_cursor = self.sqlite.cursor()
                sqlite_cursor.execute(f'PRAGMA table_info({table})')
                columns_info = sqlite_cursor.fetchall()
                columns = [col[1] for col in columns_info]
                types = [col[2] for col in columns_info]

                # Crear la tabla en la base de datos PostgreSQL
                create_table_query = sql.SQL(
                    "CREATE TABLE IF NOT EXISTS {} ({})"
                ).format(
                    sql.Identifier(table),
                    sql.SQL(', ').join(
                        sql.SQL("{} {}").format(
                            sql.Identifier(col),
                            sql.SQL(type_)
                        ) for col, type_ in zip(columns, types)
                    )
                )
                cursor.execute(create_table_query)
                print(f"Tabla {table} creada o ya existe en PostgreSQL.")

                
                insert_query = sql.SQL(
                    "INSERT INTO {} ({}) VALUES ({})"
                ).format(
                    sql.Identifier(table),
                    sql.SQL(', ').join(map(sql.Identifier, columns)),
                    sql.SQL(', ').join(sql.Placeholder() * len(columns))
                )

                
                data = [tuple(row) for row in df_sqlite.itertuples(index=False, name=None)]
                cursor.executemany(insert_query, data)
                print(f"Datos insertados en la tabla {table}.")

            except Exception as e:
                print(f"Error procesando la tabla {table}: {e}")

    
            try:
                self.pg.commit()
                print("Cambios confirmados en PostgreSQL.")
            except Exception as e:
                print(f"Error al confirmar los cambios en PostgreSQL: {e}")

            
        try:
            cursor.close()
            self.pg.close()
            self.sqlite.close()
            print("Conexiones cerradas.")
        except Exception as e:
            print(f"Error al cerrar las conexiones: {e}")



if __name__ == '__main__':
    h = ingresarDB()
    h.create_tables()

    print("Todas las tablas se han creado.")