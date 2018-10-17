/*
	Miscellaneous
	
	Small features that aren't worth splitting into their own file.
*/



// =========================  GOKZ.CFG  ========================= //

#define GOKZ_CFG_PATH "sourcemod/gokz/gokz.cfg"

void OnMapStart_KZConfig()
{
	char gokzCfgFullPath[PLATFORM_MAX_PATH];
	FormatEx(gokzCfgFullPath, sizeof(gokzCfgFullPath), "cfg/%s", GOKZ_CFG_PATH);
	
	if (FileExists(gokzCfgFullPath))
	{
		ServerCommand("exec %s", GOKZ_CFG_PATH);
	}
	else
	{
		SetFailState("Failed to load config (%s not found).", gokzCfgFullPath);
	}
}



// =========================  GODMODE  ========================= //

void UpdateGodMode(int client)
{
	// Stop players from taking damage
	SetEntProp(client, Prop_Data, "m_takedamage", 0);
}



// =========================  NOCLIP  ========================= //

void ToggleNoclip(int client)
{
	if (!IsPlayerAlive(client))
	{
		return;
	}
	
	if (Movement_GetMoveType(client) != MOVETYPE_NOCLIP)
	{
		Movement_SetMoveType(client, MOVETYPE_NOCLIP);
	}
	else
	{
		Movement_SetMoveType(client, MOVETYPE_WALK);
	}
}



// =========================  PLAYER COLLISION  ========================= //

void UpdatePlayerCollision(int client)
{
	// Let players go through other players
	SetEntData(client, FindSendPropInfo("CBaseEntity", "m_CollisionGroup"), 2, 4, true);
}



// =========================  HIDE PLAYERS  ========================= //

void SetupClientHidePlayers(int client)
{
	SDKHook(client, SDKHook_SetTransmit, OnSetTransmitClient);
}

public Action OnSetTransmitClient(int entity, int client)
{
	if (GOKZ_GetOption(client, Option_ShowingPlayers) == ShowingPlayers_Disabled
		 && entity != client
		 && entity != GetObserverTarget(client))
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}



// =========================  HIDE WEAPON  ========================= //

void UpdateHideWeapon(int client)
{
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 
		GOKZ_GetOption(client, Option_ShowingWeapon) == ShowingWeapon_Enabled);
}

void OnOptionChanged_HideWeapon(int client, Option option)
{
	if (option == Option_ShowingWeapon)
	{
		UpdateHideWeapon(client);
	}
}



// =========================  FORCE SV_FULL_ALLTALK 1  ========================= //

void OnRoundStart_ForceAllTalk()
{
	gCV_sv_full_alltalk.BoolValue = true;
}



// =========================  SLAY ON END  ========================= //

void OnTimerEnd_SlayOnEnd(int client)
{
	if (GOKZ_GetOption(client, Option_SlayOnEnd) == SlayOnEnd_Enabled)
	{
		CreateTimer(3.0, Timer_SlayPlayer, GetClientUserId(client));
	}
}

public Action Timer_SlayPlayer(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (IsValidClient(client))
	{
		ForcePlayerSuicide(client);
	}
	return Plugin_Continue;
}



// =========================  ERROR SOUNDS  ========================= //

#define SOUND_ERROR "buttons/button10.wav"

void PlayErrorSound(int client)
{
	if (GOKZ_GetOption(client, Option_ErrorSounds) == ErrorSounds_Enabled)
	{
		EmitSoundToClient(client, SOUND_ERROR);
	}
}



// =========================  STOP SOUNDS  ========================= //

void StopSounds(int client)
{
	ClientCommand(client, "snd_playsounds Music.StopAllExceptMusic");
	GOKZ_PrintToChat(client, true, "%t", "Stopped Sounds");
}

Action OnNormalSound_StopSounds(int entity)
{
	char className[20];
	GetEntityClassname(entity, className, sizeof(className));
	if (StrEqual(className, "func_button", false))
	{
		return Plugin_Handled; // No sounds directly from func_button
	}
	return Plugin_Continue;
}



// =========================  PLAYER MODELS  ========================= //

#define PLAYER_MODEL_T "models/player/tm_leet_varianta.mdl"
#define PLAYER_MODEL_CT "models/player/ctm_idf_variantc.mdl"

void UpdatePlayerModel(int client)
{
	if (gCV_gokz_player_models.BoolValue)
	{
		// Do this after a delay so that gloves apply correctly after spawning
		CreateTimer(0.1, Timer_UpdatePlayerModel, GetClientUserId(client));
	}
}

public Action Timer_UpdatePlayerModel(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client) || !IsPlayerAlive(client))
	{
		return;
	}
	
	switch (GetClientTeam(client))
	{
		case CS_TEAM_T:
		{
			SetEntityModel(client, PLAYER_MODEL_T);
		}
		case CS_TEAM_CT:
		{
			SetEntityModel(client, PLAYER_MODEL_CT);
		}
	}
	
	UpdatePlayerModelAlpha(client);
}

void UpdatePlayerModelAlpha(int client)
{
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, _, _, _, gCV_gokz_player_models_alpha.IntValue);
}

void PrecachePlayerModels()
{
	gCV_sv_disable_immunity_alpha.IntValue = 1; // Ensures player transparency works	
	
	PrecacheModel(PLAYER_MODEL_T, true);
	PrecacheModel(PLAYER_MODEL_CT, true);
}



// =========================  PISTOL  ========================= //

static char pistolEntityNames[PISTOL_COUNT][] = 
{
	"weapon_hkp2000", 
	"weapon_glock", 
	"weapon_p250", 
	"weapon_elite", 
	"weapon_deagle", 
	"weapon_cz75a", 
	"weapon_fiveseven", 
	"weapon_tec9", 
	"weapon_revolver", 
	"DISABLED" // Disabled option
};

static int pistolTeams[PISTOL_COUNT] = 
{
	CS_TEAM_CT, 
	CS_TEAM_T, 
	CS_TEAM_NONE, 
	CS_TEAM_NONE, 
	CS_TEAM_NONE, 
	CS_TEAM_NONE, 
	CS_TEAM_CT, 
	CS_TEAM_T, 
	CS_TEAM_NONE, 
	CS_TEAM_NONE // Disabled option
};

void UpdatePistol(int client)
{
	GivePistol(client, GOKZ_GetOption(client, Option_Pistol));
}

void OnOptionChanged_Pistol(int client, Option option)
{
	if (option == Option_Pistol)
	{
		UpdatePistol(client);
	}
}

static void GivePistol(int client, int pistol)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client)
		 || GetClientTeam(client) == CS_TEAM_NONE)
	{
		return;
	}
	
	int playerTeam = GetClientTeam(client);
	bool switchedTeams = false;
	
	// Switch teams to the side that buys that gun so that gun skins load
	if (pistolTeams[pistol] == CS_TEAM_CT && playerTeam != CS_TEAM_CT)
	{
		CS_SwitchTeam(client, CS_TEAM_CT);
		switchedTeams = true;
	}
	else if (pistolTeams[pistol] == CS_TEAM_T && playerTeam != CS_TEAM_T)
	{
		CS_SwitchTeam(client, CS_TEAM_T);
		switchedTeams = true;
	}
	
	// Give the player this pistol (or remove it)
	int currentPistol = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
	if (currentPistol != -1)
	{
		RemovePlayerItem(client, currentPistol);
	}
	
	if (pistol == Pistol_Disabled)
	{
		// Force switch to knife to avoid weird behaviour
		int knife = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
		if (knife != -1)
		{
			EquipPlayerWeapon(client, knife);
		}
	}
	else
	{
		GivePlayerItem(client, pistolEntityNames[pistol]);
	}
	
	// Go back to original team
	if (switchedTeams)
	{
		CS_SwitchTeam(client, playerTeam);
	}
}



// =========================  JOIN TEAM HANDLING  ========================= //

static bool hasSavedPosition[MAXPLAYERS + 1];
static float savedOrigin[MAXPLAYERS + 1][3];
static float savedAngles[MAXPLAYERS + 1][3];
static bool savedOnLadder[MAXPLAYERS + 1];

void SetupClientJoinTeam(int client)
{
	hasSavedPosition[client] = false;
}

void JoinTeam(int client, int newTeam)
{
	KZPlayer player = new KZPlayer(client);
	int currentTeam = GetClientTeam(client);
	
	if (newTeam == CS_TEAM_SPECTATOR && currentTeam != CS_TEAM_SPECTATOR)
	{
		player.GetOrigin(savedOrigin[client]);
		player.GetEyeAngles(savedAngles[client]);
		savedOnLadder[client] = player.moveType == MOVETYPE_LADDER;
		hasSavedPosition[client] = true;
		ChangeClientTeam(client, CS_TEAM_SPECTATOR);
		Call_GOKZ_OnJoinTeam(client, newTeam);
	}
	else if (newTeam == CS_TEAM_CT && currentTeam != CS_TEAM_CT
		 || newTeam == CS_TEAM_T && currentTeam != CS_TEAM_T)
	{
		ForcePlayerSuicide(client);
		CS_SwitchTeam(client, newTeam);
		CS_RespawnPlayer(client);
		if (hasSavedPosition[client])
		{
			player.SetOrigin(savedOrigin[client]);
			player.SetEyeAngles(savedAngles[client]);
			if (savedOnLadder[client])
			{
				player.moveType = MOVETYPE_LADDER;
			}
			hasSavedPosition[client] = false;
		}
		else
		{
			player.StopTimer();
		}
		Call_GOKZ_OnJoinTeam(client, newTeam);
	}
}

void OnTimerStart_JoinTeam(int client)
{
	hasSavedPosition[client] = false;
}



// =========================  VALID JUMP TRACKING  ========================= //

/*
	Valid jump tracking is intended to detect when the player
	has performed a normal jump that hasn't been affected by
	(unexpected) teleports or other cases that may result in
	the player becoming airborne, such as spawning.
	
	There are ways to trick the plugin, but it is rather
	unlikely to happen during normal gameplay.
*/

static bool validJump[MAXPLAYERS + 1];
static bool velocityTeleported[MAXPLAYERS + 1];

bool GetValidJump(int client)
{
	return validJump[client];
}

static void InvalidateJump(int client)
{
	if (validJump[client])
	{
		validJump[client] = false;
		Call_GOKZ_OnJumpInvalidated(client);
	}
}

void OnStopTouchGround_ValidJump(int client, bool jumped)
{
	// Make sure leaving the ground wasn't caused by anything fishy
	if (IsValidStopTouchGround(client))
	{
		validJump[client] = true;
		Call_GOKZ_OnJumpValidated(client, jumped, false);
	}
	else
	{
		InvalidateJump(client);
	}
}

static bool IsValidStopTouchGround(int client)
{
	if (Movement_GetMoveType(client) != MOVETYPE_WALK)
	{
		return false;
	}
	return true;
}

void OnPlayerRunCmd_ValidJump(int client, int cmdnum)
{
	if (velocityTeleported[client] && DidInvalidVelocityTeleport(client, cmdnum))
	{
		InvalidateJump(client);
	}
	velocityTeleported[client] = false;
}

static bool DidInvalidVelocityTeleport(int client, int cmdnum)
{
	// Return whether client didn't just hit a perf
	return !Movement_GetJumped(client)
	 || !GOKZ_GetHitPerf(client)
	 || cmdnum - Movement_GetTakeoffCmdNum(client) > 1;
}

void OnChangeMoveType_ValidJump(int client, MoveType oldMoveType, MoveType newMoveType)
{
	if (oldMoveType == MOVETYPE_LADDER && newMoveType == MOVETYPE_WALK) // Ladderjump
	{
		validJump[client] = true;
		Call_GOKZ_OnJumpValidated(client, false, true);
	}
	else
	{
		InvalidateJump(client);
	}
}

void OnClientDisconnect_ValidJump(int client)
{
	InvalidateJump(client);
}

void OnPlayerSpawn_ValidJump(int client)
{
	InvalidateJump(client);
}

void OnPlayerDeath_ValidJump(int client)
{
	InvalidateJump(client);
}

void OnTeleport_ValidJump(int client, bool originTp, bool velocityTp)
{
	if (originTp)
	{
		InvalidateJump(client);
	}
	if (velocityTp)
	{
		velocityTeleported[client] = true;
	}
}



// =========================  CLAN TAG  ========================= //

void UpdateClanTag(int client)
{
	if (!IsFakeClient(client))
	{
		CS_SetClientClanTag(client, gC_ModeNamesShort[GOKZ_GetOption(client, Option_Mode)]);
	}
}

void OnOptionChanged_ClanTag(int client, Option option)
{
	if (option == Option_Mode)
	{
		UpdateClanTag(client);
	}
}



// =========================  FIRST SPAWN  ========================= //

static bool hasSpawned[MAXPLAYERS + 1];

void SetupClientFirstSpawn(int client)
{
	hasSpawned[client] = false;
}

void OnPlayerSpawn_FirstSpawn(int client)
{
	int team = GetClientTeam(client);
	if (!hasSpawned[client] && (team == CS_TEAM_CT || team == CS_TEAM_T))
	{
		hasSpawned[client] = true;
		Call_GOKZ_OnFirstSpawn(client);
	}
}



// =========================  TIME LIMIT  ========================= //

void OnConfigsExecuted_TimeLimit()
{
	CreateTimer(1.0, Timer_TimeLimit, _, TIMER_REPEAT);
}

public Action Timer_TimeLimit(Handle timer)
{
	int timelimit;
	if (!GetMapTimeLimit(timelimit) || timelimit == 0)
	{
		return Plugin_Continue;
	}
	
	int timeleft;
	// Check for less than -1 in case we miss 0 - ignore -1 because that means infinite time limit
	if (GetMapTimeLeft(timeleft) && (timeleft == 0 || timeleft < -1))
	{
		CreateTimer(5.0, Timer_EndRound); // End the round after a delay or it won't end the map
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action Timer_EndRound(Handle timer)
{
	CS_TerminateRound(1.0, CSRoundEnd_Draw, true);
} 