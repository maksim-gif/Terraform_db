#!/usr/bin/env python3
import mysql.connector
import random
import string
import sys
from datetime import datetime

def generate_random_string(length):
    """Генерация случайной строки заданной длины"""
    return ''.join(random.choices(string.ascii_letters + string.digits, k=length))

def generate_random_data():
    """Генерация случайных данных длиной от 4 до 8 символов"""
    length = random.randint(4, 8)
    return generate_random_string(length)

def create_tables_and_populate(host, user, password, database):
    """Создание 200 таблиц и заполнение их данными"""
    
    try:
        # Подключение к БД
        conn = mysql.connector.connect(
            host=host,
            user=user,
            password=password,
            database=database
        )
        cursor = conn.cursor()
        
        print(f"✅ Подключение к базе данных {database} установлено")
        
        # Создание 200 таблиц
        for i in range(1, 201):
            table_name = f"test_table_{i:03d}"
            
            # Создание SQL для таблицы с 50 столбцами
            columns = []
            for j in range(1, 51):
                columns.append(f"column_{j:02d} VARCHAR(10)")
            
            create_table_sql = f"""
            CREATE TABLE IF NOT EXISTS {table_name} (
                id INT AUTO_INCREMENT PRIMARY KEY,
                {', '.join(columns)},
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
            """
            
            cursor.execute(create_table_sql)
            
            # Заполнение таблицы случайными данными (10 записей в каждой таблице)
            for record_num in range(1, 11):
                values = []
                for col_num in range(1, 51):
                    values.append(f"'{generate_random_data()}'")
                
                insert_sql = f"""
                INSERT INTO {table_name} ({', '.join([f'column_{j:02d}' for j in range(1, 51)])})
                VALUES ({', '.join(values)})
                """
                
                cursor.execute(insert_sql)
            
            if i % 10 == 0:
                print(f"📊 Создано таблиц: {i}/200")
        
        # Фиксация изменений
        conn.commit()
        print("✅ Все таблицы успешно созданы и заполнены!")
        
        # Статистика
        cursor.execute("SELECT COUNT(*) as table_count FROM information_schema.tables WHERE table_schema = %s", (database,))
        table_count = cursor.fetchone()[0]
        
        cursor.execute("""
            SELECT table_name, table_rows 
            FROM information_schema.tables 
            WHERE table_schema = %s AND table_name LIKE 'test_table_%'
        """, (database,))
        
        total_rows = 0
        for table_name, rows in cursor:
            total_rows += rows
        
        print(f"📈 Статистика:")
        print(f"   • Таблиц создано: {table_count}")
        print(f"   • Всего записей: {total_rows}")
        print(f"   • Записей в каждой таблице: 10")
        print(f"   • Столбцов в каждой таблице: 50")
        
    except mysql.connector.Error as e:
        print(f"❌ Ошибка MySQL: {e}")
        sys.exit(1)
    finally:
        if 'conn' in locals() and conn.is_connected():
            cursor.close()
            conn.close()

def main():
    if len(sys.argv) != 5:
        print("❌ Использование: python3 populate_database.py <host> <user> <password> <database>")
        print("   Пример: python3 populate_database.py 89.208.208.28 app_user '7h78gs.p70aG85wU0' app_database")
        sys.exit(1)
    
    host = sys.argv[1]
    user = sys.argv[2]
    password = sys.argv[3]
    database = sys.argv[4]
    
    print("🚀 Начало заполнения базы данных тестовыми данными...")
    print(f"📍 Хост: {host}")
    print(f"🗃️  База данных: {database}")
    print(f"👤 Пользователь: {user}")
    print("=" * 60)
    
    start_time = datetime.now()
    create_tables_and_populate(host, user, password, database)
    end_time = datetime.now()
    
    print("=" * 60)
    print(f"⏱️  Заполнение завершено за: {end_time - start_time}")

if __name__ == "__main__":
    main()
