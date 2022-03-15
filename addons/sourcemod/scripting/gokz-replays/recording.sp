/*
	Bot replay recording logic and processes.
	
	Records data every time OnPlayerRunCmdPost is called.
	If the player doesn't have their timer running, it keeps track
	of the last 2 minutes of their actions. If a player is banned
	while their timer isn't running, those 2 minutes are saved.
	If the player has their timer running, the recording is done from
	the beginning of the run. If the player misses the server record,
	then the recording goes back to only keeping track of the last
	two minutes. Upon beating the server record, a binary file will be 
	written with a 'header' containing information	about the run,
	followed by the recorded tick data from OnPlayerRunCmdPost.
*/

static float tickrate;
static int preAndPostRunTickCount;
static int currentTick;
static int maxCheaterReplayTicks;
static int recordingIndex[MAXPLAYERS + 1];
static int lastTakeoffTick[MAXPLAYERS + 1];
static int lastTakeoffPBTick[MAXPLAYERS + 1];
static float playerSensitivity[MAXPLAYERS + 1];
static float playerMYaw[MAXPLAYERS + 1];
static bool isTeleportTick[MAXPLAYERS + 1];
static bool timerRunning[MAXPLAYERS + 1];
static bool recordingPaused[MAXPLAYERS + 1];
static bool postRunRecording[MAXPLAYERS + 1];
static ArrayList recordedRecentData[MAXPLAYERS + 1];
static ArrayList recordedPostRunData[MAXPLAYERS + 1];
static ArrayList recordedRunData[MAXPLAYERS + 1];

// =====[ EVENTS ]=====

void OnMapStart_Recording()
{
    CreateReplaysDirectory(gC_CurrentMap);
    tickrate = 1/GetTickInterval();
    preAndPostRunTickCount = RoundToZero(RP_PLAYBACK_BREATHER_TIME * tickrate);
    maxCheaterReplayTicks = RoundToCeil(RP_MAX_CHEATER_REPLAY_LENGTH * tickrate);
}

void OnClientPutInServer_Recording(int client)
{
    recordedRecentData[client] = new ArrayList(sizeof(ReplayTickData));
    recordedRunData[client] = new ArrayList(sizeof(ReplayTickData));
    recordedPostRunData[client] = new ArrayList(sizeof(ReplayTickData));
    recordingIndex[client] = 0;
}

void OnClientAuthorized_Recording(int client)
{
    if(IsValidClient(client) && !IsFakeClient(client))
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

    currentTick = tickCount;
    if (Movement_GetTakeoffTick(client) == tickCount)
    {
        lastTakeoffTick[client] = tickCount;
    }
    
    if (timerRunning[client])
    {
        int runTick = GetArraySize(recordedRunData[client]);
        recordedRunData[client].Resize(runTick + 1);
        recordedRunData[client].SetArray(runTick, tickData);
    }
    
    if (postRunRecording[client])
    {
        int runTick = GetArraySize(recordedPostRunData[client]);
        recordedPostRunData[client].Resize(runTick + 1);
        recordedPostRunData[client].SetArray(runTick, tickData);
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

void GOKZ_OnTimerStart_Recording(int client)
{
    timerRunning[client] = true;
    StartRunRecording(client);
}

void GOKZ_OnTimerEnd_Recording(int client, int course, float time, int teleportsUsed)
{
    DataPack dp = new DataPack();
    dp.WriteCell(client);
    dp.WriteCell(course);
    dp.WriteFloat(time);
    dp.WriteCell(teleportsUsed);
    delete recordedPostRunData[client];
    recordedPostRunData[client] = recordedRunData[client];
    recordedRunData[client] = new ArrayList(sizeof(ReplayTickData));
    if (timerRunning[client])
    {
   		CreateTimer(RP_PLAYBACK_BREATHER_TIME, EndRecording, dp);
   		postRunRecording[client] = true;
   		timerRunning[client] = false;
    }
}

public Action EndRecording(Handle timer, DataPack dp)
{
    dp.Reset();
    int client = dp.ReadCell();
    int course = dp.ReadCell();
    float time = dp.ReadFloat();
    int teleportsUsed = dp.ReadCell();
    delete dp;
    
    postRunRecording[client] = true;

    if (gB_GOKZLocalDB && GOKZ_DB_IsCheater(client))
    {
        Call_OnTimerEnd_Post(client, "", course, time, teleportsUsed);
        return;
    }
    
    char path[PLATFORM_MAX_PATH];
    if (SaveRecordingOfRun(path, client, course, time, teleportsUsed))
    {
        Call_OnTimerEnd_Post(client, path, course, time, teleportsUsed);
    }
    else
    {
        Call_OnTimerEnd_Post(client, "", course, time, teleportsUsed);
    }
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
    timerRunning[client] = false;
}

void GOKZ_OnCountedTeleport_Recording(int client)
{
    if (gB_NubRecordMissed[client])
    {
        timerRunning[client] = false;
    }

    isTeleportTick[client] = true;
}

void GOKZ_LR_OnRecordMissed_Recording(int client, int recordType)
{
	// If missed PRO record or both records, then can no longer beat a server record
	if (recordType == RecordType_NubAndPro || recordType == RecordType_Pro)
	{
		timerRunning[client] = false;
	}

	// If on a NUB run and missed NUB record, then can no longer beat a server record
	// Otherwise wait to see if they teleport before stopping the recording
	if (recordType == RecordType_Nub)
	{
		if (GOKZ_GetTeleportCount(client) > 0)
		{
			timerRunning[client] = false;
		}
	}
}

void GOKZ_AC_OnPlayerSuspected_Recording(int client, ACReason reason)
{
    SaveRecordingOfCheater(client, reason);
}

void GOKZ_DB_OnJumpstatPB_Recording(int client, int jumptype, float distance, int block, int strafes, float sync, float pre, float max, int airtime)
{
    lastTakeoffPBTick[client] = lastTakeoffTick[client];
    DataPack dp = new DataPack();
    dp.WriteCell(client);
    dp.WriteCell(jumptype);
    dp.WriteFloat(distance);
    dp.WriteCell(block);
    dp.WriteCell(strafes);
    dp.WriteFloat(sync);
    dp.WriteFloat(pre);
    dp.WriteFloat(max);
    dp.WriteCell(airtime);
    CreateTimer(RP_PLAYBACK_BREATHER_TIME, SaveJump, dp);
}

public Action SaveJump(Handle timer, DataPack dp)
{
    dp.Reset();
    int client = dp.ReadCell();
    int jumptype = dp.ReadCell();
    float distance = dp.ReadFloat();
    int block = dp.ReadCell();
    int strafes = dp.ReadCell();
    float sync = dp.ReadFloat();
    float pre = dp.ReadFloat();
    float max = dp.ReadFloat();
    int airtime = dp.ReadCell();
    delete dp;

    SaveRecordingOfJump(client, jumptype, distance, block, strafes, sync, pre, max, airtime);
}



// =====[ PRIVATE ]=====

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
    Call_OnReplayDiscarded(client);
}

static void PauseRecording(int client)
{
    recordingPaused[client] = true;
}

static void ResumeRecording(int client)
{
    recordingPaused[client] = false;
}

static bool SaveRecordingOfRun(char replayPath[PLATFORM_MAX_PATH], int client, int course, float time, int teleportsUsed)
{
    // Prepare data
    int timeType = GOKZ_GetTimeTypeEx(teleportsUsed);

    // Create and fill General Header
    GeneralReplayHeader generalHeader;
    FillGeneralHeader(generalHeader, client, ReplayType_Run, recordedPostRunData[client].Length);

    // Create and fill Run Header
    RunReplayHeader runHeader;
    runHeader.time = time;
    runHeader.course = course;
    runHeader.teleportsUsed = teleportsUsed;

    // Build path and create/overwrite associated file
    FormatRunReplayPath(replayPath, sizeof(replayPath), course, generalHeader.mode, generalHeader.style, timeType);
    if (FileExists(replayPath))
	{
		DeleteFile(replayPath);
	}
    else
    {
        AddToReplayInfoCache(course, generalHeader.mode, generalHeader.style, timeType);
        SortReplayInfoCache();
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

    Call_OnReplaySaved(client, ReplayType_Run, gC_CurrentMap, course, timeType, time, replayPath);

    return true;
}

static bool SaveRecordingOfCheater(int client, ACReason reason)
{
    // Create and fill general header
    GeneralReplayHeader generalHeader;
    FillGeneralHeader(generalHeader, client, ReplayType_Cheater, recordedRecentData[client].Length);

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

static bool SaveRecordingOfJump(int client, int jumptype, float distance, int block, int strafes, float sync, float pre, float max, int airtime)
{
    // Create and fill general header
    GeneralReplayHeader generalHeader;
    FillGeneralHeader(generalHeader, client, ReplayType_Jump, currentTick - lastTakeoffPBTick[client]);

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
    WriteTickData(file, client, ReplayType_Jump);

    delete file;

    return true;
}

static void FillGeneralHeader(GeneralReplayHeader generalHeader, int client, int replayType, int tickCount)
{
    // Prepare data
    int mode = GOKZ_GetCoreOption(client, Option_Mode);
    int style = GOKZ_GetCoreOption(client, Option_Style);

    // Fill general header
    generalHeader.magicNumber = RP_MAGIC_NUMBER;
    generalHeader.formatVersion = RP_FORMAT_VERSION;
    generalHeader.replayType = replayType;
    generalHeader.gokzVersion = GOKZ_VERSION;
    generalHeader.mapName = gC_CurrentMap;
    generalHeader.mapFileSize = gC_CurrentMapFileSize;
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

static void WriteTickData(File file, int client, int replayType)
{
    ReplayTickData tickData;
    ReplayTickData prevTickData;
    switch(replayType)
    {
        case ReplayType_Run:
        {
            // Full run including pre and post
            int previousJ = 0;
            bool isFirstTick = true;
            for (int i = 0; i < recordedPostRunData[client].Length; i++)
            {
                recordedPostRunData[client].GetArray(i, tickData);
                recordedPostRunData[client].GetArray(previousJ, prevTickData);
                WriteTickDataToFile(file, isFirstTick, tickData, prevTickData);
                previousJ = i;
                isFirstTick = false;
            }
        }
        case ReplayType_Cheater:
        {
            int previousI = 0;
            bool isFirstTick = true;
            for (int i = 0; i < recordedRecentData[client].Length; i++)
            {
            	int rollingI = RecordingIndexAdd(client, i);
                recordedRecentData[client].GetArray(rollingI, tickData);
                recordedRecentData[client].GetArray(previousI, prevTickData);
                WriteTickDataToFile(file, isFirstTick, tickData, prevTickData);
                previousI = i;
                isFirstTick = false;
            }
            
        }
        case ReplayType_Jump:
        {
        	int replayLength = currentTick - lastTakeoffPBTick[client] + 2 * preAndPostRunTickCount;
        	int previousI = 0;
        	bool isFirstTick = true;
        	for (int i = 0; i < replayLength; i++)
            {
            	int rollingI = RecordingIndexAdd(client, i - replayLength);
                recordedRecentData[client].GetArray(rollingI, tickData);
                recordedRecentData[client].GetArray(previousI, prevTickData);
                WriteTickDataToFile(file, isFirstTick, tickData, prevTickData);
                previousI = i;
                isFirstTick = false;
            }
        }
    }
}

static void WriteTickDataToFile(File file, bool isFirstTick, ReplayTickData tickDataStruct, ReplayTickData prevTickDataStruct)
{
	any tickData[RP_V2_TICK_DATA_BLOCKSIZE];
	any prevTickData[RP_V2_TICK_DATA_BLOCKSIZE];
	TickDataToArray(tickDataStruct, tickData);
	TickDataToArray(prevTickDataStruct, prevTickData);
	
	int deltaFlags = (1 << RPDELTA_DELTAFLAGS);
	if (isFirstTick)
	{
		// NOTE: Set every bit to 1 until RP_V2_TICK_DATA_BLOCKSIZE.
		deltaFlags = (1 << (RP_V2_TICK_DATA_BLOCKSIZE)) - 1;
	}
	else
	{
		// NOTE: Test tickData against prevTickData for differences.
		for (int i = 1; i < sizeof(tickData); i++)
		{
			// If the bits in tickData[i] are different to prevTickData[i], then
			// set the corresponding bitflag.
			if (tickData[i] ^ prevTickData[i])
			{
				deltaFlags |= (1 << i);
			}
		}
	}

	file.WriteInt32(deltaFlags);
	// NOTE: write only data that has changed since the previous tick.
	for (int i = 1; i < sizeof(tickData); i++)
	{
		int currentFlag = (1 << i);
		if (deltaFlags & currentFlag)
		{
			file.WriteInt32(tickData[i]);
		}
	}
}

static void FormatRunReplayPath(char[] buffer, int maxlength, int course, int mode, int style, int timeType)
{
    BuildPath(Path_SM, buffer, maxlength,
        "%s/%s/%d_%s_%s_%s.%s",
        RP_DIRECTORY_RUNS,
        gC_CurrentMap,
        course,
        gC_ModeNamesShort[mode], 
		gC_StyleNamesShort[style], 
		gC_TimeTypeNames[timeType], 
		RP_FILE_EXTENSION);
}

static void FormatCheaterReplayPath(char[] buffer, int maxlength, int client, int mode, int style)
{
    BuildPath(Path_SM, buffer, maxlength,
        "%s/%d/%s_%d_%s_%s.%s",
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

static void CreateReplaysDirectory(const char[] map)
{
    char path[PLATFORM_MAX_PATH];

    // Create parent replay directory
    BuildPath(Path_SM, path, sizeof(path), RP_DIRECTORY);
    if (!DirExists(path))
    {
        CreateDirectory(path, 511);
    }

    // Create maps parent replay directory
    BuildPath(Path_SM, path, sizeof(path), "%s", RP_DIRECTORY_RUNS);
    if (!DirExists(path))
    {
        CreateDirectory(path, 511);
    }


    // Create maps replay directory
    BuildPath(Path_SM, path, sizeof(path), "%s/%s", RP_DIRECTORY_RUNS, map);
    if (!DirExists(path))
    {
        CreateDirectory(path, 511);
    }

    // Create cheaters replay directory
    BuildPath(Path_SM, path, sizeof(path), "%s", RP_DIRECTORY_CHEATERS);
    if (!DirExists(path))
    {
        CreateDirectory(path, 511);
    }

    // Create jumps parent replay directory
    BuildPath(Path_SM, path, sizeof(path), "%s", RP_DIRECTORY_JUMPS);
    if (!DirExists(path))
    {
        CreateDirectory(path, 511);
    }
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
