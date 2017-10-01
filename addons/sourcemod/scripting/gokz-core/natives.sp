/*
	Natives
	
	GOKZ Core plugin natives.
*/



void CreateNatives()
{
	CreateNative("GOKZ_GetModeLoaded", Native_GetModeLoaded);
	CreateNative("GOKZ_SetModeLoaded", Native_SetModeLoaded);
	CreateNative("GOKZ_GetLoadedModeCount", Native_GetLoadedModeCount);
	CreateNative("GOKZ_GetDefaultMode", Native_GetDefaultMode);
	CreateNative("GOKZ_PrintToChat", Native_PrintToChat);
	
	CreateNative("GOKZ_StartTimer", Native_StartTimer);
	CreateNative("GOKZ_EndTimer", Native_EndTimer);
	CreateNative("GOKZ_StopTimer", Native_StopTimer);
	CreateNative("GOKZ_StopTimerAll", Native_StopTimerAll);
	CreateNative("GOKZ_TeleportToStart", Native_TeleportToStart);
	CreateNative("GOKZ_MakeCheckpoint", Native_MakeCheckpoint);
	CreateNative("GOKZ_TeleportToCheckpoint", Native_TeleportToCheckpoint);
	CreateNative("GOKZ_PrevCheckpoint", Native_PrevCheckpoint);
	CreateNative("GOKZ_NextCheckpoint", Native_NextCheckpoint);
	CreateNative("GOKZ_UndoTeleport", Native_UndoTeleport);
	CreateNative("GOKZ_Pause", Native_Pause);
	CreateNative("GOKZ_Resume", Native_Resume);
	CreateNative("GOKZ_TogglePause", Native_TogglePause);
	CreateNative("GOKZ_PlayErrorSound", Native_PlayErrorSound);
	
	CreateNative("GOKZ_IsClientSetUp", Native_IsClientSetUp);
	CreateNative("GOKZ_GetTimerRunning", Native_GetTimerRunning);
	CreateNative("GOKZ_GetCurrentCourse", Native_GetCurrentCourse);
	CreateNative("GOKZ_GetPaused", Native_GetPaused);
	CreateNative("GOKZ_GetCurrentTime", Native_GetCurrentTime);
	CreateNative("GOKZ_SetCurrentTime", Native_SetCurrentTime);
	CreateNative("GOKZ_GetCheckpointCount", Native_GetCheckpointCount);
	CreateNative("GOKZ_SetCheckpointCount", Native_SetCheckpointCount);
	CreateNative("GOKZ_GetTeleportCount", Native_GetTeleportCount);
	CreateNative("GOKZ_SetTeleportCount", Native_SetTeleportCount);
	CreateNative("GOKZ_GetOption", Native_GetOption);
	CreateNative("GOKZ_SetOption", Native_SetOption);
	CreateNative("GOKZ_GetHitPerf", Native_GetHitPerf);
	CreateNative("GOKZ_SetHitPerf", Native_SetHitPerf);
	CreateNative("GOKZ_GetTakeoffSpeed", Native_GetTakeoffSpeed);
	CreateNative("GOKZ_SetTakeoffSpeed", Native_SetTakeoffSpeed);
	CreateNative("GOKZ_GetValidJump", Native_GetValidJump);
	CreateNative("GOKZ_JoinTeam", Native_JoinTeam);
}

public int Native_GetModeLoaded(Handle plugin, int numParams)
{
	return view_as<int>(GetModeLoaded(GetNativeCell(1)));
}

public int Native_SetModeLoaded(Handle plugin, int numParams)
{
	SetModeLoaded(GetNativeCell(1), GetNativeCell(2));
}

public int Native_GetLoadedModeCount(Handle plugin, int numParams)
{
	return GetLoadedModeCount();
}

public int Native_GetDefaultMode(Handle plugin, int numParams)
{
	return gCV_gokz_default_mode.IntValue;
}

public int Native_PrintToChat(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	bool addPrefix = GetNativeCell(2);
	
	char buffer[1024];
	FormatNativeString(0, 3, 4, sizeof(buffer), _, buffer);
	if (addPrefix)
	{
		char prefix[64];
		gCV_gokz_chat_prefix.GetString(prefix, sizeof(prefix));
		Format(buffer, sizeof(buffer), "%s%s", prefix, buffer);
	}
	CPrintToChat(client, "%s", buffer);
}

public int Native_StartTimer(Handle plugin, int numParams)
{
	if (BlockedExternallyCalledTimerNative(plugin))
	{
		return view_as<int>(false);
	}
	
	TimerStart(GetNativeCell(1), GetNativeCell(2));
	return view_as<int>(true);
}

public int Native_EndTimer(Handle plugin, int numParams)
{
	if (BlockedExternallyCalledTimerNative(plugin))
	{
		return view_as<int>(false);
	}
	
	TimerEnd(GetNativeCell(1), GetNativeCell(2));
	return view_as<int>(true);
}

public int Native_StopTimer(Handle plugin, int numParams)
{
	return view_as<int>(TimerStop(GetNativeCell(1), GetNativeCell(2)));
}

public int Native_StopTimerAll(Handle plugin, int numParams)
{
	TimerStopAll(GetNativeCell(1));
}

public int Native_TeleportToStart(Handle plugin, int numParams)
{
	TeleportToStart(GetNativeCell(1));
}

public int Native_MakeCheckpoint(Handle plugin, int numParams)
{
	MakeCheckpoint(GetNativeCell(1));
}

public int Native_TeleportToCheckpoint(Handle plugin, int numParams)
{
	TeleportToCheckpoint(GetNativeCell(1));
}

public int Native_PrevCheckpoint(Handle plugin, int numParams)
{
	PrevCheckpoint(GetNativeCell(1));
}

public int Native_NextCheckpoint(Handle plugin, int numParams)
{
	NextCheckpoint(GetNativeCell(1));
}

public int Native_UndoTeleport(Handle plugin, int numParams)
{
	UndoTeleport(GetNativeCell(1));
}

public int Native_Pause(Handle plugin, int numParams)
{
	Pause(GetNativeCell(1));
}

public int Native_Resume(Handle plugin, int numParams)
{
	Resume(GetNativeCell(1));
}

public int Native_TogglePause(Handle plugin, int numParams)
{
	TogglePause(GetNativeCell(1));
}

public int Native_PlayErrorSound(Handle plugin, int numParams)
{
	PlayErrorSound(GetNativeCell(1));
}

public int Native_IsClientSetUp(Handle plugin, int numParams)
{
	return view_as<int>(gB_ClientIsSetUp[GetNativeCell(1)]);
}

public int Native_GetTimerRunning(Handle plugin, int numParams)
{
	return view_as<int>(GetTimerRunning(GetNativeCell(1)));
}

public int Native_GetCurrentCourse(Handle plugin, int numParams)
{
	return GetCurrentCourse(GetNativeCell(1));
}

public int Native_GetPaused(Handle plugin, int numParams)
{
	return view_as<int>(GetPaused(GetNativeCell(1)));
}

public int Native_GetCurrentTime(Handle plugin, int numParams)
{
	return view_as<int>(GetCurrentTime(GetNativeCell(1)));
}

public int Native_SetCurrentTime(Handle plugin, int numParams)
{
	if (BlockedExternallyCalledTimerNative(plugin))
	{
		return view_as<int>(false);
	}
	
	SetCurrentTime(GetNativeCell(1), view_as<float>(GetNativeCell(2)));
	return view_as<int>(true);
}

public int Native_GetCheckpointCount(Handle plugin, int numParams)
{
	return GetCheckpointCount(GetNativeCell(1));
}

public int Native_SetCheckpointCount(Handle plugin, int numParams)
{
	if (BlockedExternallyCalledTimerNative(plugin))
	{
		return view_as<int>(false);
	}
	
	SetCheckpointCount(GetNativeCell(1), GetNativeCell(2));
	return view_as<int>(true);
}

public int Native_GetTeleportCount(Handle plugin, int numParams)
{
	return GetTeleportCount(GetNativeCell(1));
}

public int Native_SetTeleportCount(Handle plugin, int numParams)
{
	if (BlockedExternallyCalledTimerNative(plugin))
	{
		return view_as<int>(false);
	}
	
	SetTeleportCount(GetNativeCell(1), GetNativeCell(2));
	return view_as<int>(true);
}

public int Native_GetOption(Handle plugin, int numParams)
{
	return GetOption(GetNativeCell(1), GetNativeCell(2));
}

public int Native_SetOption(Handle plugin, int numParams)
{
	SetOption(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3), GetNativeCell(4));
}

public int Native_GetHitPerf(Handle plugin, int numParams)
{
	return view_as<int>(GetGOKZHitPerf(GetNativeCell(1)));
}

public int Native_SetHitPerf(Handle plugin, int numParams)
{
	SetGOKZHitPerf(GetNativeCell(1), view_as<bool>(GetNativeCell(2)));
}

public int Native_GetTakeoffSpeed(Handle plugin, int numParams)
{
	return view_as<int>(GetGOKZTakeoffSpeed(GetNativeCell(1)));
}

public int Native_SetTakeoffSpeed(Handle plugin, int numParams)
{
	SetGOKZTakeoffSpeed(GetNativeCell(1), view_as<float>(GetNativeCell(2)));
}

public int Native_GetValidJump(Handle plugin, int numParams)
{
	return view_as<int>(GetValidJump(GetNativeCell(1)));
}

public int Native_JoinTeam(Handle plugin, int numParams)
{
	JoinTeam(GetNativeCell(1), GetNativeCell(2));
}



// =========================  PRIVATE  ========================= //

static bool BlockedExternallyCalledTimerNative(Handle plugin)
{
	if (plugin != g_ThisPlugin)
	{
		Action result;
		Call_GOKZ_OnTimerNativeCalledExternally(plugin, result);
		if (result != Plugin_Continue)
		{
			return true;
		}
	}
	
	return false;
} 