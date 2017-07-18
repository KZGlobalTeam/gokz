/*
	Database - Create Tables
	
	Table creation and alteration.
*/



void DB_CreateTables()
{
	SQL_LockDatabase(gH_DB);
	
	switch (g_DBType)
	{
		case DatabaseType_SQLite:
		{
			SQL_FastQuery(gH_DB, sqlite_players_create);
			SQL_FastQuery(gH_DB, sqlite_options_create);
			SQL_FastQuery(gH_DB, sqlite_maps_create);
			SQL_FastQuery(gH_DB, sqlite_mapcourses_create);
			SQL_FastQuery(gH_DB, sqlite_times_create);
		}
		case DatabaseType_MySQL:
		{
			SQL_FastQuery(gH_DB, mysql_players_create);
			SQL_FastQuery(gH_DB, mysql_options_create);
			SQL_FastQuery(gH_DB, mysql_maps_create);
			SQL_FastQuery(gH_DB, mysql_mapcourses_create);
			SQL_FastQuery(gH_DB, mysql_times_create);
		}
	}
	
	SQL_UnlockDatabase(gH_DB);
} 