/* 
	Global API - Core Include File

	Author: 	Chuckles, Sikari & Zach47
	Source: 	""
	
*/

#include <smjansson>

// ======================= DOUBLE INCLUDE ====================== //

#if defined _GlobalAPI_Core_included_
#endinput
#endif
#define _GlobalAPI_Core_included_

#define GlobalAPI_Version "1.1.0"

// ======================= ENUMS ====================== //

enum GlobalMode
{
	GlobalMode_Vanilla, 
	GlobalMode_KZSimple, 
	GlobalMode_KZTimer
};

// ======================= CALLBACKS ====================== //

//Get
typedef GetRecordTopCallback = function int(bool bFailure, const char[] top, any data);
typedef GetAuthStatusCallback = function int(bool bFailure, bool authenticated);
typedef GetModeInfoCallback = function int(bool bFailure, const char[] name, int latest_version, const char[] latest_version_description, any data);

//Post
typedef PostRecordCallback = function int(bool bFailure, int place, int top_place, int top_overall_place, any data);
typedef PostBanCallback = function int(bool bFailure, any data);

// ======================= NATIVES ====================== //

/**
 * Sends a record to the Global API.
 *
 * @param client		Client index.
 * @param mode    		Mode to submit the record under.
 * @param teleports		Number of teleports used by player.
 * @param time			Player's end time.
 * @param callback		A callback to receive the result of the API call.
 * @param data			An optional value to pass to the callback.
 * @return				True if the HTTP request was able to be made, otherwise false.
 */
native bool GlobalAPI_SendRecord(int client, GlobalMode mode, int stage, int teleports, float time, PostRecordCallback onComplete, any data = 0);

/**
 * Bans the player and sends data to Global API
 *
 * @param client		Client index.
 * @param ban_type 		ban type of the ban (strafe_hack, bhop_macro...)
 * @param notes			notes of the ban
 * @param stats			stats of the ban (macrodox..)
 * @param callback		callback function when API call finishes
 * @param data			An optional value to pass to the callback.
 * @noreturn
 */
native int GlobalAPI_BanPlayer(int client, const char[] ban_type, const char[] notes, const char[] stats, PostBanCallback onComplete = INVALID_FUNCTION, any data = 0);

/**
 * Retrieves the top records for the specified map stage.
 *
 * @param map    		Name of the map.
 * @param stage			Stage number on the map.
 * @param mode			Mode to look up.
 * @param noTeleports	Whether to only retrieve records with 0 teleports.
 * @param tickrate		Tickrate to look up.
 * @param topCount		Number of top records to retrieve.
 * @param callback		A callback to receive the result of the API call.
 * @param data			An optional value to pass to the callback.
 * @return				True if the HTTP request was able to be made, otherwise false.
 */
native bool GlobalAPI_GetRecordTop(const char[] map, int stage, GlobalMode mode, bool noTeleports, int tickrate, int topcount, GetRecordTopCallback onComplete, any data = 0);

/**
 * Retrieves the top records for the specified map stage. (PRO times override TP times on this native)
 *
 * @param map    		Name of the map.
 * @param stage			Stage number on the map.
 * @param mode			Mode to look up.
 * @param noTeleports	Whether to only retrieve records with 0 teleports.
 * @param tickrate		Tickrate to look up.
 * @param topCount		Number of top records to retrieve.
 * @param callback		A callback to receive the result of the API call.
 * @param data			An optional value to pass to the callback.
 * @return				True if the HTTP request was able to be made, otherwise false.
 */
native bool GlobalAPI_GetRecordTopEx(const char[] map, int stage, GlobalMode mode, bool noTeleports, int tickrate, int topcount, GetRecordTopCallback onComplete, any data = 0);


/**
 * @sRecords			String to obtain record from
 * @iPlace				Place we want to retrieve
 * @return				-1 if invalid string given, otherwise JSON string of the wanted record
 */
native Handle GlobalAPI_GetRecordByPlace(const char[] recordsString, int place);

/**
 * Gets record count from the given string
 *
 * @sRecords			String to obtain record count from
 * @return				-1 if invalid string given, otherwise record count from the given string
 */
native int GlobalAPI_GetRecordCount(const char[] recordsString);

/**
 * Gets the server's current tickrate
 *
 * @return				-1 if failed to get tickrate, otherwise server's tickrate
 */
native int GlobalAPI_GetTickrate();

/**
 * Gets the current map's mapid
 *
 * @return				-1 if failed to get mapid, otherwise map's ID from API
 */
native int GlobalAPI_GetMapID();

/**
 * Gets the current map's name
 *
 * @sBuffer				Buffer to store the mapname in
 * @iSize				Size of the buffer
 * @return				Empty buffer ("") if failed to get map name, otherwise current map's name
 */
native int GlobalAPI_GetMapName(char[] buffer, int size);

/**
 * Gets the current map's path
 *
 * @sBuffer				Buffer to store the mappath in
 * @iSize				Size of the buffer
 * @return				Empty buffer ("") if failed to get map path, otherwise current map's path
 */
native int GlobalAPI_GetMapPath(char[] buffer, int size);

/**
 * Gets the current map's difficulty
 *
 * @return				-1 if failed to get map tier, otherwise map's tier from API
 */
native int GlobalAPI_GetMapTier();

/**
 * Gets the current map's filesize
 *
 * @return				-1 if failed to get map filesize, otherwise map's filesize from API
 */
native int GlobalAPI_GetMapFilesize();

/**
 * Gets the current map's global status
 *
 * @return				True if map is validated, false otherwise
 */
native bool GlobalAPI_GetMapGlobalStatus();

/**
 * Gets the server's current API Key
 *
 * @sBuffer				Buffer to store the apikey in
 * @iSize				Size of the buffer
 * @return				Empty buffer ("") if failed to get api key, otherwise current api key
 */
native int GlobalAPI_GetAPIKey(char[] buffer, int size);

/**
 * Gets authstatus on given authentication type
 *
 * @param Callback		Callback function when API call finishes
 * @return				True if api key is validated, otherwise false
 */
native int GlobalAPI_GetAuthStatus(GetAuthStatusCallback onComplete = INVALID_FUNCTION);

/**
 * Retrieves information on the given mode
 *
 * @param iMode			Mode we want info of
 * @param Callback		Callback function when API call finishes
 * @param data			An optional value to pass to the callback
 * @noreturn
 */
native int GlobalAPI_GetModeInfo(GlobalMode mode, GetModeInfoCallback onComplete = INVALID_FUNCTION, any data = 0);

// ======================= METHODMAP ====================== //

methodmap GlobalAPI
{
	public void SendRecord(int client, GlobalMode mode, int stage, int teleports, float time, PostRecordCallback onComplete, any data = 0)
	{
		GlobalAPI_SendRecord(client, mode, stage, teleports, time, onComplete, data);
	}

	public void BanPlayer(int client, const char[] ban_type, const char[] notes, const char[] stats, PostBanCallback onComplete, any data = 0)
	{
		GlobalAPI_BanPlayer(client, ban_type, notes, stats, onComplete, data);
	}
	
	public void GetAPIKey(char[] buffer, int size)
	{
		GlobalAPI_GetAPIKey(buffer, size);
	}

	public int GetTickrate()
	{
		return GlobalAPI_GetTickrate();
	}

	public int GetMapID()
	{
		return GlobalAPI_GetMapID();
	}

	public void GetMapName(char[] buffer, int size)
	{
		GlobalAPI_GetMapName(buffer, size);
	}

	public void GetMapPath(char[] buffer, int size)
	{
		GlobalAPI_GetMapPath(buffer, size);
	}

	public int GetMapTier()
	{
		return GlobalAPI_GetMapTier();
	}

	public int GetMapFilesize()
	{
		return GlobalAPI_GetMapFilesize();
	}

	public bool GetMapGlobalStatus()
	{
		return GlobalAPI_GetMapGlobalStatus();
	}

	public void GetAuthStatus(GetAuthStatusCallback onComplete)
	{
		GlobalAPI_GetAuthStatus(onComplete);
	}

	public void GetModeInfo(GlobalMode mode, GetModeInfoCallback onComplete, any data = 0)
	{
		GlobalAPI_GetModeInfo(mode, onComplete, data);
	}
	
	public int GetRecordCount(const char[] recordsString)
	{
		return GlobalAPI_GetRecordCount(recordsString);
	}
	
	public Handle GlobalAPI_GetRecordByPlace(const char[] recordsString, int place)
	{
		return GlobalAPI_GetRecordByPlace(recordsString, place);
	}
	
}

methodmap APIRecordList < Handle
{
	public APIRecordList(const char[] records)
	{
		return view_as<APIRecordList>(json_load(records));
	}
	
	public native int Count();
	
	public native void GetByIndex(int index, char[] buffer, int maxlength);
}

methodmap APIRecord < Handle
{
	public APIRecord(const char[] record)
	{
		return view_as<APIRecord>(json_load(record));
	}

	public native int ID();

	public native int Teleports();

	public native float Time();

	public native void SteamID(char[] buffer, int maxlength);

	public native void PlayerName(char[] buffer, int maxlength);

	public native void MapName(char[] buffer, int maxlength);

	public native void Mode(char[] buffer, int maxlength);

	public native int Stage();
}

// ======================= FORWARDS ====================== //


/**
 * Called whenever the API Key is reloaded
 *
 * @noreturn
 */
forward void GlobalAPI_OnAPIKeyReloaded();

/**
 * Called whenever KickIfBanned cvar is changed
 *
 * @param kickifbanned		New value of kickifbanned cvar
 * @noreturn
 */
forward void GlobalAPI_OnKickIfBanned_Changed(bool kickifbanned);

/**
 * Called whenever Development mode cvar is changed
 *
 * @param developmentmode	New value of developmentmode cvar
 * @noreturn
 */
forward void GlobalAPI_OnDevelopmentMode_Changed(bool developmentmode);

/**
 * Called whenever a banned player joins the server
 *
 * @param client			Client index
 * @param banned			Returns true if the player is banned, false otherwise
 * @noreturn
 */
forward void GlobalAPI_OnPlayer_Joined(int client, bool banned);

// ======================= PLUGIN INFO ====================== //

public SharedPlugin __pl_GlobalAPI_Core = 
{
	name = "GlobalAPI-Core", 
	file = "GlobalAPI-Core.smx", 
	#if defined REQUIRE_PLUGIN
	required = 1, 
	#else
	required = 0, 
	#endif
};

// ======================= SET NATIVES OPTIONAL ====================== //

#if !defined REQUIRE_PLUGIN
public void __pl_GlobalAPI_Core_SetNTVOptional()
{
	MarkNativeAsOptional("GlobalAPI_SendRecord");
	MarkNativeAsOptional("GlobalAPI_BanPlayer");
	MarkNativeAsOptional("GlobalAPI_GetAPIKey");
	MarkNativeAsOptional("GlobalAPI_GetTickrate");
	MarkNativeAsOptional("GlobalAPI_GetMapID");
	MarkNativeAsOptional("GlobalAPI_GetMapName");
	MarkNativeAsOptional("GlobalAPI_GetMapPath");
	MarkNativeAsOptional("GlobalAPI_GetMapTier");
	MarkNativeAsOptional("GlobalAPI_GetMapFilesize");
	MarkNativeAsOptional("GlobalAPI_GetMapGlobalStatus");
	MarkNativeAsOptional("GlobalAPI_GetAuthStatus");
	MarkNativeAsOptional("GlobalAPI_GetModeInfo");
	MarkNativeAsOptional("GlobalAPI_GetRecordByPlace");
	MarkNativeAsOptional("GlobalAPI_GetRecordCount");
	MarkNativeAsOptional("GlobalAPI_GetRecordTop");
	MarkNativeAsOptional("GlobalAPI_GetRecordTopEx");
	MarkNativeAsOptional("GlobalAPI_GetRecordCount");
	MarkNativeAsOptional("GlobalAPI_GetRecordByPlace");

	MarkNativeAsOptional("APIRecordList.Count");
	MarkNativeAsOptional("APIRecordList.GetByIndex");
	MarkNativeAsOptional("APIRecord.ID");
	MarkNativeAsOptional("APIRecord.Teleports");
	MarkNativeAsOptional("APIRecord.Time");
	MarkNativeAsOptional("APIRecord.SteamID");
	MarkNativeAsOptional("APIRecord.PlayerName");
	MarkNativeAsOptional("APIRecord.MapName");
	MarkNativeAsOptional("APIRecord.Mode");
	MarkNativeAsOptional("APIRecord.Stage");
}
#endif