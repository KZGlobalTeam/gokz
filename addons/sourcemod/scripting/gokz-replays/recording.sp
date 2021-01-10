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
static int maxCheaterReplayTicks;
static int recordingIndex[MAXPLAYERS + 1];
static int lastTakeoffTick[MAXPLAYERS + 1];
static int lastTeleportTick[MAXPLAYERS + 1];
static bool timerRunning[MAXPLAYERS + 1];
static bool recordingPaused[MAXPLAYERS + 1];
static ArrayList recordedTickData[MAXPLAYERS + 1];
static ArrayList recordedRunData[MAXPLAYERS + 1];

// =====[ EVENTS ]=====

void OnMapStart_Recording()
{
    CreateReplaysDirectory(gC_CurrentMap);
    tickrate = 1/GetTickInterval();
    maxCheaterReplayTicks = RoundToCeil(RP_MAX_CHEATER_REPLAY_LENGTH * tickrate);
}


void OnClientPutInServer_Recording(int client)
{
    if (recordedTickData[client] == null)
    {
        recordedTickData[client] = new ArrayList(sizeof(ReplayTickData));
    }
    if (recordedRunData[client] == null)
    {
        recordedRunData[client] = new ArrayList(sizeof(ReplayTickData));
    }

    StartRecording(client);
}

void OnPlayerRunCmdPost_Recording(int client, int buttons)
{
    if (!IsValidClient(client) || IsFakeClient(client) || !IsPlayerAlive(client) || recordingPaused[client])
	{
		return;
	}

    ReplayTickData tickData;

    Movement_GetOrigin(client, tickData.origin);

    float angles[3];
    Movement_GetEyeAngles(client, angles);
    tickData.angles[0] = angles[0];
    tickData.angles[1] = angles[1];
    // Don't bother tracking eye angle roll (angles[2]) - not used
    tickData.playerFlags = EncodePlayerFlags(client, buttons);
    tickData.takeoffSpeed = GetEntityFlags(client) & FL_ONGROUND ? -1.0 : Movement_GetTakeoffSpeed(client);
    
    if (timerRunning[client])
    {
        int runTick = GetArraySize(recordedRunData[client]);
        recordedRunData[client].Resize(runTick + 1);
        recordedRunData[client].SetArray(runTick, tickData);
    }
    if (!timerRunning[client] || recordedRunData[client].Length < maxCheaterReplayTicks)
    {
        int tick = GetArraySize(recordedTickData[client]);
        if (tick < maxCheaterReplayTicks)
        {
            recordedTickData[client].Resize(tick + 1);
        }
        tick = recordingIndex[client];
        recordingIndex[client] = recordingIndex[client] == maxCheaterReplayTicks - 1 ? 0 : recordingIndex[client] + 1;

        recordedTickData[client].SetArray(tick, tickData);
    }
}

void GOKZ_OnTeleportToCheckpoint_Post_Recording(int client)
{
    lastTeleportTick[client] = GetGameTickCount();
}

void GOKZ_OnTimerStart_Recording(int client)
{
    timerRunning[client] = true;
    StartRecording(client);
}

void GOKZ_OnTimerEnd_Recording(int client, int course, float time, int teleportsUsed)
{
    if (gB_GOKZLocalDB && GOKZ_DB_IsCheater(client))
    {
        SaveRecordingOfCheater(client, view_as<ACReason>(0));
        Call_OnTimerEnd_Post(client, "", course, time, teleportsUsed);
    }
    else if (timerRunning[client])
    {
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

    timerRunning[client] = false;
    StartRecording(client);
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
    StartRecording(client);
}

void GOKZ_OnCountedTeleport_Recording(int client)
{
    if (gB_NubRecordMissed[client])
    {
        timerRunning[client] = false;
        StartRecording(client);
    }
}

void GOKZ_LR_OnRecordMissed_Recording(int client, int recordType)
{
	// If missed PRO record or both records, then can no longer beat a server record
	if (recordType == RecordType_NubAndPro || recordType == RecordType_Pro)
	{
		timerRunning[client] = false;
		StartRecording(client);
	}
	// If on a NUB run and missed NUB record, then can no longer beat a server record
	// Otherwise wait to see if they teleport before stopping the recording
	if (recordType == RecordType_Nub)
	{
		if (GOKZ_GetTeleportCount(client) > 0)
		{
			timerRunning[client] = false;
			StartRecording(client);
		}
	}
}

void GOKZ_AC_OnPlayerSuspected_Recording(int client, ACReason reason)
{
    SaveRecordingOfCheater(client, reason);
}

void GOKZ_JS_OnNewPersonalBest_Recording(int client, Jump jump)
{
    SaveRecordingOfJump(client, jump);
}



// =====[ PRIVATE ]=====

static void StartRecording(int client)
{
    if (IsFakeClient(client))
    {
        return;
    }

    DiscardRecording(client);
    ResumeRecording(client);
}

static void DiscardRecording(int client)
{
    // Make sure we still have 2 mins of footage.
    if(recordedRunData[client].Length >= maxCheaterReplayTicks)
    {
        recordedTickData[client].Clear();
        any runData[RP_TICK_DATA_BLOCKSIZE];
        for (int i = recordedRunData[client].Length - maxCheaterReplayTicks; i < recordedRunData[client].Length; i++)
        {
            recordedRunData[client].GetArray(i, runData, sizeof(runData));
            recordedTickData[client].PushArray(runData, sizeof(runData));
        }
        recordingIndex[client] = 0;
    }
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
    FillGeneralHeader(generalHeader, client, ReplayType_Run, recordedRunData[client].Length);

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

    Call_OnReplaySaved(client, replayPath);

    return true;
}

static bool SaveRecordingOfCheater(int client, ACReason reason)
{
    // Create and fill general header
    GeneralReplayHeader generalHeader;
    FillGeneralHeader(generalHeader, client, ReplayType_Cheater, recordedTickData[client].Length);

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

    Call_OnReplaySaved(client, replayPath);

    return true;
}

static bool SaveRecordingOfJump(int client, Jump jump)
{
    // Create and fill general header
    GeneralReplayHeader generalHeader;
    FillGeneralHeader(generalHeader, client, ReplayType_Jump, GetGameTickCount() - lastTakeoffTick[client]);

    // Create and fill jump header
    JumpReplayHeader jumpHeader;
    FillJumpHeader(jumpHeader, jump);

    // Build path and create/overwrite associated file
    char replayPath[PLATFORM_MAX_PATH];
    FormatJumpReplayPath(replayPath, sizeof(replayPath), client, jumpHeader.jumpType, generalHeader.mode, generalHeader.style);

    File file = OpenFile(replayPath, "wb");
    if (file == null)
    {
        LogError("Failed to create/open replay file to write to: \"%s\".", replayPath);
        return false;
    }

    WriteGeneralHeader(file, generalHeader);
    WriteJumpHeader(file, jumpHeader);
    WriteTickData(file, client, ReplayType_Jump);

    delete file;

    Call_OnReplaySaved(client, replayPath);

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
    generalHeader.tickrate = tickrate;
    generalHeader.tickCount = tickCount;
    generalHeader.equippedWeapon = GetPlayerWeaponSlotDefIndex(client, CS_SLOT_SECONDARY);
    generalHeader.equippedKnife = GetPlayerWeaponSlotDefIndex(client, CS_SLOT_KNIFE);
}

static void FillJumpHeader(JumpReplayHeader jumpHeader, Jump jump)
{
    jumpHeader.jumpType = jump.type;
    jumpHeader.distance = jump.distance;
    jumpHeader.blockDistance = jump.block;
    jumpHeader.strafeCount = jump.strafes;
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
}

static void WriteTickData(File file, int client, int replayType)
{
    ReplayTickData tickData;
    switch(replayType)
    {
        case ReplayType_Run:
        {
            for (int i = 0; i < recordedRunData[client].Length - 1; i++)
            {
                recordedRunData[client].GetArray(i, tickData);
                file.WriteInt32(view_as<int>(tickData.origin[0]));
                file.WriteInt32(view_as<int>(tickData.origin[1]));
                file.WriteInt32(view_as<int>(tickData.origin[2]));
                file.WriteInt32(view_as<int>(tickData.angles[0]));
                file.WriteInt32(view_as<int>(tickData.angles[1]));
                file.WriteInt32(tickData.playerFlags);
                file.WriteInt32(tickData.takeoffSpeed);
            }
        }
        case ReplayType_Cheater:
        {
            int i = recordingIndex[client];
            do
            {
                i %= recordedTickData[client].Length;
                recordedTickData[client].GetArray(i, tickData, RP_TICK_DATA_BLOCKSIZE);
                file.Write(tickData, RP_TICK_DATA_BLOCKSIZE, 4);
                i++;
            } while (i != recordingIndex[client]);
        }
        case ReplayType_Jump:
        {
            if (timerRunning[client])
            {
                for (int i = lastTakeoffTick[client]; i <= recordingIndex[client]; i++)
                {
                    recordedRunData[client].GetArray(i, tickData, RP_TICK_DATA_BLOCKSIZE);
                }
            }
            else
            {
                int i = lastTakeoffTick[client];
                do
                {
                    i %= recordedTickData[client].Length;
                    recordedTickData[client].GetArray(i, tickData, RP_TICK_DATA_BLOCKSIZE);
                    file.Write(tickData, RP_TICK_DATA_BLOCKSIZE, 4);
                    i++;
                } while (i != recordingIndex[client]);
            }
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
        "%s/%d/%s/%s_%s_%s.%s",
        RP_DIRECTORY_JUMPS,
        GetSteamAccountID(client),
        gC_CurrentMap,
        jumpType,
        gC_ModeNamesShort[mode],
        gC_StyleNamesShort[style],
        RP_FILE_EXTENSION);
}

static int EncodePlayerFlags(int client, int buttons)
{
    int flags = 0;
    MoveType movetype = Movement_GetMovetype(client);
    int clientFlags = GetEntityFlags(client);
    
    SetKthBit(flags, 0, movetype == MOVETYPE_WALK);
    SetKthBit(flags, 1, movetype == MOVETYPE_LADDER);
    SetKthBit(flags, 2, movetype == MOVETYPE_NOCLIP);
    SetKthBit(flags, 3, movetype == MOVETYPE_NONE);

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
    SetKthBit(flags, 16, IsBitSet(clientFlags, FL_ONGROUND));
    SetKthBit(flags, 17, IsBitSet(clientFlags, FL_DUCKING));
    SetKthBit(flags, 18, IsBitSet(clientFlags, FL_SWIM));

    SetKthBit(flags, 19, GetEntProp(client, Prop_Data, "m_nWaterLevel") == 0);

    SetKthBit(flags, 20, lastTeleportTick[client] == GetGameTickCount());
    SetKthBit(flags, 21, Movement_GetTakeoffTick(client) == GetGameTickCount());
    SetKthBit(flags, 22, IsCurrentWeaponSecondary(client));

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

    char clsName[128];
    GetEntityClassname(ent, clsName, sizeof(clsName));

    CSWeaponID weaponId = CS_AliasToWeaponID(clsName);
    int defIndex = CS_WeaponIDToItemDefIndex(weaponId);
 
    return defIndex;
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

    // Create jumps replay directory
    BuildPath(Path_SM, path, sizeof(path), "%s", RP_DIRECTORY_JUMPS);
    if (!DirExists(path))
    {
        CreateDirectory(path, 511);
    }
}