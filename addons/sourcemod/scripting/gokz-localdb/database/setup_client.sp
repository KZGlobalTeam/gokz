/*
	Database - Setup Client
	
	Inserts the player into the database, or else updates their information.
*/



void DB_SetupClient(int client)
{
	if (IsFakeClient(client))
	{
		return;
	}
	
	// Setup Client Step 1 - Upsert them into Players Table
	char query[1024], name[MAX_NAME_LENGTH], nameEscaped[MAX_NAME_LENGTH * 2 + 1], clientIP[16], country[45];
	
	int steamID = GetSteamAccountID(client);
	if (!GetClientName(client, name, MAX_NAME_LENGTH))
	{
		LogMessage("Couldn't get name of %L.", client);
		name = "Unknown";
	}
	SQL_EscapeString(gH_DB, name, nameEscaped, MAX_NAME_LENGTH * 2 + 1);
	if (!GetClientIP(client, clientIP, sizeof(clientIP)))
	{
		LogMessage("Couldn't get IP of %L.", client);
		clientIP = "Unknown";
	}
	if (!GeoipCountry(clientIP, country, sizeof(country)))
	{
		LogMessage("Couldn't get country of %L (%s).", client, clientIP);
		country = "Unknown";
	}
	
	DataPack data = new DataPack();
	data.WriteCell(GetClientUserId(client));
	data.WriteCell(steamID);
	
	Transaction txn = SQL_CreateTransaction();
	
	// Insert/Update player into Players table
	switch (g_DBType)
	{
		case DatabaseType_SQLite:
		{
			// UPDATE OR IGNORE
			FormatEx(query, sizeof(query), sqlite_players_update, nameEscaped, country, clientIP, steamID);
			txn.AddQuery(query);
			// INSERT OR IGNORE
			FormatEx(query, sizeof(query), sqlite_players_insert, nameEscaped, country, clientIP, steamID);
			txn.AddQuery(query);
		}
		case DatabaseType_MySQL:
		{
			// INSERT ... ON DUPLICATE KEY ...
			FormatEx(query, sizeof(query), mysql_players_upsert, nameEscaped, country, clientIP, steamID);
			txn.AddQuery(query);
		}
	}
	
	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_SetupClient, DB_TxnFailure_Generic, data, DBPrio_High);
}

public void DB_TxnSuccess_SetupClient(Handle db, DataPack data, int numQueries, Handle[] results, any[] queryData)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	int steamID = data.ReadCell();
	data.Close();
	
	if (!IsValidClient(client))
	{
		return;
	}
	
	Call_OnClientSetup(client, steamID);
} 