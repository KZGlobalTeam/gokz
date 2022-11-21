static GlobalForward H_OnDatabaseConnect;
static GlobalForward H_OnClientSetup;
static GlobalForward H_OnMapSetup;
static GlobalForward H_OnTimeInserted;
static GlobalForward H_OnJumpstatPB;



// =====[ FORWARDS ]=====

void CreateGlobalForwards()
{
	H_OnDatabaseConnect = new GlobalForward("GOKZ_DB_OnDatabaseConnect", ET_Ignore, Param_Cell);
	H_OnClientSetup = new GlobalForward("GOKZ_DB_OnClientSetup", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	H_OnMapSetup = new GlobalForward("GOKZ_DB_OnMapSetup", ET_Ignore, Param_Cell);
	H_OnTimeInserted = new GlobalForward("GOKZ_DB_OnTimeInserted", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	H_OnJumpstatPB = new GlobalForward("GOKZ_DB_OnJumpstatPB", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
}

void Call_OnDatabaseConnect()
{
	Call_StartForward(H_OnDatabaseConnect);
	Call_PushCell(g_DBType);
	Call_Finish();
}

void Call_OnClientSetup(int client, int steamID, bool cheater)
{
	Call_StartForward(H_OnClientSetup);
	Call_PushCell(client);
	Call_PushCell(steamID);
	Call_PushCell(cheater);
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

void Call_OnJumpstatPB(int client, int jumptype, int mode, float distance, int block, int strafes, float sync, float pre, float max, int airtime)
{
	Call_StartForward(H_OnJumpstatPB);
	Call_PushCell(client);
	Call_PushCell(jumptype);
	Call_PushCell(mode);
	Call_PushCell(distance);
	Call_PushCell(block);
	Call_PushCell(strafes);
	Call_PushCell(sync);
	Call_PushCell(pre);
	Call_PushCell(max);
	Call_PushCell(airtime);
	Call_Finish();
}



// =====[ NATIVES ]=====

void CreateNatives()
{
	CreateNative("GOKZ_DB_GetDatabase", Native_GetDatabase);
	CreateNative("GOKZ_DB_GetDatabaseType", Native_GetDatabaseType);
	CreateNative("GOKZ_DB_IsClientSetUp", Native_IsClientSetUp);
	CreateNative("GOKZ_DB_IsMapSetUp", Native_IsMapSetUp);
	CreateNative("GOKZ_DB_GetCurrentMapID", Native_GetCurrentMapID);
	CreateNative("GOKZ_DB_IsCheater", Native_IsCheater);
	CreateNative("GOKZ_DB_SetCheater", Native_SetCheater);
}

public int Native_GetDatabase(Handle plugin, int numParams)
{
	if (gH_DB == null)
	{
		return view_as<int>(gH_DB);
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

public int Native_IsCheater(Handle plugin, int numParams)
{
	return view_as<int>(gB_Cheater[GetNativeCell(1)]);
}

public int Native_SetCheater(Handle plugin, int numParams)
{
	DB_SetCheater(GetNativeCell(1), GetNativeCell(2));
	return 0;
} 
