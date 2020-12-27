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

static int recordingIndex[MAXPLAYERS + 1];
static int lastTakeoffTick[MAXPLAYERS + 1];
static ArrayList recordedTickData[MAXPLAYERS + 1];
static ArrayList recordedRunData[MAXPLAYERS + 1];

// =====[ EVENTS ]=====

void OnMapStart_Recording()
{
    CreateReplaysDirectory(gC_CurrentMap);
}


void OnClientPutInServer_Recording(int client)
{
    if (recordedTickData[client] == null)
    {
        recordedTickData[client] = new ArrayList(RP_TICK_DATA_BLOCKSIZE, 0);
    }

    StartRecording(client);
}

void SaveRecordingOfRun(const char[] path, int client, int course, float time, int teleportsUsed)
{
    // Prepare data
	int timeType = GOKZ_GetTimeTypeEx(teleportsUsed);

    // Create and fill General Header
    GeneralReplayHeader generalHeader;
    FillGeneralHeader(generalHeader, client, ReplayType_Run, endTick - startTick);

    // Create and fill Run Header
    RunReplayHeader runHeader;
    runHeader.time = time;
    runHeader.course = course;
    runHeader.teleportsUsed = teleportsUsed;

    // Build path and create/overwrite associated file
    char replayPath[PLATFORM_MAX_PATH];
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

    File file = OpenFile(path, "wb");
    if (file == null)
	{
		    LogError("Failed to create/open replay file to write to: \"%s\".", path);
		    return false;
    }

    // Write general header
    WriteGeneralHeader(file, generalHeader);

    // Write run header
    file.WriteInt32(view_as<int>(runHeader.time));
    file.WriteInt8(runHeader.course);
    file.WriteInt32(runHeader.teleportsUsed);

    // Write tick data
    WriteTickData(file, client, replayType);
}

void SaveRecordingOfCheater()
{

}

void SaveRecordingOfJump()
{

}


// =====[ PRIVATE ]=====

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
    generalHeader.tickrate = 1/GetTickInterval();
    generalHeader.tickCount = tickCount;
}

static void WriteGeneralHeader(File file, GeneralReplayHeader generalHeader)
{
    file.WriteInt32(generalHeader.magicNumber);
    file.WriteInt8(generalHeader.formatVersion);
    file.WriteInt8(generalHeader.replayType)
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
}

static void WriteTickData(File file, int client, int replayType)
{
    switch(replayType)
    {
        case ReplayType_Run:
        {
            any tickData[RP_TICK_DATA_BLOCKSIZE];
            for (int i = 0; i < recordedRunData[client].Length - 1; i ++)
            {
                recordedRunData[client].GetArray(i, tickData, RP_TICK_DATA_BLOCKSIZE)
                file.Write(tickData, RP_TICK_DATA_BLOCKSIZE, 4);
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