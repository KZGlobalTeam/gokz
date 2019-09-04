static Handle H_OnOptionChanged;
static Handle H_OnTimerStart;
static Handle H_OnTimerStart_Post;
static Handle H_OnTimerEnd;
static Handle H_OnTimerEnd_Post;
static Handle H_OnTimerEndMessage;
static Handle H_OnTimerStopped;
static Handle H_OnPause;
static Handle H_OnPause_Post;
static Handle H_OnResume;
static Handle H_OnResume_Post;
static Handle H_OnMakeCheckpoint;
static Handle H_OnMakeCheckpoint_Post;
static Handle H_OnTeleportToCheckpoint;
static Handle H_OnTeleportToCheckpoint_Post;
static Handle H_OnPrevCheckpoint;
static Handle H_OnPrevCheckpoint_Post;
static Handle H_OnNextCheckpoint;
static Handle H_OnNextCheckpoint_Post;
static Handle H_OnTeleportToStart;
static Handle H_OnTeleportToStart_Post;
static Handle H_OnUndoTeleport;
static Handle H_OnUndoTeleport_Post;
static Handle H_OnCountedTeleport_Post;
static Handle H_OnStartPositionSet_Post;
static Handle H_OnJumpValidated;
static Handle H_OnJumpInvalidated;
static Handle H_OnJoinTeam;
static Handle H_OnFirstSpawn;
static Handle H_OnModeLoaded;
static Handle H_OnModeUnloaded;
static Handle H_OnTimerNativeCalledExternally;
static Handle H_OnOptionsMenuCreated;
static Handle H_OnOptionsMenuReady;
static Handle H_OnCourseRegistered;



void CreateGlobalForwards()
{
	H_OnOptionChanged = CreateGlobalForward("GOKZ_OnOptionChanged", ET_Ignore, Param_Cell, Param_String, Param_Cell);
	H_OnTimerStart = CreateGlobalForward("GOKZ_OnTimerStart", ET_Hook, Param_Cell, Param_Cell);
	H_OnTimerStart_Post = CreateGlobalForward("GOKZ_OnTimerStart_Post", ET_Ignore, Param_Cell, Param_Cell);
	H_OnTimerEnd = CreateGlobalForward("GOKZ_OnTimerEnd", ET_Hook, Param_Cell, Param_Cell, Param_Float, Param_Cell);
	H_OnTimerEnd_Post = CreateGlobalForward("GOKZ_OnTimerEnd_Post", ET_Ignore, Param_Cell, Param_Cell, Param_Float, Param_Cell);
	H_OnTimerEndMessage = CreateGlobalForward("GOKZ_OnTimerEndMessage", ET_Hook, Param_Cell, Param_Cell, Param_Float, Param_Cell);
	H_OnTimerStopped = CreateGlobalForward("GOKZ_OnTimerStopped", ET_Ignore, Param_Cell);
	H_OnPause = CreateGlobalForward("GOKZ_OnPause", ET_Hook, Param_Cell);
	H_OnPause_Post = CreateGlobalForward("GOKZ_OnPause_Post", ET_Ignore, Param_Cell);
	H_OnResume = CreateGlobalForward("GOKZ_OnResume_Post", ET_Hook, Param_Cell);
	H_OnResume_Post = CreateGlobalForward("GOKZ_OnResume_Post", ET_Ignore, Param_Cell);
	H_OnMakeCheckpoint = CreateGlobalForward("GOKZ_OnMakeCheckpoint", ET_Hook, Param_Cell);
	H_OnMakeCheckpoint_Post = CreateGlobalForward("GOKZ_OnMakeCheckpoint_Post", ET_Ignore, Param_Cell);
	H_OnTeleportToCheckpoint = CreateGlobalForward("GOKZ_OnTeleportToCheckpoint", ET_Hook, Param_Cell);
	H_OnTeleportToCheckpoint_Post = CreateGlobalForward("GOKZ_OnTeleportToCheckpoint_Post", ET_Ignore, Param_Cell);
	H_OnPrevCheckpoint = CreateGlobalForward("GOKZ_OnPrevCheckpoint", ET_Hook, Param_Cell);
	H_OnPrevCheckpoint_Post = CreateGlobalForward("GOKZ_OnPrevCheckpoint_Post", ET_Ignore, Param_Cell);
	H_OnNextCheckpoint = CreateGlobalForward("GOKZ_OnNextCheckpoint", ET_Hook, Param_Cell);
	H_OnNextCheckpoint_Post = CreateGlobalForward("GOKZ_OnNextCheckpoint_Post", ET_Ignore, Param_Cell);
	H_OnTeleportToStart = CreateGlobalForward("GOKZ_OnTeleportToStart", ET_Hook, Param_Cell);
	H_OnTeleportToStart_Post = CreateGlobalForward("GOKZ_OnTeleportToStart_Post", ET_Ignore, Param_Cell);
	H_OnUndoTeleport = CreateGlobalForward("GOKZ_OnUndoTeleport", ET_Hook, Param_Cell);
	H_OnUndoTeleport_Post = CreateGlobalForward("GOKZ_OnUndoTeleport_Post", ET_Ignore, Param_Cell);
	H_OnStartPositionSet_Post = CreateGlobalForward("GOKZ_OnStartPositionSet_Post", ET_Ignore, Param_Cell, Param_Cell, Param_Array, Param_Array);
	H_OnCountedTeleport_Post = CreateGlobalForward("GOKZ_OnCountedTeleport_Post", ET_Ignore, Param_Cell);
	H_OnJumpValidated = CreateGlobalForward("GOKZ_OnJumpValidated", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	H_OnJumpInvalidated = CreateGlobalForward("GOKZ_OnJumpInvalidated", ET_Ignore, Param_Cell);
	H_OnJoinTeam = CreateGlobalForward("GOKZ_OnJoinTeam", ET_Ignore, Param_Cell, Param_Cell);
	H_OnFirstSpawn = CreateGlobalForward("GOKZ_OnFirstSpawn", ET_Ignore, Param_Cell);
	H_OnModeLoaded = CreateGlobalForward("GOKZ_OnModeLoaded", ET_Ignore, Param_Cell);
	H_OnModeUnloaded = CreateGlobalForward("GOKZ_OnModeUnloaded", ET_Ignore, Param_Cell);
	H_OnTimerNativeCalledExternally = CreateGlobalForward("GOKZ_OnTimerNativeCalledExternally", ET_Event, Param_Cell);
	H_OnOptionsMenuCreated = CreateGlobalForward("GOKZ_OnOptionsMenuCreated", ET_Ignore, Param_Cell);
	H_OnOptionsMenuReady = CreateGlobalForward("GOKZ_OnOptionsMenuReady", ET_Ignore, Param_Cell);
	H_OnCourseRegistered = CreateGlobalForward("GOKZ_OnCourseRegistered", ET_Ignore, Param_Cell);
}

void Call_GOKZ_OnOptionChanged(int client, const char[] option, int optionValue)
{
	Call_StartForward(H_OnOptionChanged);
	Call_PushCell(client);
	Call_PushString(option);
	Call_PushCell(optionValue);
	Call_Finish();
}

void Call_GOKZ_OnTimerStart(int client, int course, Action &result)
{
	Call_StartForward(H_OnTimerStart);
	Call_PushCell(client);
	Call_PushCell(course);
	Call_Finish(result);
}

void Call_GOKZ_OnTimerStart_Post(int client, int course)
{
	Call_StartForward(H_OnTimerStart_Post);
	Call_PushCell(client);
	Call_PushCell(course);
	Call_Finish();
}

void Call_GOKZ_OnTimerEnd(int client, int course, float time, int teleportsUsed, Action &result)
{
	Call_StartForward(H_OnTimerEnd);
	Call_PushCell(client);
	Call_PushCell(course);
	Call_PushFloat(time);
	Call_PushCell(teleportsUsed);
	Call_Finish(result);
}

void Call_GOKZ_OnTimerEnd_Post(int client, int course, float time, int teleportsUsed)
{
	Call_StartForward(H_OnTimerEnd_Post);
	Call_PushCell(client);
	Call_PushCell(course);
	Call_PushFloat(time);
	Call_PushCell(teleportsUsed);
	Call_Finish();
}

void Call_GOKZ_OnTimerEndMessage(int client, int course, float time, int teleportsUsed, Action &result)
{
	Call_StartForward(H_OnTimerEndMessage);
	Call_PushCell(client);
	Call_PushCell(course);
	Call_PushFloat(time);
	Call_PushCell(teleportsUsed);
	Call_Finish(result);
}

void Call_GOKZ_OnTimerStopped(int client)
{
	Call_StartForward(H_OnTimerStopped);
	Call_PushCell(client);
	Call_Finish();
}

void Call_GOKZ_OnPause(int client, Action &result)
{
	Call_StartForward(H_OnPause);
	Call_PushCell(client);
	Call_Finish(result);
}

void Call_GOKZ_OnPause_Post(int client)
{
	Call_StartForward(H_OnPause_Post);
	Call_PushCell(client);
	Call_Finish();
}

void Call_GOKZ_OnResume(int client, Action &result)
{
	Call_StartForward(H_OnResume);
	Call_PushCell(client);
	Call_Finish(result);
}

void Call_GOKZ_OnResume_Post(int client)
{
	Call_StartForward(H_OnResume_Post);
	Call_PushCell(client);
	Call_Finish();
}

void Call_GOKZ_OnMakeCheckpoint(int client, Action &result)
{
	Call_StartForward(H_OnMakeCheckpoint);
	Call_PushCell(client);
	Call_Finish(result);
}

void Call_GOKZ_OnMakeCheckpoint_Post(int client)
{
	Call_StartForward(H_OnMakeCheckpoint_Post);
	Call_PushCell(client);
	Call_Finish();
}

void Call_GOKZ_OnTeleportToCheckpoint(int client, Action &result)
{
	Call_StartForward(H_OnTeleportToCheckpoint);
	Call_PushCell(client);
	Call_Finish(result);
}

void Call_GOKZ_OnTeleportToCheckpoint_Post(int client)
{
	Call_StartForward(H_OnTeleportToCheckpoint_Post);
	Call_PushCell(client);
	Call_Finish();
}

void Call_GOKZ_OnPrevCheckpoint(int client, Action &result)
{
	Call_StartForward(H_OnPrevCheckpoint);
	Call_PushCell(client);
	Call_Finish(result);
}

void Call_GOKZ_OnPrevCheckpoint_Post(int client)
{
	Call_StartForward(H_OnPrevCheckpoint_Post);
	Call_PushCell(client);
	Call_Finish();
}

void Call_GOKZ_OnNextCheckpoint(int client, Action &result)
{
	Call_StartForward(H_OnNextCheckpoint);
	Call_PushCell(client);
	Call_Finish(result);
}

void Call_GOKZ_OnNextCheckpoint_Post(int client)
{
	Call_StartForward(H_OnNextCheckpoint_Post);
	Call_PushCell(client);
	Call_Finish();
}

void Call_GOKZ_OnTeleportToStart(int client, Action &result)
{
	Call_StartForward(H_OnTeleportToStart);
	Call_PushCell(client);
	Call_Finish(result);
}

void Call_GOKZ_OnTeleportToStart_Post(int client)
{
	Call_StartForward(H_OnTeleportToStart_Post);
	Call_PushCell(client);
	Call_Finish();
}

void Call_GOKZ_OnUndoTeleport(int client, Action &result)
{
	Call_StartForward(H_OnUndoTeleport);
	Call_PushCell(client);
	Call_Finish(result);
}

void Call_GOKZ_OnUndoTeleport_Post(int client)
{
	Call_StartForward(H_OnUndoTeleport_Post);
	Call_PushCell(client);
	Call_Finish();
}

void Call_GOKZ_OnCountedTeleport_Post(int client)
{
	Call_StartForward(H_OnCountedTeleport_Post);
	Call_PushCell(client);
	Call_Finish();
}

void Call_GOKZ_OnStartPositionSet_Post(int client, StartPositionType type, const float origin[3], const float angles[3])
{
	Call_StartForward(H_OnStartPositionSet_Post);
	Call_PushCell(client);
	Call_PushCell(type);
	Call_PushArray(origin, 3);
	Call_PushArray(angles, 3);
	Call_Finish();
}

void Call_GOKZ_OnJumpValidated(int client, bool jumped, bool ladderJump)
{
	Call_StartForward(H_OnJumpValidated);
	Call_PushCell(client);
	Call_PushCell(jumped);
	Call_PushCell(ladderJump);
	Call_Finish();
}

void Call_GOKZ_OnJumpInvalidated(int client)
{
	Call_StartForward(H_OnJumpInvalidated);
	Call_PushCell(client);
	Call_Finish();
}

void Call_GOKZ_OnJoinTeam(int client, int team)
{
	Call_StartForward(H_OnJoinTeam);
	Call_PushCell(client);
	Call_PushCell(team);
	Call_Finish();
}

void Call_GOKZ_OnFirstSpawn(int client)
{
	Call_StartForward(H_OnFirstSpawn);
	Call_PushCell(client);
	Call_Finish();
}

void Call_GOKZ_OnModeLoaded(int mode)
{
	Call_StartForward(H_OnModeLoaded);
	Call_PushCell(mode);
	Call_Finish();
}

void Call_GOKZ_OnModeUnloaded(int mode)
{
	Call_StartForward(H_OnModeUnloaded);
	Call_PushCell(mode);
	Call_Finish();
}

void Call_GOKZ_OnTimerNativeCalledExternally(Handle plugin, Action &result)
{
	Call_StartForward(H_OnTimerNativeCalledExternally);
	Call_PushCell(plugin);
	Call_Finish(result);
}

void Call_GOKZ_OnOptionsMenuCreated(TopMenu topMenu)
{
	Call_StartForward(H_OnOptionsMenuCreated);
	Call_PushCell(topMenu);
	Call_Finish();
}

void Call_GOKZ_OnOptionsMenuReady(TopMenu topMenu)
{
	Call_StartForward(H_OnOptionsMenuReady);
	Call_PushCell(topMenu);
	Call_Finish();
}

void Call_GOKZ_OnCourseRegistered(int course)
{
	Call_StartForward(H_OnCourseRegistered);
	Call_PushCell(course);
	Call_Finish();
} 