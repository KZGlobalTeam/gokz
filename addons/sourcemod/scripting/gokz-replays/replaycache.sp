/*
	Replay Cache
	
	Cached info about the map's available replay bots stored in an ArrayList.
*/



// =========================  PUBLIC  ========================= //

void AddToReplayInfoCache(int course, int mode, int style, int timeType)
{
	int index = g_ReplayInfoCache.Length;
	g_ReplayInfoCache.Resize(index + 1);
	g_ReplayInfoCache.Set(index, course, 0);
	g_ReplayInfoCache.Set(index, mode, 1);
	g_ReplayInfoCache.Set(index, style, 2);
	g_ReplayInfoCache.Set(index, timeType, 3);
}



// =========================  LISTENERS  ========================= //

void OnMapStart_ReplayCache()
{
	if (g_ReplayInfoCache == INVALID_HANDLE)
	{
		g_ReplayInfoCache = new ArrayList(REPLAY_CACHE_BLOCKSIZE, 0);
	}
	else
	{
		g_ReplayInfoCache.Clear();
	}
	
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "%s/%s", REPLAY_DIRECTORY, gC_CurrentMap);
	DirectoryListing dir = OpenDirectory(path);
	
	// We want to find files that look like "0_KZT_NRM_PRO.rec"
	char file[PLATFORM_MAX_PATH], pieces[4][16];
	int replays = 0, length, dotpos, course, mode, style, timeType;
	
	while (dir.GetNext(file, sizeof(file)))
	{
		// Credit to Influx Timer - https://github.com/TotallyMehis/Influx-Timer
		
		// Check file extension
		length = strlen(file);
		dotpos = 0;
		for (int i = 0; i < length; i++)
		{
			if (file[i] == '.')
			{
				dotpos = i;
			}
		}
		if (!StrEqual(file[dotpos + 1], REPLAY_FILE_EXTENSION, false))
		{
			continue;
		}
		
		// Break down file name into pieces
		if (ExplodeString(file, "_", pieces, sizeof(pieces), sizeof(pieces[])) < sizeof(pieces))
		{
			continue;
		}
		
		// Extract info from the pieces
		course = StringToInt(pieces[0]);
		mode = GetModeIDFromString(pieces[1]);
		style = GetStyleIDFromString(pieces[2]);
		timeType = GetTimeTypeIDFromString(pieces[3]);
		if (course < 0 || course > MAX_COURSES || mode == -1 || style == -1 || timeType == -1)
		{
			continue;
		}
		
		// Add it to the cache
		g_ReplayInfoCache.Resize(replays + 1);
		g_ReplayInfoCache.Set(replays, course, 0);
		g_ReplayInfoCache.Set(replays, mode, 1);
		g_ReplayInfoCache.Set(replays, style, 2);
		g_ReplayInfoCache.Set(replays, timeType, 3);
		
		replays++;
	}
}



// =========================  PRIVATE  ========================= //

static int GetModeIDFromString(const char[] mode)
{
	for (int modeID = 0; modeID < MODE_COUNT; modeID++)
	{
		if (StrEqual(mode, gC_ModeNamesShort[modeID], false))
		{
			return modeID;
		}
	}
	return -1;
}

static int GetStyleIDFromString(const char[] style)
{
	for (int styleID = 0; styleID < STYLE_COUNT; styleID++)
	{
		if (StrEqual(style, gC_StyleNamesShort[styleID], false))
		{
			return styleID;
		}
	}
	return -1;
}

static int GetTimeTypeIDFromString(const char[] timeType)
{
	for (int timeTypeID = 0; timeTypeID < TIMETYPE_COUNT; timeTypeID++)
	{
		if (StrEqual(timeType, gC_TimeTypeNames[timeTypeID], false))
		{
			return timeTypeID;
		}
	}
	return -1;
} 