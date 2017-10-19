/*
	API
	
	GOKZ Local DB API.
*/



static Handle H_OnDatabaseConnect;
static Handle H_OnClientSetup;
static Handle H_OnMapSetup;
static Handle H_OnTimeInserted;



// =========================  FORWARDS  ========================= //

void CreateGlobalForwards()
{
	H_OnDatabaseConnect = CreateGlobalForward("GOKZ_DB_OnDatabaseConnect", ET_Ignore, Param_Cell);
	H_OnClientSetup = CreateGlobalForward("GOKZ_DB_OnClientSetup", ET_Ignore, Param_Cell, Param_Cell);
	H_OnMapSetup = CreateGlobalForward("GOKZ_DB_OnMapSetup", ET_Ignore, Param_Cell);
	H_OnTimeInserted = CreateGlobalForward("GOKZ_DB_OnTimeInserted", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
}

void Call_OnDatabaseConnect()
{
	Call_StartForward(H_OnDatabaseConnect);
	Call_PushCell(g_DBType);
	Call_Finish();
}

void Call_OnClientSetup(int client, int steamID)
{
	Call_StartForward(H_OnClientSetup);
	Call_PushCell(client);
	Call_PushCell(steamID);
	Call_Finish();
}

void Call_OnMapSetup()
{
	Call_StartForward(H_OnMapSetup);
	Call_PushCell(gI_DBCurrentMapID);
	Call_Finish();
}

void Call_OnTimeInserted(int client, int steamID, int mapID, int course, int mode, int style, int runTimeMS, int teleportsUsed)
{
	Call_StartForward(H_OnTimeInserted);
	Call_PushCell(client);
	Call_PushCell(steamID);
	Call_PushCell(mapID);
	Call_PushCell(course);
	Call_PushCell(mode);
	Call_PushCell(style);
	Call_PushCell(runTimeMS);
	Call_PushCell(teleportsUsed);
	Call_Finish();
}



// =========================  NATIVES  ========================= //

void CreateNatives()
{
	CreateNative("GOKZ_DB_GetDatabase", Native_GetDatabase);
	CreateNative("GOKZ_DB_GetDatabaseType", Native_GetDatabaseType);
	CreateNative("GOKZ_DB_IsClientSetUp", Native_IsClientSetUp);
	CreateNative("GOKZ_DB_IsMapSetUp", Native_IsMapSetUp);
	CreateNative("GOKZ_DB_GetCurrentMapID", Native_GetCurrentMapID);
}

public int Native_GetDatabase(Handle plugin, int numParams)
{
	if (gH_DB == null)
	{
		return view_as<int>(INVALID_HANDLE);
	}
	return view_as<int>(CloneHandle(gH_DB));
}

public int Native_GetDatabaseType(Handle plugin, int numParams)
{
	return view_as<int>(g_DBType);
}

public int Native_IsClientSetUp(Handle plugin, int numParams)
{
	return view_as<int>(gB_ClientSetUp[GetNativeCell(1)]);
}

public int Native_IsMapSetUp(Handle plugin, int numParams)
{
	return view_as<int>(gB_MapSetUp);
}

public int Native_GetCurrentMapID(Handle plugin, int numParams)
{
	return gI_DBCurrentMapID;
} 