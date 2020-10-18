/*
	Bot replay playback logic and processes.
	
	The recorded files are read and their information and tick data
	stored into variables. A bot is then used to playback the recorded
	data by setting it's origin, velocity, etc. in OnPlayerRunCmd.
*/



static int playbackTick[RP_MAX_BOTS];
static ArrayList playbackTickData[RP_MAX_BOTS];
static bool inBreather[RP_MAX_BOTS];
static float breatherStartTime[RP_MAX_BOTS];

static bool botInGame[RP_MAX_BOTS];
static int botClient[RP_MAX_BOTS];
static bool botDataLoaded[RP_MAX_BOTS];
static int botSteamAccountID[RP_MAX_BOTS];
static int botCourse[RP_MAX_BOTS];
static int botMode[RP_MAX_BOTS];
static int botStyle[RP_MAX_BOTS];
static float botTime[RP_MAX_BOTS];
static char botAlias[RP_MAX_BOTS][MAX_NAME_LENGTH];
static bool botPaused[RP_MAX_BOTS];

static int timeOnGround[RP_MAX_BOTS];
static int timeInAir[RP_MAX_BOTS];
static int botTeleportsUsed[RP_MAX_BOTS];
static int botButtons[RP_MAX_BOTS];
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
int LoadReplayBot(int course, int mode, int style, int timeType)
{
	int bot;
	if (GetBotsInUse() < RP_MAX_BOTS)
	{
		bot = GetUnusedBot();
	}
	else
	{
		return -1;
	}
	
	if (bot == -1)
	{
		LogError(
			"Unused bot could not be found even though only %d out of %d are known to be in use.", 
			GetBotsInUse(), 
			RP_MAX_BOTS);
		return -1;
	}
	
	if (!LoadPlayback(bot, course, mode, style, timeType))
	{
		return -1;
	}
	
	SetBotStuff(bot);
	
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

	info.TimerRunning = true;
	info.Time = float(playbackTick[bot]) * GetTickInterval();
	info.TimeType = botTeleportsUsed[bot] > 0 ? TimeType_Nub : TimeType_Pro;
	info.Speed = botSpeed[bot];
	info.Paused = false;
	info.OnLadder = false;
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
	return botPaused[bot];
}

void PlaybackPause(int bot)
{
	botPaused[bot] = true;
}

void PlaybackResume(int bot)
{
	botPaused[bot] = false;
}

void PlaybackSkipForward(int bot)
{
	if (playbackTick[bot] + RP_SKIP_TICKS < playbackTickData[bot].Length)
	{
		PlaybackSkipToTick(bot, playbackTick[bot] + RP_SKIP_TICKS);
	}
}

void PlaybackSkipBack(int bot)
{
	if (playbackTick[bot] < RP_SKIP_TICKS)
	{
		PlaybackSkipToTick(bot, 0);
	}
	else
	{
		PlaybackSkipToTick(bot, playbackTick[bot] - RP_SKIP_TICKS);
	}
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
	return playbackTick[bot] / 128.0;
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
		if (!botInGame[bot])
		{
			botInGame[bot] = true;
			botClient[bot] = client;
			ResetBotStuff(bot);
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
					EmitSoundToClientSpectators(client, gC_ModeEndSounds[GOKZ_GetCoreOption(client, Option_Mode)]);
				}
			}
			else if (GetEngineTime() > breatherStartTime[bot] + RP_PLAYBACK_BREATHER_TIME)
			{
				// End the breather period
				inBreather[bot] = false;
				botPaused[bot] = false;
				if (playbackTick[bot] == 0)
				{
					EmitSoundToClientSpectators(client, gC_ModeStartSounds[GOKZ_GetCoreOption(client, Option_Mode)]);
				}
				// Start the bot if first tick. Clear bot if last tick.
				playbackTick[bot]++;
				if (playbackTick[bot] == size)
				{
					playbackTickData[bot].Clear(); // Clear it all out
					botDataLoaded[bot] = false;
					CancelReplayControlsForBot(bot);
					ResetBotStuff(bot);
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
				ResetBotStuff(bot);
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
			if (botPaused[bot])
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
		
		break;
	}
}



// =====[ PRIVATE ]=====

// Returns false if there was a problem loading the playback e.g. doesn't exist
static bool LoadPlayback(int bot, int course, int mode, int style, int timeType)
{
	// Setup file path and file
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), 
		"%s/%s/%d_%s_%s_%s.%s", 
		RP_DIRECTORY, gC_CurrentMap, course, gC_ModeNamesShort[mode], gC_StyleNamesShort[style], gC_TimeTypeNames[timeType], RP_FILE_EXTENSION);
	if (!FileExists(path))
	{
		LogError("Failed to load file: \"%s\".", path);
		return false;
	}
	
	File file = OpenFile(path, "rb");
	int length;
	
	// Check magic number in header
	int magicNumber;
	file.ReadInt32(magicNumber);
	if (magicNumber != RP_MAGIC_NUMBER)
	{
		LogError("Failed to load invalid replay file: \"%s\".", path);
		return false;
	}
	
	// Check replay format version
	int formatVersion;
	file.ReadInt8(formatVersion);
	if (formatVersion != RP_FORMAT_VERSION)
	{
		LogError("Failed to load replay file with unsupported format version: \"%s\".", path);
		return false;
	}
	
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
		playbackTickData[bot] = new ArrayList(RP_TICK_DATA_BLOCKSIZE, length);
	}
	else
	{  // Make sure it's all clear and the correct size
		playbackTickData[bot].Clear();
		playbackTickData[bot].Resize(length);
	}
	
	any tickData[RP_TICK_DATA_BLOCKSIZE];
	for (int i = 0; i < length; i++)
	{
		file.Read(tickData, RP_TICK_DATA_BLOCKSIZE, 4);
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

// Reset the bot client's clan tag and named to the default, unused state
static void ResetBotStuff(int bot)
{
	int client = botClient[bot];
	
	CS_SetClientClanTag(client, "!REPLAY");
	char name[MAX_NAME_LENGTH];
	FormatEx(name, sizeof(name), "%d", bot + 1);
	gB_HideNameChange = true;
	SetClientName(client, name);
	
	GOKZ_JoinTeam(client, CS_TEAM_SPECTATOR);
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
	
	// Set bot clan tag
	char tag[MAX_NAME_LENGTH];
	if (botCourse[bot] == 0)
	{  // Main course so tag "MODE NUB/PRO"
		FormatEx(tag, sizeof(tag), "%s %s", 
			gC_ModeNamesShort[botMode[bot]], gC_TimeTypeNames[GOKZ_GetTimeTypeEx(botTeleportsUsed[bot])]);
	}
	else
	{  // Bonus course so tag "MODE B# NUB/PRO"
		FormatEx(tag, sizeof(tag), "%s B%d %s", 
			gC_ModeNamesShort[botMode[bot]], botCourse[bot], gC_TimeTypeNames[GOKZ_GetTimeTypeEx(botTeleportsUsed[bot])]);
	}
	CS_SetClientClanTag(client, tag);
	
	// Set bot name e.g. "DanZay (01:23.45)"
	char name[MAX_NAME_LENGTH];
	FormatEx(name, sizeof(name), "%s (%s)", botAlias[bot], GOKZ_FormatTime(botTime[bot]));
	gB_HideNameChange = true;
	SetClientName(client, name);
	
	// Set the bot's team based on if it's NUB or PRO
	if (GOKZ_GetTimeTypeEx(botTeleportsUsed[bot]) == TimeType_Pro)
	{
		GOKZ_JoinTeam(client, CS_TEAM_CT);
	}
	else
	{
		GOKZ_JoinTeam(client, CS_TEAM_T);
	}
	
	// Set bot weapon according to mode of the replay
	// Always start by removing the pistol
	int currentPistol = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
	if (currentPistol != -1)
	{
		RemovePlayerItem(client, currentPistol);
	}
	
	if (botMode[bot] == Mode_Vanilla)
	{
		// If Vanilla replay, hold out a knife
		int currentKnife = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
		if (currentKnife != -1)
		{
			RemovePlayerItem(client, currentKnife);
		}
		
		GivePlayerItem(client, "weapon_knife");
	}
	else
	{
		// For other modes, wield a USP-S
		GivePlayerItem(client, "weapon_usp_silencer");
	}
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

// Returns a bot that isn't currently replaying, or -1 if unused bots found
static int GetUnusedBot()
{
	for (int bot = 0; bot < RP_MAX_BOTS; bot++)
	{
		if (botInGame[bot] && !botDataLoaded[bot])
		{
			return bot;
		}
	}
	return -1;
}

static void PlaybackSkipToTick(int bot, int tick)
{
	// Load in the next tick	
	float repOrigin[3], repAngles[3];
	repOrigin[0] = playbackTickData[bot].Get(tick, 0);
	repOrigin[1] = playbackTickData[bot].Get(tick, 1);
	repOrigin[2] = playbackTickData[bot].Get(tick, 2);
	repAngles[0] = playbackTickData[bot].Get(tick, 3);
	repAngles[1] = playbackTickData[bot].Get(tick, 4);
	
	TeleportEntity(botClient[bot], repOrigin, repAngles, view_as<float>( { 0.0, 0.0, 0.0 } ));
	Movement_SetMovetype(botClient[bot], MOVETYPE_NOCLIP);
	playbackTick[bot] = tick;
}
