/*
	Set up the connection to the local database.
*/



void DB_SetupDatabase()
{
	char error[255];
	gH_DB = SQL_Connect("gokz", true, error, sizeof(error));
	if (gH_DB == null)
	{
		SetFailState("Database connection failed. Error: \"%s\".", error);
	}
	
	char databaseType[8];
	SQL_ReadDriver(gH_DB, databaseType, sizeof(databaseType));
	if (strcmp(databaseType, "sqlite", false) == 0)
	{
		g_DBType = DatabaseType_SQLite;
	}
	else if (strcmp(databaseType, "mysql", false) == 0)
	{
		g_DBType = DatabaseType_MySQL;
	}
	else
	{
		SetFailState("Incompatible database driver. Use SQLite or MySQL.");
	}
	
	DB_CreateTables();
	
	Call_OnDatabaseConnect();
} 