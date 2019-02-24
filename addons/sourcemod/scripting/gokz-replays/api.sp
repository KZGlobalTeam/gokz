static Handle H_OnReplaySaved;
static Handle H_OnReplayDiscarded;
static Handle H_OnTimerEnd_Post;



// =====[ FORWARDS ]=====

void CreateGlobalForwards()
{
	H_OnReplaySaved = CreateGlobalForward("GOKZ_RP_OnReplaySaved", ET_Ignore, Param_Cell, Param_String);
	H_OnReplayDiscarded = CreateGlobalForward("GOKZ_RP_OnReplayDiscarded", ET_Ignore, Param_Cell);
	H_OnTimerEnd_Post = CreateGlobalForward("GOKZ_RP_OnTimerEnd_Post", ET_Ignore, Param_Cell, Param_String, Param_Cell, Param_Float, Param_Cell);
}

void Call_OnReplaySaved(int client, const char[] filePath)
{
	Call_StartForward(H_OnReplaySaved);
	Call_PushCell(client);
	Call_PushString(filePath);
	Call_Finish();
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