/*
	Inserts the map's courses into the database.
*/



void DB_SetupMapCourses()
{
	int entity = -1;
	char buffer[32], query[512];
	
	Transaction txn = SQL_CreateTransaction();
	
	while ((entity = FindEntityByClassname(entity, "func_button")) != -1)
	{
		if (GetEntityName(entity, buffer, sizeof(buffer)) == 0)
		{
			continue;
		}
		
		if (StrEqual(GOKZ_START_BUTTON_NAME, buffer, false))
		{
			switch (g_DBType)
			{
				case DatabaseType_SQLite:FormatEx(query, sizeof(query), sqlite_mapcourses_insert, gI_DBCurrentMapID, 0);
				case DatabaseType_MySQL:FormatEx(query, sizeof(query), mysql_mapcourses_insert, gI_DBCurrentMapID, 0);
			}
			txn.AddQuery(query);
		}
		else if (MatchRegex(gRE_BonusStartButton, buffer) > 0)
		{
			GetRegexSubString(gRE_BonusStartButton, 1, buffer, sizeof(buffer));
			int bonus = StringToInt(buffer);
			switch (g_DBType)
			{
				case DatabaseType_SQLite:FormatEx(query, sizeof(query), sqlite_mapcourses_insert, gI_DBCurrentMapID, bonus);
				case DatabaseType_MySQL:FormatEx(query, sizeof(query), mysql_mapcourses_insert, gI_DBCurrentMapID, bonus);
			}
			txn.AddQuery(query);
		}
	}
	
	SQL_ExecuteTransaction(gH_DB, txn, INVALID_FUNCTION, DB_TxnFailure_Generic, 0, DBPrio_High);
} 