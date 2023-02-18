/*
	Bot replay playback logic and processes.
	
	The recorded files are read and their information and tick data
	stored into variables. A bot is then used to playback the recorded
	data by setting it's origin, velocity, etc. in OnPlayerRunCmd.
*/



static int preAndPostRunTickCount;

static int playbackTick[RP_MAX_BOTS];
static ArrayList playbackTickData[RP_MAX_BOTS];
static bool inBreather[RP_MAX_BOTS];
static float breatherStartTime[RP_MAX_BOTS];

// Original bot caller, needed for OnClientPutInServer callback
static int botCaller[RP_MAX_BOTS];
// Original bot name after creation by bot_add, needed for bot removal
static char botName[RP_MAX_BOTS][MAX_NAME_LENGTH];
static bool botInGame[RP_MAX_BOTS];
static int botClient[RP_MAX_BOTS];
static bool botDataLoaded[RP_MAX_BOTS];
static int botReplayType[RP_MAX_BOTS];
static int botReplayVersion[RP_MAX_BOTS];
static int botSteamAccountID[RP_MAX_BOTS];
static int botCourse[RP_MAX_BOTS];
static int botMode[RP_MAX_BOTS];
static int botStyle[RP_MAX_BOTS];
static float botTime[RP_MAX_BOTS];
static int botTimeTicks[RP_MAX_BOTS];
static char botAlias[RP_MAX_BOTS][MAX_NAME_LENGTH];
static bool botPaused[RP_MAX_BOTS];
static bool botPlaybackPaused[RP_MAX_BOTS];
static int botKnife[RP_MAX_BOTS];
static int botWeapon[RP_MAX_BOTS];
static int botJumpType[RP_MAX_BOTS];
static float botJumpDistance[RP_MAX_BOTS];
static int botJumpBlockDistance[RP_MAX_BOTS];

static int timeOnGround[RP_MAX_BOTS];
static int timeInAir[RP_MAX_BOTS];
static int botTeleportsUsed[RP_MAX_BOTS];
static int botCurrentTeleport[RP_MAX_BOTS];
static int botButtons[RP_MAX_BOTS];
static MoveType botMoveType[RP_MAX_BOTS];
static float botTakeoffSpeed[RP_MAX_BOTS];
static float botSpeed[RP_MAX_BOTS];
static float botLastOrigin[RP_MAX_BOTS][3];
static bool hitBhop[RP_MAX_BOTS];
static bool hitPerf[RP_MAX_BOTS];
static bool botJumped[RP_MAX_BOTS];
static bool botIsTakeoff[RP_MAX_BOTS];
static float botLandingSpeed[RP_MAX_BOTS];



// =====[ PUBLIC ]=====

// Returns the client index of the replay bot, or -1 otherwise
int LoadReplayBot(int client, char[] path)
{
	// Safeguard Check
	if (GOKZ_GetCoreOption(client, Option_Safeguard) > Safeguard_Disabled && GOKZ_GetTimerRunning(client) && GOKZ_GetValidTimer(client))
	{
		if (!GOKZ_GetPaused(client) && !GOKZ_GetCanPause(client))
		{
			GOKZ_PrintToChat(client, true, "%t", "Safeguard - Blocked");
			GOKZ_PlayErrorSound(client);
			return -1;
		}
	}
	int bot;
	if (GetBotsInUse() < RP_MAX_BOTS)
	{
		bot = GetUnusedBot();
	}
	else
	{
		GOKZ_PrintToChat(client, true, "%t", "No Bots Available");
		GOKZ_PlayErrorSound(client);
		return -1;
	}
	
	if (bot == -1)
	{
		LogError("Unused bot could not be found even though only %d out of %d are known to be in use.", 
				 GetBotsInUse(), RP_MAX_BOTS);
		GOKZ_PlayErrorSound(client);
		return -1;
	}

	if (!LoadPlayback(client, bot, path))
	{
		GOKZ_PlayErrorSound(client);
		return -1;
	}
	
	ServerCommand("bot_add");
	botCaller[bot] = client;
	return botClient[bot];
}

// Passes the current state of the replay into the HUDInfo struct
void GetPlaybackState(int client, HUDInfo info)
{
	int bot, i;
	for(i = 0; i < RP_MAX_BOTS; i++)
	{
		bot = botClient[i] == client ? i : bot;
	}
	if (i == RP_MAX_BOTS + 1) return;
	
	if (playbackTickData[bot] == INVALID_HANDLE)
	{
		return;
	}
	
	info.TimerRunning = botReplayType[bot] == ReplayType_Jump ? false : true;
	if (botReplayVersion[bot] == 1)
	{
		info.Time = botTime[bot];
	}
	else if (botReplayVersion[bot] == 2)
	{
		if (playbackTick[bot] < preAndPostRunTickCount)
		{
			info.Time = 0.0;
		}
		else if (playbackTick[bot] >= playbackTickData[bot].Length - preAndPostRunTickCount)
		{
			info.Time = botTime[bot];
		}
		else if (playbackTick[bot] >= preAndPostRunTickCount)
		{
			info.Time = (playbackTick[bot] - preAndPostRunTickCount) * GetTickInterval();
		}
	}
	info.TimeType = botTeleportsUsed[bot] > 0 ? TimeType_Nub : TimeType_Pro;
	info.Speed = botSpeed[bot];
	info.Paused = false;
	info.OnLadder = (botMoveType[bot] == MOVETYPE_LADDER);
	info.Noclipping = false;
	info.OnGround = Movement_GetOnGround(client);
	info.Ducking = botButtons[bot] & IN_DUCK > 0;
	info.ID = botClient[bot];
	info.Jumped = botJumped[bot];
	info.HitBhop = hitBhop[bot];
	info.HitPerf = hitPerf[bot];
	info.Buttons = botButtons[bot];
	info.TakeoffSpeed = botTakeoffSpeed[bot];
	info.IsTakeoff = botIsTakeoff[bot] && !Movement_GetOnGround(client);
	info.CurrentTeleport = botCurrentTeleport[bot];
}

int GetBotFromClient(int client)
{
	for (int bot = 0; bot < RP_MAX_BOTS; bot++)
	{
		if (botClient[bot] == client)
		{
			return bot;
		}
	}
	return -1;
}

bool InBreather(int bot)
{
	return inBreather[bot];
}

bool PlaybackPaused(int bot)
{
	return botPlaybackPaused[bot];
}

void PlaybackTogglePause(int bot)
{
	if(botPlaybackPaused[bot])
	{
		botPlaybackPaused[bot] = false;
	}
	else
	{
		botPlaybackPaused[bot] = true;
	}
}

void PlaybackSkipForward(int bot)
{
	if (playbackTick[bot] + RoundToZero(RP_SKIP_TIME / GetTickInterval()) < playbackTickData[bot].Length)
	{
		PlaybackSkipToTick(bot, playbackTick[bot] + RoundToZero(RP_SKIP_TIME / GetTickInterval()));
	}
}

void PlaybackSkipBack(int bot)
{
	if (playbackTick[bot] < RoundToZero(RP_SKIP_TIME / GetTickInterval()))
	{
		PlaybackSkipToTick(bot, 0);
	}
	else
	{
		PlaybackSkipToTick(bot, playbackTick[bot] - RoundToZero(RP_SKIP_TIME / GetTickInterval()));
	}
}

int PlaybackGetTeleports(int bot)
{
	return botCurrentTeleport[bot];
}

void TrySkipToTime(int client, int seconds)
{
	if (!IsValidClient(client))
	{
		return;
	}
	
	int tick = seconds * 128;
	int bot = GetBotFromClient(GetObserverTarget(client));
	
	if (tick >= 0 && tick < playbackTickData[bot].Length)
	{
		PlaybackSkipToTick(bot, tick);
	}
	else
	{
		GOKZ_PrintToChat(client, true, "%t", "Replay Controls - Invalid Time");
	}
}

float GetPlaybackTime(int bot)
{
	if (playbackTick[bot] < preAndPostRunTickCount)
	{
		return 0.0;
	}
	if (playbackTick[bot] >= playbackTickData[bot].Length - (preAndPostRunTickCount * 2))
	{
		return botTime[bot];
	}
	if (playbackTick[bot] >= preAndPostRunTickCount)
	{
		return (playbackTick[bot] - preAndPostRunTickCount) * GetTickInterval();
	}

	return 0.0;
}



// =====[ EVENTS ]=====

void OnClientPutInServer_Playback(int client)
{
	if (!IsFakeClient(client) || IsClientSourceTV(client))
	{
		return;
	}
	
	// Check if an unassigned bot has joined, and assign it
	for (int bot; bot < RP_MAX_BOTS; bot++)
	{
		// Also check if the bot was created by us.
		if (!botInGame[bot] && botCaller[bot] != 0)
		{
			botInGame[bot] = true;
			botClient[bot] = client;
			GetClientName(client, botName[bot], sizeof(botName[]));
			// The bot won't receive its weapons properly if we don't wait a frame
			RequestFrame(SetBotStuff, bot);
			if (IsValidClient(botCaller[bot]))
			{
				MakePlayerSpectate(botCaller[bot], botClient[bot]);
				botCaller[bot] = 0;
			}
			break;
		}
	}
}

void OnClientDisconnect_Playback(int client)
{
	for (int bot; bot < RP_MAX_BOTS; bot++)
	{
		if (botClient[bot] != client)
		{
			continue;
		}
		
		botInGame[bot] = false;
		if (playbackTickData[bot] != null)
		{
			playbackTickData[bot].Clear(); // Clear it all out
			botDataLoaded[bot] = false;
		}
	}
}

void OnPlayerRunCmd_Playback(int client, int &buttons)
{
	if (!IsFakeClient(client))
	{
		return;
	}
	
	for (int bot; bot < RP_MAX_BOTS; bot++)
	{
		// Check if not the bot we're looking for
		if (!botInGame[bot] || botClient[bot] != client || !botDataLoaded[bot])
		{
			continue;
		}

		switch (botReplayVersion[bot])
		{
			case 1: PlaybackVersion1(client, bot, buttons);
			case 2: PlaybackVersion2(client, bot, buttons);
		}
		break;
	}
}

void GOKZ_OnOptionsLoaded_Playback(int client)
{
	for (int bot = 0; bot < RP_MAX_BOTS; bot++)
	{
		if (botClient[bot] == client)
		{
			// Reset its movement options as it might be wrongfully changed
			GOKZ_SetCoreOption(client, Option_Mode, botMode[bot]);
			GOKZ_SetCoreOption(client, Option_Style, botStyle[bot]);
		}
	}
}

// =====[ PRIVATE ]=====

// Returns false if there was a problem loading the playback e.g. doesn't exist
static bool LoadPlayback(int client, int bot, char[] path)
{
	if (!FileExists(path))
	{
		GOKZ_PrintToChat(client, true, "%t", "No Replay Found");
		return false;
	}

	File file = OpenFile(path, "rb");
	
	// Check magic number in header
	int magicNumber;
	file.ReadInt32(magicNumber);
	if (magicNumber != RP_MAGIC_NUMBER)
	{
		LogError("Failed to load invalid replay file: \"%s\".", path);
		delete file;
		return false;
	}
	
	// Check replay format version
	int formatVersion;
	file.ReadInt8(formatVersion);
	switch(formatVersion)
	{
		case 1:
		{
			botReplayVersion[bot] = 1;
			if (!LoadFormatVersion1Replay(file, bot))
			{
				return false;
			}
		}
		case 2:
		{
			botReplayVersion[bot] = 2;
			if (!LoadFormatVersion2Replay(file, client, bot))
			{
				return false;
			}
		}

		default:
		{
			LogError("Failed to load replay file with unsupported format version: \"%s\".", path);
			delete file;
			return false;
		}
	}

	return true;
}

static bool LoadFormatVersion1Replay(File file, int bot)
{	
	// Old replays only support runs, not jumps
	botReplayType[bot] = ReplayType_Run;

	int length;

	// GOKZ version
	file.ReadInt8(length);
	char[] gokzVersion = new char[length + 1];
	file.ReadString(gokzVersion, length, length);
	gokzVersion[length] = '\0';
	
	// Map name 
	file.ReadInt8(length);
	char[] mapName = new char[length + 1];
	file.ReadString(mapName, length, length);
	mapName[length] = '\0';
	
	// Some integers...
	file.ReadInt32(botCourse[bot]);
	file.ReadInt32(botMode[bot]);
	file.ReadInt32(botStyle[bot]);
	
	// Old replays don't store the weapon information
	botKnife[bot] = CS_WeaponIDToItemDefIndex(CSWeapon_KNIFE);
	botWeapon[bot] = (botMode[bot] == Mode_Vanilla) ? -1 : CS_WeaponIDToItemDefIndex(CSWeapon_USP_SILENCER);
	
	// Time
	int timeAsInt;
	file.ReadInt32(timeAsInt);
	botTime[bot] = view_as<float>(timeAsInt);
	
	// Some integers...
	file.ReadInt32(botTeleportsUsed[bot]);
	file.ReadInt32(botSteamAccountID[bot]);
	
	// SteamID2 
	file.ReadInt8(length);
	char[] steamID2 = new char[length + 1];
	file.ReadString(steamID2, length, length);
	steamID2[length] = '\0';
	
	// IP
	file.ReadInt8(length);
	char[] IP = new char[length + 1];
	file.ReadString(IP, length, length);
	IP[length] = '\0';
	
	// Alias
	file.ReadInt8(length);
	file.ReadString(botAlias[bot], sizeof(botAlias[]), length);
	botAlias[bot][length] = '\0';
	
	// Read tick data
	file.ReadInt32(length);
	
	// Setup playback tick data array list
	if (playbackTickData[bot] == null)
	{
		playbackTickData[bot] = new ArrayList(IntMax(RP_V1_TICK_DATA_BLOCKSIZE, sizeof(ReplayTickData)), length);
	}
	else
	{  // Make sure it's all clear and the correct size
		playbackTickData[bot].Clear();
		playbackTickData[bot].Resize(length);
	}

	// The replay has no replay data, this shouldn't happen normally,
	// but this would cause issues in other code, so we don't even try to load this.
	if (length == 0)
	{
		delete file;
		return false;
	}
	
	any tickData[RP_V1_TICK_DATA_BLOCKSIZE];
	for (int i = 0; i < length; i++)
	{
		file.Read(tickData, RP_V1_TICK_DATA_BLOCKSIZE, 4);
		playbackTickData[bot].Set(i, view_as<float>(tickData[0]), 0); // origin[0]
		playbackTickData[bot].Set(i, view_as<float>(tickData[1]), 1); // origin[1]
		playbackTickData[bot].Set(i, view_as<float>(tickData[2]), 2); // origin[2]
		playbackTickData[bot].Set(i, view_as<float>(tickData[3]), 3); // angles[0]
		playbackTickData[bot].Set(i, view_as<float>(tickData[4]), 4); // angles[1]
		playbackTickData[bot].Set(i, view_as<int>(tickData[5]), 5); // buttons
		playbackTickData[bot].Set(i, view_as<int>(tickData[6]), 6); // flags
	}
	
	playbackTick[bot] = 0;
	botDataLoaded[bot] = true;
	
	delete file;
	return true;
}

static bool LoadFormatVersion2Replay(File file, int client, int bot)
{
	int length;

	// Replay type
	int replayType;
	file.ReadInt8(replayType);

	// GOKZ version
	file.ReadInt8(length);
	char[] gokzVersion = new char[length + 1];
	file.ReadString(gokzVersion, length, length);
	gokzVersion[length] = '\0';
	
	// Map name 
	file.ReadInt8(length);
	char[] mapName = new char[length + 1];
	file.ReadString(mapName, length, length);
	mapName[length] = '\0';
	if (!StrEqual(mapName, gC_CurrentMap))
	{
		GOKZ_PrintToChat(client, true, "%t", "Replay Menu - Wrong Map", mapName);
		delete file;
		return false;
	}

	// Map filesize
	int mapFileSize;
	file.ReadInt32(mapFileSize);

	// Server IP
	int serverIP;
	file.ReadInt32(serverIP);

	// Timestamp
	int timestamp;
	file.ReadInt32(timestamp);

	// Player Alias
	file.ReadInt8(length);
	file.ReadString(botAlias[bot], sizeof(botAlias[]), length);
	botAlias[bot][length] = '\0';

	// Player Steam ID
	int steamID;
	file.ReadInt32(steamID);

	// Mode
	file.ReadInt8(botMode[bot]);

	// Style
	file.ReadInt8(botStyle[bot]);

	// Player Sensitivity
	int intPlayerSensitivity;
	file.ReadInt32(intPlayerSensitivity);
	float playerSensitivity = view_as<float>(intPlayerSensitivity);

	// Player MYAW
	int intPlayerMYaw;
	file.ReadInt32(intPlayerMYaw);
	float playerMYaw = view_as<float>(intPlayerMYaw);

	// Tickrate
	int tickrateAsInt;
	file.ReadInt32(tickrateAsInt);
	float tickrate = view_as<float>(tickrateAsInt);
	if (tickrate != RoundToZero(1 / GetTickInterval()))
	{
		GOKZ_PrintToChat(client, true, "%t", "Replay Menu - Wrong Tickrate", tickrate, (RoundToZero(1 / GetTickInterval())));
		delete file;
		return false;
	}

	// Tick Count
	int tickCount;
	file.ReadInt32(tickCount);

	// The replay has no replay data, this shouldn't happen normally,
	// but this would cause issues in other code, so we don't even try to load this.
	if (tickCount == 0)
	{
		delete file;
		return false;
	}

	// Equipped Weapon
	file.ReadInt32(botWeapon[bot]);
	
	// Equipped Knife
	file.ReadInt32(botKnife[bot]);

	// Big spit to console
	PrintToConsole(client, "Replay Type: %d\nGOKZ Version: %s\nMap Name: %s\nMap Filesize: %d\nServer IP: %d\nTimestamp: %d\nPlayer Alias: %s\nPlayer Steam ID: %d\nMode: %d\nStyle: %d\nPlayer Sensitivity: %f\nPlayer m_yaw: %f\nTickrate: %f\nTick Count: %d\nWeapon: %d\nKnife: %d", replayType, gokzVersion, mapName, mapFileSize, serverIP, timestamp, botAlias[bot], steamID, botMode[bot], botStyle[bot], playerSensitivity, playerMYaw, tickrate, tickCount, botWeapon[bot], botKnife[bot]);

	switch(replayType)
	{
		case ReplayType_Run:
		{
			// Time
			int timeAsInt;
			file.ReadInt32(timeAsInt);
			botTime[bot] = view_as<float>(timeAsInt);
			botTimeTicks[bot] = RoundToNearest(botTime[bot] * tickrate);

			// Course
			file.ReadInt8(botCourse[bot]);

			// Teleports Used
			file.ReadInt32(botTeleportsUsed[bot]);

			// Type
			botReplayType[bot] = ReplayType_Run;
			
			// Finish spit to console
			PrintToConsole(client, "Time: %f\nCourse: %d\nTeleports Used: %d", botTime[bot], botCourse[bot], botTeleportsUsed[bot]);
		}
		case ReplayType_Cheater:
		{
			// Reason
			int reason;
			file.ReadInt8(reason);
			
			// Type
			botReplayType[bot] = ReplayType_Cheater;

			// Finish spit to console
			PrintToConsole(client, "AC Reason: %s", gC_ACReasons[reason]);
		}
		case ReplayType_Jump:
		{
			// Jump Type
			file.ReadInt8(botJumpType[bot]);

			// Distance
			file.ReadInt32(view_as<int>(botJumpDistance[bot]));

			// Block Distance
			file.ReadInt32(botJumpBlockDistance[bot]);

			// Strafe Count
			int strafeCount;
			file.ReadInt8(strafeCount);

			// Sync
			float sync;
			file.ReadInt32(view_as<int>(sync));

			// Pre
			float pre;
			file.ReadInt32(view_as<int>(pre));

			// Max
			float max;
			file.ReadInt32(view_as<int>(max));

			// Airtime
			int airtime;
			file.ReadInt32(airtime);

			// Type
			botReplayType[bot] = ReplayType_Jump;

			// Finish spit to console
			PrintToConsole(client, "Jump Type: %s\nJump Distance: %f\nBlock Distance: %d\nStrafe Count: %d\nSync: %f\n Pre: %f\nMax: %f\nAirtime: %d", 
				gC_JumpTypes[botJumpType[bot]], botJumpDistance[bot], botJumpBlockDistance[bot], strafeCount, sync, pre, max, airtime);
		}
	}

	// Tick Data
	// Setup playback tick data array list
	if (playbackTickData[bot] == null)
	{
		playbackTickData[bot] = new ArrayList(IntMax(RP_V1_TICK_DATA_BLOCKSIZE, sizeof(ReplayTickData)));
	}
	else
	{
		playbackTickData[bot].Clear();
	}
	
	// Read tick data
	preAndPostRunTickCount = RoundToZero(RP_PLAYBACK_BREATHER_TIME / GetTickInterval());
	any tickDataArray[RP_V2_TICK_DATA_BLOCKSIZE];
	for (int i = 0; i < tickCount; i++)
	{
		file.ReadInt32(tickDataArray[RPDELTA_DELTAFLAGS]);
		
		for (int index = 1; index < sizeof(tickDataArray); index++)
		{
			int currentFlag = (1 << index);
			if (tickDataArray[RPDELTA_DELTAFLAGS] & currentFlag)
			{
				file.ReadInt32(tickDataArray[index]);
			}
		}
		
		ReplayTickData tickData;
		TickDataFromArray(tickDataArray, tickData);
		// HACK: Jump replays don't record proper length sometimes. I don't know why.
		//		 This leads to oversized replays full of 0s at the end.
		// 		 So, we do this horrible check to dodge that issue.
		if (tickData.origin[0] == 0 && tickData.origin[1] == 0 && tickData.origin[2] == 0 && tickData.angles[0] == 0 && tickData.angles[1] == 0)
		{
			break;
		}
		playbackTickData[bot].PushArray(tickData);
	}
	
	playbackTick[bot] = 0;
	botDataLoaded[bot] = true;
	
	delete file;

	return true;
}

static void PlaybackVersion1(int client, int bot, int &buttons)
{		
	int size = playbackTickData[bot].Length;
	float repOrigin[3], repAngles[3];
	int repButtons, repFlags;
	
	// If first or last frame of the playback
	if (playbackTick[bot] == 0 || playbackTick[bot] == (size - 1))
	{
		// Move the bot and pause them at that tick
		repOrigin[0] = playbackTickData[bot].Get(playbackTick[bot], 0);
		repOrigin[1] = playbackTickData[bot].Get(playbackTick[bot], 1);
		repOrigin[2] = playbackTickData[bot].Get(playbackTick[bot], 2);
		repAngles[0] = playbackTickData[bot].Get(playbackTick[bot], 3);
		repAngles[1] = playbackTickData[bot].Get(playbackTick[bot], 4);
		TeleportEntity(client, repOrigin, repAngles, view_as<float>( { 0.0, 0.0, 0.0 } ));
		
		if (!inBreather[bot])
		{
			// Start the breather period
			inBreather[bot] = true;
			breatherStartTime[bot] = GetEngineTime();
			if (playbackTick[bot] == (size - 1)) 
			{
				GOKZ_EmitSoundToClientSpectators(client, gC_ModeEndSounds[GOKZ_GetCoreOption(client, Option_Mode)], _, "Timer End");
			}
		}
		else if (GetEngineTime() > breatherStartTime[bot] + RP_PLAYBACK_BREATHER_TIME)
		{
			// End the breather period
			inBreather[bot] = false;
			botPlaybackPaused[bot] = false;
			if (playbackTick[bot] == 0)
			{
				GOKZ_EmitSoundToClientSpectators(client, gC_ModeStartSounds[GOKZ_GetCoreOption(client, Option_Mode)], _, "Timer Start");
			}
			// Start the bot if first tick. Clear bot if last tick.
			playbackTick[bot]++;
			if (playbackTick[bot] == size)
			{
				playbackTickData[bot].Clear(); // Clear it all out
				botDataLoaded[bot] = false;
				CancelReplayControlsForBot(bot);
				ServerCommand("bot_kick %s", botName[bot]);
			}
		}
	}
	else
	{
		// Check whether somebody is actually spectating the bot
		int spec;
		for (spec = 1; spec < MAXPLAYERS + 1; spec++)
		{
			if (IsValidClient(spec) && GetObserverTarget(spec) == botClient[bot])
			{
				break;
			}
		}
		if (spec == MAXPLAYERS + 1 && !IsReplayBotControlled(bot, botClient[bot]))
		{
			playbackTickData[bot].Clear();
			botDataLoaded[bot] = false;
			CancelReplayControlsForBot(bot);
			ServerCommand("bot_kick %s", botName[bot]);
			return;
		}
		
		// Load in the next tick
		repOrigin[0] = playbackTickData[bot].Get(playbackTick[bot], 0);
		repOrigin[1] = playbackTickData[bot].Get(playbackTick[bot], 1);
		repOrigin[2] = playbackTickData[bot].Get(playbackTick[bot], 2);
		repAngles[0] = playbackTickData[bot].Get(playbackTick[bot], 3);
		repAngles[1] = playbackTickData[bot].Get(playbackTick[bot], 4);
		repButtons = playbackTickData[bot].Get(playbackTick[bot], 5);
		repFlags = playbackTickData[bot].Get(playbackTick[bot], 6);
		
		// Check if the replay is paused
		if (botPlaybackPaused[bot])
		{
			TeleportEntity(client, repOrigin, repAngles, view_as<float>( { 0.0, 0.0, 0.0 } ));
			return;
		}
		
		// Set velocity to travel from current origin to recorded origin
		float currentOrigin[3], velocity[3];
		Movement_GetOrigin(client, currentOrigin);
		MakeVectorFromPoints(currentOrigin, repOrigin, velocity);
		ScaleVector(velocity, 128.0); // Hard-coded 128 tickrate
		TeleportEntity(client, NULL_VECTOR, repAngles, velocity);

		// We need the velocity directly from the replay to calculate the speeds
		// for the HUD.
		MakeVectorFromPoints(botLastOrigin[bot], repOrigin, velocity);
		ScaleVector(velocity, 128.0); // Hard-coded 128 tickrate
		CopyVector(repOrigin, botLastOrigin[bot]);
		
		botSpeed[bot] = GetVectorHorizontalLength(velocity);
		buttons = repButtons;
		botButtons[bot] = repButtons;

		// Should the bot be ducking?!
		if (repButtons & IN_DUCK || repFlags & FL_DUCKING)
		{
			buttons |= IN_DUCK;
		}
		
		// If the replay file says the bot's on the ground, then fine! Unless you're going too fast...
		// Note that we don't mind if replay file says bot isn't on ground but the bot is.
		if (repFlags & FL_ONGROUND && Movement_GetSpeed(client) < SPEED_NORMAL * 2)
		{
			if (timeInAir[bot] > 0)
			{
				botLandingSpeed[bot] = botSpeed[bot];
				timeInAir[bot] = 0;
				botIsTakeoff[bot] = false;
				botJumped[bot] = false;
				hitBhop[bot] = false;
				hitPerf[bot] = false;
				if (!Movement_GetOnGround(client))
				{
					timeOnGround[bot] = 0;
				}
			}
			
			SetEntityFlags(client, GetEntityFlags(client) | FL_ONGROUND);
			Movement_SetMovetype(client, MOVETYPE_WALK);
			
			timeOnGround[bot]++;
			botTakeoffSpeed[bot] = botSpeed[bot];
		}
		else
		{
			if (timeInAir[bot] == 0)
			{
				botIsTakeoff[bot] = true;
				botJumped[bot] = botButtons[bot] & IN_JUMP > 0;
				hitBhop[bot] = (timeOnGround[bot] <= RP_MAX_BHOP_GROUND_TICKS) && botJumped[bot];
				
				if (botMode[bot] == Mode_SimpleKZ)
				{
					hitPerf[bot] = timeOnGround[bot] < 3 && botJumped[bot];
				}
				else
				{
					hitPerf[bot] = timeOnGround[bot] < 2 && botJumped[bot];
				}
				
				if (hitPerf[bot])
				{
					if (botMode[bot] == Mode_SimpleKZ)
					{
						botTakeoffSpeed[bot] = FloatMin(botLandingSpeed[bot], (0.2 * botLandingSpeed[bot] + 200));
					}
					else if (botMode[bot] == Mode_KZTimer)
					{
						botTakeoffSpeed[bot] = FloatMin(botLandingSpeed[bot], 380.0);
					}
					else
					{
						botTakeoffSpeed[bot] = FloatMin(botLandingSpeed[bot], 286.0);
					}
				}
			}
			else
			{
				botJumped[bot] = false;
				botIsTakeoff[bot] = false;
			}
			
			timeInAir[bot]++;
			Movement_SetMovetype(client, MOVETYPE_NOCLIP);
		}

		playbackTick[bot]++;
	}
}
void PlaybackVersion2(int client, int bot, int &buttons)
{
	int size = playbackTickData[bot].Length;
	ReplayTickData prevTickData;
	ReplayTickData currentTickData;
	
	// If first or last frame of the playback
	if (playbackTick[bot] == 0 || playbackTick[bot] == (size - 1))
	{
		// Move the bot and pause them at that tick
		playbackTickData[bot].GetArray(playbackTick[bot], currentTickData);
		playbackTickData[bot].GetArray(IntMax(playbackTick[bot] - 1, 0), prevTickData);
		TeleportEntity(client, currentTickData.origin, currentTickData.angles, view_as<float>( { 0.0, 0.0, 0.0 } ));
		
		if (!inBreather[bot])
		{
			// Start the breather period
			inBreather[bot] = true;
			breatherStartTime[bot] = GetEngineTime();
		}
		else if (GetEngineTime() > breatherStartTime[bot] + RP_PLAYBACK_BREATHER_TIME)
		{
			// End the breather period
			inBreather[bot] = false;
			botPlaybackPaused[bot] = false;

			// Start the bot if first tick. Clear bot if last tick.
			playbackTick[bot]++;
			if (playbackTick[bot] == size)
			{
				playbackTickData[bot].Clear(); // Clear it all out
				botDataLoaded[bot] = false;
				CancelReplayControlsForBot(bot);
				ServerCommand("bot_kick %s", botName[bot]);
			}
		}
	}
	else
	{
		// Check whether somebody is actually spectating the bot
		int spec;
		for (spec = 1; spec < MAXPLAYERS + 1; spec++)
		{
			if (IsValidClient(spec) && GetObserverTarget(spec) == botClient[bot])
			{
				break;
			}
		}
		if (spec == MAXPLAYERS + 1 && !IsReplayBotControlled(bot, botClient[bot]))
		{
			playbackTickData[bot].Clear();
			botDataLoaded[bot] = false;
			CancelReplayControlsForBot(bot);
			ServerCommand("bot_kick %s", botName[bot]);
			return;
		}
		
		// Load in the next tick
		playbackTickData[bot].GetArray(playbackTick[bot], currentTickData);
		playbackTickData[bot].GetArray(IntMax(playbackTick[bot] - 1, 0), prevTickData);
		
		// Check if the replay is paused
		if (botPlaybackPaused[bot])
		{
			TeleportEntity(client, currentTickData.origin, currentTickData.angles, view_as<float>( { 0.0, 0.0, 0.0 } ));
			return;
		}

		// Play timer start/end sound, if necessary. Reset teleports
		if (playbackTick[bot] == preAndPostRunTickCount && botReplayType[bot] == ReplayType_Run)
		{
			GOKZ_EmitSoundToClientSpectators(client, gC_ModeStartSounds[GOKZ_GetCoreOption(client, Option_Mode)], _, "Timer Start");
			botCurrentTeleport[bot] = 0;
		}
		if (playbackTick[bot] == botTimeTicks[bot] + preAndPostRunTickCount && botReplayType[bot] == ReplayType_Run)
		{
			GOKZ_EmitSoundToClientSpectators(client, gC_ModeEndSounds[GOKZ_GetCoreOption(client, Option_Mode)], _, "Timer End");
		}

		// Set velocity to travel from current origin to recorded origin
		float currentOrigin[3], velocity[3];
		Movement_GetOrigin(client, currentOrigin);
		MakeVectorFromPoints(currentOrigin, currentTickData.origin, velocity);
		ScaleVector(velocity, 1.0 / GetTickInterval());
		TeleportEntity(client, NULL_VECTOR, currentTickData.angles, velocity);
		
		botSpeed[bot] = GetVectorHorizontalLength(currentTickData.velocity);

		// Set buttons
		int newButtons;
		if (currentTickData.flags & RP_IN_ATTACK)
		{
			newButtons |= IN_ATTACK;
		}
		if (currentTickData.flags & RP_IN_ATTACK2)
		{
			newButtons |= IN_ATTACK2;
		}
		if (currentTickData.flags & RP_IN_JUMP)
		{
			newButtons |= IN_JUMP;
		}
		if (currentTickData.flags & RP_IN_DUCK || currentTickData.flags & RP_FL_DUCKING)
		{
			newButtons |= IN_DUCK;
		}
		if (currentTickData.flags & RP_IN_FORWARD)
		{
			newButtons |= IN_FORWARD;
		}
		if (currentTickData.flags & RP_IN_BACK)
		{
			newButtons |= IN_BACK;
		}
		if (currentTickData.flags & RP_IN_LEFT)
		{
			newButtons |= IN_LEFT;
		}
		if (currentTickData.flags & RP_IN_RIGHT)
		{
			newButtons |= IN_RIGHT;
		}
		if (currentTickData.flags & RP_IN_MOVELEFT)
		{
			newButtons |= IN_MOVELEFT;
		}
		if (currentTickData.flags & RP_IN_MOVERIGHT)
		{
			newButtons |= IN_MOVERIGHT;
		}
		if (currentTickData.flags & RP_IN_RELOAD)
		{
			newButtons |= IN_RELOAD;
		}
		if (currentTickData.flags & RP_IN_SPEED)
		{
			newButtons |= IN_SPEED;
		}
		buttons = newButtons;
		botButtons[bot] = buttons;

		int entityFlags = GetEntityFlags(client);
		// Set the bot's MoveType
		MoveType replayMoveType = view_as<MoveType>(currentTickData.flags & RP_MOVETYPE_MASK);
		botMoveType[bot] = replayMoveType;
		if (Movement_GetSpeed(client) > SPEED_NORMAL * 2)
		{
			Movement_SetMovetype(client, MOVETYPE_NOCLIP);
		}
		else if (replayMoveType == MOVETYPE_WALK && currentTickData.flags & RP_FL_ONGROUND)
		{
			botPaused[bot] = false;
			SetEntityFlags(client, entityFlags | FL_ONGROUND);
			Movement_SetMovetype(client, MOVETYPE_WALK);
			// The bot is on the ground, so there must be a ground entity attributed to the bot.
			int groundEnt = GetEntPropEnt(client, Prop_Send, "m_hGroundEntity");
			if (groundEnt == -1)
			{
				float endPosition[3], mins[3], maxs[3];
				GetEntPropVector(client, Prop_Send, "m_vecMaxs", maxs);
				GetEntPropVector(client, Prop_Send, "m_vecMins", mins);
				endPosition = currentTickData.origin;
				endPosition[2] -= 2.0;
				TR_TraceHullFilter(currentTickData.origin, endPosition, mins, maxs, MASK_PLAYERSOLID, TraceEntityFilterPlayers);
				// This should always hit.
				if (TR_DidHit())
				{
					groundEnt = TR_GetEntityIndex();
					SetEntPropEnt(client, Prop_Data, "m_hGroundEntity", groundEnt);
				}
			}
		}
		else if (replayMoveType == MOVETYPE_LADDER)
		{
			botPaused[bot] = false;
			Movement_SetMovetype(client, MOVETYPE_LADDER);
		}
		else
		{
			Movement_SetMovetype(client, MOVETYPE_NOCLIP);
		}
		
		if (currentTickData.flags & RP_UNDER_WATER)
		{
			SetEntityFlags(client, entityFlags | FL_INWATER);
		}

		// Set some variables
		if (currentTickData.flags & RP_TELEPORT_TICK)
		{
			botCurrentTeleport[bot]++;
			Movement_SetMovetype(client, MOVETYPE_NOCLIP);
		}

		if (currentTickData.flags & RP_TAKEOFF_TICK)
		{
			hitPerf[bot] = currentTickData.flags & RP_HIT_PERF > 0;
			botIsTakeoff[bot] = true;
			botTakeoffSpeed[bot] = GetVectorHorizontalLength(currentTickData.velocity);
		}

		if ((currentTickData.flags & RP_SECONDARY_EQUIPPED) && !IsCurrentWeaponSecondary(client))
		{
			int item = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
			if (item != -1)
			{
				char name[64];
				GetEntityClassname(item, name, sizeof(name));
				FakeClientCommand(client, "use %s", name);
			}
		}
		else if (!(currentTickData.flags & RP_SECONDARY_EQUIPPED) && IsCurrentWeaponSecondary(client))
		{
			int item = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
			if (item != -1)
			{
				char name[64];
				GetEntityClassname(item, name, sizeof(name));
				FakeClientCommand(client, "use %s", name);
			}
		}

		#if defined DEBUG
		if(!botPlaybackPaused[bot])
		{
			PrintToServer("Tick: %d", playbackTick[bot]);
			PrintToServer("X %f \nY %f \nZ %f\nPitch %f\nYaw %f", currentTickData.origin[0], currentTickData.origin[1], currentTickData.origin[2], currentTickData.angles[0], currentTickData.angles[1]);
			if(currentTickData.flags & RP_MOVETYPE_MASK == view_as<int>(MOVETYPE_WALK)) PrintToServer("MOVETYPE_WALK");
			if(currentTickData.flags & RP_MOVETYPE_MASK == view_as<int>(MOVETYPE_LADDER)) PrintToServer("MOVETYPE_LADDER");
			if(currentTickData.flags & RP_MOVETYPE_MASK == view_as<int>(MOVETYPE_NOCLIP)) PrintToServer("MOVETYPE_NOCLIP");
			if(currentTickData.flags & RP_MOVETYPE_MASK == view_as<int>(MOVETYPE_NOCLIP)) PrintToServer("MOVETYPE_NONE");

			if(currentTickData.flags & RP_IN_ATTACK) PrintToServer("IN_ATTACK");
			if(currentTickData.flags & RP_IN_ATTACK2) PrintToServer("IN_ATTACK2");
			if(currentTickData.flags & RP_IN_JUMP) PrintToServer("IN_JUMP");
			if(currentTickData.flags & RP_IN_DUCK) PrintToServer("IN_DUCK");
			if(currentTickData.flags & RP_IN_FORWARD) PrintToServer("IN_FORWARD");
			if(currentTickData.flags & RP_IN_BACK) PrintToServer("IN_BACK");
			if(currentTickData.flags & RP_IN_LEFT) PrintToServer("IN_LEFT");
			if(currentTickData.flags & RP_IN_RIGHT) PrintToServer("IN_RIGHT");
			if(currentTickData.flags & RP_IN_MOVELEFT) PrintToServer("IN_MOVELEFT");
			if(currentTickData.flags & RP_IN_MOVERIGHT) PrintToServer("IN_MOVERIGHT");
			if(currentTickData.flags & RP_IN_RELOAD) PrintToServer("IN_RELOAD");
			if(currentTickData.flags & RP_IN_SPEED) PrintToServer("IN_SPEED");
			if(currentTickData.flags & RP_IN_USE) PrintToServer("IN_USE");
			if(currentTickData.flags & RP_IN_BULLRUSH) PrintToServer("IN_BULLRUSH");

			if(currentTickData.flags & RP_FL_ONGROUND) PrintToServer("FL_ONGROUND");
			if(currentTickData.flags & RP_FL_DUCKING ) PrintToServer("FL_DUCKING");
			if(currentTickData.flags & RP_FL_SWIM) PrintToServer("FL_SWIM");
			if(currentTickData.flags & RP_UNDER_WATER) PrintToServer("WATERLEVEL!=0");
			if(currentTickData.flags & RP_TELEPORT_TICK) PrintToServer("TELEPORT");
			if(currentTickData.flags & RP_TAKEOFF_TICK) PrintToServer("TAKEOFF");
			if(currentTickData.flags & RP_HIT_PERF) PrintToServer("PERF");
			if(currentTickData.flags & RP_SECONDARY_EQUIPPED) PrintToServer("SECONDARY_WEAPON_EQUIPPED");
			PrintToServer("==============================================================");
		}
		#endif

		playbackTick[bot]++;
	}
}

// Set the bot client's GOKZ options, clan tag and name based on the loaded replay data
static void SetBotStuff(int bot)
{
	if (!botInGame[bot] || !botDataLoaded[bot])
	{
		return;
	}

	int client = botClient[bot];
	
	// Set its movement options just in case it could negatively affect the playback
	GOKZ_SetCoreOption(client, Option_Mode, botMode[bot]);
	GOKZ_SetCoreOption(client, Option_Style, botStyle[bot]);
	
	// Clan tag and name
	SetBotClanTag(bot);
	SetBotName(bot);

	// Bot takes one tick after being put in server to be able to respawn.
	RequestFrame(RequestFrame_SetBotStuff, GetClientUserId(client));
}

public void RequestFrame_SetBotStuff(int userid)
{
	int client = GetClientOfUserId(userid);
	if (!client)
	{
		return;
	}
	int bot;
	for (bot = 0; bot <= RP_MAX_BOTS; bot++)
	{
		if (botClient[bot] == client)
		{
			break;
		}
		else if (bot == RP_MAX_BOTS)
		{
			return;
		}
	}
	// Set the bot's team based on if it's NUB or PRO
	if (botReplayType[bot] == ReplayType_Run 
		&& GOKZ_GetTimeTypeEx(botTeleportsUsed[bot]) == TimeType_Pro)
	{
		GOKZ_JoinTeam(client, CS_TEAM_CT, .forceBroadcast = true);
	}
	else
	{
		GOKZ_JoinTeam(client, CS_TEAM_CT, .forceBroadcast = true);
	}
	// Set bot weapons
	// Always start by removing the pistol and knife
	int currentPistol = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
	if (currentPistol != -1)
	{
		RemovePlayerItem(client, currentPistol);
	}
	
	int currentKnife = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
	if (currentKnife != -1)
	{
		RemovePlayerItem(client, currentKnife);
	}

	char weaponName[128];
	// Give the bot the knife stored in the replay
	/*
	if (botKnife[bot] != 0)
	{
		CS_WeaponIDToAlias(CS_ItemDefIndexToID(botKnife[bot]), weaponName, sizeof(weaponName));
		Format(weaponName, sizeof(weaponName), "weapon_%s", weaponName);	
		GivePlayerItem(client, weaponName);
	}
	else
	{
		GivePlayerItem(client, "weapon_knife");
	}
	*/
	// We are currently not doing that, as it would require us to disable the
	// FollowCSGOServerGuidelines failsafe if the bot has a non-standard knife.
	GivePlayerItem(client, "weapon_knife");
	
	// Give the bot the pistol stored in the replay
	if (botWeapon[bot] != -1)
	{
		CS_WeaponIDToAlias(CS_ItemDefIndexToID(botWeapon[bot]), weaponName, sizeof(weaponName));
		Format(weaponName, sizeof(weaponName), "weapon_%s", weaponName);
		GivePlayerItem(client, weaponName);
	}

	botCurrentTeleport[bot] = 0;
}

static void SetBotClanTag(int bot)
{
	char tag[MAX_NAME_LENGTH];

	if (botReplayType[bot] == ReplayType_Run)
	{
		if (botCourse[bot] == 0)
		{
			// KZT PRO
			FormatEx(tag, sizeof(tag), "%s %s", 
				gC_ModeNamesShort[botMode[bot]], gC_TimeTypeNames[GOKZ_GetTimeTypeEx(botTeleportsUsed[bot])]);
		}
		else
		{
			// KZT B2 PRO
			FormatEx(tag, sizeof(tag), "%s B%d %s", 
				gC_ModeNamesShort[botMode[bot]], botCourse[bot], gC_TimeTypeNames[GOKZ_GetTimeTypeEx(botTeleportsUsed[bot])]);
		}
	}
	else if (botReplayType[bot] == ReplayType_Jump)
	{
		// KZT LJ
		FormatEx(tag, sizeof(tag), "%s %s",
			gC_ModeNamesShort[botMode[bot]], gC_JumpTypesShort[botJumpType[bot]]);
	}
	else
	{
		// KZT
		FormatEx(tag, sizeof(tag), "%s", 
			gC_ModeNamesShort[botMode[bot]]);
	}

	CS_SetClientClanTag(botClient[bot], tag);
}

static void SetBotName(int bot)
{
	char name[MAX_NAME_LENGTH];

	if (botReplayType[bot] == ReplayType_Run)
	{
		// DanZay (01:23.45)
		FormatEx(name, sizeof(name), "%s (%s)", 
			botAlias[bot], GOKZ_FormatTime(botTime[bot]));
	}
	else if (botReplayType[bot] == ReplayType_Jump)
	{
		if (botJumpBlockDistance[bot] == 0)
		{
			// DanZay (291.44)
			FormatEx(name, sizeof(name), "%s (%.2f)", 
				botAlias[bot], botJumpDistance[bot]);
		}
		else
		{
			// DanZay (291.44 on 289 block)
			FormatEx(name, sizeof(name), "%s (%.2f on %d block)", 
				botAlias[bot], botJumpDistance[bot], botJumpBlockDistance[bot]);
		}
	}
	else
	{
		// DanZay
		FormatEx(name, sizeof(name), "%s", 
			botAlias[bot]);
	}
	
	gB_HideNameChange = true;
	SetClientName(botClient[bot], name);
}

// Returns the number of bots that are currently replaying
static int GetBotsInUse()
{
	int botsInUse = 0;
	for (int bot; bot < RP_MAX_BOTS; bot++)
	{
		if (botInGame[bot] && botDataLoaded[bot])
		{
			botsInUse++;
		}
	}
	return botsInUse;
}

// Returns a bot that isn't currently replaying, or -1 if no unused bots found
static int GetUnusedBot()
{
	for (int bot = 0; bot < RP_MAX_BOTS; bot++)
	{
		if (!botInGame[bot])
		{
			return bot;
		}
	}
	return -1;
}

static void PlaybackSkipToTick(int bot, int tick)
{
	if (botReplayVersion[bot] == 1)
	{
		// Load in the next tick	
		float repOrigin[3], repAngles[3];
		repOrigin[0] = playbackTickData[bot].Get(tick, 0);
		repOrigin[1] = playbackTickData[bot].Get(tick, 1);
		repOrigin[2] = playbackTickData[bot].Get(tick, 2);
		repAngles[0] = playbackTickData[bot].Get(tick, 3);
		repAngles[1] = playbackTickData[bot].Get(tick, 4);
		
		TeleportEntity(botClient[bot], repOrigin, repAngles, view_as<float>( { 0.0, 0.0, 0.0 } ));
	}
	else if (botReplayVersion[bot] == 2)
	{
		// Load in the next tick
		ReplayTickData currentTickData;
		playbackTickData[bot].GetArray(tick, currentTickData);

		TeleportEntity(botClient[bot], currentTickData.origin, currentTickData.angles, view_as<float>( { 0.0, 0.0, 0.0 } ));

		int direction = tick < playbackTick[bot] ? -1 : 1;
		for (int i = playbackTick[bot]; i != tick; i += direction)
		{
			playbackTickData[bot].GetArray(i, currentTickData);
			if (currentTickData.flags & RP_TELEPORT_TICK)
			{
				botCurrentTeleport[bot] += direction;
			}
		}

		#if defined DEBUG 
			PrintToServer("X %f \nY %f \nZ %f\nPitch %f\nYaw %f", currentTickData.origin[0], currentTickData.origin[1], currentTickData.origin[2], currentTickData.angles[0], currentTickData.angles[1]);
			if(currentTickData.flags & RP_MOVETYPE_MASK == view_as<int>(MOVETYPE_WALK)) PrintToServer("MOVETYPE_WALK");
			if(currentTickData.flags & RP_MOVETYPE_MASK == view_as<int>(MOVETYPE_LADDER)) PrintToServer("MOVETYPE_LADDER");
			if(currentTickData.flags & RP_MOVETYPE_MASK == view_as<int>(MOVETYPE_NOCLIP)) PrintToServer("MOVETYPE_NOCLIP");
			if(currentTickData.flags & RP_MOVETYPE_MASK == view_as<int>(MOVETYPE_NONE)) PrintToServer("MOVETYPE_NONE");

			if(currentTickData.flags & RP_IN_ATTACK) PrintToServer("IN_ATTACK");
			if(currentTickData.flags & RP_IN_ATTACK2) PrintToServer("IN_ATTACK2");
			if(currentTickData.flags & RP_IN_JUMP) PrintToServer("IN_JUMP");
			if(currentTickData.flags & RP_IN_DUCK) PrintToServer("IN_DUCK");
			if(currentTickData.flags & RP_IN_FORWARD) PrintToServer("IN_FORWARD");
			if(currentTickData.flags & RP_IN_BACK) PrintToServer("IN_BACK");
			if(currentTickData.flags & RP_IN_LEFT) PrintToServer("IN_LEFT");
			if(currentTickData.flags & RP_IN_RIGHT) PrintToServer("IN_RIGHT");
			if(currentTickData.flags & RP_IN_MOVELEFT) PrintToServer("IN_MOVELEFT");
			if(currentTickData.flags & RP_IN_MOVERIGHT) PrintToServer("IN_MOVERIGHT");
			if(currentTickData.flags & RP_IN_RELOAD) PrintToServer("IN_RELOAD");
			if(currentTickData.flags & RP_IN_SPEED) PrintToServer("IN_SPEED");
			if(currentTickData.flags & RP_FL_ONGROUND) PrintToServer("FL_ONGROUND");
			if(currentTickData.flags & RP_FL_DUCKING ) PrintToServer("FL_DUCKING");
			if(currentTickData.flags & RP_FL_SWIM) PrintToServer("FL_SWIM");
			if(currentTickData.flags & RP_UNDER_WATER) PrintToServer("WATERLEVEL!=0");
			if(currentTickData.flags & RP_TELEPORT_TICK) PrintToServer("TELEPORT");
			if(currentTickData.flags & RP_TAKEOFF_TICK) PrintToServer("TAKEOFF");
			if(currentTickData.flags & RP_HIT_PERF) PrintToServer("PERF");
			if(currentTickData.flags & RP_SECONDARY_EQUIPPED) PrintToServer("SECONDARY_WEAPON_EQUIPPED");
			PrintToServer("==============================================================");
		#endif
	}

	Movement_SetMovetype(botClient[bot], MOVETYPE_NOCLIP);
	playbackTick[bot] = tick;
}

static bool IsCurrentWeaponSecondary(int client)
{
	int activeWeaponEnt = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	int secondaryEnt = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
	return activeWeaponEnt == secondaryEnt;
}

static void MakePlayerSpectate(int client, int bot)
{
	GOKZ_JoinTeam(client, CS_TEAM_SPECTATOR);
	SetEntProp(client, Prop_Send, "m_iObserverMode", 4);
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", bot);
		
	int clientUserID = GetClientUserId(client);
	DataPack data = new DataPack();
	data.WriteCell(clientUserID);
	data.WriteCell(GetClientUserId(bot));
	CreateTimer(0.1, Timer_UpdateBotName, GetClientUserId(bot));
	EnableReplayControls(client);
}

public Action Timer_UpdateBotName(Handle timer, int botUID)
{
	Event e = CreateEvent("spec_target_updated");
	e.SetInt("userid", botUID);
	e.Fire();
	return Plugin_Continue;
}