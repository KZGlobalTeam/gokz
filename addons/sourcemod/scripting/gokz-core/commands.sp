void RegisterCommands()
{
	RegConsoleCmd("sm_options", CommandOptions, "[KZ] Open the options menu.");
	RegConsoleCmd("sm_o", CommandOptions, "[KZ] Open the options menu.");
	RegConsoleCmd("sm_checkpoint", CommandMakeCheckpoint, "[KZ] Set a checkpoint.");
	RegConsoleCmd("sm_gocheck", CommandTeleportToCheckpoint, "[KZ] Teleport to your current checkpoint.");
	RegConsoleCmd("sm_prev", CommandPrevCheckpoint, "[KZ] Go back a checkpoint.");
	RegConsoleCmd("sm_next", CommandNextCheckpoint, "[KZ] Go forward a checkpoint.");
	RegConsoleCmd("sm_undo", CommandUndoTeleport, "[KZ] Undo teleport.");
	RegConsoleCmd("sm_start", CommandTeleportToStart, "[KZ] Teleport to the start.");
	RegConsoleCmd("sm_searchstart", CommandSearchStart, "[KZ] Teleport to the start zone/button of a specified course.");
	RegConsoleCmd("sm_end", CommandTeleportToEnd, "[KZ] Teleport to the end.");
	RegConsoleCmd("sm_restart", CommandTeleportToStart, "[KZ] Teleport to your start position.");
	RegConsoleCmd("sm_r", CommandTeleportToStart, "[KZ] Teleport to your start position.");
	RegConsoleCmd("sm_setstartpos", CommandSetStartPos, "[KZ] Set your custom start position to your current position.");
	RegConsoleCmd("sm_ssp", CommandSetStartPos, "[KZ] Set your custom start position to your current position.");
	RegConsoleCmd("sm_clearstartpos", CommandClearStartPos, "[KZ] Clear your custom start position.");
	RegConsoleCmd("sm_csp", CommandClearStartPos, "[KZ] Clear your custom start position.");
	RegConsoleCmd("sm_main", CommandMain, "[KZ] Teleport to the start of the main course.");
	RegConsoleCmd("sm_m", CommandMain, "[KZ] Teleport to the start of the main course.");
	RegConsoleCmd("sm_bonus", CommandBonus, "[KZ] Teleport to the start of a bonus. Usage: `!bonus <#bonus>");
	RegConsoleCmd("sm_b", CommandBonus, "[KZ] Teleport to the start of a bonus. Usage: `!b <#bonus>");
	RegConsoleCmd("sm_pause", CommandTogglePause, "[KZ] Toggle pausing your timer and stopping you in your position.");
	RegConsoleCmd("sm_resume", CommandTogglePause, "[KZ] Toggle pausing your timer and stopping you in your position.");
	RegConsoleCmd("sm_stop", CommandStopTimer, "[KZ] Stop your timer.");
	RegConsoleCmd("sm_virtualbuttonindicators", CommandToggleVirtualButtonIndicators, "[KZ] Toggle virtual button indicators.");
	RegConsoleCmd("sm_vbi", CommandToggleVirtualButtonIndicators, "[KZ] Toggle virtual button indicators.");
	RegConsoleCmd("sm_virtualbuttons", CommandToggleVirtualButtonsLock, "[KZ] Toggle locking virtual buttons, preventing them from being moved.");
	RegConsoleCmd("sm_vb", CommandToggleVirtualButtonsLock, "[KZ] Toggle locking virtual buttons, preventing them from being moved.");
	RegConsoleCmd("sm_mode", CommandMode, "[KZ] Open the movement mode selection menu.");
	RegConsoleCmd("sm_vanilla", CommandVanilla, "[KZ] Switch to the Vanilla mode.");
	RegConsoleCmd("sm_vnl", CommandVanilla, "[KZ] Switch to the Vanilla mode.");
	RegConsoleCmd("sm_v", CommandVanilla, "[KZ] Switch to the Vanilla mode.");
	RegConsoleCmd("sm_simplekz", CommandSimpleKZ, "[KZ] Switch to the SimpleKZ mode.");
	RegConsoleCmd("sm_skz", CommandSimpleKZ, "[KZ] Switch to the SimpleKZ mode.");
	RegConsoleCmd("sm_s", CommandSimpleKZ, "[KZ] Switch to the SimpleKZ mode.");
	RegConsoleCmd("sm_kztimer", CommandKZTimer, "[KZ] Switch to the KZTimer mode.");
	RegConsoleCmd("sm_kzt", CommandKZTimer, "[KZ] Switch to the KZTimer mode.");
	RegConsoleCmd("sm_k", CommandKZTimer, "[KZ] Switch to the KZTimer mode.");
	RegConsoleCmd("sm_nc", CommandToggleNoclip, "[KZ] Toggle noclip.");
	RegConsoleCmd("+noclip", CommandEnableNoclip, "[KZ] Noclip on.");
	RegConsoleCmd("-noclip", CommandDisableNoclip, "[KZ] Noclip off.");
	RegConsoleCmd("sm_ncnt", CommandToggleNoclipNotrigger, "[KZ] Toggle noclip-notrigger.");
	RegConsoleCmd("+noclipnt", CommandEnableNoclipNotrigger, "[KZ] Noclip-notrigger on.");
	RegConsoleCmd("-noclipnt", CommandDisableNoclipNotrigger, "[KZ] Noclip-notrigger off.");
	RegConsoleCmd("sm_sg", CommandNubSafeGuard, "[KZ] Toggle NUB safeguard.");
	RegConsoleCmd("sm_safe", CommandNubSafeGuard, "[KZ] Toggle NUB safeguard.");
	RegConsoleCmd("sm_safeguard", CommandNubSafeGuard, "[KZ] Toggle NUB safeguard.");
	RegConsoleCmd("sm_pro", CommandProSafeGuard, "[KZ] Toggle PRO safeguard.");
	RegConsoleCmd("kill", CommandKill);
	RegConsoleCmd("killvector", CommandKill);
	RegConsoleCmd("explode", CommandKill);
	RegConsoleCmd("explodevector", CommandKill);
}

void AddCommandsListeners()
{
	AddCommandListener(CommandJoinTeam, "jointeam");
}

bool SwitchToModeIfAvailable(int client, int mode)
{
	if (!GOKZ_GetModeLoaded(mode))
	{
		GOKZ_PrintToChat(client, true, "%t", "Mode Not Available", gC_ModeNames[mode]);
		return false;
	}
	else
	{
		// Safeguard Check
		if (GOKZ_GetCoreOption(client, Option_Safeguard) > Safeguard_Disabled && GOKZ_GetTimerRunning(client) && GOKZ_GetValidTimer(client))
		{
			GOKZ_PrintToChat(client, true, "%t", "Safeguard - Blocked");
			GOKZ_PlayErrorSound(client);
			return false;
		}
		GOKZ_SetCoreOption(client, Option_Mode, mode);
		return true;
	}
}

public Action CommandKill(int client, int args)
{
	if (IsPlayerAlive(client) && GOKZ_GetCoreOption(client, Option_Safeguard) > Safeguard_Disabled && GOKZ_GetTimerRunning(client) && GOKZ_GetValidTimer(client))
	{
		GOKZ_PrintToChat(client, true, "%t", "Safeguard - Blocked");
		GOKZ_PlayErrorSound(client);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action CommandOptions(int client, int args)
{
	DisplayOptionsMenu(client);
	return Plugin_Handled;
}

public Action CommandJoinTeam(int client, const char[] command, int argc)
{
	char teamString[4];
	GetCmdArgString(teamString, sizeof(teamString));
	int team = StringToInt(teamString);
	
	if (team == CS_TEAM_SPECTATOR)
	{
		if (!GOKZ_GetPaused(client) && !GOKZ_GetCanPause(client))
		{
			SendFakeTeamEvent(client);
			return Plugin_Handled;
		}
	}
	else if (IsPlayerAlive(client) && GOKZ_GetCoreOption(client, Option_Safeguard) > Safeguard_Disabled && GOKZ_GetTimerRunning(client) && GOKZ_GetValidTimer(client))
	{
		GOKZ_PrintToChat(client, true, "%t", "Safeguard - Blocked");
		GOKZ_PlayErrorSound(client);
		SendFakeTeamEvent(client);
		return Plugin_Handled;
	}
	GOKZ_JoinTeam(client, team);
	return Plugin_Handled;
}

public Action CommandMakeCheckpoint(int client, int args)
{
	GOKZ_MakeCheckpoint(client);
	return Plugin_Handled;
}

public Action CommandTeleportToCheckpoint(int client, int args)
{
	GOKZ_TeleportToCheckpoint(client);
	return Plugin_Handled;
}

public Action CommandPrevCheckpoint(int client, int args)
{
	GOKZ_PrevCheckpoint(client);
	return Plugin_Handled;
}

public Action CommandNextCheckpoint(int client, int args)
{
	GOKZ_NextCheckpoint(client);
	return Plugin_Handled;
}

public Action CommandUndoTeleport(int client, int args)
{
	GOKZ_UndoTeleport(client);
	return Plugin_Handled;
}

public Action CommandTeleportToStart(int client, int args)
{
	GOKZ_TeleportToStart(client);
	return Plugin_Handled;
}

public Action CommandSearchStart(int client, int args)
{
	if (args == 0)
	{
		GOKZ_TeleportToSearchStart(client, GetCurrentCourse(client));
		return Plugin_Handled;
	}
	else
	{
		char argCourse[4];
		GetCmdArg(1, argCourse, sizeof(argCourse));
		int course = StringToInt(argCourse);
		if (GOKZ_IsValidCourse(course, false))
		{
			GOKZ_TeleportToSearchStart(client, course);
		}
		else if (StrEqual(argCourse, "main", false) || course == 0)
		{
			GOKZ_TeleportToSearchStart(client, 0);
		}
		else 
		{
			GOKZ_PrintToChat(client, true, "%t", "Invalid Course Number", argCourse);
		}
	}
	return Plugin_Handled;
}

public Action CommandTeleportToEnd(int client, int args)
{
	if (args == 0)
	{  
		GOKZ_TeleportToEnd(client, GetCurrentCourse(client));
	}
	else
	{
		char argCourse[4];
		GetCmdArg(1, argCourse, sizeof(argCourse));
		int course = StringToInt(argCourse);
		if (GOKZ_IsValidCourse(course, false))
		{
			GOKZ_TeleportToEnd(client, course);
		}
		else if (StrEqual(argCourse, "main", false) || course == 0)
		{
			GOKZ_TeleportToEnd(client, 0);
		}
		else
		{
			GOKZ_PrintToChat(client, true, "%t", "Invalid Course Number", argCourse);
		}
	}
	return Plugin_Handled;
}

public Action CommandSetStartPos(int client, int args)
{
	SetStartPositionToCurrent(client, StartPositionType_Custom);
	
	GOKZ_PrintToChat(client, true, "%t", "Set Custom Start Position");
	if (GOKZ_GetCoreOption(client, Option_CheckpointSounds) == CheckpointSounds_Enabled)
	{
		GOKZ_EmitSoundToClient(client, GOKZ_SOUND_CHECKPOINT, _, "Set Start Position");
	}
	
	return Plugin_Handled;
}

public Action CommandClearStartPos(int client, int args)
{
	if (ClearCustomStartPosition(client))
	{
		GOKZ_PrintToChat(client, true, "%t", "Cleared Custom Start Position");
	}
	
	return Plugin_Handled;
}

public Action CommandMain(int client, int args)
{
	TeleportToCourseStart(client, 0);
	return Plugin_Handled;
}

public Action CommandBonus(int client, int args)
{
	if (args == 0)
	{  // Go to Bonus 1
		TeleportToCourseStart(client, 1);
	}
	else
	{  // Go to specified Bonus #
		char argBonus[4];
		GetCmdArg(1, argBonus, sizeof(argBonus));
		int bonus = StringToInt(argBonus);
		if (GOKZ_IsValidCourse(bonus, true))
		{
			TeleportToCourseStart(client, bonus);
		}
		else
		{
			GOKZ_PrintToChat(client, true, "%t", "Invalid Bonus Number", argBonus);
		}
	}
	return Plugin_Handled;
}

public Action CommandTogglePause(int client, int args)
{
	if (!IsPlayerAlive(client))
	{
		GOKZ_RespawnPlayer(client);
	}
	else
	{
		TogglePause(client);
	}
	return Plugin_Handled;
}

public Action CommandStopTimer(int client, int args)
{
	if (TimerStop(client))
	{
		GOKZ_PrintToChat(client, true, "%t", "Timer Stopped");
	}
	return Plugin_Handled;
}

public Action CommandToggleVirtualButtonIndicators(int client, int args)
{
	if (GOKZ_GetCoreOption(client, Option_VirtualButtonIndicators) == VirtualButtonIndicators_Disabled)
	{
		GOKZ_SetCoreOption(client, Option_VirtualButtonIndicators, VirtualButtonIndicators_Enabled);
	}
	else
	{
		GOKZ_SetCoreOption(client, Option_VirtualButtonIndicators, VirtualButtonIndicators_Disabled);
	}
	return Plugin_Handled;
}

public Action CommandToggleVirtualButtonsLock(int client, int args)
{
	if (ToggleVirtualButtonsLock(client))
	{
		GOKZ_PrintToChat(client, true, "%t", "Locked Virtual Buttons");
	}
	else
	{
		GOKZ_PrintToChat(client, true, "%t", "Unlocked Virtual Buttons");
	}
	return Plugin_Handled;
}

public Action CommandMode(int client, int args)
{
	DisplayModeMenu(client);
	return Plugin_Handled;
}

public Action CommandVanilla(int client, int args)
{
	SwitchToModeIfAvailable(client, Mode_Vanilla);
	return Plugin_Handled;
}

public Action CommandSimpleKZ(int client, int args)
{
	SwitchToModeIfAvailable(client, Mode_SimpleKZ);
	return Plugin_Handled;
}

public Action CommandKZTimer(int client, int args)
{
	SwitchToModeIfAvailable(client, Mode_KZTimer);
	return Plugin_Handled;
}

public Action CommandToggleNoclip(int client, int args)
{
	ToggleNoclip(client);
	return Plugin_Handled;
}

public Action CommandEnableNoclip(int client, int args)
{
	EnableNoclip(client);
	return Plugin_Handled;
}

public Action CommandDisableNoclip(int client, int args)
{
	DisableNoclip(client);
	return Plugin_Handled;
}

public Action CommandToggleNoclipNotrigger(int client, int args)
{
	ToggleNoclipNotrigger(client);
	return Plugin_Handled;
}

public Action CommandEnableNoclipNotrigger(int client, int args)
{
	EnableNoclipNotrigger(client);
	return Plugin_Handled;
}

public Action CommandDisableNoclipNotrigger(int client, int args)
{
	DisableNoclipNotrigger(client);
	return Plugin_Handled;
}

public Action CommandNubSafeGuard(int client, int args)
{
	ToggleNubSafeGuard(client);
	return Plugin_Handled;
}

public Action CommandProSafeGuard(int client, int args)
{
	ToggleProSafeGuard(client);
	return Plugin_Handled;
}