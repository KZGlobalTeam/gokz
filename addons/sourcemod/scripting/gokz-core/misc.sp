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
	if (IsPlayerAlive(client))
	{
		Movement_SetMovetype(client, MOVETYPE_NOCLIP);
		GOKZ_StopTimer(client);
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
		GOKZ_StopTimer(client);
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

void OnSetModel_PlayerCollision(int client)
{
	// Fix custom models temporarily changing player collisions
	SetEntPropVector(client, Prop_Data, "m_vecMins", PLAYER_MINS);
	if (GetEntityFlags(client) & FL_DUCKING != 0)
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
	// After OnClientPutInServer, player is moved to the origin of a point_viewcontrol entity.
	// We need to wait one tick before assign the player's team and teleport them to a valid spawn.
	if (!IsFakeClient(client))
	{
		RequestFrame(AutoJoinTeam, client);
	}
	hasSavedPosition[client] = false;
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

void OnStopTouchGround_ValidJump(int client, bool jumped, bool ladderJump, bool jumpbug)
{
	if (Movement_GetMovetype(client) == MOVETYPE_WALK)
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
	if (oldMovetype == MOVETYPE_LADDER && newMovetype == MOVETYPE_WALK) // Ladderjump
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

static void AutoJoinTeam(int client)
{
	int team = GetRandomInt(CS_TEAM_T, CS_TEAM_CT);
	JoinTeam(client, team, false);
}

// =====[ BUTTONS ]=====

void OnClientPreThinkPost_UseButtons(int client)
{
	if (GetEntProp(client, Prop_Data, "m_afButtonPressed") & IN_USE)
	{
		int entity = FindUseEntity(client);
		if (entity != -1)
		{
			AcceptEntityInput(entity, "Use", client, client, 1);
		}
	}
}

static int FindUseEntity(int client)
{
	float fwd[3];
	float angles[3];
	GetClientEyeAngles(client, angles);
	GetAngleVectors(angles, fwd, NULL_VECTOR, NULL_VECTOR);

	Handle trace;

	float eyeOrigin[3];
	GetClientEyePosition(client, eyeOrigin);
	int useableContents = (MASK_NPCSOLID_BRUSHONLY | MASK_OPAQUE_AND_NPCS) & ~CONTENTS_OPAQUE;

	float endpos[3];

	// Check if +use trace collide with a player first, so we don't activate any button twice
	trace = TR_TraceRayFilterEx(eyeOrigin, angles, useableContents, RayType_Infinite, TRFOtherPlayersOnly, client);
	if (TR_DidHit(trace))
	{
		int ent = TR_GetEntityIndex(trace);
		if (ent < 1 || ent > MaxClients)
		{
			return -1;
		}
		// Search for a button behind it.
		trace = TR_TraceRayFilterEx(eyeOrigin, angles, useableContents, RayType_Infinite, TraceEntityFilterPlayers);
		if (TR_DidHit(trace))
		{
			char buffer[20];
			ent = TR_GetEntityIndex(trace);
			// Make sure that it is a button, and this button activates when pressed.
			// If it is not a button, check its parent to see if it is a button.
			bool isButton;
			while (ent != -1)
			{
				GetEntityClassname(ent, buffer, sizeof(buffer));
				if (StrEqual("func_button", buffer, false) && GetEntProp(ent, Prop_Data, "m_spawnflags") & SF_BUTTON_USE_ACTIVATES)
				{
					isButton = true;
					break;
				}
				else
				{
					ent = GetEntPropEnt(ent, Prop_Data, "m_hMoveParent");
				}
			}
			if (isButton)
			{
				TR_GetEndPosition(endpos, trace);
				float delta[3];
				for (int i = 0; i < 2; i++)
				{
					delta[i] = endpos[i] - eyeOrigin[i];
				}
				// Z distance is treated differently.
				float m_vecMins[3];
				float m_vecMaxs[3];
				float m_vecOrigin[3];
				GetEntPropVector(ent, Prop_Send, "m_vecOrigin", m_vecOrigin);
				GetEntPropVector(ent, Prop_Send, "m_vecMins", m_vecMins);
				GetEntPropVector(ent, Prop_Send, "m_vecMaxs", m_vecMaxs);

				delta[2] = IntervalDistance(endpos[2], m_vecOrigin[2] + m_vecMins[2], m_vecOrigin[2] + m_vecMaxs[2]);
				if (GetVectorLength(delta) < 80.0)
				{
					return ent;
				}
			}
		}
	}
	// This is 1.11 only.
	/*
	float nearestPoint[3];
	float nearestDist = FLOAT_MAX;
	ArrayList entities;
	TR_EnumerateEntitiesSphere(eyeOrigin, 80.0, 0, AddEntities, entities);
	for (int i = 0; i < entities.Length; i++)
	{
		char buffer[64];
		int ent = entities.Get(i);
		GetEntityClassname(ent, buffer, sizeof(buffer));
		if (StrEqual("func_button", buffer, false) && GetEntProp(entity, Prop_Data, "m_spawnflags") & SF_BUTTON_USE_ACTIVATES)
		{
			float point[3];
			CalcNearestPoint(ent, eyeOrigin, point);
						
			float dir[3];
			for (int j = 0; j < 3; j++)
			{
				dir[j] = point[j] - eyeOrigin[2];
			}

			float minimumDot = GetEntPropFloat(ent, Prop_Send, "m_flUseLookAtAngle");
			float dot = GetVectorDotProduct(dir, fwd);
			if (dot < minimumDot)
			{
				continue;
			}

			float dist = CalcDistanceToLine(point, eyeOrigin, fwd);
			if (dist < nearestDist)
			{
				trace = TR_TraceRayFilterEx(eyeOrigin, point, useableContents, RayType_EndPoint, TraceEntityFilterPlayers);
				if (TR_GetFraction(trace) == 1.0 || TR_GetEntityIndex(trace) == ent)
				{
					CopyVector(point, nearestPoint);
					entity = ent;
					nearestDist = dist;
				}
			}
		}
	}
	// We found the closest button, but we still need to check if there is a player in front of it or not.
	// In the case that there isn't a player inbetween, we don't return the entity index, because that button will be pressed by the game function anyway.
	// If there is, we will press two buttons at once, the "right" button found by this function and the "wrong" button that we only happen to press because
	// there is a player in the way.
	
	trace = TR_TraceRayFilterEx(eyeOrigin, nearestPoint, useableContents, RayType_EndPoint, TRFOtherPlayersOnly);
	if (TR_DidHit(trace))
	{
		return -1;
	}
	*/
	return -1; 
}

public bool AddEntities(int entity, ArrayList entities)
{
	entities.Push(entity);
	return true;
}

static float IntervalDistance(float x, float x0, float x1)
{
	if (x0 > x1)
	{
		float tmp = x0;
		x0 = x1;
		x1 = tmp;
	}
	if (x < x0)
	{
		return x0 - x;
	}
	else if (x > x1)
	{
		return x - x1;
	}
	return 0.0;
}
// TraceRay filter for other players exclusively.
public bool TRFOtherPlayersOnly(int entity, int contentmask, int client)
{
	return (0 < entity <= MaxClients) && (entity != client);
}
