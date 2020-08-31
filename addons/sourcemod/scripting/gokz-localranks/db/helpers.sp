/*
	Database helper functions and callbacks.
*/



/* Error report callback for failed transactions */
public void DB_TxnFailure_Generic(Handle db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	LogError("Database transaction error: %s", error);
}

/* Error report callback for failed transactions which deletes the DataPack */
public void DB_TxnFailure_Generic_DataPack(Handle db, DataPack data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	delete data;
	LogError("Database transaction error: %s", error);
}

/*	Used to search the database for a player name and return their PlayerID and alias

	For SQLTxnSuccess onSuccess:
	results[0] - 0:PlayerID, 1:Alias
*/
void DB_FindPlayer(const char[] playerSearch, SQLTxnSuccess onSuccess, any data = 0, DBPriority priority = DBPrio_Normal)
{
	char query[1024], playerEscaped[MAX_NAME_LENGTH * 2 + 1];
	SQL_EscapeString(gH_DB, playerSearch, playerEscaped, sizeof(playerEscaped));
	
	String_ToLower(playerEscaped, playerEscaped, sizeof(playerEscaped));
	
	Transaction txn = SQL_CreateTransaction();
	
	// Look for player name and retrieve their PlayerID
	FormatEx(query, sizeof(query), sql_players_searchbyalias, playerEscaped, playerEscaped);
	txn.AddQuery(query);
	
	SQL_ExecuteTransaction(gH_DB, txn, onSuccess, DB_TxnFailure_Generic, data, priority);
}

/*	Used to search the database for a map name and return its MapID and name

	For SQLTxnSuccess onSuccess:
	results[0] - 0:MapID, 1:Name
*/
void DB_FindMap(const char[] mapSearch, SQLTxnSuccess onSuccess, any data = 0, DBPriority priority = DBPrio_Normal)
{
	char query[1024], mapEscaped[129];
	SQL_EscapeString(gH_DB, mapSearch, mapEscaped, sizeof(mapEscaped));
	
	Transaction txn = SQL_CreateTransaction();
	
	// Look for map name and retrieve it's MapID
	FormatEx(query, sizeof(query), sql_maps_searchbyname, mapEscaped, mapEscaped);
	txn.AddQuery(query);
	
	SQL_ExecuteTransaction(gH_DB, txn, onSuccess, DB_TxnFailure_Generic, data, priority);
}

/*	Used to search the database for a player name and return their PlayerID and alias,
	and search the database for a map name and return its MapID and name
	
	For SQLTxnSuccess onSuccess:
	results[0] - 0:PlayerID, 1:Alias
	results[1] - 0:MapID, 1:Name
*/
void DB_FindPlayerAndMap(const char[] playerSearch, const char[] mapSearch, SQLTxnSuccess onSuccess, any data = 0, DBPriority priority = DBPrio_Normal)
{
	char query[1024], mapEscaped[129], playerEscaped[MAX_NAME_LENGTH * 2 + 1];
	SQL_EscapeString(gH_DB, playerSearch, playerEscaped, sizeof(playerEscaped));
	SQL_EscapeString(gH_DB, mapSearch, mapEscaped, sizeof(mapEscaped));
	
	String_ToLower(playerEscaped, playerEscaped, sizeof(playerEscaped));
	
	Transaction txn = SQL_CreateTransaction();
	
	// Look for player name and retrieve their PlayerID
	FormatEx(query, sizeof(query), sql_players_searchbyalias, playerEscaped, playerEscaped);
	txn.AddQuery(query);
	// Look for map name and retrieve it's MapID
	FormatEx(query, sizeof(query), sql_maps_searchbyname, mapEscaped, mapEscaped);
	txn.AddQuery(query);
	
	SQL_ExecuteTransaction(gH_DB, txn, onSuccess, DB_TxnFailure_Generic, data, priority);
} 