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
