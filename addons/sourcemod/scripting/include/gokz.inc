/*
	GOKZ General Include

	Website: https://bitbucket.org/kztimerglobalteam/gokz
*/

#if defined _gokz_included_
#endinput
#endif
#define _gokz_included_

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

#define GOKZ_UPDATER_BASE_URL "http://updater.gokz.org/v2/"
#define GOKZ_COLLISION_GROUP_STANDARD 2
#define GOKZ_COLLISION_GROUP_NOTRIGGER 1
#define GOKZ_TP_FREEZE_TICKS 5
#define EPSILON 0.000001
#define PI 3.14159265359
#define SPEED_NORMAL 250.0
#define SPEED_NO_WEAPON 260.0



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
 * immediately and also after a 0.1 second delay. Automatically
 * makes the player crouch if there is a ceiling above them.
 *
 * @param client		Client index.
 * @param origin		Origin to teleport to.
 * @param angles		Eye angles to set.
 */
stock void TeleportPlayer(int client, const float origin[3], const float angles[3])
{
	Movement_SetOrigin(client, origin);
	Movement_SetEyeAngles(client, angles);
	
	// Duck the player if there is something blocking them from above
	Handle trace = TR_TraceHullFilterEx(origin, 
		origin, 
		view_as<float>( { -16.0, -16.0, 0.0 } ),  // Standing players are 32 x 32 x 72
		view_as<float>( { 16.0, 16.0, 72.0 } ), 
		MASK_PLAYERSOLID, 
		TraceEntityFilterPlayers, 
		client);
	bool ducked = TR_DidHit(trace);
	
	// Prevent noclip exploit
	SetEntProp(client, Prop_Send, "m_CollisionGroup", GOKZ_COLLISION_GROUP_STANDARD);

	// Intelligently hold player still to prevent booster and trigger exploits
	StartHoldStill(client, ducked);
	
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