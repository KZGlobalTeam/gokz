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
	if (IsPlayerAlive(client))
	{
		Movement_SetMovetype(client, MOVETYPE_NOCLIP);
	}
}

void DisableNoclip(int client)
{
	if (IsPlayerAlive(client) && Movement_GetMovetype(client) == MOVETYPE_NOCLIP)
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
	if (IsPlayerAlive(client))
	{
		Movement_SetMovetype(client, MOVETYPE_NOCLIP);
		SetEntProp(client, Prop_Send, "m_CollisionGroup", GOKZ_COLLISION_GROUP_NOTRIGGER);
	}
}

void DisableNoclipNotrigger(int client)
{
	if (IsPlayerAlive(client) && Movement_GetMovetype(client) == MOVETYPE_NOCLIP)
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



// =====[ PLAYER COLLISION ]=====

void OnPlayerSpawn_PlayerCollision(int client)
{
	// Let players go through other players
	SetEntProp(client, Prop_Send, "m_CollisionGroup", GOKZ_COLLISION_GROUP_STANDARD);
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
static MoveType specMovetype[MAXPLAYERS + 1];

void OnClientPutInServer_JoinTeam(int client)
{
	hasSavedPosition[client] = false;
	specMovetype[client] = MOVETYPE_WALK;
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
		player.GetOrigin(savedOrigin[client]);
		player.GetEyeAngles(savedAngles[client]);
		savedOnLadder[client] = player.Movetype == MOVETYPE_LADDER;
		hasSavedPosition[client] = true;
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
		}
		hasSavedPosition[client] = false;
		Call_GOKZ_OnJoinTeam(client, newTeam);
	}
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
	if (Movement_GetMovetype(client) == MOVETYPE_WALK)
	{
		validJump[client] = true;
		Call_GOKZ_OnJumpValidated(client, jumped, false);
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
	if (oldMovetype == MOVETYPE_LADDER && newMovetype == MOVETYPE_WALK) // Ladderjump
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
