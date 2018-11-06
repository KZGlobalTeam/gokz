void RegisterCommands()
{
	RegConsoleCmd("sm_checkpoint", CommandMakeCheckpoint, "[KZ] Set a checkpoint.");
	RegConsoleCmd("sm_gocheck", CommandTeleportToCheckpoint, "[KZ] Teleport to your current checkpoint.");
	RegConsoleCmd("sm_prev", CommandPrevCheckpoint, "[KZ] Go back a checkpoint.");
	RegConsoleCmd("sm_next", CommandNextCheckpoint, "[KZ] Go forward a checkpoint.");
	RegConsoleCmd("sm_undo", CommandUndoTeleport, "[KZ] Undo teleport.");
	RegConsoleCmd("sm_start", CommandTeleportToStart, "[KZ] Teleport to the start of the map.");
	RegConsoleCmd("sm_restart", CommandTeleportToStart, "[KZ] Teleport to the start of the map.");
	RegConsoleCmd("sm_r", CommandTeleportToStart, "[KZ] Teleport to the start of the map.");
	RegConsoleCmd("sm_setstartpos", CommandSetStartPos, "[KZ] Set your current position as your custom start position.");
	RegConsoleCmd("sm_ssp", CommandSetStartPos, "[KZ] Set your current position as your custom start position.");
	RegConsoleCmd("sm_clearstartpos", CommandClearStartPos, "[KZ] Clear your custom start position.");
	RegConsoleCmd("sm_csp", CommandClearStartPos, "[KZ] Clear your custom start position.");
	RegConsoleCmd("sm_pause", CommandTogglePause, "[KZ] Toggle pausing your timer and stopping you in your position.");
	RegConsoleCmd("sm_resume", CommandTogglePause, "[KZ] Toggle pausing your timer and stopping you in your position.");
	RegConsoleCmd("sm_stop", CommandStopTimer, "[KZ] Stop your timer.");
	RegConsoleCmd("sm_options", CommandOptions, "[KZ] Open the options menu.");
	RegConsoleCmd("sm_autorestart", CommandToggleAutoRestart, "[KZ] Toggle auto restart upon teleporting to start.");
	RegConsoleCmd("sm_nc", CommandToggleNoclip, "[KZ] Toggle noclip.");
	RegConsoleCmd("+noclip", CommandEnableNoclip, "[KZ] Noclip on.");
	RegConsoleCmd("-noclip", CommandDisableNoclip, "[KZ] Noclip off.");
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
}

void AddCommandsListeners()
{
	AddCommandListener(CommandJoinTeam, "jointeam");
	for (int i = 0; i < sizeof(gC_RadioCommands); i++)
	{
		AddCommandListener(CommandBlock, gC_RadioCommands[i]);
	}
}

public Action CommandBlock(int client, const char[] command, int argc)
{
	return Plugin_Handled;
}

public Action CommandJoinTeam(int client, const char[] command, int argc)
{
	char teamString[4];
	GetCmdArgString(teamString, sizeof(teamString));
	int team = StringToInt(teamString);
	JoinTeam(client, team);
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

public Action CommandSetStartPos(int client, int args)
{
	SetCustomStartPosition(client);
	return Plugin_Handled;
}

public Action CommandClearStartPos(int client, int args)
{
	ClearCustomStartPosition(client);
	return Plugin_Handled;
}

public Action CommandTogglePause(int client, int args)
{
	if (GetClientTeam(client) == CS_TEAM_SPECTATOR)
	{
		JoinTeam(client, CS_TEAM_CT);
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

public Action CommandOptions(int client, int args)
{
	DisplayOptionsMenu(client);
	return Plugin_Handled;
}

public Action CommandToggleAutoRestart(int client, int args)
{
	if (GOKZ_GetCoreOption(client, Option_AutoRestart) == AutoRestart_Disabled)
	{
		GOKZ_SetCoreOption(client, Option_AutoRestart, AutoRestart_Enabled);
	}
	else
	{
		GOKZ_SetCoreOption(client, Option_AutoRestart, AutoRestart_Disabled);
	}
	return Plugin_Handled;
}

public Action CommandToggleNoclip(int client, int args)
{
	ToggleNoclip(client);
	return Plugin_Handled;
}

public Action CommandEnableNoclip(int client, int args)
{
	if (IsPlayerAlive(client))
	{
		Movement_SetMoveType(client, MOVETYPE_NOCLIP);
	}
	return Plugin_Handled;
}

public Action CommandDisableNoclip(int client, int args)
{
	if (IsPlayerAlive(client))
	{
		Movement_SetMoveType(client, MOVETYPE_WALK);
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



// =====[ PRIVATE ]=====

static void SwitchToModeIfAvailable(int client, int mode)
{
	if (!GOKZ_GetModeLoaded(mode))
	{
		GOKZ_PrintToChat(client, true, "%t", "Mode Not Available", gC_ModeNames[mode]);
	}
	else
	{
		GOKZ_SetCoreOption(client, Option_Mode, mode);
	}
} 