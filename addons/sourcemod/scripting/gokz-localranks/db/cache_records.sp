/*
	Caches the record times on the map.
*/



void DB_CacheRecords(int mapID)
{
	char query[1024];
	
	Transaction txn = SQL_CreateTransaction();
	
	// Reset record exists array
	for (int course = 0; course < GOKZ_MAX_COURSES; course++)
	{
		for (int mode = 0; mode < MODE_COUNT; mode++)
		{
			for (int timeType = 0; timeType < TIMETYPE_COUNT; timeType++)
			{
				gB_RecordExistsCache[course][mode][timeType] = false;
			}
		}
	}
	
	// Get Map WRs
	FormatEx(query, sizeof(query), sql_getwrs, mapID);
	txn.AddQuery(query);
	// Get PRO WRs
	FormatEx(query, sizeof(query), sql_getwrspro, mapID);
	txn.AddQuery(query);
	
	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_CacheRecords, DB_TxnFailure_Generic, _, DBPrio_High);
}

public void DB_TxnSuccess_CacheRecords(Handle db, any data, int numQueries, Handle[] results, any[] queryData)
{
	int course, mode;
	
	while (SQL_FetchRow(results[0]))
	{
		course = SQL_FetchInt(results[0], 1);
		mode = SQL_FetchInt(results[0], 2);
		gB_RecordExistsCache[course][mode][TimeType_Nub] = true;
		gF_RecordTimesCache[course][mode][TimeType_Nub] = GOKZ_DB_TimeIntToFloat(SQL_FetchInt(results[0], 0));
	}
	
	while (SQL_FetchRow(results[1]))
	{
		course = SQL_FetchInt(results[1], 1);
		mode = SQL_FetchInt(results[1], 2);
		gB_RecordExistsCache[course][mode][TimeType_Pro] = true;
		gF_RecordTimesCache[course][mode][TimeType_Pro] = GOKZ_DB_TimeIntToFloat(SQL_FetchInt(results[1], 0));
	}
} 