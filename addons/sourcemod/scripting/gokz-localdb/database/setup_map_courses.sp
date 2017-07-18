/*
	Database - Setup Map Courses
	
	Inserts the map's courses into the database.
*/



void DB_SetupMapCourses()
{
	int entity = -1;
	char tempString[32], query[512];
	
	Transaction txn = SQL_CreateTransaction();
	
	while ((entity = FindEntityByClassname(entity, "func_button")) != -1)
	{
		GetEntPropString(entity, Prop_Data, "m_iName", tempString, sizeof(tempString));
		if (StrEqual("climb_startbutton", tempString, false))
		{
			switch (g_DBType)
			{
				case DatabaseType_SQLite:FormatEx(query, sizeof(query), sqlite_mapcourses_insert, gI_DBCurrentMapID, 0);
				case DatabaseType_MySQL:FormatEx(query, sizeof(query), mysql_mapcourses_insert, gI_DBCurrentMapID, 0);
			}
			txn.AddQuery(query);
		}
		else if (MatchRegex(gRE_BonusStartButton, tempString) > 0)
		{
			GetRegexSubString(gRE_BonusStartButton, 1, tempString, sizeof(tempString));
			int bonus = StringToInt(tempString);
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