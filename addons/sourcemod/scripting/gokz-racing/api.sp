static Handle H_OnFinish;
static Handle H_OnSurrender;
static Handle H_OnRequestReceived;
static Handle H_OnRequestAccepted;
static Handle H_OnRequestDeclined;
static Handle H_OnRaceRegistered;
static Handle H_OnRaceInfoChanged;



// =====[ FORWARDS ]=====

void CreateGlobalForwards()
{
	H_OnFinish = CreateGlobalForward("GOKZ_RC_OnFinish", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	H_OnSurrender = CreateGlobalForward("GOKZ_RC_OnSurrender", ET_Ignore, Param_Cell, Param_Cell);
	H_OnRequestReceived = CreateGlobalForward("GOKZ_RC_OnRequestReceived", ET_Ignore, Param_Cell, Param_Cell);
	H_OnRequestAccepted = CreateGlobalForward("GOKZ_RC_OnRequestAccepted", ET_Ignore, Param_Cell, Param_Cell);
	H_OnRequestDeclined = CreateGlobalForward("GOKZ_RC_OnRequestDeclined", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	H_OnRaceRegistered = CreateGlobalForward("GOKZ_RC_OnRaceRegistered", ET_Ignore, Param_Cell);
	H_OnRaceInfoChanged = CreateGlobalForward("GOKZ_RC_OnRaceInfoChanged", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
}

void Call_OnFinish(int client, int raceID, int place)
{
	Call_StartForward(H_OnFinish);
	Call_PushCell(client);
	Call_PushCell(raceID);
	Call_PushCell(place);
	Call_Finish();
}

void Call_OnSurrender(int client, int raceID)
{
	Call_StartForward(H_OnSurrender);
	Call_PushCell(client);
	Call_PushCell(raceID);
	Call_Finish();
}

void Call_OnRequestReceived(int client, int raceID)
{
	Call_StartForward(H_OnRequestReceived);
	Call_PushCell(client);
	Call_PushCell(raceID);
	Call_Finish();
}

void Call_OnRequestAccepted(int client, int raceID)
{
	Call_StartForward(H_OnRequestAccepted);
	Call_PushCell(client);
	Call_PushCell(raceID);
	Call_Finish();
}

void Call_OnRequestDeclined(int client, int raceID, bool timeout)
{
	Call_StartForward(H_OnRequestDeclined);
	Call_PushCell(client);
	Call_PushCell(raceID);
	Call_PushCell(timeout);
	Call_Finish();
}

void Call_OnRaceRegistered(int raceID)
{
	Call_StartForward(H_OnRaceRegistered);
	Call_PushCell(raceID);
	Call_Finish();
}

void Call_OnRaceInfoChanged(int raceID, RaceInfo infoIndex, int oldValue, int newValue)
{
	Call_StartForward(H_OnRaceInfoChanged);
	Call_PushCell(raceID);
	Call_PushCell(infoIndex);
	Call_PushCell(oldValue);
	Call_PushCell(newValue);
	Call_Finish();
}



// =====[ NATIVES ]=====

void CreateNatives()
{
	CreateNative("GOKZ_RC_GetRaceInfo", Native_GetRaceInfo);
	CreateNative("GOKZ_RC_GetStatus", Native_GetStatus);
	CreateNative("GOKZ_RC_GetRaceID", Native_GetRaceID);
}

public int Native_GetRaceInfo(Handle plugin, int numParams)
{
	return GetRaceInfo(GetNativeCell(1), GetNativeCell(2));
}

public int Native_GetStatus(Handle plugin, int numParams)
{
	return GetStatus(GetNativeCell(1));
}

public int Native_GetRaceID(Handle plugin, int numParams)
{
	return GetRaceID(GetNativeCell(1));
} 