static GlobalForward H_OnOptionsLoaded;
static GlobalForward H_OnOptionChanged;
static GlobalForward H_OnTimerStart;
static GlobalForward H_OnTimerStart_Post;
static GlobalForward H_OnTimerEnd;
static GlobalForward H_OnTimerEnd_Post;
static GlobalForward H_OnTimerEndMessage;
static GlobalForward H_OnTimerStopped;
static GlobalForward H_OnPause;
static GlobalForward H_OnPause_Post;
static GlobalForward H_OnResume;
static GlobalForward H_OnResume_Post;
static GlobalForward H_OnMakeCheckpoint;
static GlobalForward H_OnMakeCheckpoint_Post;
static GlobalForward H_OnTeleportToCheckpoint;
static GlobalForward H_OnTeleportToCheckpoint_Post;
static GlobalForward H_OnTeleport;
static GlobalForward H_OnPrevCheckpoint;
static GlobalForward H_OnPrevCheckpoint_Post;
static GlobalForward H_OnNextCheckpoint;
static GlobalForward H_OnNextCheckpoint_Post;
static GlobalForward H_OnTeleportToStart;
static GlobalForward H_OnTeleportToStart_Post;
static GlobalForward H_OnTeleportToEnd;
static GlobalForward H_OnTeleportToEnd_Post;
static GlobalForward H_OnUndoTeleport;
static GlobalForward H_OnUndoTeleport_Post;
static GlobalForward H_OnCountedTeleport_Post;
static GlobalForward H_OnStartPositionSet_Post;
static GlobalForward H_OnJumpValidated;
static GlobalForward H_OnJumpInvalidated;
static GlobalForward H_OnJoinTeam;
static GlobalForward H_OnFirstSpawn;
static GlobalForward H_OnModeLoaded;
static GlobalForward H_OnModeUnloaded;
static GlobalForward H_OnTimerNativeCalledExternally;
static GlobalForward H_OnOptionsMenuCreated;
static GlobalForward H_OnOptionsMenuReady;
static GlobalForward H_OnCourseRegistered;
static GlobalForward H_OnRunInvalidated;
static GlobalForward H_OnEmitSoundToClient;

void CreateGlobalForwards()
{
	H_OnOptionsLoaded = new GlobalForward("GOKZ_OnOptionsLoaded", ET_Ignore, Param_Cell);
	H_OnOptionChanged = new GlobalForward("GOKZ_OnOptionChanged", ET_Ignore, Param_Cell, Param_String, Param_Cell);
	H_OnTimerStart = new GlobalForward("GOKZ_OnTimerStart", ET_Hook, Param_Cell, Param_Cell);
	H_OnTimerStart_Post = new GlobalForward("GOKZ_OnTimerStart_Post", ET_Ignore, Param_Cell, Param_Cell);
	H_OnTimerEnd = new GlobalForward("GOKZ_OnTimerEnd", ET_Hook, Param_Cell, Param_Cell, Param_Float, Param_Cell);
	H_OnTimerEnd_Post = new GlobalForward("GOKZ_OnTimerEnd_Post", ET_Ignore, Param_Cell, Param_Cell, Param_Float, Param_Cell);
	H_OnTimerEndMessage = new GlobalForward("GOKZ_OnTimerEndMessage", ET_Hook, Param_Cell, Param_Cell, Param_Float, Param_Cell);
	H_OnTimerStopped = new GlobalForward("GOKZ_OnTimerStopped", ET_Ignore, Param_Cell);
	H_OnPause = new GlobalForward("GOKZ_OnPause", ET_Hook, Param_Cell);
	H_OnPause_Post = new GlobalForward("GOKZ_OnPause_Post", ET_Ignore, Param_Cell);
	H_OnResume = new GlobalForward("GOKZ_OnResume", ET_Hook, Param_Cell);
	H_OnResume_Post = new GlobalForward("GOKZ_OnResume_Post", ET_Ignore, Param_Cell);
	H_OnMakeCheckpoint = new GlobalForward("GOKZ_OnMakeCheckpoint", ET_Hook, Param_Cell);
	H_OnMakeCheckpoint_Post = new GlobalForward("GOKZ_OnMakeCheckpoint_Post", ET_Ignore, Param_Cell);
	H_OnTeleportToCheckpoint = new GlobalForward("GOKZ_OnTeleportToCheckpoint", ET_Hook, Param_Cell);
	H_OnTeleportToCheckpoint_Post = new GlobalForward("GOKZ_OnTeleportToCheckpoint_Post", ET_Ignore, Param_Cell);
	H_OnTeleport = new GlobalForward("GOKZ_OnTeleport", ET_Hook, Param_Cell);
	H_OnPrevCheckpoint = new GlobalForward("GOKZ_OnPrevCheckpoint", ET_Hook, Param_Cell);
	H_OnPrevCheckpoint_Post = new GlobalForward("GOKZ_OnPrevCheckpoint_Post", ET_Ignore, Param_Cell);
	H_OnNextCheckpoint = new GlobalForward("GOKZ_OnNextCheckpoint", ET_Hook, Param_Cell);
	H_OnNextCheckpoint_Post = new GlobalForward("GOKZ_OnNextCheckpoint_Post", ET_Ignore, Param_Cell);
	H_OnTeleportToStart = new GlobalForward("GOKZ_OnTeleportToStart", ET_Hook, Param_Cell, Param_Cell);
	H_OnTeleportToStart_Post = new GlobalForward("GOKZ_OnTeleportToStart_Post", ET_Ignore, Param_Cell, Param_Cell);
	H_OnTeleportToEnd = new GlobalForward("GOKZ_OnTeleportToEnd", ET_Hook, Param_Cell, Param_Cell);
	H_OnTeleportToEnd_Post = new GlobalForward("GOKZ_OnTeleportToEnd_Post", ET_Ignore, Param_Cell, Param_Cell);
	H_OnUndoTeleport = new GlobalForward("GOKZ_OnUndoTeleport", ET_Hook, Param_Cell);
	H_OnUndoTeleport_Post = new GlobalForward("GOKZ_OnUndoTeleport_Post", ET_Ignore, Param_Cell);
	H_OnStartPositionSet_Post = new GlobalForward("GOKZ_OnStartPositionSet_Post", ET_Ignore, Param_Cell, Param_Cell, Param_Array, Param_Array);
	H_OnCountedTeleport_Post = new GlobalForward("GOKZ_OnCountedTeleport_Post", ET_Ignore, Param_Cell);
	H_OnJumpValidated = new GlobalForward("GOKZ_OnJumpValidated", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	H_OnJumpInvalidated = new GlobalForward("GOKZ_OnJumpInvalidated", ET_Ignore, Param_Cell);
	H_OnJoinTeam = new GlobalForward("GOKZ_OnJoinTeam", ET_Ignore, Param_Cell, Param_Cell);
	H_OnFirstSpawn = new GlobalForward("GOKZ_OnFirstSpawn", ET_Ignore, Param_Cell);
	H_OnModeLoaded = new GlobalForward("GOKZ_OnModeLoaded", ET_Ignore, Param_Cell);
	H_OnModeUnloaded = new GlobalForward("GOKZ_OnModeUnloaded", ET_Ignore, Param_Cell);
	H_OnTimerNativeCalledExternally = new GlobalForward("GOKZ_OnTimerNativeCalledExternally", ET_Event, Param_Cell, Param_Cell);
	H_OnOptionsMenuCreated = new GlobalForward("GOKZ_OnOptionsMenuCreated", ET_Ignore, Param_Cell);
	H_OnOptionsMenuReady = new GlobalForward("GOKZ_OnOptionsMenuReady", ET_Ignore, Param_Cell);
	H_OnCourseRegistered = new GlobalForward("GOKZ_OnCourseRegistered", ET_Ignore, Param_Cell);
	H_OnRunInvalidated = new GlobalForward("GOKZ_OnRunInvalidated", ET_Ignore, Param_Cell);
	H_OnEmitSoundToClient = new GlobalForward("GOKZ_OnEmitSoundToClient", ET_Hook, Param_Cell, Param_String, Param_FloatByRef, Param_String);
}

void Call_GOKZ_OnOptionsLoaded(int client)
{
	Call_StartForward(H_OnOptionsLoaded);
	Call_PushCell(client);
	Call_Finish();
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

void Call_GOKZ_OnTeleport(int client)
{
	Call_StartForward(H_OnTeleport);
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

void Call_GOKZ_OnTeleportToStart(int client, int course, Action &result)
{
	Call_StartForward(H_OnTeleportToStart);
	Call_PushCell(client);
	Call_PushCell(course);
	Call_Finish(result);
}

void Call_GOKZ_OnTeleportToStart_Post(int client, int course)
{
	Call_StartForward(H_OnTeleportToStart_Post);
	Call_PushCell(client);
	Call_PushCell(course);
	Call_Finish();
}

void Call_GOKZ_OnTeleportToEnd(int client, int course, Action &result)
{
	Call_StartForward(H_OnTeleportToEnd);
	Call_PushCell(client);
	Call_PushCell(course);
	Call_Finish(result);
}

void Call_GOKZ_OnTeleportToEnd_Post(int client, int course)
{
	Call_StartForward(H_OnTeleportToEnd_Post);
	Call_PushCell(client);
	Call_PushCell(course);
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

void Call_GOKZ_OnJumpValidated(int client, bool jumped, bool ladderJump, bool jumpbug)
{
	Call_StartForward(H_OnJumpValidated);
	Call_PushCell(client);
	Call_PushCell(jumped);
	Call_PushCell(ladderJump);
	Call_PushCell(jumpbug);
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

void Call_GOKZ_OnTimerNativeCalledExternally(Handle plugin, int client, Action &result)
{
	Call_StartForward(H_OnTimerNativeCalledExternally);
	Call_PushCell(plugin);
	Call_PushCell(client);
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

void Call_GOKZ_OnRunInvalidated(int client)
{
	Call_StartForward(H_OnRunInvalidated);
	Call_PushCell(client);
	Call_Finish();
}

void Call_GOKZ_OnEmitSoundToClient(int client, const char[] sample, float &volume, const char[] description, Action &result)
{
	Call_StartForward(H_OnEmitSoundToClient);
	Call_PushCell(client);
	Call_PushString(sample);
	Call_PushFloatRef(volume);
	Call_PushString(description);
	Call_Finish(result);
}