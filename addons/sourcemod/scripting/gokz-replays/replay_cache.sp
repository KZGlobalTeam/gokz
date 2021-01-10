/*
	Cached info about the map's available replay bots stored in an ArrayList.
*/



// =====[ PUBLIC ]=====

// Adds a replay to the cache
void AddToReplayInfoCache(int course, int mode, int style, int timeType)
{
	int index = g_ReplayInfoCache.Length;
	g_ReplayInfoCache.Resize(index + 1);
	g_ReplayInfoCache.Set(index, course, 0);
	g_ReplayInfoCache.Set(index, mode, 1);
	g_ReplayInfoCache.Set(index, style, 2);
	g_ReplayInfoCache.Set(index, timeType, 3);
}

// Use this to sort the cache after finished adding to it
void SortReplayInfoCache()
{
	g_ReplayInfoCache.SortCustom(SortFunc_ReplayInfoCache);
}

public int SortFunc_ReplayInfoCache(int index1, int index2, Handle array, Handle hndl)
{
	// Do not expect any indexes to be 'equal'	
	int replayInfo1[RP_CACHE_BLOCKSIZE], replayInfo2[RP_CACHE_BLOCKSIZE];
	g_ReplayInfoCache.GetArray(index1, replayInfo1);
	g_ReplayInfoCache.GetArray(index2, replayInfo2);
	
	// Compare courses - lower course number goes first
	if (replayInfo1[0] < replayInfo2[0])
	{
		return -1;
	}
	else if (replayInfo1[0] > replayInfo2[0])
	{
		return 1;
	}
	// Same course, so compare mode
	else if (replayInfo1[1] < replayInfo2[1])
	{
		return -1;
	}
	else if (replayInfo1[1] > replayInfo2[1])
	{
		return 1;
	}
	// Same course and mode, so compare style
	else if (replayInfo1[2] < replayInfo2[2])
	{
		return -1;
	}
	else if (replayInfo1[2] > replayInfo2[2])
	{
		return 1;
	}
	// Same course, mode and style so compare time type, assuming can't be identical
	else if (replayInfo1[3] == TimeType_Pro)
	{
		return 1;
	}
	return -1;
}



// =====[ EVENTS ]=====

void OnMapStart_ReplayCache()
{
	if (g_ReplayInfoCache == null)
	{
		g_ReplayInfoCache = new ArrayList(RP_CACHE_BLOCKSIZE, 0);
	}
	else
	{
		g_ReplayInfoCache.Clear();
	}
	
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "%s/%s", RP_DIRECTORY_RUNS, gC_CurrentMap);
	DirectoryListing dir = OpenDirectory(path);
	
	// We want to find files that look like "0_KZT_NRM_PRO.rec"
	char file[PLATFORM_MAX_PATH], pieces[4][16];
	int length, dotpos, course, mode, style, timeType;
	
	while (dir.GetNext(file, sizeof(file)))
	{
		// Some credit to Influx Timer - https://github.com/TotallyMehis/Influx-Timer
		
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
		if (!StrEqual(file[dotpos + 1], RP_FILE_EXTENSION, false))
		{
			continue;
		}
		
		// Remove file extension
		Format(file, dotpos + 1, file);
		
		// Break down file name into pieces
		if (ExplodeString(file, "_", pieces, sizeof(pieces), sizeof(pieces[])) != sizeof(pieces))
		{
			continue;
		}
		
		// Extract info from the pieces
		course = StringToInt(pieces[0]);
		mode = GetModeIDFromString(pieces[1]);
		style = GetStyleIDFromString(pieces[2]);
		timeType = GetTimeTypeIDFromString(pieces[3]);
		if (!GOKZ_IsValidCourse(course) || mode == -1 || style == -1 || timeType == -1)
		{
			continue;
		}
		
		// Add it to the cache
		AddToReplayInfoCache(course, mode, style, timeType);
	}
	
	SortReplayInfoCache();
	
	delete dir;
}



// =====[ PRIVATE ]=====

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