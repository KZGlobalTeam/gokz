/*
	Table creation.
*/



void DB_CreateTables()
{
	Transaction txn = SQL_CreateTransaction();
	
	// Create database tables
	switch (g_DBType)
	{
		case DatabaseType_SQLite:
		{
			txn.AddQuery(sqlite_jumpstats_create);
		}
		case DatabaseType_MySQL:
		{
			txn.AddQuery(mysql_jumpstats_create);
		}
	}
	
	SQL_ExecuteTransaction(gH_DB, txn, _, DB_TxnFailure_Generic, _, DBPrio_High);
} 

/* Error report callback for failed transactions */
public void DB_TxnFailure_Generic(Handle db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	LogError("Database transaction error: %s", error);
}
