/* 	
	gokz-racing Plugin Include
	
	Website: https://bitbucket.org/kztimerglobalteam/gokz
*/

#if defined _gokz_racing_included_
#endinput
#endif
#define _gokz_racing_included_



// =====[ ENUMS ]=====

enum RaceInfo:
{
	RaceInfo_ID, 
	RaceInfo_Status, 
	RaceInfo_HostUserID, 
	RaceInfo_FinishedRacerCount, 
	RaceInfo_Type, 
	RaceInfo_Course, 
	RaceInfo_Mode, 
	RaceInfo_CheckpointRule, 
	RaceInfo_CooldownRule,
	RACEINFO_COUNT
};

enum
{
	RaceType_Normal, 
	RaceType_Duel, 
	RACETYPE_COUNT
};

enum
{
	RaceStatus_Pending, 
	RaceStatus_Countdown, 
	RaceStatus_Started, 
	RaceStatus_Aborting, 
	RACESTATUS_COUNT
};

enum
{
	RacerStatus_Available, 
	RacerStatus_Pending, 
	RacerStatus_Accepted, 
	RacerStatus_Racing, 
	RacerStatus_Finished, 
	RacerStatus_Surrendered, 
	RACERSTATUS_COUNT
};

enum
{
	CheckpointRule_None,
	CheckpointRule_Limit,
	CheckpointRule_Cooldown,
	CheckpointRule_Unlimited,
	CHECKPOINTRULE_COUNT
};



// =====[ CONSTANTS ]=====

#define RC_COUNTDOWN_TIME 10.0
#define RC_REQUEST_TIMEOUT_TIME 15.0



// =====[ FORWARDS ]=====

/**
 * Called when a player has finished their race.
 *
 * @param client		Client index.
 * @param raceID		ID of the race.
 * @param place			Final placement in the race.
 */
forward void GOKZ_RC_OnFinish(int client, int raceID, int place);

/**
 * Called when a player has surrendered their race.
 *
 * @param client		Client index.
 * @param raceID		ID of the race.
 */
forward void GOKZ_RC_OnSurrender(int client, int raceID);

/**
 * Called when a player receives a race request.
 *
 * @param client		Client index.
 * @param raceID		ID of the race.
 */
forward void GOKZ_RC_OnRequestReceived(int client, int raceID)

/**
 * Called when a player accepts a race request.
 *
 * @param client		Client index.
 * @param raceID		ID of the race.
 */
forward void GOKZ_RC_OnRequestAccepted(int client, int raceID)

/**
 * Called when a player declines a race request.
 *
 * @param client		Client index.
 * @param raceID		ID of the race.
 * @param timeout		Whether the client was too late to respond.
 */
forward void GOKZ_RC_OnRequestDeclined(int client, int raceID, bool timeout)

/**
 * Called when a race has been registered.
 * The initial status of a race is RaceStatus_Pending.
 *
 * @param raceID		ID of the race.
 */
forward void GOKZ_RC_OnRaceRegistered(int raceID);

/**
 * Called when a race's info property has changed.
 *
 * @param raceID		ID of the race.
 * @param prop			Info property that was changed.
 * @param oldValue		Previous value.
 * @param newValue		New value.
 */
forward void GOKZ_RC_OnRaceInfoChanged(int raceID, RaceInfo prop, int oldValue, int newValue);



// =====[ NATIVES ]=====

/**
 * Gets the value of a race info property.
 *
 * @param raceID    	Race index.
 * @param prop			Info property to get.
 * @return				Value of the info property.
 */
native int GOKZ_RC_GetRaceInfo(int raceID, RaceInfo prop);

/**
 * Gets a player's racer status.
 * Refer to the RacerStatus enumeration.
 *
 * @param client    	Client index.
 * @return				Racer status of the client.
 */
native int GOKZ_RC_GetStatus(int client);

/**
 * Gets the ID of the race a player is in.
 *
 * @param client    	Client index.
 * @return				ID of the race the player is in, or -1 if not in a race.
 */
native int GOKZ_RC_GetRaceID(int client);



// =====[ DEPENDENCY ]=====

public SharedPlugin __pl_gokz_racing = 
{
	name = "gokz-racing", 
	file = "gokz-racing.smx", 
	#if defined REQUIRE_PLUGIN
	required = 1, 
	#else
	required = 0, 
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_gokz_racing_SetNTVOptional()
{
	MarkNativeAsOptional("GOKZ_RC_GetRaceInfo");
	MarkNativeAsOptional("GOKZ_RC_GetStatus");
	MarkNativeAsOptional("GOKZ_RC_GetRaceID");
}
#endif