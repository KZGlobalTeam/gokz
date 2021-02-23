// ================== DOUBLE INCLUDE ========================= //

#if defined _GlobalAPI_included_
#endinput
#endif
#define _GlobalAPI_included_

// ======================= DEFINITIONS ======================= //

#define DEFAULT_DATA 0
#define DEFAULT_INT -1
#define DEFAULT_STRING ""
#define DEFAULT_FLOAT -1.0
#define DEFAULT_BOOL view_as<bool>(-1)

#define GlobalAPI_Plugin_Version "2.0.0"
#define GlobalAPI_Plugin_Desc "Plugin helper for GlobalAPI Production & Staging"
#define GlobalAPI_Plugin_Url "https://bitbucket.org/kztimerglobalteam/GlobalAPI-SMPlugin"
#define GlobalAPI_Plugin_NameVersion "GlobalAPI Plugin " ... GlobalAPI_Plugin_Version

#define GlobalAPI_Backend_Version "v2.0"
#define GlobalAPI_Backend_Staging_Version "v2.0"
#define GlobalAPI_BaseUrl "https://kztimerglobal.com/api/" ... GlobalAPI_Backend_Version
#define GlobalAPI_Staging_BaseUrl "https://staging.kztimerglobal.com/api/" ... GlobalAPI_Backend_Staging_Version

#define GlobalAPI_Max_BaseUrl_Length 128
#define GlobalAPI_Max_QueryParam_Num 20
#define GlobalAPI_Max_QueryParam_Length 64
#define GlobalAPI_Max_QueryParams_Length (GlobalAPI_Max_QueryParam_Num * GlobalAPI_Max_QueryParam_Length)
#define GlobalAPI_Max_QueryUrl_Length (GlobalAPI_Max_QueryParams_Length + GlobalAPI_Max_BaseUrl_Length)
#define GlobalAPI_Max_QueryParam_Array_Length 64

#define GlobalAPI_Max_APIKey_Length 128
#define GlobalAPI_Max_PluginName_Length 64
#define GlobalAPI_Max_PluginVersion_Length 32
#define GlobalAPI_Data_File_Extension "GAPI"

// ======================= INCLUDES ========================== //

#include <GlobalAPI/requestdata>
#include <GlobalAPI/responses>
#include <GlobalAPI/stocks>

// ======================= ENUMS ============================= //

/**
 * Defines what request method is used on requests
 */
enum
{
	GlobalAPIRequestType_GET = 0,	/**< Request uses GET HTTP method */
	GlobalAPIRequestType_POST		/**< Request uses POST HTTP method */
};

/**
 * Defines what accept type is used on requests
 */
enum
{
	GlobalAPIRequestAcceptType_JSON = 0,	/**< Request uses application/json HTTP accept type */
	GlobalAPIRequestAcceptType_OctetStream	/**< Request uses application/octet-stream HTTP accept type */
};

/**
 * Defines what content type is used on requests
 */
enum
{
	GlobalAPIRequestContentType_JSON = 0,	/**< Request uses application/json HTTP content type */
	GlobalAPIRequestContentType_OctetStream	/**< Request uses application/octet-stream HTTP content type */
};

// ======================= TYPEDEFS ========================== //

/*
	Function types when API call finishes
*/
typeset OnAPICallFinished
{
   /**
 	* Called when an API call has finished
 	*
 	* @param hResponse			JSON_Object handle to the response
 	* @param hData				GlobalAPIRequestData handle for the request
 	* @noreturn
 	*/
	function void(JSON_Object hResponse, GlobalAPIRequestData hData);

   /**
 	* Called when an API call has finished
 	*
 	* @param hResponse			JSON_Object handle to the response
 	* @param hData				GlobalAPIRequestData handle for the request
 	* @param data				Optional data that was passed
 	* @noreturn
 	*/
	function void(JSON_Object hResponse, GlobalAPIRequestData hData, any data);
};

// ======================= FORWARDS ========================== //

/**
 * Called when GlobalAPI plugin is initialized,
 * this means API Key is loaded and all the cvars are loaded
 *
 * @noreturn
 */
forward void GlobalAPI_OnInitialized();

/**
 * Called when GlobalAPI plugin has failed a request
 *
 * @param request				Handle to the request failed
 * @param hData					Handle to request's GlobalAPIRequestData
 * @noreturn
 */
forward void GlobalAPI_OnRequestFailed(Handle request, GlobalAPIRequestData hData);

/**
 * Called when GlobalAPI plugin has started a request
 *
 * @param request				Handle to the request started
 * @param hData					Handle to request's GlobalAPIRequestData
 * @noreturn
 */
forward void GlobalAPI_OnRequestStarted(Handle request, GlobalAPIRequestData hData);

/**
 * Called when GlobalAPI plugin has finished a request
 *
 * @param request				Handle to the request finished
 * @param hData					Handle to request's GlobalAPIRequestData
 * @noreturn
 */
forward void GlobalAPI_OnRequestFinished(Handle request, GlobalAPIRequestData hData);

// ======================= NATIVES =========================== //

/**
 * Gets a boolean of whether GlobalAPI plugin is initialized.
 *
 * @note						See GlobalAPI_OnInitialized for the event version.
 * @return						Whether GlobalAPI plugin is initialized.
 */
native bool GlobalAPI_IsInit();

/**
 * Gets the API Key used by GlobalAPI plugin
 *
 * @param buffer				Buffer to store result in
 * @param maxlength				Max length of the buffer
 * @noreturn		
 */
native void GlobalAPI_GetAPIKey(char[] buffer, int maxlength);

/**
 * Gets whether GlobalAPI is using an API Key
 *
 * @note						This does not mean the API Key is valid!
 * @return						Whether API Key is used by GlobalAPI plugin
 */
native bool GlobalAPI_HasAPIKey();

/**
 * Gets whether GlobalAPI is using the staging endpoint
 *
 * @note						It is not safe to call this before GlobalAPI_OnInitialized!
 * @return						Whether staging endpoint is used by GlobalAPI plugin
 */
native bool GlobalAPI_IsStaging();

/**
 * Gets whether GlobalAPI is in debug mode
 *
 * @note						It is not safe to call this before GlobalAPI_OnInitialized!
 * @return						Whether GlobalAPI plugin is in debug mode
 */
native bool GlobalAPI_IsDebugging();

/**
 * Sends a request in GlobalAPI plugin format
 *
 * @param hData					Handle to GlobalAPIRequestData
 * @return						Whether the request was sent successfully
 */
native bool GlobalAPI_SendRequest(GlobalAPIRequestData hData);

/**
 * Sends a debug message to GlobalAPI plugin logs if debugging is enabled
 *
 * @param message				Formatting rules
 * @param ...					Variable number of format parameters
 * @note						This is not safe to use before convars have loaded
 * @return						Whether the message was logged
 */
native bool GlobalAPI_DebugMessage(const char[] message, any ...);

/**
 * Starts a GET HTTP Request to /api/{version}/auth/status
 *
 * @param callback				Callback when request has finished
 * @param data					Optional data to pass
 * @return						Whether request was successfully sent
 */
native bool GlobalAPI_GetAuthStatus(OnAPICallFinished callback = INVALID_FUNCTION, any data = DEFAULT_DATA);

/**
 * Starts a GET HTTP Request to /api/{version}/bans
 *
 * @param callback				Callback when request has finished
 * @param data					Optional data to pass
 * @param banTypes				Ban types to query
 * @param banTypesList			-Unsupported at the moment-
 * @param isExpired				Whether to query for isExpired or not
 * @param ipAddress				IP address to query
 * @param steamId64				SteamID64 to query
 * @param steamId				SteamID2 to query
 * @param notesContain			Notes to query
 * @param statsContain			Stats to query
 * @param serverId				Server ID to query
 * @param createdSince			Created since date to query
 * @param updatedSince			Updated since date to query
 * @param offset				Offset of the dataset to query
 * @param limit					Amount of items returned for the query
 * @return						Whether request was successfully sent
 */
native bool GlobalAPI_GetBans(OnAPICallFinished callback = INVALID_FUNCTION, any data = DEFAULT_DATA, const char[] banTypes = DEFAULT_STRING,
								const char[] banTypesList = DEFAULT_STRING, bool isExpired = DEFAULT_BOOL, const char[] ipAddress = DEFAULT_STRING,
								int steamId64 = DEFAULT_INT, const char[] steamId = DEFAULT_STRING, const char[] notesContain = DEFAULT_STRING,
								const char[] statsContain = DEFAULT_STRING, int serverId = DEFAULT_INT, const char[] createdSince = DEFAULT_STRING,
								const char[] updatedSince = DEFAULT_STRING, int offset = DEFAULT_INT, int limit = DEFAULT_INT);

/**
 * Starts a POST HTTP Request to /api/{version}/bans
 *
 * @param callback				Callback when request has finished
 * @param data					Optional data to pass
 * @param steamId				SteamID2 of the user
 * @param banType				Type of the ban
 * @param stats					Stats of the ban
 * @param notes					Notes of the ban
 * @param ipAddress				IP address of the user
 * @return						Whether request was successfully sent
 */
native bool GlobalAPI_CreateBan(OnAPICallFinished callback = INVALID_FUNCTION, any data = DEFAULT_DATA,
									const char[] steamId, const char[] banType, const char[] stats,
									const char[] notes, const char[] ipAddress);

/**
 * Starts a GET HTTP Request to /api/{version}/jumpstats
 *
 * @param callback				Callback when request has finished
 * @param data					Optional data to pass
 * @param id					Id to query
 * @param serverId				Server id to query
 * @param steamId64				SteamID64 to query
 * @param steamId				SteamID2 to query
 * @param jumpType				Jump type to query
 * @param steamId64List			-Unsupported at the moment-
 * @param jumpTypeList			-Unsupported at the moment-
 * @param greaterThanDistance	Greater than distance to query
 * @param lessThanDistance		Less than distance to query
 * @param isMsl					Whether to query for isMsl or not
 * @param isCrouchBind			Whether to query for isCrouchBind or not
 * @param isForwardBind			Whether to query for isForwardBind or not
 * @param isCrouchBoost			Whether to query for isCrouchBoost or not
 * @param updatedById			Updated by id to query
 * @param createdSince			Created since date to query
 * @param updatedSince			Updated since date to query
 * @param offset				Offset of the dataset to query
 * @param limit					Amount of items returned for the query
 * @return						Whether request was successfully sent
 */
native bool GlobalAPI_GetJumpstats(OnAPICallFinished callback = INVALID_FUNCTION, any data = DEFAULT_DATA, int id = DEFAULT_INT,
									int serverId = DEFAULT_INT, int steamId64 = DEFAULT_INT, const char[] steamId = DEFAULT_STRING,
									const char[] jumpType = DEFAULT_STRING, const char[] steamId64List = DEFAULT_STRING,
									const char[] jumpTypeList = DEFAULT_STRING, float greaterThanDistance = DEFAULT_FLOAT,
									float lessThanDistance = DEFAULT_FLOAT, bool isMsl = DEFAULT_BOOL, bool isCrouchBind = DEFAULT_BOOL,
									bool isForwardBind = DEFAULT_BOOL, bool isCrouchBoost = DEFAULT_BOOL, int updatedById = DEFAULT_INT,
									const char[] createdSince = DEFAULT_STRING, const char[] updatedSince = DEFAULT_STRING,
									int offset = DEFAULT_INT, int limit = DEFAULT_INT);

/**
 * Starts a POST HTTP Request to /api/{version}/jumpstats
 *
 * @param callback				Callback when request has finished
 * @param data					Optional data to pass
 * @param steamId				SteamID2 of the user
 * @param jumpType				Type of the jump
 * @param distance				Distance of the jump
 * @param jumpJsonInfo			Data of the jump
 * @param tickRate				Tickrate of the server
 * @param mslCount				Msl count of the jump
 * @param isCrouchBind			Whether crouch bind was used
 * @param isForwardBind			Whether forward bind was used
 * @param isCrouchBoost			Whether crouch boost was used
 * @param strafeCount			Strafe count of the jump
 * @return						Whether request was successfully sent
 */
native bool GlobalAPI_CreateJumpstat(OnAPICallFinished callback = INVALID_FUNCTION, any data = DEFAULT_DATA, const char[] steamId,
										int jumpType, float distance, const char[] jumpJsonInfo, int tickRate, int mslCount,
										bool isCrouchBind, bool isForwardBind, bool isCrouchBoost, int strafeCount);

/**
 * Starts a GET HTTP Request to /api/{version}/jumpstats/{jump_type}/top
 *
 * @param callback				Callback when request has finished
 * @param data					Optional data to pass
 * @param jumpType				Jump type to query
 * @param id					Id to query
 * @param serverId				Server Id to query
 * @param steamId64				SteamID64 to query
 * @param steamId				SteamID2 to query
 * @param steamId64List			-Unsupported at the moment-
 * @param jumpTypeList			-Unsupported at the moment-
 * @param greaterThanDistance	Greater than distance to query
 * @param lessThanDistance		Less than distance to query
 * @param isMsl					Whether to query for isMsl or not
 * @param isCrouchBind			Whether to query for isCrouchBind or not
 * @param isForwardBind			Whether to query for isForwardBind or not
 * @param isCrouchBoost			Whether to query for isCrouchBoost or not
 * @param updatedById			Updated by id to query
 * @param createdSince			Created since date to query
 * @param updatedSince			Updated since date to query
 * @param offset				Offset of the dataset to query
 * @param limit					Amount of items returned for the query
 * @return						Whether request was successfully sent
 */
native bool GlobalAPI_GetJumpstatTop(OnAPICallFinished callback = INVALID_FUNCTION, any data = DEFAULT_DATA, const char[] jumpType,
										int id = DEFAULT_INT, int serverId = DEFAULT_INT, int steamId64 = DEFAULT_INT,
										const char[] steamId = DEFAULT_STRING, const char[] steamId64List = DEFAULT_STRING,
										const char[] jumpTypeList = DEFAULT_STRING, float greaterThanDistance = DEFAULT_FLOAT,
										float lessThanDistance = DEFAULT_FLOAT, bool isMsl = DEFAULT_BOOL, bool isCrouchBind = DEFAULT_BOOL,
										bool isForwardBind = DEFAULT_BOOL, bool isCrouchBoost = DEFAULT_BOOL, int updatedById = DEFAULT_INT,
										const char[] createdSince = DEFAULT_STRING, const char[] updatedSince = DEFAULT_STRING,
										int offset = DEFAULT_INT, int limit = DEFAULT_INT);

/**
 * Starts a GET HTTP Request to /api/{version}/jumpstats/{jump_type}/top30
 *
 * @param callback				Callback when request has finished
 * @param data					Optional data to pass
 * @param jumpType				Jump type to query
 * @return						Whether request was successfully sent
 */
native bool GlobalAPI_GetJumpstatTop30(OnAPICallFinished callback = INVALID_FUNCTION, any data = DEFAULT_DATA, const char[] jumpType);

/**
 * Starts a GET HTTP Request to /api/{version}/maps
 *
 * @param callback				Callback when request has finished
 * @param data					Optional data to pass
 * @param name					Map name to query
 * @param largerThanFilesize	Larger than filesize to query
 * @param smallerThanFilesize	Smaller than filesize to query
 * @param isValidated			Whether to query for isValidated or not
 * @param difficulty			Map difficulty to query
 * @param createdSince			Created since date to query
 * @param updatedSince 			Updated since date to query 
 * @param offset				Offset of the dataset to query
 * @param limit					Amount of items returned for the query
 * @return						Whether request was successfully sent
 */
native bool GlobalAPI_GetMaps(OnAPICallFinished callback = INVALID_FUNCTION, any data = DEFAULT_DATA, const char[] name = DEFAULT_STRING,
								int largerThanFilesize = DEFAULT_INT, int smallerThanFilesize = DEFAULT_INT, bool isValidated = DEFAULT_BOOL,
								int difficulty = DEFAULT_INT, const char[] createdSince = DEFAULT_STRING, const char[] updatedSince = DEFAULT_STRING,
								int offset = DEFAULT_INT, int limit = DEFAULT_INT);

/**
 * Starts a GET HTTP Request to /api/{version}/maps/{id}
 *
 * @param callback				Callback when request has finished
 * @param data					Optional data to pass
 * @param id					Map id to query
 * @return						Whether request was successfully sent
 */
native bool GlobalAPI_GetMapById(OnAPICallFinished callback = INVALID_FUNCTION, any data = DEFAULT_DATA, int id);

/**
 * Starts a GET HTTP Request to /api/{version}/maps/name/{map_name}
 *
 * @param callback				Callback when request has finished
 * @param data					Optional data to pass
 * @param name					Map name to query
 * @return						Whether request was successfully sent
 */
native bool GlobalAPI_GetMapByName(OnAPICallFinished callback = INVALID_FUNCTION, any data = DEFAULT_DATA, const char[] name);

/**
 * Starts a GET HTTP Request to /api/{version}/modes
 *
 * @param callback				Callback when request has finished
 * @param data					Optional data to pass
 * @return						Whether request was successfully sent
 */
native bool GlobalAPI_GetModes(OnAPICallFinished callback = INVALID_FUNCTION, any data = DEFAULT_DATA);

/**
 * Starts a GET HTTP Request to /api/{version}/modes/id/{id}
 *
 * @param callback				Callback when request has finished
 * @param data					Optional data to pass
 * @param id					Mode id to query
 * @return						Whether request was successfully sent
 */
native bool GlobalAPI_GetModeById(OnAPICallFinished callback = INVALID_FUNCTION, any data = DEFAULT_DATA, int id);

/**
 * Starts a GET HTTP Request to /api/{version}/modes/name/{mode_name}
 *
 * @param callback				Callback when request has finished
 * @param data					Optional data to pass
 * @param name					Mode name to query
 * @return						Whether request was successfully sent
 */
native bool GlobalAPI_GetModeByName(OnAPICallFinished callback = INVALID_FUNCTION, any data = DEFAULT_DATA, const char[] name);

/**
 * Starts a GET HTTP Request to /api/{version}/players
 *
 * @param callback				Callback when request has finished
 * @param data					Optional data to pass
 * @param steamId				SteamID2 to query
 * @param isBanned				Whether to query for isBanned or not
 * @param totalRecords			Total records to query
 * @param ipAddress				IP address to query
 * @param steamId64List			-Unsupported at the moment-
 * @return						Whether request was successfully sent
 */
native bool GlobalAPI_GetPlayers(OnAPICallFinished callback = INVALID_FUNCTION, any data = DEFAULT_DATA, const char[] steamId = DEFAULT_STRING,
									bool isBanned = DEFAULT_BOOL, int totalRecords = DEFAULT_INT, const char[] ipAddress = DEFAULT_STRING,
									const char[] steamId64List = DEFAULT_STRING);

/**
 * Starts a GET HTTP Request to /api/{version}/players/steamid/{steamid}
 *
 * @param callback				Callback when request has finished
 * @param data					Optional data to pass
 * @param steamId				SteamID2 to query
 * @return						Whether request was successfully sent
 */
native bool GlobalAPI_GetPlayerBySteamId(OnAPICallFinished callback = INVALID_FUNCTION, any data = DEFAULT_DATA, const char[] steamId);

/**
 * Starts a GET HTTP Request to /api/{version}/players/steamid/{steamid}/ip/{ip}
 *
 * @param callback				Callback when request has finished
 * @param data					Optional data to pass
 * @param steamId				SteamID2 to query
 * @param ipAddress				IP address to query
 * @return						Whether request was successfully sent
 */
native bool GlobalAPI_GetPlayerBySteamIdAndIp(OnAPICallFinished callback = INVALID_FUNCTION, any data = DEFAULT_DATA,
												const char[] steamId, const char[] ipAddress);

/**
 * Starts a POST HTTP Request to /api/{version}/records
 *
 * @param callback				Callback when request has finished
 * @param data					Optional data to pass
 * @param steamId				SteamID2 of the user
 * @param mapId					Map id of the record
 * @param mode					Mode of the record
 * @param stage					Stage of the record
 * @param tickRate				Tickrate of the server
 * @param teleports				Teleport count of the record
 * @param time					Elapsed time of the record
 * @return						Whether request was successfully sent
 */
native bool GlobalAPI_CreateRecord(OnAPICallFinished callback = INVALID_FUNCTION, any data = DEFAULT_DATA, const char[] steamId,
									int mapId, const char[] mode, int stage, int tickRate, int teleports, float time);

/**
 * Starts a GET HTTP Request to /api/{version}/records/place/{id}
 *
 * @note						This is deprecated!
 * @param callback				Callback when request has finished
 * @param data					Optional data to pass
 * @param id					Id to query
 * @return						Whether request was successfully sent
 */
native bool GlobalAPI_GetRecordPlaceById(OnAPICallFinished callback = INVALID_FUNCTION, any data = DEFAULT_DATA, int id);

/**
 * Starts a GET HTTP Request to /api/{version}/records/top
 *
 * @param callback				Callback when request has finished
 * @param data					Optional data to pass
 * @param steamId				SteamID2 to query
 * @param steamId64				SteamID64 to query
 * @param mapId					Map id to query
 * @param mapName				Map name to query
 * @param tickRate				Tickrate to query
 * @param stage					Stage to query
 * @param modes					Mode(s) to query
 * @param hasTeleports			Whether to query for hasTeleports or not
 * @param playerName			Player name to query
 * @param offset				Offset of the dataset to query
 * @param limit					Amount of items returned for the query
 * @return						Whether request was successfully sent
 */
native bool GlobalAPI_GetRecordsTop(OnAPICallFinished callback = INVALID_FUNCTION, any data = DEFAULT_DATA,
										const char[] steamId = DEFAULT_STRING, int steamId64 = DEFAULT_INT, int mapId = DEFAULT_INT,
										const char[] mapName = DEFAULT_STRING, int tickRate = DEFAULT_INT, int stage = DEFAULT_INT,
										const char[] modes = DEFAULT_STRING, bool hasTeleports = DEFAULT_BOOL,
										const char[] playerName = DEFAULT_STRING, int offset = DEFAULT_INT, int limit = DEFAULT_INT);

/**
 * Starts a GET HTTP Request to /api/{version}/records/top/recent
 *
 * @param callback				Callback when request has finished
 * @param data					Optional data to pass
 * @param steamId				SteamID2 to query
 * @param steamId64				SteamID64 to query
 * @param mapId					Map id to query
 * @param mapName				Map name to query
 * @param tickRate				Tickrate to query
 * @param stage					Stage to query
 * @param modes					Mode(s) to query
 * @param topAtLeast			Place top at least to query
 * @param topOverallAtLeast		Place top overall at least to query
 * @param hasTeleports			Whether to query for hasTeleports or not
 * @param createdSince			Created since date to query
 * @param playerName			Player name to query
 * @param offset				Offset of the dataset to query
 * @param limit					Amount of items returned for the query
 * @return						Whether request was successfully sent
 */
native bool GlobalAPI_GetRecordsTopRecent(OnAPICallFinished callback = INVALID_FUNCTION, any data = DEFAULT_DATA,
											const char[] steamId = DEFAULT_STRING, int steamId64 = DEFAULT_INT,
											int mapId = DEFAULT_INT, const char[] mapName = DEFAULT_STRING,
											int tickRate = DEFAULT_INT, int stage = DEFAULT_INT,
											const char[] modes = DEFAULT_STRING, int topAtLeast = DEFAULT_INT,
											int topOverallAtLeast = DEFAULT_INT, bool hasTeleports = DEFAULT_BOOL,
											const char[] createdSince = DEFAULT_STRING, const char[] playerName = DEFAULT_STRING,
											int offset = DEFAULT_INT, int limit = DEFAULT_INT);

/**
 * Starts a GET HTTP Request to /api/{version}/records/top/world_records
 *
 * @param callback				Callback when request has finished
 * @param data					Optional data to pass
 * @param ids					Array of ids to query
 * @param idsLength 			Length of the ids array
 * @param mapIds				Array of map ids to query
 * @param mapIdsLength			Length of the map ids array
 * @param stages				Array of stages to query
 * @param stagesLength			Length of the stages array
 * @param modeIds				Array of mode ids to query
 * @param modeIdsLength			Length of the mode ids array
 * @param tickRates				Array of tickrates to query
 * @param tickRatesLength		Length of the tickrates array
 * @param hasTeleports			Whether to query for hasTeleports or not
 * @param mapTag				Map tags to query
 * @param offset				Offset of the dataset to query
 * @param limit					Amount of items returned for the query
 * @return						Whether request was successfully sent
 */
native bool GlobalAPI_GetRecordsTopWorldRecords(OnAPICallFinished callback = INVALID_FUNCTION, any data = DEFAULT_DATA,
												int[] ids = DEFAULT_INT, int idsLength = DEFAULT_INT,
												int[] mapIds = DEFAULT_INT, int mapIdsLength = DEFAULT_INT,
												int[] stages = DEFAULT_INT, int stagesLength = DEFAULT_INT,
												int[] modeIds = DEFAULT_INT, int modeIdsLength = DEFAULT_INT,
												int[] tickRates = DEFAULT_INT, int tickRatesLength = DEFAULT_INT,
												bool hasTeleports = DEFAULT_BOOL, char[] mapTag = DEFAULT_STRING,
												int offset = DEFAULT_INT, int limit = DEFAULT_INT);

/**
 * Starts a GET HTTP Request to /api/{version}/servers
 *
 * @param callback				Callback when request has finished
 * @param data					Optional data to pass
 * @param id					Id to query
 * @param port					Port to query
 * @param ip					IP address to query
 * @param name					Server name to query
 * @param ownerSteamId64		Owner's steamid64 to query
 * @param approvalStatus		Approval status to query
 * @param offset				Offset of the dataset to query
 * @param limit					Amount of items returned for the query
 * @return						Whether request was successfully sent
 */
native bool GlobalAPI_GetServers(OnAPICallFinished callback = INVALID_FUNCTION, any data = DEFAULT_DATA,
									int id = DEFAULT_INT, int port = DEFAULT_INT, const char[] ip = DEFAULT_STRING,
									const char[] name = DEFAULT_STRING, int ownerSteamId64 = DEFAULT_INT,
									int approvalStatus = DEFAULT_INT, int offset = DEFAULT_INT, int limit = DEFAULT_INT);

/**
 * Starts a GET HTTP Request to /api/{version}/servers/{id}
 *
 * @param callback				Callback when request has finished
 * @param data					Optional data to pass
 * @param id					Id to query
 * @return						Whether request was successfully sent
 */
native bool GlobalAPI_GetServerById(OnAPICallFinished callback = INVALID_FUNCTION, any data = DEFAULT_DATA, int id);

/**
 * Starts a GET HTTP Request to /api/{version}/servers/name/{server_name}
 *
 * @param callback				Callback when request has finished
 * @param data					Optional data to pass
 * @param serverName			Server name to query
 * @return						Whether request was successfully sent
 */
native bool GlobalAPI_GetServersByName(OnAPICallFinished callback = INVALID_FUNCTION, any data = DEFAULT_DATA, const char[] serverName);

/**
 * Starts a GET HTTP Request to /api/{version}/player_ranks
 *
 * @param callback				Callback when request has finished
 * @param data					Optional data to pass
 * @param pointsGreaterThan		Points greater than to query
 * @param averageGreaterThan	Average greater than to query
 * @param ratingGreaterThan		Rating greater than to query
 * @param finishesGreaterThan	Finishes greater than to query
 * @param steamId64s			Array of steamid64s to query
 * @param steamId64sLength		Length of the steamid64s array
 * @param recordFilterIds		Array of record filter ids to query
 * @param recordFilterIdsLength	Length of the record filter ids array
 * @param mapIds				Array of map ids to query
 * @param mapIdsLength			Length of the map ids array
 * @param stages				Array of stages to query
 * @param stagesLength			Length of the stages array
 * @param modeIds				Array of mode ids to query
 * @param modeIdsLength			Length of the mode ids array
 * @param tickRates				Array of tickrates to query
 * @param tickRatesLength		Length of the tickrates array
 * @param hasTeleports			Whether to query for hasTeleports or not
 * @param offset				Offset of the dataset to query
 * @param limit					Amount of items returned for the query
 * @return						Whether request was successfully sent
 */
native bool GlobalAPI_GetPlayerRanks(OnAPICallFinished callback = INVALID_FUNCTION, any data = DEFAULT_DATA,
										int pointsGreaterThan = DEFAULT_INT, float averageGreaterThan = DEFAULT_FLOAT,
										float ratingGreaterThan = DEFAULT_FLOAT, int finishesGreaterThan = DEFAULT_INT,
										int[] steamId64s = DEFAULT_INT, int steamId64sLength = DEFAULT_INT, 
										int[] recordFilterIds = DEFAULT_INT, int recordFilterIdsLength = DEFAULT_INT,
										int[] mapIds = DEFAULT_INT, int mapIdsLength = DEFAULT_INT,
										int[] stages = DEFAULT_INT, int stagesLength = DEFAULT_INT,
										int[] modeIds = DEFAULT_INT, int modeIdsLength = DEFAULT_INT,
										int[] tickRates = DEFAULT_INT, int tickRatesLength = DEFAULT_INT,
										bool hasTeleports = DEFAULT_BOOL, int offset = DEFAULT_INT, int limit = DEFAULT_INT);

/**
 * Starts a GET HTTP Request to /api/{version}/record_filters
 *
 * @param callback				Callback when request has finished
 * @param data					Optional data to pass
 * @param ids					Array of ids to query
 * @param idsLength 			Length of the ids array
 * @param mapIds				Array of map ids to query
 * @param mapIdsLength			Length of the map ids array
 * @param stages				Array of stages to query
 * @param stagesLength			Length of the stages array
 * @param modeIds				Array of mode ids to query
 * @param modeIdsLength			Length of the mode ids array
 * @param tickRates				Array of tickrates to query
 * @param tickRatesLength		Length of the tickrates array
 * @param hasTeleports			Whether to query for hasTeleports or not
 * @param offset				Offset of the dataset to query
 * @param limit					Amount of items returned for the query
 * @return						Whether request was successfully sent
 */
native bool GlobalAPI_GetRecordFilters(OnAPICallFinished callback = INVALID_FUNCTION, any data = DEFAULT_DATA,
										int[] ids = DEFAULT_INT, int idsLength = DEFAULT_INT,
										int[] mapIds = DEFAULT_INT, int mapIdsLength = DEFAULT_INT,
										int[] stages = DEFAULT_INT, int stagesLength = DEFAULT_INT,
										int[] modeIds = DEFAULT_INT, int modeIdsLength = DEFAULT_INT,
										int[] tickRates = DEFAULT_INT, int tickRatesLength = DEFAULT_INT,
										bool hasTeleports = DEFAULT_BOOL, int offset = DEFAULT_INT, int limit = DEFAULT_INT);

/**
 * Starts a GET HTTP Request to /api/{version}/record_filters/distributions
 *
 * @param callback				Callback when request has finished
 * @param data					Optional data to pass
 * @param ids					Array of ids to query
 * @param idsLength 			Length of the ids array
 * @param mapIds				Array of map ids to query
 * @param mapIdsLength			Length of the map ids array
 * @param stages				Array of stages to query
 * @param stagesLength			Length of the stages array
 * @param modeIds				Array of mode ids to query
 * @param modeIdsLength			Length of the mode ids array
 * @param tickRates				Array of tickrates to query
 * @param tickRatesLength		Length of the tickrates array
 * @param hasTeleports			Whether to query for hasTeleports or not
 * @param offset				Offset of the dataset to query
 * @param limit					Amount of items returned for the query
 * @return						Whether request was successfully sent
 */
native bool GlobalAPI_GetRecordFilterDistributions(OnAPICallFinished callback = INVALID_FUNCTION, any data = DEFAULT_DATA,
													int[] ids = DEFAULT_INT, int idsLength = DEFAULT_INT,
													int[] mapIds = DEFAULT_INT, int mapIdsLength = DEFAULT_INT,
													int[] stages = DEFAULT_INT, int stagesLength = DEFAULT_INT,
													int[] modeIds = DEFAULT_INT, int modeIdsLength = DEFAULT_INT,
													int[] tickRates = DEFAULT_INT, int tickRatesLength = DEFAULT_INT,
													bool hasTeleports = DEFAULT_BOOL, int offset = DEFAULT_INT, int limit = DEFAULT_INT);

/**
 * Starts a GET HTTP Request to /api/{version}/records/replay/list
 *
 * @param callback				Callback when request has finished
 * @param data					Optional data to pass
 * @param offset				Offset of the dataset to query
 * @param limit					Amount of items returned for the query
 * @return						Whether request was successfully sent
 */
native bool GlobalAPI_GetReplayList(OnAPICallFinished callback = INVALID_FUNCTION, any data = DEFAULT_DATA,
									int offset = DEFAULT_INT, int limit = DEFAULT_INT);

/**
 * Starts a GET HTTP Request to /api/{version}/records/{recordId}/replay
 *
 * @param callback				Callback when request has finished
 * @param data					Optional data to pass
 * @param recordId				Record id to query
 * @return						Whether request was successfully sent
 */
native bool GlobalAPI_GetReplayByRecordId(OnAPICallFinished callback = INVALID_FUNCTION, any data = DEFAULT_DATA, int recordId);
/**
 * Starts a GET HTTP Request to /api/{version}/records/replay/{replayId}
 *
 * @param callback				Callback when request has finished
 * @param data					Optional data to pass
 * @param replayId				Replay id to query
 * @return						Whether request was successfully sent
 */
native bool GlobalAPI_GetReplayByReplayId(OnAPICallFinished callback = INVALID_FUNCTION, any data = DEFAULT_DATA, int replayId);

/**
 * Starts a POST HTTP Request to /api/{version}/records/{recordId}/replay
 *
 * @param callback				Callback when request has finished
 * @param data					Optional data to pass
 * @param recordId				Id of the record
 * @param replayFile			Path to the replay file
 * @return						Whether request was successfully sent
 */
native bool GlobalAPI_CreateReplayForRecordId(OnAPICallFinished callback = INVALID_FUNCTION, any data = DEFAULT_DATA,
												int recordId, char[] replayFile);

// ======================= PLUGIN INFO ======================= //

public SharedPlugin __pl_GlobalAPI =
{
	name = "GlobalAPI",
	file = "GlobalAPI.smx",
	#if defined REQUIRE_PLUGIN
	required = 1,
	#else
	required = 0,
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_GlobalAPI_SetNTVOptional()
{
	// Plugin
	MarkNativeAsOptional("GlobalAPI_IsInit");
	MarkNativeAsOptional("GlobalAPI_GetAPIKey");
	MarkNativeAsOptional("GlobalAPI_HasAPIKey");
	MarkNativeAsOptional("GlobalAPI_IsStaging");
	MarkNativeAsOptional("GlobalAPI_IsDebugging");
	MarkNativeAsOptional("GlobalAPI_SendRequest");
	MarkNativeAsOptional("GlobalAPI_DebugMessage");

	// Auth
	MarkNativeAsOptional("GlobalAPI_GetAuthStatus");
	
	// Bans
	MarkNativeAsOptional("GlobalAPI_GetBans");
	MarkNativeAsOptional("GlobalAPI_CreateBan");

	// Jumpstats
	MarkNativeAsOptional("GlobalAPI_GetJumpstats");
	MarkNativeAsOptional("GlobalAPI_GetJumpstatTop");
	MarkNativeAsOptional("GlobalAPI_GetJumpstatTop30");

	// Maps
	MarkNativeAsOptional("GlobalAPI_GetMaps");
	MarkNativeAsOptional("GlobalAPI_GetMapById");
	MarkNativeAsOptional("GlobalAPI_GetMapByName");

	// Modes
	MarkNativeAsOptional("GlobalAPI_GetModes");
	MarkNativeAsOptional("GlobalAPI_GetModeById");
	MarkNativeAsOptional("GlobalAPI_GetModeByName");

	// Players
	MarkNativeAsOptional("GlobalAPI_GetPlayers");
	MarkNativeAsOptional("GlobalAPI_GetPlayerBySteamId");
	MarkNativeAsOptional("GlobalAPI_GetPlayerBySteamIdAndIp");

	// Records
	MarkNativeAsOptional("GlobalAPI_CreateRecord");
	MarkNativeAsOptional("GlobalAPI_GetRecordPlaceById");
	MarkNativeAsOptional("GlobalAPI_GetRecordsTop");
	MarkNativeAsOptional("GlobalAPI_GetRecordsTopRecent");
	MarkNativeAsOptional("GlobalAPI_GetRecordsTopWorldRecords");

	// Servers
	MarkNativeAsOptional("GlobalAPI_GetServers");
	MarkNativeAsOptional("GlobalAPI_GetServerById");
	MarkNativeAsOptional("GlobalAPI_GetServersByName");
	
	// Ranks
	MarkNativeAsOptional("GlobalAPI_GetPlayerRanks");
	
	// Record Filters
	MarkNativeAsOptional("GlobalAPI_GetRecordFilters");
	MarkNativeAsOptional("GlobalAPI_GetRecordFilterDistributions");

	// Replays
	MarkNativeAsOptional("GlobalAPI_GetReplayList");
	MarkNativeAsOptional("GlobalAPI_GetReplayByRecordId");
	MarkNativeAsOptional("GlobalAPI_GetReplayByReplayId");
	MarkNativeAsOptional("GlobalAPI_CreateReplayForRecordId");
}
#endif
