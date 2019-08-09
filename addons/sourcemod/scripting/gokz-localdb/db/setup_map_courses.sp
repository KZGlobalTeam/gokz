/*
	Inserts the map's courses into the database.
*/



void DB_SetupMapCourses()
{
	char query[512];
	
	Transaction txn = SQL_CreateTransaction();
	
	for (int course = 0; course < GOKZ_MAX_COURSES; course++)
	{
		if (!GOKZ_GetCourseRegistered(course))
		{
			continue;
		}
		
		switch (g_DBType)
		{
			case DatabaseType_SQLite:FormatEx(query, sizeof(query), sqlite_mapcourses_insert, gI_DBCurrentMapID, course);
			case DatabaseType_MySQL:FormatEx(query, sizeof(query), mysql_mapcourses_insert, gI_DBCurrentMapID, course);
		}
		txn.AddQuery(query);
	}
	
	SQL_ExecuteTransaction(gH_DB, txn, INVALID_FUNCTION, DB_TxnFailure_Generic, _, DBPrio_High);
}

void DB_SetupMapCourse(int course)
{
	char query[512];
	
	Transaction txn = SQL_CreateTransaction();
	
	switch (g_DBType)
	{
		case DatabaseType_SQLite:FormatEx(query, sizeof(query), sqlite_mapcourses_insert, gI_DBCurrentMapID, course);
		case DatabaseType_MySQL:FormatEx(query, sizeof(query), mysql_mapcourses_insert, gI_DBCurrentMapID, course);
	}
	txn.AddQuery(query);
	
	SQL_ExecuteTransaction(gH_DB, txn, INVALID_FUNCTION, DB_TxnFailure_Generic, _, DBPrio_High);
} 