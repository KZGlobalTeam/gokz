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
		}
		case DatabaseType_MySQL:
		{
			txn.AddQuery(mysql_players_create);
			txn.AddQuery(mysql_maps_create);
			txn.AddQuery(mysql_mapcourses_create);
			txn.AddQuery(mysql_times_create);
		}
	}
	
	SQL_ExecuteTransaction(gH_DB, txn, _, DB_TxnFailure_Generic, _, DBPrio_High);
} 