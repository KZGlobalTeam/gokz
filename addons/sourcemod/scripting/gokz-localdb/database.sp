/*
	Database
	
	Database helper callbacks.
*/



/* Error report callback for failed transactions */
public void DB_TxnFailure_Generic(Handle db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	SetFailState("Database transaction error: %s", error);
} 