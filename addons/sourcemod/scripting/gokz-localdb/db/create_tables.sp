/*
	Table creation and alteration.
*/



void DB_CreateTables()
{
	Transaction txn = SQL_CreateTransaction();
	
	switch (g_DBType)
	{
		case DatabaseType_SQLite:
		{
			txn.AddQuery(sqlite_players_create);
			txn.AddQuery(sqlite_maps_create);
			txn.AddQuery(sqlite_mapcourses_create);
			txn.AddQuery(sqlite_times_create);
			txn.AddQuery(sqlite_jumpstats_create);
			txn.AddQuery(sqlite_vbpos_create);
			txn.AddQuery(sqlite_startpos_create);
		}
		case DatabaseType_MySQL:
		{
			txn.AddQuery(mysql_players_create);
			txn.AddQuery(mysql_maps_create);
			txn.AddQuery(mysql_mapcourses_create);
			txn.AddQuery(mysql_times_create);
			txn.AddQuery(mysql_jumpstats_create);
			txn.AddQuery(mysql_vbpos_create);
			txn.AddQuery(mysql_startpos_create);
		}
	}

	txn.AddQuery(sql_times_alter_add_guid);
	
	// No error logs for this transaction as it will always throw an error
	// if the column already exists, which is more annoying than helpful.
	SQL_ExecuteTransaction(gH_DB, txn, _, _, _, DBPrio_High);
} 