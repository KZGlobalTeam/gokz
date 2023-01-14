void CreateNatives()
{
	CreateNative("GOKZ_GetModeLoaded", Native_GetModeLoaded);
	CreateNative("GOKZ_GetModeVersion", Native_GetModeVersion);
	CreateNative("GOKZ_SetModeLoaded", Native_SetModeLoaded);
	CreateNative("GOKZ_GetLoadedModeCount", Native_GetLoadedModeCount);
	CreateNative("GOKZ_SetMode", Native_SetMode);
	CreateNative("GOKZ_PrintToChat", Native_PrintToChat);
	CreateNative("GOKZ_PrintToChatAndLog", Native_PrintToChatAndLog);
	CreateNative("GOKZ_GetOptionsTopMenu", Native_GetOptionsTopMenu);
	CreateNative("GOKZ_GetCourseRegistered", Native_GetCourseRegistered);
	
	CreateNative("GOKZ_StartTimer", Native_StartTimer);
	CreateNative("GOKZ_EndTimer", Native_EndTimer);
	CreateNative("GOKZ_StopTimer", Native_StopTimer);
	CreateNative("GOKZ_StopTimerAll", Native_StopTimerAll);
	CreateNative("GOKZ_TeleportToStart", Native_TeleportToStart);
	CreateNative("GOKZ_TeleportToSearchStart", Native_TeleportToSearchStart);
	CreateNative("GOKZ_GetVirtualButtonPosition", Native_GetVirtualButtonPosition);
	CreateNative("GOKZ_SetVirtualButtonPosition", Native_SetVirtualButtonPosition);
	CreateNative("GOKZ_ResetVirtualButtonPosition", Native_ResetVirtualButtonPosition);	
	CreateNative("GOKZ_LockVirtualButtons", Native_LockVirtualButtons);
	CreateNative("GOKZ_GetStartPosition", Native_GetStartPosition);
	CreateNative("GOKZ_SetStartPosition", Native_SetStartPosition);
	CreateNative("GOKZ_TeleportToEnd", Native_TeleportToEnd);
	CreateNative("GOKZ_GetStartPositionType", Native_GetStartPositionType);
	CreateNative("GOKZ_SetStartPositionToMapStart", Native_SetStartPositionToMapStart);
	CreateNative("GOKZ_MakeCheckpoint", Native_MakeCheckpoint);
	CreateNative("GOKZ_GetCanMakeCheckpoint", Native_GetCanMakeCheckpoint);
	CreateNative("GOKZ_TeleportToCheckpoint", Native_TeleportToCheckpoint);
	CreateNative("GOKZ_GetCanTeleportToCheckpoint", Native_GetCanTeleportToCheckpoint);
	CreateNative("GOKZ_PrevCheckpoint", Native_PrevCheckpoint);
	CreateNative("GOKZ_GetCanPrevCheckpoint", Native_GetCanPrevCheckpoint);
	CreateNative("GOKZ_NextCheckpoint", Native_NextCheckpoint);
	CreateNative("GOKZ_GetCanNextCheckpoint", Native_GetCanNextCheckpoint);
	CreateNative("GOKZ_UndoTeleport", Native_UndoTeleport);
	CreateNative("GOKZ_GetCanUndoTeleport", Native_GetCanUndoTeleport);
	CreateNative("GOKZ_Pause", Native_Pause);
	CreateNative("GOKZ_GetCanPause", Native_GetCanPause);
	CreateNative("GOKZ_Resume", Native_Resume);
	CreateNative("GOKZ_GetCanResume", Native_GetCanResume);
	CreateNative("GOKZ_TogglePause", Native_TogglePause);
	CreateNative("GOKZ_GetCanTeleportToStart", Native_GetCanTeleportToStart);
	CreateNative("GOKZ_GetCanTeleportToEnd", Native_GetCanTeleportToEnd);
	CreateNative("GOKZ_PlayErrorSound", Native_PlayErrorSound);
	CreateNative("GOKZ_SetValidJumpOrigin", Native_SetValidJumpOrigin);
	
	CreateNative("GOKZ_GetTimerRunning", Native_GetTimerRunning);
	CreateNative("GOKZ_GetValidTimer", Native_GetValidTimer);
	CreateNative("GOKZ_GetCourse", Native_GetCourse);
	CreateNative("GOKZ_SetCourse", Native_SetCourse);
	CreateNative("GOKZ_GetPaused", Native_GetPaused);
	CreateNative("GOKZ_GetTime", Native_GetTime);
	CreateNative("GOKZ_SetTime", Native_SetTime);
	CreateNative("GOKZ_InvalidateRun", Native_InvalidateRun);
	CreateNative("GOKZ_GetCheckpointCount", Native_GetCheckpointCount);
	CreateNative("GOKZ_SetCheckpointCount", Native_SetCheckpointCount);
	CreateNative("GOKZ_GetCheckpointData", Native_GetCheckpointData);
	CreateNative("GOKZ_SetCheckpointData", Native_SetCheckpointData);
	CreateNative("GOKZ_GetUndoTeleportData", Native_GetUndoTeleportData);
	CreateNative("GOKZ_SetUndoTeleportData", Native_SetUndoTeleportData);
	CreateNative("GOKZ_GetTeleportCount", Native_GetTeleportCount);
	CreateNative("GOKZ_SetTeleportCount", Native_SetTeleportCount);
	CreateNative("GOKZ_RegisterOption", Native_RegisterOption);
	CreateNative("GOKZ_GetOptionProp", Native_GetOptionProp);
	CreateNative("GOKZ_SetOptionProp", Native_SetOptionProp);
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

public int Native_GetModeVersion(Handle plugin, int numParams)
{
	return view_as<int>(GetModeVersion(GetNativeCell(1)));
}

public int Native_SetModeLoaded(Handle plugin, int numParams)
{
	SetModeLoaded(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3));
	return 0;
}

public int Native_GetLoadedModeCount(Handle plugin, int numParams)
{
	return GetLoadedModeCount();
}

public int Native_SetMode(Handle plugin, int numParams)
{
	return view_as<bool>(SwitchToModeIfAvailable(GetNativeCell(1),GetNativeCell(2)));
}

public int Native_PrintToChatAndLog(Handle plugin, int numParams)
{
	NativeHelper_PrintToChatOrLog(true);
	return 0;
}

public int Native_PrintToChat(Handle plugin, int numParams)
{
	NativeHelper_PrintToChatOrLog(false);
	return 0;
}

static int NativeHelper_PrintToChatOrLog(bool alwaysLog)
{
	int client = GetNativeCell(1);
	bool addPrefix = GetNativeCell(2);
	
	char buffer[1024];
	SetGlobalTransTarget(client);
	FormatNativeString(0, 3, 4, sizeof(buffer), _, buffer);
	
	// The console (client 0) gets a special treatment
	if (client == 0 || (!IsValidClient(client) && !IsClientSourceTV(client)) || alwaysLog)
	{
		// Strip colors
		// We can't regex-replace, so I'm quite sure that's the most efficient way.
		// It's also not perfectly safe, we will just assume you never have curly
		// braces without a color in beween.
		char colorlessBuffer[1024];
		FormatEx(colorlessBuffer, sizeof(colorlessBuffer), "%L: ", client);
		int iIn = 0, iOut = strlen(colorlessBuffer);
		do
		{
			if (buffer[iIn] == '{')
			{
				for (; buffer[iIn] != '}' && iIn < sizeof(buffer) - 2; iIn++){}
				if (iIn >= sizeof(buffer) - 2)
				{
					break;
				}
				iIn++;
				continue;
			}
			
			colorlessBuffer[iOut] = buffer[iIn];
			iIn++;
			iOut++;
		} while (buffer[iIn] != '\0' && iIn < sizeof(buffer) - 1 && iOut < sizeof(colorlessBuffer) - 1);
		colorlessBuffer[iOut] = '\0';
		LogMessage(colorlessBuffer);
	}
	
	if (client != 0)
	{
		if (addPrefix)
		{
			char prefix[64];
			gCV_gokz_chat_prefix.GetString(prefix, sizeof(prefix));
			Format(buffer, sizeof(buffer), "%s%s", prefix, buffer);
		}

		CPrintToChat(client, "%s", buffer);
	}
	return 0;
}

public int Native_GetOptionsTopMenu(Handle plugin, int numParams)
{
	return view_as<int>(GetOptionsTopMenu());
}

public int Native_GetCourseRegistered(Handle plugin, int numParams)
{
	return view_as<int>(GetCourseRegistered(GetNativeCell(1)));
}

public int Native_StartTimer(Handle plugin, int numParams)
{
	if (BlockedExternallyCalledTimerNative(plugin, GetNativeCell(1)))
	{
		return view_as<int>(false);
	}
	
	return view_as<int>(TimerStart(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3)));
}

public int Native_EndTimer(Handle plugin, int numParams)
{
	if (BlockedExternallyCalledTimerNative(plugin, GetNativeCell(1)))
	{
		return view_as<int>(false);
	}
	
	return view_as<int>(TimerEnd(GetNativeCell(1), GetNativeCell(2)));
}

public int Native_StopTimer(Handle plugin, int numParams)
{
	return view_as<int>(TimerStop(GetNativeCell(1), GetNativeCell(2)));
}

public int Native_StopTimerAll(Handle plugin, int numParams)
{
	TimerStopAll(GetNativeCell(1));
	return 0;
}

public int Native_TeleportToStart(Handle plugin, int numParams)
{
	TeleportToStart(GetNativeCell(1));
	return 0;
}

public int Native_TeleportToSearchStart(Handle plugin, int numParams)
{
	TeleportToSearchStart(GetNativeCell(1), GetNativeCell(2));
	return 0;
}

public int Native_GetVirtualButtonPosition(Handle plugin, int numParams)
{
	int course;
	float position[3];
	
	course = GetVirtualButtonPosition(GetNativeCell(1), position, GetNativeCell(3));
	SetNativeArray(2, position, sizeof(position));
	
	return course;
}

public int Native_SetVirtualButtonPosition(Handle plugin, int numParams)
{
	float position[3];
	
	GetNativeArray(2, position, sizeof(position));
	SetVirtualButtonPosition(GetNativeCell(1), position, GetNativeCell(3), view_as<bool>(GetNativeCell(4)));
	return 0;
}

public int Native_ResetVirtualButtonPosition(Handle plugin, int numParams)
{
	ResetVirtualButtonPosition(GetNativeCell(1), GetNativeCell(2));
	return 0;
}

public int Native_LockVirtualButtons(Handle plugin, int numParams)
{
	LockVirtualButtons(GetNativeCell(1));
	return 0;
}

public int Native_GetStartPosition(Handle plugin, int numParams)
{
	StartPositionType type;
	float position[3], angles[3];
	
	type = GetStartPosition(GetNativeCell(1), position, angles);
	SetNativeArray(2, position, sizeof(position));
	SetNativeArray(3, angles, sizeof(angles));
	
	return view_as<int>(type);
}

public int Native_SetStartPosition(Handle plugin, int numParams)
{
	float position[3], angles[3];
	
	GetNativeArray(3, position, sizeof(position));
	GetNativeArray(4, angles, sizeof(angles));
	SetStartPosition(GetNativeCell(1), GetNativeCell(2), position, angles);
	return 0;
}

public int Native_TeleportToEnd(Handle plugin, int numParams)
{
	TeleportToEnd(GetNativeCell(1), GetNativeCell(2));
	return 0;
}

public int Native_GetStartPositionType(Handle plugin, int numParams)
{
	return view_as<int>(GetStartPositionType(GetNativeCell(1)));
}

public int Native_SetStartPositionToMapStart(Handle plugin, int numParams)
{
	return SetStartPositionToMapStart(GetNativeCell(1), GetNativeCell(2));
}

public int Native_MakeCheckpoint(Handle plugin, int numParams)
{
	MakeCheckpoint(GetNativeCell(1));
	return 0;
}

public int Native_GetCanMakeCheckpoint(Handle plugin, int numParams)
{
	return CanMakeCheckpoint(GetNativeCell(1));
}

public int Native_TeleportToCheckpoint(Handle plugin, int numParams)
{
	TeleportToCheckpoint(GetNativeCell(1));
	return 0;
}

public int Native_GetCanTeleportToCheckpoint(Handle plugin, int numParams)
{
	return CanTeleportToCheckpoint(GetNativeCell(1));
}

public int Native_PrevCheckpoint(Handle plugin, int numParams)
{
	PrevCheckpoint(GetNativeCell(1));
	return 0;
}

public int Native_GetCanPrevCheckpoint(Handle plugin, int numParams)
{
	return CanPrevCheckpoint(GetNativeCell(1));
}

public int Native_NextCheckpoint(Handle plugin, int numParams)
{
	NextCheckpoint(GetNativeCell(1));
	return 0;
}

public int Native_GetCanNextCheckpoint(Handle plugin, int numParams)
{
	return CanNextCheckpoint(GetNativeCell(1));
}

public int Native_UndoTeleport(Handle plugin, int numParams)
{
	UndoTeleport(GetNativeCell(1));
	return 0;
}

public int Native_GetCanUndoTeleport(Handle plugin, int numParams)
{
	return CanUndoTeleport(GetNativeCell(1));
}

public int Native_Pause(Handle plugin, int numParams)
{
	Pause(GetNativeCell(1));
	return 0;
}

public int Native_GetCanPause(Handle plugin, int numParams)
{
	return CanPause(GetNativeCell(1));
}

public int Native_Resume(Handle plugin, int numParams)
{
	Resume(GetNativeCell(1));
	return 0;
}

public int Native_GetCanResume(Handle plugin, int numParams)
{
	return CanResume(GetNativeCell(1));
}

public int Native_TogglePause(Handle plugin, int numParams)
{
	TogglePause(GetNativeCell(1));
	return 0;
}

public int Native_GetCanTeleportToStart(Handle plugin, int numParams)
{
	return CanTeleportToStart(GetNativeCell(1));
}

public int Native_GetCanTeleportToEnd(Handle plugin, int numParams)
{
	return CanTeleportToEnd(GetNativeCell(1));
}

public int Native_PlayErrorSound(Handle plugin, int numParams)
{
	PlayErrorSound(GetNativeCell(1));
	return 0;
}

public int Native_SetValidJumpOrigin(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	float origin[3];
	GetNativeArray(2, origin, sizeof(origin));
	
	// The order is important here!
	OnValidOriginChange_ValidJump(client, origin);
	
	// Using Movement_SetOrigin instead causes considerable lag for spectators
	SetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", origin);
	return 0;
}

public int Native_GetTimerRunning(Handle plugin, int numParams)
{
	return view_as<int>(GetTimerRunning(GetNativeCell(1)));
}

public int Native_GetValidTimer(Handle plugin, int numParams)
{
	return view_as<int>(GetValidTimer(GetNativeCell(1)));
}

public int Native_GetCourse(Handle plugin, int numParams)
{
	return GetCurrentCourse(GetNativeCell(1));
}

public int Native_SetCourse(Handle plugin, int numParams)
{
	if (BlockedExternallyCalledTimerNative(plugin, GetNativeCell(1)))
	{
		return view_as<int>(false);
	}
	SetCurrentCourse(GetNativeCell(1), GetNativeCell(2));
	return view_as<int>(false);	
}

public int Native_GetPaused(Handle plugin, int numParams)
{
	return view_as<int>(GetPaused(GetNativeCell(1)));
}

public int Native_GetTime(Handle plugin, int numParams)
{
	return view_as<int>(GetCurrentTime(GetNativeCell(1)));
}

public int Native_SetTime(Handle plugin, int numParams)
{
	if (BlockedExternallyCalledTimerNative(plugin, GetNativeCell(1)))
	{
		return view_as<int>(false);
	}
	
	SetCurrentTime(GetNativeCell(1), view_as<float>(GetNativeCell(2)));
	return view_as<int>(true);
}

public int Native_InvalidateRun(Handle plugin, int numParams)
{
	InvalidateRun(GetNativeCell(1));
	return view_as<int>(true);
}

public int Native_GetCheckpointCount(Handle plugin, int numParams)
{
	return GetCheckpointCount(GetNativeCell(1));
}

public int Native_SetCheckpointCount(Handle plugin, int numParams)
{
	if (BlockedExternallyCalledTimerNative(plugin, GetNativeCell(1)))
	{
		return view_as<int>(false);
	}
	SetCheckpointCount(GetNativeCell(1), GetNativeCell(2));
	return view_as<int>(true);
}

public int Native_GetCheckpointData(Handle plugin, int numParams)
{
	ArrayList temp = GetCheckpointData(GetNativeCell(1));
	Handle cps = CloneHandle(temp, plugin);
	delete temp;
	return view_as<int>(cps);
}

public int Native_SetCheckpointData(Handle plugin, int numParams)
{
	if (BlockedExternallyCalledTimerNative(plugin, GetNativeCell(1)))
	{
		return view_as<int>(false);
	}
	return SetCheckpointData(GetNativeCell(1), view_as<ArrayList>(GetNativeCell(2)), GetNativeCell(3));
}

public int Native_GetUndoTeleportData(Handle plugin, int numParams)
{
	ArrayList temp = GetUndoTeleportData(GetNativeCell(1));
	Handle utd = CloneHandle(temp, plugin);
	delete temp;
	return view_as<int>(utd);
}

public int Native_SetUndoTeleportData(Handle plugin, int numParams)
{
	if (BlockedExternallyCalledTimerNative(plugin, GetNativeCell(1)))
	{
		return view_as<int>(false);
	}
	return SetUndoTeleportData(GetNativeCell(1), view_as<ArrayList>(GetNativeCell(2)), GetNativeCell(3));
}

public int Native_GetTeleportCount(Handle plugin, int numParams)
{
	return GetTeleportCount(GetNativeCell(1));
}

public int Native_SetTeleportCount(Handle plugin, int numParams)
{
	if (BlockedExternallyCalledTimerNative(plugin, GetNativeCell(1)))
	{
		return view_as<int>(false);
	}
	
	SetTeleportCount(GetNativeCell(1), GetNativeCell(2));
	return view_as<int>(true);
}

public int Native_RegisterOption(Handle plugin, int numParams)
{
	char name[GOKZ_OPTION_MAX_NAME_LENGTH];
	GetNativeString(1, name, sizeof(name));
	char description[255];
	GetNativeString(2, description, sizeof(description));
	return view_as<int>(RegisterOption(name, description, GetNativeCell(3), GetNativeCell(4), GetNativeCell(5), GetNativeCell(6)));
}

public int Native_GetOptionProp(Handle plugin, int numParams)
{
	char option[GOKZ_OPTION_MAX_NAME_LENGTH];
	GetNativeString(1, option, sizeof(option));
	OptionProp prop = GetNativeCell(2);
	any value = GetOptionProp(option, prop);
	
	// Return clone of Handle if called by another plugin
	if (prop == OptionProp_Cookie && plugin != gH_ThisPlugin)
	{
		value = CloneHandle(value, plugin);
	}
	
	return value;
}

public int Native_SetOptionProp(Handle plugin, int numParams)
{
	char option[GOKZ_OPTION_MAX_NAME_LENGTH];
	GetNativeString(1, option, sizeof(option));
	OptionProp prop = GetNativeCell(2);
	return SetOptionProp(option, prop, GetNativeCell(3));
}

public int Native_GetOption(Handle plugin, int numParams)
{
	char option[GOKZ_OPTION_MAX_NAME_LENGTH];
	GetNativeString(2, option, sizeof(option));
	return view_as<int>(GetOption(GetNativeCell(1), option));
}

public int Native_SetOption(Handle plugin, int numParams)
{
	char option[GOKZ_OPTION_MAX_NAME_LENGTH];
	GetNativeString(2, option, sizeof(option));
	return view_as<int>(SetOption(GetNativeCell(1), option, GetNativeCell(3)));
}

public int Native_GetHitPerf(Handle plugin, int numParams)
{
	return view_as<int>(GetGOKZHitPerf(GetNativeCell(1)));
}

public int Native_SetHitPerf(Handle plugin, int numParams)
{
	SetGOKZHitPerf(GetNativeCell(1), view_as<bool>(GetNativeCell(2)));
	return 0;
}

public int Native_GetTakeoffSpeed(Handle plugin, int numParams)
{
	return view_as<int>(GetGOKZTakeoffSpeed(GetNativeCell(1)));
}

public int Native_SetTakeoffSpeed(Handle plugin, int numParams)
{
	SetGOKZTakeoffSpeed(GetNativeCell(1), view_as<float>(GetNativeCell(2)));
	return 0;
}

public int Native_GetValidJump(Handle plugin, int numParams)
{
	return view_as<int>(GetValidJump(GetNativeCell(1)));
}

public int Native_JoinTeam(Handle plugin, int numParams)
{
	JoinTeam(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3), GetNativeCell(4));
	return 0;
}



// =====[ PRIVATE ]=====

static bool BlockedExternallyCalledTimerNative(Handle plugin, int client)
{
	if (plugin != gH_ThisPlugin)
	{
		Action result;
		Call_GOKZ_OnTimerNativeCalledExternally(plugin, client, result);
		if (result != Plugin_Continue)
		{
			return true;
		}
	}
	return false;
} 
