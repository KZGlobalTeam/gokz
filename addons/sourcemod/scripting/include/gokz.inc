/*
	GOKZ General Include

	Website: https://bitbucket.org/kztimerglobalteam/gokz
*/

#if defined _gokz_included_
#endinput
#endif
#define _gokz_included_
#include <cstrike>
#include <movement>

#include <gokz/version>



// =====[ ENUMS ]=====

enum ObsMode
{
	ObsMode_None = 0,  // Not in spectator mode
	ObsMode_DeathCam,  // Special mode for death cam animation
	ObsMode_FreezeCam,  // Zooms to a target, and freeze-frames on them
	ObsMode_Fixed,  // View from a fixed camera position
	ObsMode_InEye,  // Follow a player in first person view
	ObsMode_Chase,  // Follow a player in third person view
	ObsMode_Roaming // Free roaming
};



// =====[ CONSTANTS ]=====

#define GOKZ_SOURCE_URL "https://github.com/KZGlobalTeam/gokz"
#define GOKZ_UPDATER_BASE_URL "http://updater.gokz.org/v2/"
#define GOKZ_COLLISION_GROUP_STANDARD 2
#define GOKZ_COLLISION_GROUP_NOTRIGGER 1
#define GOKZ_TP_FREEZE_TICKS 5
#define EPSILON 0.000001
#define PI 3.14159265359
#define SPEED_NORMAL 250.0
#define SPEED_NO_WEAPON 260.0
#define IGNORE_JUMP_TIME 0.2
stock float PLAYER_MINS[3] = {-16.0, -16.0, 0.0};
stock float PLAYER_MAXS[3] = {16.0, 16.0, 72.0};
stock float PLAYER_MAXS_DUCKED[3] = {16.0, 16.0, 54.0};



// =====[ STOCKS ]=====

/**
 * Represents a time float as a string e.g. 01:23.45.
 *
 * @param time			Time in seconds.
 * @param precise		Whether to include fractional seconds.
 * @return				String representation of time.
 */
stock char[] GOKZ_FormatTime(float time, bool precise = true)
{
	char formattedTime[12];

	int roundedTime = RoundFloat(time * 100); // Time rounded to number of centiseconds

	int centiseconds = roundedTime % 100;
	roundedTime = (roundedTime - centiseconds) / 100;
	int seconds = roundedTime % 60;
	roundedTime = (roundedTime - seconds) / 60;
	int minutes = roundedTime % 60;
	roundedTime = (roundedTime - minutes) / 60;
	int hours = roundedTime;

	if (hours == 0)
	{
		if (precise)
		{
			FormatEx(formattedTime, sizeof(formattedTime), "%02d:%02d.%02d", minutes, seconds, centiseconds);
		}
		else
		{
			FormatEx(formattedTime, sizeof(formattedTime), "%d:%02d", minutes, seconds);
		}
	}
	else
	{
		if (precise)
		{
			FormatEx(formattedTime, sizeof(formattedTime), "%d:%02d:%02d.%02d", hours, minutes, seconds, centiseconds);
		}
		else
		{
			FormatEx(formattedTime, sizeof(formattedTime), "%d:%02d:%02d", hours, minutes, seconds);
		}
	}
	return formattedTime;
}

/**
 * Checks if the value is a valid client entity index, if they are in-game and not GOTV.
 *
 * @param client		Client index.
 * @return				Whether client is valid.
 */
stock bool IsValidClient(int client)
{
	return client >= 1 && client <= MaxClients && IsClientInGame(client) && !IsClientSourceTV(client);
}

/**
 * Returns the greater of two float values.
 *
 * @param value1		First value.
 * @param value2		Second value.
 * @return				Greatest value.
 */
stock float FloatMax(float value1, float value2)
{
	if (value1 >= value2)
	{
		return value1;
	}
	return value2;
}

/**
 * Returns the lesser of two float values.
 *
 * @param value1		First value.
 * @param value2		Second value.
 * @return				Lesser value.
 */
stock float FloatMin(float value1, float value2)
{
	if (value1 <= value2)
	{
		return value1;
	}
	return value2;
}

/**
 * Clamp a float value between an upper and lower bound.
 *
 * @param value			Preferred value.
 * @param min			Minimum value.
 * @param max			Maximum value.
 * @return				The closest value to the preferred value.
 */
stock float FloatClamp(float value, float min, float max)
{
	if (value >= max)
	{
		return max;
	}
	if (value <= min)
	{
		return min;
	}
	return value;
}


/**
 * Returns the greater of two int values.
 *
 * @param value1		First value.
 * @param value2		Second value.
 * @return				Greatest value.
 */
stock int IntMax(int value1, int value2)
{
	if (value1 >= value2)
	{
		return value1;
	}
	return value2;
}

/**
 * Returns the lesser of two int values.
 *
 * @param value1		First value.
 * @param value2		Second value.
 * @return				Lesser value.
 */
stock int IntMin(int value1, int value2)
{
	if (value1 <= value2)
	{
		return value1;
	}
	return value2;
}

/**
 * Rounds a float to the nearest specified power of 10.
 *
 * @param value			Value to round.
 * @param power			Power of 10 to round to.
 * @return				Rounded value.
 */
stock float RoundToPowerOfTen(float value, int power)
{
	float pow = Pow(10.0, float(power));
	return RoundFloat(value / pow) * pow;
}

/**
 * Sets all characters in a string to lower case.
 *
 * @param input			Input string.
 * @param output		Output buffer.
 * @param size			Maximum size of output.
 */
stock void String_ToLower(const char[] input, char[] output, int size)
{
	size--;
	int i = 0;
	while (input[i] != '\0' && i < size)
	{
		output[i] = CharToLower(input[i]);
		i++;
	}
	output[i] = '\0';
}

/**
 * Gets the client's observer mode.
 *
 * @param client		Client index.
 * @return				Current observer mode.
 */
stock ObsMode GetObserverMode(int client)
{
	return view_as<ObsMode>(GetEntProp(client, Prop_Send, "m_iObserverMode"));
}

/**
 * Gets the player a client is spectating.
 *
 * @param client		Client index.
 * @return				Client index of target, or -1 if not spectating anyone.
 */
stock int GetObserverTarget(int client)
{
	if (!IsValidClient(client))
	{
		return -1;
	}
	ObsMode mode = GetObserverMode(client);
	if (mode == ObsMode_InEye || mode == ObsMode_Chase)
	{
		return GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
	}
	return -1;
}

/**
 * Emits a sound to other players that are spectating the client.
 *
 * @param client		Client being spectated.
 * @param sound			Sound to play.
 */
stock void EmitSoundToClientSpectators(int client, const char[] sound)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && GetObserverTarget(i) == client)
		{
			EmitSoundToClient(i, sound);
		}
	}
}

/**
 * Calculates the lowest angle from angle A to angle B.
 * Input and result angles are between -180 and 180.
 *
 * @param angleA		Angle A.
 * @param angleB		Angle B.
 * @return				Delta angle.
 */
stock float CalcDeltaAngle(float angleA, float angleB)
{
	float difference = angleB - angleA;

	if (difference > 180.0)
	{
		difference = difference - 360.0;
	}
	else if (difference <= -180.0)
	{
		difference = difference + 360.0;
	}

	return difference;
}

/**
 * Strips all color control characters in a string.
 * The Output buffer can be the same as the input buffer.
 * Original code by Psychonic, thanks.
 * Source: smlib
 *
 * @param input				Input String.
 * @param output			Output String.
 * @param size				Max Size of the Output string
 */
stock void Color_StripFromChatText(const char[] input, char[] output, int size)
{
	int x = 0;
	for (int i = 0; input[i] != '\0'; i++) {

		if (x + 1 == size)
		{
			break;
		}

		int character = input[i];

		if (character > 0x08)
		{
			output[x++] = character;
		}
	}

	output[x] = '\0';
}

/**
 * Returns an integer as a string.
 *
 * @param num				Integer to stringify.
 * @return					Integer as a string.
 */
stock char[] IntToStringEx(int num)
{
	char string[12];
	IntToString(num, string, sizeof(string));
	return string;
}

/**
 * Returns a float as a string.
 *
 * @param num				Float to stringify.
 * @return					Float as a string.
 */
stock char[] FloatToStringEx(float num)
{
	char string[32];
	FloatToString(num, string, sizeof(string));
	return string;
}

/**
 * Increment an index, looping back to 0 if the max value is reached.
 *
 * @param index			Current index.
 * @param buffer		Max value of index.
 * @return				Current index incremented, or 0 if max value is reached.
 */
stock int NextIndex(int index, int max)
{
	index++;
	if (index == max)
	{
		return 0;
	}
	return index;
}

/**
 * Reorders an array with current index at the front, and previous
 * values after, including looping back to the end after reaching
 * the start of the array.
 *
 * @param input			Array to reorder.
 * @param inputSize		Size of input array.
 * @param buffer		Output buffer.
 * @param bufferSize	Size of buffer.
 * @param index			Index of current/most recent value of input array.
 */
stock void SortByRecent(const int[] input, int inputSize, int[] buffer, int bufferSize, int index)
{
	int reorderedIndex = 0;
	for (int i = index; reorderedIndex < bufferSize && i >= 0; i--)
	{
		buffer[reorderedIndex] = input[i];
		reorderedIndex++;
	}
	for (int i = inputSize - 1; reorderedIndex < bufferSize && i > index; i--)
	{
		buffer[reorderedIndex] = input[i];
		reorderedIndex++;
	}
}

/**
 * Returns the Steam account ID for a given SteamID2.
 * Checks for invalid input are not very extensive.
 *
 * @param steamID2		SteamID2 to convert.
 * @return				Steam account ID, or -1 if invalid.
 */
stock int Steam2ToSteamAccountID(const char[] steamID2)
{
	char pieces[3][16];
	if (ExplodeString(steamID2, ":", pieces, sizeof(pieces), sizeof(pieces[])) != 3)
	{
		return -1;
	}

	int IDNumberPart1 = StringToInt(pieces[1]);
	int IDNumberPart2 = StringToInt(pieces[2]);
	if (pieces[1][0] != '0' && IDNumberPart1 == 0 || IDNumberPart1 != 0 && IDNumberPart1 != 1 || IDNumberPart2 <= 0)
	{
		return -1;
	}

	return IDNumberPart1 + (IDNumberPart2 << 1);
}

/**
 * Teleports a player and removes their velocity and base velocity
 * immediately and also every tick for the next 5 ticks. Automatically
 * makes the player crouch if there is a ceiling above them.
 *
 * @param client		Client index.
 * @param origin		Origin to teleport to.
 * @param angles		Eye angles to set.
 */
stock void TeleportPlayer(int client, const float origin[3], const float angles[3], bool setAngles = true, bool holdStill = true)
{
	// Clear the player's parent before teleporting to fix being
	// teleported into seemingly random places if the player has a parent.
	AcceptEntityInput(client, "ClearParent");

	Movement_SetOrigin(client, origin);
	if (setAngles)
	{
		// NOTE: changing angles with TeleportEntity can fail due to packet loss!!!
		// (Movement_SetEyeAngles is a thin wrapper of TeleportEntity)
		Movement_SetEyeAngles(client, angles);
	}
	// Duck the player if there is something blocking them from above
	Handle trace = TR_TraceHullFilterEx(origin,
		origin,
		view_as<float>( { -16.0, -16.0, 0.0 } ),  // Standing players are 32 x 32 x 72
		view_as<float>( { 16.0, 16.0, 72.0 } ),
		MASK_PLAYERSOLID,
		TraceEntityFilterPlayers,
		client);
	bool ducked = TR_DidHit(trace);

	if (holdStill)
	{
		// Prevent noclip exploit
		SetEntProp(client, Prop_Send, "m_CollisionGroup", GOKZ_COLLISION_GROUP_STANDARD);

		// Intelligently hold player still to prevent booster and trigger exploits
		StartHoldStill(client, ducked);
	}
	else if (ducked)
	{
		ForcePlayerDuck(client);
	}

	delete trace;
}

static void StartHoldStill(int client, bool ducked)
{
	DataPack data = new DataPack();
	data.WriteCell(GetClientUserId(client));
	data.WriteCell(0); // tick counter
	data.WriteCell(GOKZ_TP_FREEZE_TICKS); // number of ticks to hold still
	data.WriteCell(ducked);
	ContinueHoldStill(data);
}

public void ContinueHoldStill(DataPack data)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	int ticks = data.ReadCell();
	int tickCount = data.ReadCell();
	bool ducked = data.ReadCell();
	delete data;

	if (!IsValidClient(client))
	{
		return;
	}

	if (ticks < tickCount)
	{
		Movement_SetVelocity(client, view_as<float>( { 0.0, 0.0, 0.0 } ));
		Movement_SetBaseVelocity(client, view_as<float>( { 0.0, 0.0, 0.0 } ));
		Movement_SetGravity(client, 1.0);

		// Don't drop the player off of ladders.
		// The game will automatically change the movetype back to MOVETYPE_WALK if it can't find a ladder.
		// Don't change the movetype if it's currently MOVETYPE_NONE, as that means the player is paused.
		if (Movement_GetMovetype(client) != MOVETYPE_NONE)
		{
			Movement_SetMovetype(client, MOVETYPE_LADDER);
		}

		// Prevent noclip exploit
		SetEntProp(client, Prop_Send, "m_CollisionGroup", GOKZ_COLLISION_GROUP_STANDARD);

		// Force duck on player and make sure that the player can't trigger triggers above them.
		// they can still trigger triggers even when we force ducking.
		if (ducked)
		{
			ForcePlayerDuck(client);

			if (ticks < tickCount - 1)
			{
				// Don't trigger triggers
				SetEntProp(client, Prop_Send, "m_CollisionGroup", GOKZ_COLLISION_GROUP_NOTRIGGER);
			}
			else
			{
				// Let the player trigger triggers on the last tick
				SetEntProp(client, Prop_Send, "m_CollisionGroup", GOKZ_COLLISION_GROUP_STANDARD);
			}
		}

		++ticks;
		data = new DataPack();
		data.WriteCell(GetClientUserId(client));
		data.WriteCell(ticks);
		data.WriteCell(tickCount);
		data.WriteCell(ducked);
		RequestFrame(ContinueHoldStill, data);
	}
}

/**
 * Forces the player to instantly duck.
 *
 * @param client		Client index.
 */
stock void ForcePlayerDuck(int client)
{
	// these are both necessary, because on their own the player will sometimes still be in a state that isn't fully ducked.
	SetEntPropFloat(client, Prop_Send, "m_flDuckAmount", 1.0, 0);
	SetEntProp(client, Prop_Send, "m_bDucking", true);
}

/**
 * Returns whether the player is stuck e.g. in a wall after noclipping.
 *
 * @param client		Client index.
 * @return				Whether player is stuck.
 */
stock bool IsPlayerStuck(int client)
{
	float vecMin[3], vecMax[3], vecOrigin[3];

	GetClientMins(client, vecMin);
	GetClientMaxs(client, vecMax);
	GetClientAbsOrigin(client, vecOrigin);

	TR_TraceHullFilter(vecOrigin, vecOrigin, vecMin, vecMax, MASK_PLAYERSOLID, TraceEntityFilterPlayers);
	return TR_DidHit(); // head in wall ?
}

/**
 * Retrieves the absolute origin of an entity.
 *
 * @param entity			Index of the entity.
 * @param result			Entity's origin if successful.
 * @return					Returns true if successful.
 */
stock bool GetEntityAbsOrigin(int entity, float result[3])
{
	if (!IsValidEntity(entity))
	{
		return false;
	}

	if (!HasEntProp(entity, Prop_Data, "m_vecAbsOrigin"))
	{
		return false;
	}

	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", result);
	return true;
}

/**
 * Retrieves the name of an entity.
 *
 * @param entity			Index of the entity.
 * @param buffer			Buffer to store the name.
 * @param maxlength			Maximum length of the buffer.
 * @return					Number of non-null bytes written.
 */
stock int GetEntityName(int entity, char[] buffer, int maxlength)
{
	return GetEntPropString(entity, Prop_Data, "m_iName", buffer, maxlength);
}

/**
 * Finds an entity by name or by name and classname.
 * Taken from smlib https://github.com/bcserv/smlib
 * This can take anywhere from ~0.2% to ~11% of frametime (i5-7600k) in the worst case scenario where
 * every entity which has a name (4096 of them) is iterated over. Your mileage may vary.
 *
 * @param name				Name of the entity to find.
 * @param className			Optional classname to match along with name.
 * @param ignorePlayers		Ignore player entities.
 * @return					Entity index if successful, INVALID_ENT_REFERENCE if not.
 */
stock int GOKZFindEntityByName(const char[] name, const char[] className = "", bool ignorePlayers = false)
{
	int result = INVALID_ENT_REFERENCE;
	if (className[0] == '\0')
	{
		// HACK: Double the limit to get non-networked entities too.
		// https://developer.valvesoftware.com/wiki/Entity_limit
		int realMaxEntities = GetMaxEntities() * 2;
		int startEntity = 1;
		if (ignorePlayers)
		{
			startEntity = MaxClients + 1;
		}
		for (int entity = startEntity; entity < realMaxEntities; entity++)
		{
			if (!IsValidEntity(entity))
			{
				continue;
			}

			char entName[65];
			GetEntityName(entity, entName, sizeof(entName));
			if (StrEqual(entName, name))
			{
				result = entity;
				break;
			}
		}
	}
	else
	{
		int entity = INVALID_ENT_REFERENCE;
		while ((entity = FindEntityByClassname(entity, className)) != INVALID_ENT_REFERENCE)
		{
			char entName[65];
			GetEntityName(entity, entName, sizeof(entName));
			if (StrEqual(entName, name))
			{
				result = entity;
				break;
			}
		}
	}
	return result;
}

/**
 * Gets the current map's display name in lower case.
 *
 * @param buffer			Buffer to store the map name.
 * @param maxlength			Maximum length of buffer.
 */
stock void GetCurrentMapDisplayName(char[] buffer, int maxlength)
{
	char map[PLATFORM_MAX_PATH];
	GetCurrentMap(map, sizeof(map));
	GetMapDisplayName(map, map, sizeof(map));
	String_ToLower(map, buffer, maxlength);
}

/**
 * Gets the current map's file size.
 */
stock int GetCurrentMapFileSize()
{
	char mapBuffer[PLATFORM_MAX_PATH];
	GetCurrentMap(mapBuffer, sizeof(mapBuffer));
	Format(mapBuffer, sizeof(mapBuffer), "maps/%s.bsp", mapBuffer);
	return FileSize(mapBuffer);
}

/**
 * Copies the elements of a source vector to a destination vector.
 *
 * @param src				Source vector.
 * @param dest				Destination vector.
 */
stock void CopyVector(const any src[3], any dest[3])
{
	dest[0] = src[0];
	dest[1] = src[1];
	dest[2] = src[2];
}

/**
 * Returns whether the player is spectating.
 *
 * @param client		Client index.
 */
stock bool IsSpectating(int client)
{
	int team = GetClientTeam(client);
	return team == CS_TEAM_SPECTATOR || team == CS_TEAM_NONE;
}

/**
 * Rotate a vector on an axis.
 *
 * @param vec				Vector to rotate.
 * @param axis				Axis to rotate around.
 * @param theta				Angle in radians.
 * @param result			Rotated vector.
 */
stock void RotateVectorAxis(float vec[3], float axis[3], float theta, float result[3])
{
	float cosTheta = Cosine(theta);
	float sinTheta = Sine(theta);

	float axisVecCross[3];
	GetVectorCrossProduct(axis, vec, axisVecCross);

	for (int i = 0; i < 3; i++)
	{
		result[i] = (vec[i] * cosTheta) + (axisVecCross[i] * sinTheta) + (axis[i] * GetVectorDotProduct(axis, vec)) * (1.0 - cosTheta);
	}
}

/**
 * Rotate a vector by pitch and yaw.
 *
 * @param vec				Vector to rotate.
 * @param pitch				Pitch angle (in degrees).
 * @param yaw				Yaw angle (in degrees).
 * @param result			Rotated vector.
 */
stock void RotateVectorPitchYaw(float vec[3], float pitch, float yaw, float result[3])
{
	if (pitch != 0.0)
	{
		RotateVectorAxis(vec, view_as<float>({0.0, 1.0, 0.0}), DegToRad(pitch), result);
	}
	if (yaw != 0.0)
	{
		RotateVectorAxis(result, view_as<float>({0.0, 0.0, 1.0}), DegToRad(yaw), result);
	}
}

/**
 * Attempts to return a valid spawn location.
 *
 * @param origin			Spawn origin if found.
 * @param angles			Spawn angles if found.
 * @return					Whether a valid spawn point is found.
 */
stock bool GetValidSpawn(float origin[3], float angles[3])
{
	// Return true if the spawn found is truly valid (not in the ground or out of bounds)
	bool foundValidSpawn;
	bool searchCT;
	float spawnOrigin[3];
	float spawnAngles[3];
	int spawnEntity = -1;
	while (!foundValidSpawn)
	{
		if (searchCT)
		{
			spawnEntity = FindEntityByClassname(spawnEntity, "info_player_counterterrorist");
		}
		else
		{
			spawnEntity = FindEntityByClassname(spawnEntity, "info_player_terrorist");
		}

		if (spawnEntity != -1)
		{
			GetEntPropVector(spawnEntity, Prop_Data, "m_vecOrigin", spawnOrigin);
			GetEntPropVector(spawnEntity, Prop_Data, "m_angRotation", spawnAngles);
			if (IsSpawnValid(spawnOrigin))
			{
				origin = spawnOrigin;
				angles = spawnAngles;
				foundValidSpawn = true;
			}
		}
		else if (!searchCT)
		{
			searchCT = true;
		}
		else
		{
			break;
		}
	}
	return foundValidSpawn;
}

/**
 * Check whether a position is a valid spawn location.
 * A spawn location is considered valid if it is in bounds and not stuck inside the ground.
 *
 * @param origin			Origin vector.
 * @return					Whether the origin is a valid spawn location.
 */
stock bool IsSpawnValid(float origin[3])
{
	Handle trace = TR_TraceHullFilterEx(origin, origin, PLAYER_MINS, PLAYER_MAXS, MASK_PLAYERSOLID, TraceEntityFilterPlayers);
	if (!TR_StartSolid(trace) && !TR_AllSolid(trace) && TR_GetFraction(trace) == 1.0)
	{
		delete trace;
		return true;
	}
	delete trace;
	return false;
}

/**
 * Get an entity's origin, angles, its bounding box's center and the distance from the center to its bounding box's edges.
 *
 * @param entity			Index of the entity.
 * @param origin			Entity's origin.
 * @param center			Center of the entity's bounding box.
 * @param angles			Entity's angles.
 * @param distFromCenter	The distance between the center of the entity's bounding box and its edges.
 */
stock void GetEntityPositions(int entity, float origin[3], float center[3], float angles[3], float distFromCenter[3])
{
	int ent = entity;
	float maxs[3], mins[3];
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", origin);
	// Take parent entities into account.
	while (GetEntPropEnt(ent, Prop_Send, "moveparent") != -1)
	{
		ent = GetEntPropEnt(ent, Prop_Send, "moveparent");
		float tempOrigin[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", tempOrigin);
		for (int i = 0; i < 3; i++)
		{
			origin[i] += tempOrigin[i];
		}
	}

	GetEntPropVector(ent, Prop_Data, "m_angRotation", angles);

	GetEntPropVector(ent, Prop_Send, "m_vecMaxs", maxs);
	GetEntPropVector(ent, Prop_Send, "m_vecMins", mins);
	for (int i = 0; i < 3; i++)
	{
		center[i] = origin[i] + (maxs[i] + mins[i]) / 2;
		distFromCenter[i] = (maxs[i] - mins[i]) / 2;
	}
}

/**
 * Find a valid position around a timer.
 *
 * @param entity			Index of the timer entity.
 * @param originDest		Result origin if a valid position is found.
 * @param anglesDest		Result angles if a valid position is found.
 * @return					Whether a valid position is found.
 */
stock bool FindValidPositionAroundTimerEntity(int entity, float originDest[3], float anglesDest[3], bool isButton)
{
	float origin[3], center[3], angles[3], distFromCenter[3];
	GetEntityPositions(entity, origin, center, angles, distFromCenter);
	float extraOffset[3];
	if (isButton) // Test several positions within button press range.
	{
		extraOffset[0] = 32.0;
		extraOffset[1] = 32.0;
		extraOffset[2] = 32.0;
	}
	else // Test positions at the inner surface of the zone.
	{
		extraOffset[0] = -(PLAYER_MAXS[0] - PLAYER_MINS[0]) - 1.03125;
		extraOffset[1] = -(PLAYER_MAXS[1] - PLAYER_MINS[1]) - 1.03125;
		extraOffset[2] = -(PLAYER_MAXS[2] - PLAYER_MINS[2]) - 1.03125;
	}
	if (FindValidPositionAroundCenter(center, distFromCenter, extraOffset, originDest, anglesDest))
	{
		return true;
	}
	// Test the positions right next to the timer button/zones if the tests above fail.
	// This can fail when the timer has a cover brush over it.
	extraOffset[0] = 0.03125;
	extraOffset[1] = 0.03125;
	extraOffset[2] = 0.03125;
	return FindValidPositionAroundCenter(center, distFromCenter, extraOffset, originDest, anglesDest);
}

static bool FindValidPositionAroundCenter(float center[3], float distFromCenter[3], float extraOffset[3], float originDest[3], float anglesDest[3])
{
	float testOrigin[3];
	int x, y;

	for (int i = 0; i < 3; i++)
	{
		// The search starts from the center then outwards to opposite directions.
		x = i == 2 ? -1 : i;
		for (int j = 0; j < 3; j++)
		{
			y = j == 2 ? -1 : j;
			for (int z = -1; z <= 1; z++)
			{
				testOrigin = center;
				testOrigin[0] = testOrigin[0] + (distFromCenter[0] + extraOffset[0]) * x + (PLAYER_MAXS[0] - PLAYER_MINS[0]) * x * 0.5;
				testOrigin[1] = testOrigin[1] + (distFromCenter[1] + extraOffset[1]) * y + (PLAYER_MAXS[1] - PLAYER_MINS[1]) * y * 0.5;
				testOrigin[2] = testOrigin[2] + (distFromCenter[2] + extraOffset[2]) * z + (PLAYER_MAXS[2] - PLAYER_MINS[2]) * z;

				// Check if there's a line of sight towards the zone as well.
				if (IsSpawnValid(testOrigin) && CanSeeBox(testOrigin, center, distFromCenter))
				{
					originDest = testOrigin;
					// Always look towards the center.
					float offsetVector[3];
					offsetVector[0] = -(distFromCenter[0] + extraOffset[0]) * x;
					offsetVector[1] = -(distFromCenter[1] + extraOffset[1]) * y;
					offsetVector[2] = -(distFromCenter[2] + extraOffset[2]) * z;
					GetVectorAngles(offsetVector, anglesDest);
					anglesDest[2] = 0.0; // Roll should always be 0.0
					return true;
				}
			}
		}
	}
	return false;
}

static bool CanSeeBox(float origin[3], float center[3], float distFromCenter[3])
{
	float traceOrigin[3], traceDest[3], mins[3], maxs[3];

	CopyVector(origin, traceOrigin);


	SubtractVectors(center, distFromCenter, mins);
	AddVectors(center, distFromCenter, maxs);

	for (int i = 0; i < 3; i++)
	{
		mins[i] += 0.03125;
		maxs[i] -= 0.03125;
		traceDest[i] = FloatClamp(traceOrigin[i], mins[i], maxs[i]);
	}
	int mask = (MASK_NPCSOLID_BRUSHONLY | MASK_OPAQUE_AND_NPCS) & ~CONTENTS_OPAQUE;
	Handle trace = TR_TraceRayFilterEx(traceOrigin, traceDest, mask, RayType_EndPoint, TraceEntityFilterPlayers);
	if (TR_DidHit(trace))
	{
		float end[3];
		TR_GetEndPosition(end, trace);
		for (int i = 0; i < 3; i++)
		{
			if (end[i] != traceDest[i])
			{
				delete trace;
				return false;
			}
		}
	}
	delete trace;
	return true;
}

/**
 * Gets entity index from the address to an entity.
 *
 * @param pEntity			Entity address.
 * @return					Entity index.
 * @error					Couldn't find offset for m_angRotation, m_vecViewOffset, couldn't confirm offset of m_RefEHandle.
 */
stock int GOKZGetEntityFromAddress(Address pEntity)
{
	static int offs_RefEHandle;
	if (offs_RefEHandle)
	{
		return EntRefToEntIndex(LoadFromAddress(pEntity + view_as<Address>(offs_RefEHandle), NumberType_Int32) | (1 << 31));
	}

	// if we don't have it already, attempt to lookup offset based on SDK information
	// CWorld is derived from CBaseEntity so it should have both offsets
	int offs_angRotation = FindDataMapInfo(0, "m_angRotation"), offs_vecViewOffset = FindDataMapInfo(0, "m_vecViewOffset");
	if (offs_angRotation == -1)
	{
		SetFailState("Could not find offset for ((CBaseEntity) CWorld)::m_angRotation");
	}
	else if (offs_vecViewOffset == -1)
	{
		SetFailState("Could not find offset for ((CBaseEntity) CWorld)::m_vecViewOffset");
	}
	else if ((offs_angRotation + 0x0C) != (offs_vecViewOffset - 0x04))
	{
		char game[32];
		GetGameFolderName(game, sizeof(game));
		SetFailState("Could not confirm offset of CBaseEntity::m_RefEHandle (incorrect assumption for game '%s'?)", game);
	}

	// offset seems right, cache it for the next call
	offs_RefEHandle = offs_angRotation + 0x0C;
	return GOKZGetEntityFromAddress(pEntity);
}

/**
 * Gets client index from CGameMovement class.
 *
 * @param addr							Address of CGameMovement class.
 * @param offsetCGameMovement_player	Offset of CGameMovement::player.
 * @return								Client index.
 * @error								Couldn't find offset for m_angRotation, m_vecViewOffset, couldn't confirm offset of m_RefEHandle.
 */
stock int GOKZGetClientFromGameMovementAddress(Address addr, int offsetCGameMovement_player)
{
	Address playerAddr = view_as<Address>(LoadFromAddress(view_as<Address>(view_as<int>(addr) + offsetCGameMovement_player), NumberType_Int32));
	return GOKZGetEntityFromAddress(playerAddr);
}
