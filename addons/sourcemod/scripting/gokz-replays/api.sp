static GlobalForward H_OnReplaySaved;
static GlobalForward H_OnReplayDiscarded;
static GlobalForward H_OnTimerEnd_Post;

// =====[ NATIVES ]=====

void CreateNatives()
{
	CreateNative("GOKZ_RP_GetPlaybackInfo", Native_RP_GetPlaybackInfo);
	CreateNative("GOKZ_RP_LoadJumpReplay", Native_RP_LoadJumpReplay);
}

public int Native_RP_GetPlaybackInfo(Handle plugin, int numParams)
{
	HUDInfo info;
	GetPlaybackState(GetNativeCell(1), info);
	SetNativeArray(2, info, sizeof(HUDInfo));
	return 1;
}

public int Native_RP_LoadJumpReplay(Handle plugin, int numParams)
{
	int len;
	GetNativeStringLength(2, len);
	char[] path = new char[len + 1];
	GetNativeString(2, path, len + 1);
	int botClient = LoadReplayBot(GetNativeCell(1), path);
	return botClient;
}

// =====[ FORWARDS ]=====

void CreateGlobalForwards()
{
	H_OnReplaySaved = new GlobalForward("GOKZ_RP_OnReplaySaved", ET_Event, Param_Cell, Param_Cell, Param_String, Param_Cell, Param_Cell, Param_Float, Param_String, Param_Cell);
	H_OnReplayDiscarded = new GlobalForward("GOKZ_RP_OnReplayDiscarded", ET_Ignore, Param_Cell);
	H_OnTimerEnd_Post = new GlobalForward("GOKZ_RP_OnTimerEnd_Post", ET_Ignore, Param_Cell, Param_String, Param_Cell, Param_Float, Param_Cell);
}

Action Call_OnReplaySaved(int client, int replayType, const char[] map, int course, int timeType, float time, const char[] filePath, bool tempReplay)
{
	Action result;
	Call_StartForward(H_OnReplaySaved);
	Call_PushCell(client);
	Call_PushCell(replayType);
	Call_PushString(map);
	Call_PushCell(course);
	Call_PushCell(timeType);
	Call_PushFloat(time);
	Call_PushString(filePath);
	Call_PushCell(tempReplay);
	Call_Finish(result);
	return result;
}

void Call_OnReplayDiscarded(int client)
{
	Call_StartForward(H_OnReplayDiscarded);
	Call_PushCell(client);
	Call_Finish();
}

void Call_OnTimerEnd_Post(int client, const char[] filePath, int course, float time, int teleportsUsed)
{
	Call_StartForward(H_OnTimerEnd_Post);
	Call_PushCell(client);
	Call_PushString(filePath);
	Call_PushCell(course);
	Call_PushFloat(time);
	Call_PushCell(teleportsUsed);
	Call_Finish();
} 
