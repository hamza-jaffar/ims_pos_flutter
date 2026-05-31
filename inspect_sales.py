import sqlite3, os
path=os.path.join(os.getcwd(), ".dart_tool","sqflite_common_ffi","databases","ims_pos_system.db")
print(path)
print(os.path.exists(path))
con=sqlite3.connect(path)
rows=con.execute("PRAGMA table_info('sales')").fetchall()
print(rows)
con.close()
