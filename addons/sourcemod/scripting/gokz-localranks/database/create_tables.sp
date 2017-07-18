/*
	Database - Create Tables
	
	Table creation and alteration.
*/



void DB_CreateTables()
{
	SQL_LockDatabase(gH_DB);
	
	// Create/alter database tables
	switch (g_DBType)
	{
		case DatabaseType_SQLite:
		{
			SQL_FastQuery(gH_DB, sqlite_maps_alter1);
		}
		case DatabaseType_MySQL:
		{
			SQL_FastQuery(gH_DB, mysql_maps_alter1);
		}
	}
	
	SQL_UnlockDatabase(gH_DB);
} 