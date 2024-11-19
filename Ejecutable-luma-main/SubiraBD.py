from datetime import datetime
import pandas as pd
import os
from configparser import ConfigParser
import psycopg2
from psycopg2 import sql
from dotenv import load_dotenv

CONFIG = ".config"


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




class SubirDB:

    def __init__(self):
        self.config = set_up()
        try:
            self.connection = psycopg2.connect(
                user=self.config['user'],
                password=self.config['password'],
                host=self.config['host'],
                port=self.config['port'],
                database=self.config['database'],
                sslmode='require'
            )
        except Exception as e:
            print(f"Error al conectar a Postgresql: {e}")



    def max_date(self, table):
        query = f'SELECT MAX(date) AS max FROM {table};'
        with self.connection.cursor() as cursor:
            cursor.execute(query)
            max_date = cursor.fetchone()[0]
        return max_date

    def create_tables(self):
        year = str(datetime.now().year) 

        tables = [
            'eit171', 'eit195', 'eit284', 'eit304', 'hmiigr', 'hmimag'
        ]
        
        for table in tables:
            # Leer el DataFrame desde el archivo CSV
            df_csv = pd.read_csv(f'./DATA/output_{year}_{table}.csv')
            
            # Consultar la última fecha en la base de datos
            last_date = self.max_date(table)

            # Filtrar solo las filas con fechas mayores a la última fecha en la base de datos
            df_new_data = df_csv[df_csv['date'] > last_date]

            if not df_new_data.empty:
                # Obtener el último valor de la columna 'index'
                query = f'SELECT MAX(index) FROM {table};'
                with self.connection.cursor() as cursor:
                    cursor.execute(query)
                    last_index = cursor.fetchone()[0]  # Si no hay filas, empieza desde 0

                # Incrementar el valor de 'index' para cada nueva fila
                df_new_data['index'] = range(last_index + 1, last_index + 1 + len(df_new_data))

                # Si hay nuevas fechas, guardar en la base de datos
                with self.connection.cursor() as cursor:
                    for index, row in df_new_data.iterrows():
                        insert_query = f"INSERT INTO {table} ({', '.join(df_new_data.columns)}) VALUES ({', '.join(['%s'] * len(row))})"
                        cursor.execute(insert_query, tuple(row))
                    self.connection.commit()
                print(f'Se agregaron {len(df_new_data)} nuevas filas a la tabla {table}.')

    def close_connection(self):
        if self.connection:
            self.connection.close()

