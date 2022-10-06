/*
	Small features that aren't worth splitting into their own file.
*/



// =====[ GOKZ.CFG ]=====

void OnMapStart_KZConfig()
{
	char gokzCfgFullPath[PLATFORM_MAX_PATH];
	FormatEx(gokzCfgFullPath, sizeof(gokzCfgFullPath), "cfg/%s", GOKZ_CFG_SERVER);
	
	if (FileExists(gokzCfgFullPath))
	{
		ServerCommand("exec %s", GOKZ_CFG_SERVER);
	}
	else
	{
		SetFailState("Failed to load file: \"%s\". Check that it exists.", gokzCfgFullPath);
	}
}



// =====[ GODMODE ]=====

void OnPlayerSpawn_GodMode(int client)
{
	// Stop players from taking damage
	SetEntProp(client, Prop_Data, "m_takedamage", 0);
	SetEntityFlags(client, GetEntityFlags(client) | FL_GODMODE);
}



// =====[ NOCLIP ]=====

int noclipReleaseTime[MAXPLAYERS + 1];

void ToggleNoclip(int client)
{
	if (Movement_GetMovetype(client) != MOVETYPE_NOCLIP)
	{
		EnableNoclip(client);
	}
	else
	{
		DisableNoclip(client);
	}
}

void EnableNoclip(int client)
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		if (GOKZ_GetCoreOption(client, Option_Safeguard) > Safeguard_Disabled && GOKZ_GetTimerRunning(client) && GOKZ_GetValidTimer(client))
		{
			GOKZ_PrintToChat(client, true, "%t", "Safeguard - Blocked");
			GOKZ_PlayErrorSound(client);
			return;
		}
		Movement_SetMovetype(client, MOVETYPE_NOCLIP);
		GOKZ_StopTimer(client);
	}
}

void DisableNoclip(int client)
{
	if (IsValidClient(client) && IsPlayerAlive(client) && Movement_GetMovetype(client) == MOVETYPE_NOCLIP)
	{
		noclipReleaseTime[client] = GetGameTickCount();
		Movement_SetMovetype(client, MOVETYPE_WALK);
		SetEntProp(client, Prop_Send, "m_CollisionGroup", GOKZ_COLLISION_GROUP_STANDARD);
		
		// Prevents an exploit that would let you noclip out of start zones
		RemoveNoclipGroundFlag(client);
	}
}

void ToggleNoclipNotrigger(int client)
{
	if (Movement_GetMovetype(client) != MOVETYPE_NOCLIP)
	{
		EnableNoclipNotrigger(client);
	}
	else
	{
		DisableNoclipNotrigger(client);
	}
}

void EnableNoclipNotrigger(int client)
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		if (GOKZ_GetCoreOption(client, Option_Safeguard) > Safeguard_Disabled && GOKZ_GetTimerRunning(client) && GOKZ_GetValidTimer(client))
		{
			GOKZ_PrintToChat(client, true, "%t", "Safeguard - Blocked");
			GOKZ_PlayErrorSound(client);
			return;
		}
		Movement_SetMovetype(client, MOVETYPE_NOCLIP);
		SetEntProp(client, Prop_Send, "m_CollisionGroup", GOKZ_COLLISION_GROUP_NOTRIGGER);
		GOKZ_StopTimer(client);
	}
}

void DisableNoclipNotrigger(int client)
{
	if (IsValidClient(client) && IsPlayerAlive(client) && Movement_GetMovetype(client) == MOVETYPE_NOCLIP)
	{
		noclipReleaseTime[client] = GetGameTickCount();
		Movement_SetMovetype(client, MOVETYPE_WALK);
		SetEntProp(client, Prop_Send, "m_CollisionGroup", GOKZ_COLLISION_GROUP_STANDARD);
		
		// Prevents an exploit that would let you noclip out of start zones
		RemoveNoclipGroundFlag(client);
	}
}

void RemoveNoclipGroundFlag(int client)
{
	float startPosition[3], endPosition[3];
	GetClientAbsOrigin(client, startPosition);
	endPosition = startPosition;
	endPosition[2] = startPosition[2] - 2.0;
	Handle trace = TR_TraceHullFilterEx(
		startPosition, 
		endPosition, 
		view_as<float>( { -16.0, -16.0, 0.0 } ),
		view_as<float>( { 16.0, 16.0, 72.0 } ), 
		MASK_PLAYERSOLID, 
		TraceEntityFilterPlayers, 
		client);
	
	if (!TR_DidHit(trace))
	{
		SetEntityFlags(client, GetEntityFlags(client) & ~FL_ONGROUND);
	}
	delete trace;
}

bool JustNoclipped(int client)
{
	return GetGameTickCount() - noclipReleaseTime[client] <= GOKZ_TIMER_START_NOCLIP_TICKS;
}

void OnClientPutInServer_Noclip(int client)
{
	noclipReleaseTime[client] = 0;
}

// =====[ TURNBINDS ]=====

int turnbindsLastLeftStart[MAXPLAYERS + 1];
int turnbindsLastRightStart[MAXPLAYERS + 1];
float turnbindsLastValidYaw[MAXPLAYERS + 1];
int turnbindsOldButtons[MAXPLAYERS + 1];

// Ensures that there is a minimum time between starting to turnbind in one direction
// and then starting to turnbind in the other direction
void OnPlayerRunCmd_Turnbinds(int client, int buttons, int tickcount, float angles[3])
{
	if (buttons & IN_LEFT && tickcount < turnbindsLastRightStart[client] + GOKZ_TURNBIND_COOLDOWN)
	{
		angles[1] = turnbindsLastValidYaw[client];
		TeleportEntity(client, NULL_VECTOR, angles, NULL_VECTOR);
		buttons = 0;
	}
	else if (buttons & IN_RIGHT && tickcount < turnbindsLastLeftStart[client] + GOKZ_TURNBIND_COOLDOWN)
	{
		angles[1] = turnbindsLastValidYaw[client];
		TeleportEntity(client, NULL_VECTOR, angles, NULL_VECTOR);
		buttons = 0;
	}
	else
	{
		turnbindsLastValidYaw[client] = angles[1];
		
		if (!(turnbindsOldButtons[client] & IN_LEFT) && (buttons & IN_LEFT))
		{
			turnbindsLastLeftStart[client] = tickcount;
		}
		
		if (!(turnbindsOldButtons[client] & IN_RIGHT) && (buttons & IN_RIGHT))
		{
			turnbindsLastRightStart[client] = tickcount;
		}
		
		turnbindsOldButtons[client] = buttons;
	}
}



// =====[ PLAYER COLLISION ]=====

void OnPlayerSpawn_PlayerCollision(int client)
{
	// Let players go through other players
	SetEntProp(client, Prop_Send, "m_CollisionGroup", GOKZ_COLLISION_GROUP_STANDARD);
}

void OnSetModel_PlayerCollision(int client)
{
	// Fix custom models temporarily changing player collisions
	SetEntPropVector(client, Prop_Data, "m_vecMins", PLAYER_MINS);
	if (GetEntityFlags(client) & FL_DUCKING == 0)
	{
		SetEntPropVector(client, Prop_Data, "m_vecMaxs", PLAYER_MAXS);
	}
	else
	{
		SetEntPropVector(client, Prop_Data, "m_vecMaxs", PLAYER_MAXS_DUCKED);
	}
}


// =====[ FORCE SV_FULL_ALLTALK 1 ]=====

void OnRoundStart_ForceAllTalk()
{
	gCV_sv_full_alltalk.BoolValue = true;
}



// =====[ ERROR SOUNDS ]=====

#define SOUND_ERROR "buttons/button10.wav"

void PlayErrorSound(int client)
{
	if (GOKZ_GetCoreOption(client, Option_ErrorSounds) == ErrorSounds_Enabled)
	{
		EmitSoundToClient(client, SOUND_ERROR);
	}
}



// =====[ STOP SOUNDS ]=====

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



// =====[ JOIN TEAM HANDLING ]=====

static bool hasSavedPosition[MAXPLAYERS + 1];
static float savedOrigin[MAXPLAYERS + 1][3];
static float savedAngles[MAXPLAYERS + 1][3];
static bool savedOnLadder[MAXPLAYERS + 1];

void OnClientPutInServer_JoinTeam(int client)
{
	// Automatically put the player on a team if he doesn't choose one.
	// The mp_force_pick_time convar is the built in way to do this, but that obviously
	// does not call GOKZ_JoinTeam which includes a fix for spawning in the void when
	// there is no valid spawns available. 
	CreateTimer(12.0, Timer_ForceJoinTeam, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);

	hasSavedPosition[client] = false;
}

public Action Timer_ForceJoinTeam(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (IsValidClient(client))
    {
        int team = GetClientTeam(client);
        if (team == CS_TEAM_NONE)
        {
            GOKZ_JoinTeam(client, CS_TEAM_SPECTATOR, false);
        }
    }
    return Plugin_Stop;
}

void OnTimerStart_JoinTeam(int client)
{
	hasSavedPosition[client] = false;
}

void JoinTeam(int client, int newTeam, bool restorePos)
{
	KZPlayer player = KZPlayer(client);
	int currentTeam = GetClientTeam(client);

	// Don't use CS_TEAM_NONE
	if (newTeam == CS_TEAM_NONE)
	{
		newTeam = CS_TEAM_SPECTATOR;
	}
	
	if (newTeam == CS_TEAM_SPECTATOR && currentTeam != CS_TEAM_SPECTATOR)
	{
		if (currentTeam != CS_TEAM_NONE)
		{
			player.GetOrigin(savedOrigin[client]);
			player.GetEyeAngles(savedAngles[client]);
			savedOnLadder[client] = player.Movetype == MOVETYPE_LADDER;
			hasSavedPosition[client] = true;
		}

		if (!player.Paused && !player.CanPause)
		{
			player.StopTimer();
		}
		ChangeClientTeam(client, CS_TEAM_SPECTATOR);
		Call_GOKZ_OnJoinTeam(client, newTeam);
	}
	else if (newTeam == CS_TEAM_CT && currentTeam != CS_TEAM_CT
		 || newTeam == CS_TEAM_T && currentTeam != CS_TEAM_T)
	{
		ForcePlayerSuicide(client);
		CS_SwitchTeam(client, newTeam);
		CS_RespawnPlayer(client);
		if (restorePos && hasSavedPosition[client])
		{
			TeleportPlayer(client, savedOrigin[client], savedAngles[client]);
			if (savedOnLadder[client])
			{
				player.Movetype = MOVETYPE_LADDER;
			}
		}
		else
		{
			player.StopTimer();
			// Just joining a team alone can put you into weird invalid spawns. 
			// Need to teleport the player to a valid one.
			float spawnOrigin[3];
			float spawnAngles[3];
			GetValidSpawn(spawnOrigin, spawnAngles);
			TeleportPlayer(client, spawnOrigin, spawnAngles);
		}
		hasSavedPosition[client] = false;
		Call_GOKZ_OnJoinTeam(client, newTeam);
	}
}

void SendFakeTeamEvent(int client)
{
	// Send a fake event to close the team menu
	Event event = CreateEvent("player_team");
	event.SetInt("userid", GetClientUserId(client));
	event.FireToClient(client);
	event.Cancel();
}

// =====[ VALID JUMP TRACKING ]=====

/*
	Valid jump tracking is intended to detect when the player
	has performed a normal jump that hasn't been affected by
	(unexpected) teleports or other cases that may result in
	the player becoming airborne, such as spawning.
	
	There are ways to trick the plugin, but it is rather
	unlikely to happen during normal gameplay.
*/

static bool validJump[MAXPLAYERS + 1];
static float validJumpTeleportOrigin[MAXPLAYERS + 1][3];
static int lastInvalidatedTick[MAXPLAYERS + 1];
bool GetValidJump(int client)
{
	return validJump[client];
}

static void InvalidateJump(int client)
{
	lastInvalidatedTick[client] = GetGameTickCount();
	if (validJump[client])
	{
		validJump[client] = false;
		Call_GOKZ_OnJumpInvalidated(client);
	}
}

void OnStopTouchGround_ValidJump(int client, bool jumped, bool ladderJump, bool jumpbug)
{
	if (Movement_GetMovetype(client) == MOVETYPE_WALK && lastInvalidatedTick[client] != GetGameTickCount())
	{
		validJump[client] = true;
		Call_GOKZ_OnJumpValidated(client, jumped, ladderJump, jumpbug);
	}
	else
	{
		InvalidateJump(client);
	}
}

void OnPlayerRunCmdPost_ValidJump(int client)
{
	if (gB_VelocityTeleported[client] || gB_OriginTeleported[client])
	{
		InvalidateJump(client);
	}
}

void OnChangeMovetype_ValidJump(int client, MoveType oldMovetype, MoveType newMovetype)
{
	if (oldMovetype == MOVETYPE_LADDER && newMovetype == MOVETYPE_WALK && lastInvalidatedTick[client] != GetGameTickCount()) // Ladderjump
	{
		validJump[client] = true;
		Call_GOKZ_OnJumpValidated(client, false, true, false);
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
	// That should definitely be out of bounds
	CopyVector({ 40000.0, 40000.0, 40000.0 }, validJumpTeleportOrigin[client]);
	InvalidateJump(client);
}

void OnPlayerDeath_ValidJump(int client)
{
	InvalidateJump(client);
}

void OnValidOriginChange_ValidJump(int client, const float origin[3])
{
	CopyVector(origin, validJumpTeleportOrigin[client]);
}

void OnTeleport_ValidJump(int client)
{
	float origin[3];
	Movement_GetOrigin(client, origin);
	if (gB_OriginTeleported[client] && GetVectorDistance(validJumpTeleportOrigin[client], origin, true) <= EPSILON)
	{
		gB_OriginTeleported[client] = false;
		CopyVector({ 40000.0, 40000.0, 40000.0 }, validJumpTeleportOrigin[client]);
		return;
	}
	
	if (gB_OriginTeleported[client])
	{
		InvalidateJump(client);
		Call_GOKZ_OnTeleport(client);
	}

	if (gB_VelocityTeleported[client])
	{
		InvalidateJump(client);
	}
}



// =====[ FIRST SPAWN ]=====

static bool hasSpawned[MAXPLAYERS + 1];

void OnClientPutInServer_FirstSpawn(int client)
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



// =====[ TIME LIMIT ]=====

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
	return Plugin_Continue;
}



// =====[ COURSE REGISTER ]=====

static bool startRegistered[GOKZ_MAX_COURSES];
static bool endRegistered[GOKZ_MAX_COURSES];
static bool courseRegistered[GOKZ_MAX_COURSES];

bool GetCourseRegistered(int course)
{
	return courseRegistered[course];
}

void RegisterCourseStart(int course)
{
	startRegistered[course] = true;
	TryRegisterCourse(course);
}

void RegisterCourseEnd(int course)
{
	endRegistered[course] = true;
	TryRegisterCourse(course);
}

void OnMapStart_CourseRegister()
{
	for (int course = 0; course < GOKZ_MAX_COURSES; course++)
	{
		courseRegistered[course] = false;
	}
}

static void TryRegisterCourse(int course)
{
	if (!courseRegistered[course] && startRegistered[course] && endRegistered[course])
	{
		courseRegistered[course] = true;
		Call_GOKZ_OnCourseRegistered(course);
	}
} 



// =====[ SPAWN FIXES ]=====

void OnMapStart_FixMissingSpawns()
{
	int tSpawn = FindEntityByClassname(-1, "info_player_terrorist");
	int ctSpawn = FindEntityByClassname(-1, "info_player_counterterrorist");

	if (tSpawn == -1 && ctSpawn == -1)
	{
		LogMessage("Couldn't fix spawns because none exist.");
		return;
	}

	if (tSpawn == -1 || ctSpawn == -1)
	{
		float origin[3], angles[3];
		GetValidSpawn(origin, angles);

		int newSpawn = CreateEntityByName((tSpawn == -1) ? "info_player_terrorist" : "info_player_counterterrorist");
		if (DispatchSpawn(newSpawn))
		{
			TeleportEntity(newSpawn, origin, angles, NULL_VECTOR);
		}
	}
}


// =====[ SAFE MODE ]=====

void ToggleSafeGuard(int client)
{
	GOKZ_SetCoreOption(client, Option_Safeguard, (GOKZ_GetCoreOption(client, Option_Safeguard) + 1) % SAFEGUARD_COUNT);
}

void ToggleProSafeGuard(int client)
{
	if (GOKZ_GetCoreOption(client, Option_Safeguard) == Safeguard_EnabledPRO)
	{
		GOKZ_SetCoreOption(client, Option_Safeguard, Safeguard_Disabled);
	}
	else
	{
		GOKZ_SetCoreOption(client, Option_Safeguard, Safeguard_EnabledPRO);
	}
}