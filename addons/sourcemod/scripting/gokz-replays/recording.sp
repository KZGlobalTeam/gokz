/*
	Bot replay recording logic and processes.
	
	Records data every time OnPlayerRunCmdPost is called.
	If the player doesn't have their timer running, it keeps track
	of the last 2 minutes of their actions. If a player is banned
	while their timer isn't running, those 2 minutes are saved.
	If the player has their timer running, the recording is done from
	the beginning of the run. If the player can no longer beat their PB,
	then the recording goes back to only keeping track of the last
	two minutes. Upon beating the server record, a binary file will be 
	written with a 'header' containing information about the run,
	followed by the recorded tick data from OnPlayerRunCmdPost.
*/

static float tickrate;
static int preAndPostRunTickCount;
static int maxCheaterReplayTicks;
static int recordingIndex[MAXPLAYERS + 1];
static float playerSensitivity[MAXPLAYERS + 1];
static float playerMYaw[MAXPLAYERS + 1];
static bool isTeleportTick[MAXPLAYERS + 1];
static bool isRecordingRun[MAXPLAYERS + 1];
static bool recordingPaused[MAXPLAYERS + 1];
static bool postRunRecording[MAXPLAYERS + 1];
static ArrayList recordedRecentData[MAXPLAYERS + 1];
static ArrayList recordedRunData[MAXPLAYERS + 1];
static ArrayList recordedPostRunData[MAXPLAYERS + 1];
static Handle runningRunBreatherTimer[MAXPLAYERS + 1];
static ArrayList runningJumpstatTimers[MAXPLAYERS + 1];

// =====[ EVENTS ]=====

void OnMapStart_Recording()
{
	CreateReplaysDirectory();
	tickrate = 1/GetTickInterval();
	preAndPostRunTickCount = RoundToZero(RP_PLAYBACK_BREATHER_TIME * tickrate);
	maxCheaterReplayTicks = RoundToCeil(RP_MAX_CHEATER_REPLAY_LENGTH * tickrate);
}

void OnClientPutInServer_Recording(int client)
{
	ClearClientRecordingState(client);
}

void OnClientAuthorized_Recording(int client)
{
	// Apparently the client isn't valid yet here, so we can't check for that!
	if(!IsFakeClient(client))
	{
		// Create directory path for player if not exists
		char replayPath[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, replayPath, sizeof(replayPath), "%s/%d", RP_DIRECTORY_JUMPS, GetSteamAccountID(client));
		if (!DirExists(replayPath))
		{
			CreateDirectory(replayPath, 511);
		}
		BuildPath(Path_SM, replayPath, sizeof(replayPath), "%s/%d/%s", RP_DIRECTORY_JUMPS, GetSteamAccountID(client), RP_DIRECTORY_BLOCKJUMPS);
		if (!DirExists(replayPath))
		{
			CreateDirectory(replayPath, 511);
		}
	}
}

void OnClientDisconnect_Recording(int client)
{
	// Stop exceptions if OnClientPutInServer was never ran for this client id.
	// As long as the arrays aren't null we'll be fine.
	if (runningJumpstatTimers[client] == null)
	{
		return;
	}

	// Trigger all timers early
	if(!IsFakeClient(client))
	{
		if (runningRunBreatherTimer[client] != INVALID_HANDLE)
		{
			TriggerTimer(runningRunBreatherTimer[client], false);
		}

		// We have to clone the array because the timer callback removes the timer
		// from the array we're running over, and doing weird tricks is scary.
		ArrayList timers = runningJumpstatTimers[client].Clone();
		for (int i = 0; i < timers.Length; i++)
		{
			Handle timer = timers.Get(i);
			TriggerTimer(timer, false);
		}
		delete timers;
	}

	ClearClientRecordingState(client);
}

void OnPlayerRunCmdPost_Recording(int client, int buttons, int tickCount, const float vel[3], const int mouse[2])
{
	if (!IsValidClient(client) || IsFakeClient(client) || !IsPlayerAlive(client) || recordingPaused[client])
	{
		return;
	}

	ReplayTickData tickData;

	Movement_GetOrigin(client, tickData.origin);

	tickData.mouse = mouse;
	tickData.vel = vel;
	Movement_GetVelocity(client, tickData.velocity);
	Movement_GetEyeAngles(client, tickData.angles);
	tickData.flags = EncodePlayerFlags(client, buttons, tickCount);
	tickData.packetsPerSecond = GetClientAvgPackets(client, NetFlow_Incoming);
	tickData.laggedMovementValue = GetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue");
	tickData.buttonsForced = GetEntProp(client, Prop_Data, "m_afButtonForced");

	// HACK: Reset teleport tick marker. Too bad!
	if (isTeleportTick[client])
	{
		isTeleportTick[client] = false;
	}
	
	if (isRecordingRun[client])
	{
		int runTick = GetArraySize(recordedRunData[client]);
		if (runTick < RP_MAX_DURATION)
		{
			// Resize might fail if the timer exceed the max duration,
			// as it is not guaranteed to allocate more than 1GB of contiguous memory,
			// causing mass lag spikes that kick everyone out of the server.
			// We can still attempt to save the rest of the recording though.
			recordedRunData[client].Resize(runTick + 1);
			recordedRunData[client].SetArray(runTick, tickData);
		}
	}
	if (postRunRecording[client])
	{
		int tick = GetArraySize(recordedPostRunData[client]);
		if (tick < RP_MAX_DURATION)
		{
			recordedPostRunData[client].Resize(tick + 1);
			recordedPostRunData[client].SetArray(tick, tickData);
		}
	}
	
	int tick = recordingIndex[client];
	if (recordedRecentData[client].Length < maxCheaterReplayTicks)
	{
		recordedRecentData[client].Resize(recordedRecentData[client].Length + 1);
		recordingIndex[client] = recordingIndex[client] + 1 == maxCheaterReplayTicks ? 0 : recordingIndex[client] + 1;
	}
	else
	{
		recordingIndex[client] = RecordingIndexAdd(client, 1);
	}

	recordedRecentData[client].SetArray(tick, tickData);
}

Action GOKZ_OnTimerStart_Recording(int client)
{
	// Hack to fix an exception when starting the timer on the very
	// first tick after loading the plugin.
	if (recordedRecentData[client].Length == 0)
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

void GOKZ_OnTimerStart_Post_Recording(int client)
{
	isRecordingRun[client] = true;
	StartRunRecording(client);
}

void GOKZ_OnTimerEnd_Recording(int client, int course, float time, int teleportsUsed)
{
	if (!isRecordingRun[client])
	{
		return;
	}

	int mode = GOKZ_GetCoreOption(client, Option_Mode);
	int style = GOKZ_GetCoreOption(client, Option_Style);

	char guid[GOKZ_DB_TIME_GUID_MAX];
	GOKZ_DB_GetRunGUID(client, guid);

	DataPack data = new DataPack();
	data.WriteCell(GetClientUserId(client));
	data.WriteCell(mode);
	data.WriteCell(style);
	data.WriteCell(course);
	data.WriteFloat(time);
	data.WriteCell(teleportsUsed);
	data.WriteString(guid);
	// The previous run breather still did not finish, end it now or
	// we will start overwriting the data.
	if (runningRunBreatherTimer[client] != INVALID_HANDLE)
	{
		TriggerTimer(runningRunBreatherTimer[client], false);
	}

	isRecordingRun[client] = false;
	postRunRecording[client] = true;

	// Swap recordedRunData and recordedPostRunData.
	// This lets new runs start immediately, before the post-run breather is
	// finished recording.
	ArrayList tmp = recordedPostRunData[client];
	recordedPostRunData[client] = recordedRunData[client];
	recordedRunData[client] = tmp;
	recordedRunData[client].Clear();

	runningRunBreatherTimer[client] = CreateTimer(RP_PLAYBACK_BREATHER_TIME, Timer_EndRecording, data);
	if (runningRunBreatherTimer[client] == INVALID_HANDLE)
	{
		LogError("Could not create a timer so can't end the run replay recording");
	}
}

public Action Timer_EndRecording(Handle timer, DataPack data)
{
	char guid[GOKZ_DB_TIME_GUID_MAX];

	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	int mode = data.ReadCell();
	int style = data.ReadCell();
	int course = data.ReadCell();
	float time = data.ReadFloat();
	int teleportsUsed = data.ReadCell();
	data.ReadString(guid, sizeof(guid));
	delete data;

	// The client left after the run was done but before the post-run
	// breather had the chance to finish. This should not happen, as we
	// trigger all running timers on disconnect.
	if (!IsValidClient(client))
	{
		return Plugin_Stop;
	}

	runningRunBreatherTimer[client] = INVALID_HANDLE;
	postRunRecording[client] = false;
	
	SaveRecordingOfRun(client, mode, style, course, time, teleportsUsed, guid);

	return Plugin_Stop;
}

void GOKZ_OnPause_Recording(int client)
{
	PauseRecording(client);
}

void GOKZ_OnResume_Recording(int client)
{
	ResumeRecording(client);
}

void GOKZ_OnTimerStopped_Recording(int client)
{
	isRecordingRun[client] = false;
}

void GOKZ_OnCountedTeleport_Recording(int client)
{
	isTeleportTick[client] = true;
}

public void GOKZ_LR_OnPBMissed(int client, float pbTime, int course, int mode, int style, int recordType)
{
	// If missed PRO record or both records, then can no longer beat PB
	if (recordType == RecordType_NubAndPro || recordType == RecordType_Pro)
	{
		isRecordingRun[client] = false;
	}

	// If on a NUB run and missed NUB record, then can no longer beat PB
	// Otherwise wait to see if they teleport before stopping the recording
	if (recordType == RecordType_Nub)
	{
		if (GOKZ_GetTeleportCount(client) > 0)
		{
			isRecordingRun[client] = false;
		}
	}
}

void GOKZ_AC_OnPlayerSuspected_Recording(int client, ACReason reason)
{
	SaveRecordingOfCheater(client, reason);
}

void GOKZ_DB_OnJumpstatPB_Recording(int client, int jumptype, int mode, float distance, int block, int strafes, float sync, float pre, float max, int airtime)
{
	// Do NOT call GOKZ_GetCoreOption here, this is many ticks after the PB actually happened.
	int style = Style_Normal;

	DataPack data = new DataPack();
	data.WriteCell(GetClientUserId(client));
	data.WriteCell(mode);
	data.WriteCell(style);
	data.WriteCell(jumptype);
	data.WriteFloat(distance);
	data.WriteCell(block);
	data.WriteCell(strafes);
	data.WriteFloat(sync);
	data.WriteFloat(pre);
	data.WriteFloat(max);
	data.WriteCell(airtime);

	Handle timer = CreateTimer(RP_PLAYBACK_BREATHER_TIME, SaveJump, data);
	if (timer != INVALID_HANDLE)
	{
		runningJumpstatTimers[client].Push(timer);
	}
	else
	{
		LogError("Could not create a timer so can't save jumpstat pb replay");
	}
}

public Action SaveJump(Handle timer, DataPack data)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	int mode = data.ReadCell();
	int style = data.ReadCell();
	int jumptype = data.ReadCell();
	float distance = data.ReadFloat();
	int block = data.ReadCell();
	int strafes = data.ReadCell();
	float sync = data.ReadFloat();
	float pre = data.ReadFloat();
	float max = data.ReadFloat();
	int airtime = data.ReadCell();
	delete data;

	// The client left after the jump was done but before the post-jump
	// breather had the chance to finish. This should not happen, as we
	// trigger all running timers on disconnect.
	if (!IsValidClient(client))
	{
		return Plugin_Stop;
	}

	RemoveFromRunningTimers(client, timer);

	SaveRecordingOfJump(client, mode, style, jumptype, distance, block, strafes, sync, pre, max, airtime);
	return Plugin_Stop;
}



// =====[ PRIVATE ]=====

static void ClearClientRecordingState(int client)
{
	recordingIndex[client] = 0;
	playerSensitivity[client] = -1.0;
	playerMYaw[client] = -1.0;
	isTeleportTick[client] = false;
	isRecordingRun[client] = false;
	recordingPaused[client] = false;
	postRunRecording[client] = false;
	runningRunBreatherTimer[client] = INVALID_HANDLE;

	if (recordedRecentData[client] == null)
		recordedRecentData[client] = new ArrayList(sizeof(ReplayTickData));

	if (recordedRunData[client] == null)
		recordedRunData[client] = new ArrayList(sizeof(ReplayTickData));

	if (recordedPostRunData[client] == null)
		recordedPostRunData[client] = new ArrayList(sizeof(ReplayTickData));

	if (runningJumpstatTimers[client] == null)
		runningJumpstatTimers[client] = new ArrayList();

	recordedRecentData[client].Clear();
	recordedRunData[client].Clear();
	recordedPostRunData[client].Clear();
	runningJumpstatTimers[client].Clear();
}

static void StartRunRecording(int client)
{
	if (IsFakeClient(client))
	{
		return;
	}

	QueryClientConVar(client, "sensitivity", SensitivityCheck, client);
	QueryClientConVar(client, "m_yaw", MYAWCheck, client);
	
	DiscardRecording(client);
	ResumeRecording(client);
	
	// Copy pre data
	int index;
	recordedRunData[client].Resize(preAndPostRunTickCount);
	if (recordedRecentData[client].Length < preAndPostRunTickCount)
	{
		index = recordingIndex[client] - preAndPostRunTickCount;
	}
	else
	{
		index = RecordingIndexAdd(client, -preAndPostRunTickCount);
	}
	for (int i = 0; i < preAndPostRunTickCount; i++)
	{
		ReplayTickData tickData;
		if (index < 0)
		{
			recordedRecentData[client].GetArray(0, tickData);
			recordedRunData[client].SetArray(i, tickData);
			index += 1;
		}
		else
		{
			recordedRecentData[client].GetArray(index, tickData);
			recordedRunData[client].SetArray(i, tickData);
			index = RecordingIndexAdd(client, -preAndPostRunTickCount + i + 1);
		}
	}
}

static void DiscardRecording(int client)
{
	recordedRunData[client].Clear();
}

static void PauseRecording(int client)
{
	recordingPaused[client] = true;
}

static void ResumeRecording(int client)
{
	recordingPaused[client] = false;
}

static bool SaveRecordingOfRun(int client, int mode, int style, int course, float time, int teleportsUsed, const char[] guid)
{
	// Create and fill General Header
	GeneralReplayHeader generalHeader;
	FillGeneralHeader(generalHeader, client, ReplayType_Run, mode, style, recordedPostRunData[client].Length);

	// Create and fill Run Header
	RunReplayHeader runHeader;
	runHeader.time = time;
	runHeader.course = course;
	runHeader.teleportsUsed = teleportsUsed;

	// Build path and create/overwrite associated file
	char replayPath[PLATFORM_MAX_PATH];
	FormatRunReplayPath(replayPath, sizeof(replayPath), guid);
	if (FileExists(replayPath)) // This is the coldest branch in the history of cold branches.
	{
		DeleteFile(replayPath);
	}

	File file = OpenFile(replayPath, "wb");
	if (file == null)
	{
		LogError("Failed to create/open replay file to write to: \"%s\".", replayPath);
		return false;
	}

	WriteGeneralHeader(file, generalHeader);

	// Write run header
	file.WriteInt32(view_as<int>(runHeader.time));
	file.WriteInt8(runHeader.course);
	file.WriteInt32(runHeader.teleportsUsed);

	WriteTickData(file, client, ReplayType_Run);

	delete file;

	return true;
}

static bool SaveRecordingOfCheater(int client, ACReason reason)
{
	int mode = GOKZ_GetCoreOption(client, Option_Mode);
	int style = GOKZ_GetCoreOption(client, Option_Style);

	// Create and fill general header
	GeneralReplayHeader generalHeader;
	FillGeneralHeader(generalHeader, client, ReplayType_Cheater, mode, style, recordedRecentData[client].Length);

	// Create and fill cheater header
	CheaterReplayHeader cheaterHeader;
	cheaterHeader.ACReason = reason;

	//Build path and create/overwrite associated file
	char replayPath[PLATFORM_MAX_PATH];
	FormatCheaterReplayPath(replayPath, sizeof(replayPath), client, generalHeader.mode, generalHeader.style);

	File file = OpenFile(replayPath, "wb");
	if (file == null)
	{
		LogError("Failed to create/open replay file to write to: \"%s\".", replayPath);
		return false;
	}

	WriteGeneralHeader(file, generalHeader);
	file.WriteInt8(view_as<int>(cheaterHeader.ACReason));
	WriteTickData(file, client, ReplayType_Cheater);

	delete file;

	return true;
}

static bool SaveRecordingOfJump(int client, int mode, int style, int jumptype, float distance, int block, int strafes, float sync, float pre, float max, int airtime)
{
	// Just cause I know how buggy jumpstats can be
	int airtimeTicks = RoundToNearest((float(airtime) / GOKZ_DB_JS_AIRTIME_PRECISION) * tickrate);
	if (airtimeTicks + 2 * preAndPostRunTickCount >= maxCheaterReplayTicks)
	{
		LogError("WARNING: Invalid airtime (this is probably a bugged jump, please report it!).");
		return false;
	}
	
	// Create and fill general header
	GeneralReplayHeader generalHeader;
	FillGeneralHeader(generalHeader, client, ReplayType_Jump, mode, style, 2 * preAndPostRunTickCount + airtimeTicks);

	// Create and fill jump header
	JumpReplayHeader jumpHeader;
	FillJumpHeader(jumpHeader, jumptype, distance, block, strafes, sync, pre, max, airtime);

	// Make sure the client is authenticated
	if (GetSteamAccountID(client) == 0)
	{
		LogError("Failed to save jump, client is not authenticated.");
		return false;
	}

	// Build path and create/overwrite associated file
	char replayPath[PLATFORM_MAX_PATH];
	if (block > 0)
	{
		FormatBlockJumpReplayPath(replayPath, sizeof(replayPath), client, block, jumpHeader.jumpType, generalHeader.mode, generalHeader.style);
	}
	else
	{
		FormatJumpReplayPath(replayPath, sizeof(replayPath), client, jumpHeader.jumpType, generalHeader.mode, generalHeader.style);
	}

	File file = OpenFile(replayPath, "wb");
	if (file == null)
	{
		LogError("Failed to create/open replay file to write to: \"%s\".", replayPath);
		delete file;
		return false;
	}

	WriteGeneralHeader(file, generalHeader);
	WriteJumpHeader(file, jumpHeader);
	WriteTickData(file, client, ReplayType_Jump, airtimeTicks);

	delete file;

	return true;
}

static void FillGeneralHeader(GeneralReplayHeader generalHeader, int client, int replayType, int mode, int style, int tickCount)
{
	// Fill general header
	generalHeader.magicNumber = RP_MAGIC_NUMBER;
	generalHeader.formatVersion = RP_FORMAT_VERSION;
	generalHeader.replayType = replayType;
	generalHeader.gokzVersion = GOKZ_VERSION;
	generalHeader.mapName = gC_CurrentMap;
	generalHeader.mapFileSize = gI_CurrentMapFileSize;
	generalHeader.serverIP = FindConVar("hostip").IntValue;
	generalHeader.timestamp = GetTime();
	GetClientName(client, generalHeader.playerAlias, sizeof(GeneralReplayHeader::playerAlias));
	generalHeader.playerSteamID = GetSteamAccountID(client);
	generalHeader.mode = mode;
	generalHeader.style = style;
	generalHeader.playerSensitivity = playerSensitivity[client];
	generalHeader.playerMYaw = playerMYaw[client];
	generalHeader.tickrate = tickrate;
	generalHeader.tickCount = tickCount;
	generalHeader.equippedWeapon = GetPlayerWeaponSlotDefIndex(client, CS_SLOT_SECONDARY);
	generalHeader.equippedKnife = GetPlayerWeaponSlotDefIndex(client, CS_SLOT_KNIFE);
}

static void FillJumpHeader(JumpReplayHeader jumpHeader, int jumptype, float distance, int block, int strafes, float sync, float pre, float max, int airtime)
{
	jumpHeader.jumpType = jumptype;
	jumpHeader.distance = distance;
	jumpHeader.blockDistance = block;
	jumpHeader.strafeCount = strafes;
	jumpHeader.sync = sync;
	jumpHeader.pre = pre;
	jumpHeader.max = max;
	jumpHeader.airtime = airtime;
}

static void WriteGeneralHeader(File file, GeneralReplayHeader generalHeader)
{
	file.WriteInt32(generalHeader.magicNumber);
	file.WriteInt8(generalHeader.formatVersion);
	file.WriteInt8(generalHeader.replayType);
	file.WriteInt8(strlen(generalHeader.gokzVersion));
	file.WriteString(generalHeader.gokzVersion, false);
	file.WriteInt8(strlen(generalHeader.mapName));
	file.WriteString(generalHeader.mapName, false);
	file.WriteInt32(generalHeader.mapFileSize);
	file.WriteInt32(generalHeader.serverIP);
	file.WriteInt32(generalHeader.timestamp);
	file.WriteInt8(strlen(generalHeader.playerAlias));
	file.WriteString(generalHeader.playerAlias, false);
	file.WriteInt32(generalHeader.playerSteamID);
	file.WriteInt8(generalHeader.mode);
	file.WriteInt8(generalHeader.style);
	file.WriteInt32(view_as<int>(generalHeader.playerSensitivity));
	file.WriteInt32(view_as<int>(generalHeader.playerMYaw));
	file.WriteInt32(view_as<int>(generalHeader.tickrate));
	file.WriteInt32(generalHeader.tickCount);
	file.WriteInt32(generalHeader.equippedWeapon);
	file.WriteInt32(generalHeader.equippedKnife);
}

static void WriteJumpHeader(File file, JumpReplayHeader jumpHeader)
{
	file.WriteInt8(jumpHeader.jumpType);
	file.WriteInt32(view_as<int>(jumpHeader.distance));
	file.WriteInt32(jumpHeader.blockDistance);
	file.WriteInt8(jumpHeader.strafeCount);
	file.WriteInt32(view_as<int>(jumpHeader.sync));
	file.WriteInt32(view_as<int>(jumpHeader.pre));
	file.WriteInt32(view_as<int>(jumpHeader.max));
	file.WriteInt32((jumpHeader.airtime));
}

static void WriteTickData(File file, int client, int replayType, int airtime = 0)
{
	// Do NOT use file.Write functions here or write cache will write out of order!!!
	WriteCache_SetFile(file);

	any tickData[2][RP_V2_TICK_DATA_BLOCKSIZE];
	int currentTickData = 0;
	bool isFirstTick = true;
	switch(replayType)
	{
		case ReplayType_Run:
		{
			int replayLength = recordedPostRunData[client].Length;
			for (int i = 0; i < replayLength; i++)
			{
				recordedPostRunData[client].GetArray(i, tickData[currentTickData]);
				WriteTickDataThroughWriteCache(isFirstTick, tickData[currentTickData], tickData[currentTickData ^ 1]);
				currentTickData ^= 1;
				isFirstTick = false;
			}
		}
		case ReplayType_Cheater:
		{
			int replayLength = recordedRecentData[client].Length;
			for (int i = 0; i < replayLength; i++)
			{
				int rollingI = RecordingIndexAdd(client, i);
				recordedRecentData[client].GetArray(rollingI, tickData[currentTickData]);
				WriteTickDataThroughWriteCache(isFirstTick, tickData[currentTickData], tickData[currentTickData ^ 1]);
				currentTickData ^= 1;
				isFirstTick = false;
			}
			
		}
		case ReplayType_Jump:
		{
			int replayLength = 2 * preAndPostRunTickCount + airtime;
			for (int i = 0; i < replayLength; i++)
			{
				int rollingI = RecordingIndexAdd(client, i - replayLength);
				recordedRecentData[client].GetArray(rollingI, tickData[currentTickData]);
				WriteTickDataThroughWriteCache(isFirstTick, tickData[currentTickData], tickData[currentTickData ^ 1]);
				currentTickData ^= 1;
				isFirstTick = false;
			}
		}
	}

	WriteCache_Flush();
}

static void WriteTickDataThroughWriteCache(bool isFirstTick, const any tickData[RP_V2_TICK_DATA_BLOCKSIZE], const any prevTickData[RP_V2_TICK_DATA_BLOCKSIZE])
{
	int deltaFlags = (1 << RPDELTA_DELTAFLAGS);
	if (isFirstTick)
	{
		// NOTE: Set every bit to 1 until RP_V2_TICK_DATA_BLOCKSIZE.
		deltaFlags = (1 << (RP_V2_TICK_DATA_BLOCKSIZE)) - 1;
	}
	else
	{
		// NOTE: Test tickData against prevTickData for differences.
		for (int i = 1; i < RP_V2_TICK_DATA_BLOCKSIZE; i++)
		{
			// If the bits in tickData[i] are different to prevTickData[i], then
			// set the corresponding bitflag.
			if (tickData[i] ^ prevTickData[i])
			{
				deltaFlags |= (1 << i);
			}
		}
	}

	WriteCache_WriteData(deltaFlags);
	// NOTE: write only data that has changed since the previous tick.
	for (int i = 1; deltaFlags; i++)
	{
		deltaFlags >>= 1;
		if (deltaFlags & 1)
		{
			WriteCache_WriteData(tickData[i]);
		}
	}
}

static void FormatRunReplayPath(char[] buffer, int maxlength, const char[] guid)
{
	BuildPath(Path_SM, buffer, maxlength,
		"%s/%s.%s",
		RP_DIRECTORY_RUNS,
		guid,
		RP_FILE_EXTENSION);
}

static void FormatCheaterReplayPath(char[] buffer, int maxlength, int client, int mode, int style)
{
	BuildPath(Path_SM, buffer, maxlength,
		"%s/%d_%s_%d_%s_%s.%s",
		RP_DIRECTORY_CHEATERS,
		GetSteamAccountID(client),
		gC_CurrentMap,
		GetTime(),
		gC_ModeNamesShort[mode], 
		gC_StyleNamesShort[style], 
		RP_FILE_EXTENSION);
}

static void FormatJumpReplayPath(char[] buffer, int maxlength, int client, int jumpType, int mode, int style)
{
	BuildPath(Path_SM, buffer, maxlength,
		"%s/%d/%d_%s_%s.%s",
		RP_DIRECTORY_JUMPS,
		GetSteamAccountID(client),
		jumpType,
		gC_ModeNamesShort[mode],
		gC_StyleNamesShort[style],
		RP_FILE_EXTENSION);
}

static void FormatBlockJumpReplayPath(char[] buffer, int maxlength, int client, int block, int jumpType, int mode, int style)
{
	BuildPath(Path_SM, buffer, maxlength,
		"%s/%d/%s/%d_%d_%s_%s.%s",
		RP_DIRECTORY_JUMPS,
		GetSteamAccountID(client),
		RP_DIRECTORY_BLOCKJUMPS,
		jumpType,
		block,
		gC_ModeNamesShort[mode],
		gC_StyleNamesShort[style],
		RP_FILE_EXTENSION);
}

static int EncodePlayerFlags(int client, int buttons, int tickCount)
{
	int flags = 0;
	MoveType movetype = Movement_GetMovetype(client);
	int clientFlags = GetEntityFlags(client);
	
	flags = view_as<int>(movetype) & RP_MOVETYPE_MASK;

	SetKthBit(flags, 4, IsBitSet(buttons, IN_ATTACK));
	SetKthBit(flags, 5, IsBitSet(buttons, IN_ATTACK2));
	SetKthBit(flags, 6, IsBitSet(buttons, IN_JUMP));
	SetKthBit(flags, 7, IsBitSet(buttons, IN_DUCK));
	SetKthBit(flags, 8, IsBitSet(buttons, IN_FORWARD));
	SetKthBit(flags, 9, IsBitSet(buttons, IN_BACK));
	SetKthBit(flags, 10, IsBitSet(buttons, IN_LEFT));
	SetKthBit(flags, 11, IsBitSet(buttons, IN_RIGHT));
	SetKthBit(flags, 12, IsBitSet(buttons, IN_MOVELEFT));
	SetKthBit(flags, 13, IsBitSet(buttons, IN_MOVERIGHT));
	SetKthBit(flags, 14, IsBitSet(buttons, IN_RELOAD));
	SetKthBit(flags, 15, IsBitSet(buttons, IN_SPEED));
	SetKthBit(flags, 16, IsBitSet(buttons, IN_USE));
	SetKthBit(flags, 17, IsBitSet(buttons, IN_BULLRUSH));
	SetKthBit(flags, 18, IsBitSet(clientFlags, FL_ONGROUND));
	SetKthBit(flags, 19, IsBitSet(clientFlags, FL_DUCKING));
	SetKthBit(flags, 20, IsBitSet(clientFlags, FL_SWIM));

	SetKthBit(flags, 21, GetEntProp(client, Prop_Data, "m_nWaterLevel") != 0);

	SetKthBit(flags, 22, isTeleportTick[client]);
	SetKthBit(flags, 23, Movement_GetTakeoffTick(client) == tickCount);
	SetKthBit(flags, 24, GOKZ_GetHitPerf(client));
	SetKthBit(flags, 25, IsCurrentWeaponSecondary(client));

	return flags;
}

// Function to set the bitNum bit in integer to value
static void SetKthBit(int &number, int offset, bool value)
{
	int intValue = value ? 1 : 0;
	number |= intValue << offset;
}

static bool IsBitSet(int number, int checkBit)
{
	return (number & checkBit) ? true : false;
}

static int GetPlayerWeaponSlotDefIndex(int client, int slot)
{
	int ent = GetPlayerWeaponSlot(client, slot);
	
	// Nothing equipped in the slot
	if (ent == -1)
	{
		return -1;
	}
	
	return GetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex");
}

static bool IsCurrentWeaponSecondary(int client)
{
	int activeWeaponEnt = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	int secondaryEnt = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
	return activeWeaponEnt == secondaryEnt;
}

static void CreateReplaysDirectory()
{
	char path[PLATFORM_MAX_PATH];

	// Create parent replay directory
	BuildPath(Path_SM, path, sizeof(path), RP_DIRECTORY);
	CreateDirectory(path, 511);

	// Create runs replay directory
	BuildPath(Path_SM, path, sizeof(path), "%s", RP_DIRECTORY_RUNS);
	CreateDirectory(path, 511);

	// Create cheaters replay directory
	BuildPath(Path_SM, path, sizeof(path), "%s", RP_DIRECTORY_CHEATERS);
	CreateDirectory(path, 511);

	// Create jumps parent replay directory
	BuildPath(Path_SM, path, sizeof(path), "%s", RP_DIRECTORY_JUMPS);
	CreateDirectory(path, 511);
}

public void MYAWCheck(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, any value)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		playerMYaw[client] = StringToFloat(cvarValue);
	}
}

public void SensitivityCheck(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, any value)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		playerSensitivity[client] = StringToFloat(cvarValue);
	}
}

static int RecordingIndexAdd(int client, int offset)
{
	int index = recordingIndex[client] + offset;
	if (index < 0)
	{
		index += recordedRecentData[client].Length;
	}
	return index % recordedRecentData[client].Length;
}

static void RemoveFromRunningTimers(int client, Handle timerToRemove)
{
	int index = runningJumpstatTimers[client].FindValue(timerToRemove);
	if (index != -1)
	{
		runningJumpstatTimers[client].Erase(index);
	}
}



// =====[ WRITE CACHE HACK ]=====

static File writeCacheFile;
static int writeCacheNext = 0;
static any writeCache[4096];
static void WriteCache_SetFile(File file)
{
	writeCacheFile = file;
	writeCacheNext = 0;
}
static void WriteCache_WriteData(any data)
{
	if (writeCacheNext == sizeof(writeCache))
	{
		WriteCache_Flush();
	}
	writeCache[writeCacheNext] = data;
	writeCacheNext++;
}
static void WriteCache_Flush()
{
	writeCacheFile.Write(writeCache, writeCacheNext, 4);
	writeCacheNext = 0;
}
