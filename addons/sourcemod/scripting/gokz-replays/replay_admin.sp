/*
	Lets admins load replays the replay menu doesn't list: imported replays
	from other servers and replays of suspected cheaters.

	Everything the menus show comes from replay headers, not file names.
*/



enum
{
	ReplayFolder_Imported = 0,
	ReplayFolder_Cheaters,
	REPLAYFOLDER_COUNT
};

enum struct AdminReplay
{
	int folder;
	int replayType;
	int mode;
	int steamAccountID;
	int timestamp;
	int course;
	float time;
	int teleportsUsed;
	int jumpType;
	float distance;
	int acReason;
	char map[64];
	char alias[MAX_NAME_LENGTH];
	char path[PLATFORM_MAX_PATH];
}

static ArrayList adminReplays[MAXPLAYERS + 1];
static int selectedFolder[MAXPLAYERS + 1];
static char selectedMap[MAXPLAYERS + 1][64];
static int selectedReplay[MAXPLAYERS + 1];
static int unreadableFiles[MAXPLAYERS + 1];

// A page of replays, the title and the page controls must fit SourceMod's 512-byte menu
#define RP_ADMIN_REPLAYS_PER_PAGE 5
#define RP_ADMIN_ALIAS_LENGTH 21

// The replay an admin changed the map for, loaded once they join a team on the new map
static int pendingAccountID;
static char pendingMap[64];
static char pendingPath[PLATFORM_MAX_PATH];



// =====[ PUBLIC ]=====

void DisplayReplayAdminMenu(int client, const char[] filter)
{
	delete adminReplays[client];
	adminReplays[client] = new ArrayList(sizeof(AdminReplay));

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "%s", RP_DIRECTORY_IMPORTED);
	unreadableFiles[client] = AddFolderReplays(client, ReplayFolder_Imported, path, filter);
	BuildPath(Path_SM, path, sizeof(path), "%s", RP_DIRECTORY_CHEATERS);
	unreadableFiles[client] += AddFolderReplays(client, ReplayFolder_Cheaters, path, filter);

	adminReplays[client].SortCustom(SortAdminReplaysNewestFirst);
	DisplayFolderMenu(client);
}



// =====[ EVENTS ]=====

void OnMapStart_ReplayAdmin()
{
	// The admin never joined a team on the replay's map
	if (!StrEqual(pendingMap, gC_CurrentMap))
	{
		pendingAccountID = 0;
	}
}

void GOKZ_OnJoinTeam_ReplayAdmin(int client)
{
	if (pendingAccountID == 0 || GetSteamAccountID(client) != pendingAccountID)
	{
		return;
	}

	pendingAccountID = 0;
	if (StrEqual(pendingMap, gC_CurrentMap))
	{
		// Joining a team is still in progress, and loading moves the admin to spectate the bot
		RequestFrame(LoadPendingReplay, GetClientUserId(client));
	}
}

public void LoadPendingReplay(int userid)
{
	int client = GetClientOfUserId(userid);
	if (IsValidClient(client))
	{
		LoadReplayBot(client, pendingPath);
	}
}

public int MenuHandler_ReplayAdminFolder(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		selectedFolder[param1] = param2;
		DisplayMapMenu(param1);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public int MenuHandler_ReplayAdminMap(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		menu.GetItem(param2, selectedMap[param1], sizeof(selectedMap[]));
		DisplayReplayListMenu(param1);
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		DisplayFolderMenu(param1);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public int MenuHandler_ReplayAdminReplay(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[8];
		menu.GetItem(param2, info, sizeof(info));
		selectedReplay[param1] = StringToInt(info);
		AdminReplay replay;
		adminReplays[param1].GetArray(selectedReplay[param1], replay);
		if (StrEqual(replay.map, gC_CurrentMap))
		{
			LoadReplayBot(param1, replay.path);
		}
		else
		{
			DisplayOtherMapMenu(param1);
		}
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		DisplayMapMenu(param1);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public int MenuHandler_ReplayAdminOtherMap(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char map[PLATFORM_MAX_PATH];
		if (GetSteamAccountID(param1) == 0)
		{
			// Without a Steam account ID the replay couldn't be matched to the admin after the map change
			GOKZ_PrintToChat(param1, true, "%t", "Replay Menu - Wrong Map", selectedMap[param1]);
			GOKZ_PlayErrorSound(param1);
		}
		else if (FindExactMap(selectedMap[param1], map, sizeof(map)))
		{
			AdminReplay replay;
			adminReplays[param1].GetArray(selectedReplay[param1], replay);
			pendingAccountID = GetSteamAccountID(param1);
			strcopy(pendingMap, sizeof(pendingMap), replay.map);
			strcopy(pendingPath, sizeof(pendingPath), replay.path);
			LogAction(param1, -1, "\"%L\" changed map to \"%s\" from the replay admin menu", param1, map);
			ForceChangeLevel(map, "sm_replayadmin");
		}
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		DisplayReplayListMenu(param1);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public int SortAdminReplaysNewestFirst(int index1, int index2, Handle array, Handle hndl)
{
	ArrayList replays = view_as<ArrayList>(array);
	int timestamp1 = replays.Get(index1, AdminReplay::timestamp);
	int timestamp2 = replays.Get(index2, AdminReplay::timestamp);
	if (timestamp1 == timestamp2)
	{
		return 0;
	}
	return timestamp1 > timestamp2 ? -1 : 1;
}



// =====[ PRIVATE ]=====

static void DisplayFolderMenu(int client)
{
	int counts[REPLAYFOLDER_COUNT];
	for (int i = 0; i < adminReplays[client].Length; i++)
	{
		counts[adminReplays[client].Get(i, AdminReplay::folder)]++;
	}

	Menu menu = new Menu(MenuHandler_ReplayAdminFolder);
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "%s", RP_DIRECTORY_IMPORTED);
	if (unreadableFiles[client] > 0)
	{
		menu.SetTitle("%T", "Replay Admin (Unreadable) - Title", client, path, unreadableFiles[client]);
	}
	else
	{
		menu.SetTitle("%T", "Replay Admin - Title", client, path);
	}
	char display[64];
	FormatEx(display, sizeof(display), "%T", "Replay Admin - Imported", client, counts[ReplayFolder_Imported]);
	menu.AddItem("", display, counts[ReplayFolder_Imported] > 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	FormatEx(display, sizeof(display), "%T", "Replay Admin - Cheaters", client, counts[ReplayFolder_Cheaters]);
	menu.AddItem("", display, counts[ReplayFolder_Cheaters] > 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	menu.Display(client, MENU_TIME_FOREVER);
}

// Lists the selected folder's maps, the current map first, then by newest replay
static void DisplayMapMenu(int client)
{
	ArrayList maps = new ArrayList(ByteCountToCells(sizeof(selectedMap[])));
	StringMap replayCounts = new StringMap();
	AdminReplay replay;
	int count;
	for (int i = 0; i < adminReplays[client].Length; i++)
	{
		adminReplays[client].GetArray(i, replay);
		if (replay.folder != selectedFolder[client])
		{
			continue;
		}
		count = 0;
		if (!replayCounts.GetValue(replay.map, count))
		{
			maps.PushString(replay.map);
		}
		replayCounts.SetValue(replay.map, count + 1);
	}

	Menu menu = new Menu(MenuHandler_ReplayAdminMap);
	menu.SetTitle("%T", "Replay Admin (Map) - Title", client);
	menu.ExitBackButton = true;
	char map[sizeof(selectedMap[])], display[128];
	if (replayCounts.GetValue(gC_CurrentMap, count))
	{
		FormatEx(display, sizeof(display), "%T", "Replay Admin - Current Map", client, gC_CurrentMap, count);
		menu.AddItem(gC_CurrentMap, display);
	}
	for (int i = 0; i < maps.Length; i++)
	{
		maps.GetString(i, map, sizeof(map));
		if (StrEqual(map, gC_CurrentMap))
		{
			continue;
		}
		replayCounts.GetValue(map, count);
		FormatEx(display, sizeof(display), "%T", "Replay Admin - Map", client, map, count);
		menu.AddItem(map, display);
	}
	delete maps;
	delete replayCounts;
	menu.Display(client, MENU_TIME_FOREVER);
}

static void DisplayReplayListMenu(int client)
{
	Menu menu = new Menu(MenuHandler_ReplayAdminReplay);
	menu.SetTitle("%T", "Replay Admin (Replay) - Title", client, selectedMap[client]);
	menu.ExitBackButton = true;
	menu.Pagination = RP_ADMIN_REPLAYS_PER_PAGE;
	AdminReplay replay;
	char info[8], alias[RP_ADMIN_ALIAS_LENGTH], kind[32], date[32], display[128];
	for (int i = 0; i < adminReplays[client].Length; i++)
	{
		adminReplays[client].GetArray(i, replay);
		if (replay.folder != selectedFolder[client] || !StrEqual(replay.map, selectedMap[client]))
		{
			continue;
		}
		ShortenAlias(replay.alias, alias, sizeof(alias));
		FormatReplayKind(replay, kind, sizeof(kind));
		// FormatTime can't format a time before 1970 on every platform
		if (replay.timestamp < 0)
		{
			FormatEx(date, sizeof(date), "%T", "Replay Admin - Unknown Date", client);
		}
		else
		{
			FormatTime(date, sizeof(date), "%Y-%m-%d", replay.timestamp);
		}
		// DanZay - KZT - Main 01:23.45 PRO - 2026-11-10
		FormatEx(display, sizeof(display), "%s - %s - %s - %s",
			alias, gC_ModeNamesShort[replay.mode], kind, date);
		IntToString(i, info, sizeof(info));
		menu.AddItem(info, display);
	}
	menu.Display(client, MENU_TIME_FOREVER);
}

static void DisplayOtherMapMenu(int client)
{
	char map[PLATFORM_MAX_PATH];
	if (!CheckCommandAccess(client, "sm_map", ADMFLAG_CHANGEMAP))
	{
		GOKZ_PrintToChat(client, true, "%t", "Replay Menu - Wrong Map", selectedMap[client]);
		GOKZ_PlayErrorSound(client);
		DisplayReplayListMenu(client);
		return;
	}
	if (!FindExactMap(selectedMap[client], map, sizeof(map)))
	{
		GOKZ_PrintToChat(client, true, "%t", "Replay Admin - Map Not On Server", selectedMap[client]);
		GOKZ_PlayErrorSound(client);
		DisplayReplayListMenu(client);
		return;
	}

	Menu menu = new Menu(MenuHandler_ReplayAdminOtherMap);
	menu.SetTitle("%T", "Replay Admin (Replay) - Title", client, selectedMap[client]);
	menu.ExitBackButton = true;
	char display[128];
	FormatEx(display, sizeof(display), "%T", "Replay Admin - Change Map", client, selectedMap[client]);
	menu.AddItem("", display);
	menu.Display(client, MENU_TIME_FOREVER);
}

// Main 01:23.45 PRO, Bonus 2 00:41.20 NUB, LJ 271.3 or the anticheat reason
static void FormatReplayKind(AdminReplay replay, char[] buffer, int maxlength)
{
	switch (replay.replayType)
	{
		case ReplayType_Run:
		{
			if (replay.course == 0)
			{
				FormatEx(buffer, maxlength, "Main %s %s",
					GOKZ_FormatTime(replay.time), gC_TimeTypeNames[GOKZ_GetTimeTypeEx(replay.teleportsUsed)]);
			}
			else
			{
				FormatEx(buffer, maxlength, "Bonus %d %s %s",
					replay.course, GOKZ_FormatTime(replay.time), gC_TimeTypeNames[GOKZ_GetTimeTypeEx(replay.teleportsUsed)]);
			}
		}
		case ReplayType_Jump:
		{
			FormatEx(buffer, maxlength, "%s %.1f", gC_JumpTypesShort[replay.jumpType], replay.distance);
		}
		case ReplayType_Cheater:
		{
			strcopy(buffer, maxlength, gC_ACReasons[replay.acReason]);
		}
	}
}

// Cuts a name at a whole UTF-8 character
static void ShortenAlias(const char[] alias, char[] buffer, int maxlength)
{
	int length;
	while (alias[length] != '\0' && length + GetCharBytes(alias[length]) < maxlength)
	{
		length += GetCharBytes(alias[length]);
	}
	strcopy(buffer, length + 1, alias);
}

// FindMap also accepts partial names, so the resolved map's name must match exactly
static bool FindExactMap(const char[] map, char[] foundMap, int maxlength)
{
	char displayName[PLATFORM_MAX_PATH];
	return FindMap(map, foundMap, maxlength) != FindMap_NotFound
		&& GetMapDisplayName(foundMap, displayName, sizeof(displayName))
		&& StrEqual(displayName, map, false);
}

// Returns the number of replay files in the folder that couldn't be read
static int AddFolderReplays(int client, int folder, const char[] folderPath, const char[] filter)
{
	DirectoryListing dir = OpenDirectory(folderPath);
	if (dir == null)
	{
		return 0;
	}

	int filterAccountID = Steam2ToSteamAccountID(filter);
	int unreadable;
	char file[PLATFORM_MAX_PATH];
	FileType type;
	AdminReplay replay;
	while (dir.GetNext(file, sizeof(file), type))
	{
		int extension = FindCharInString(file, '.', true);
		if (type != FileType_File || extension == -1 || !StrEqual(file[extension + 1], RP_FILE_EXTENSION, false))
		{
			continue;
		}

		FormatEx(replay.path, sizeof(replay.path), "%s/%s", folderPath, file);
		if (!ReadReplayHeader(replay))
		{
			unreadable++;
			continue;
		}
		if (filter[0] != '\0'
			&& (filterAccountID == -1 || replay.steamAccountID != filterAccountID)
			&& StrContains(replay.alias, filter, false) == -1)
		{
			continue;
		}
		replay.folder = folder;
		adminReplays[client].PushArray(replay);
	}
	delete dir;
	return unreadable;
}

// Files can come from other servers, so every read and value is checked
static bool ReadReplayHeader(AdminReplay replay)
{
	File file = OpenFile(replay.path, "rb");
	if (file == null)
	{
		return false;
	}

	replay.acReason = -1;
	int magicNumber, formatVersion;
	bool read = file.ReadInt32(magicNumber) && magicNumber == RP_MAGIC_NUMBER
		&& file.ReadInt8(formatVersion)
		&& (formatVersion == 1 && ReadReplayHeaderV1(file, replay)
			|| formatVersion == 2 && ReadReplayHeaderV2(file, replay));
	delete file;

	if (formatVersion == 1)
	{
		// Old replays don't store when they were recorded
		replay.timestamp = GetFileTime(replay.path, FileTime_Created);
	}

	return read
		&& replay.mode >= 0 && replay.mode < MODE_COUNT
		&& (replay.replayType == ReplayType_Run
			|| replay.replayType == ReplayType_Jump
				&& replay.jumpType >= 0 && replay.jumpType < JUMPTYPE_COUNT
			|| replay.replayType == ReplayType_Cheater
				&& replay.acReason >= 0 && replay.acReason < view_as<int>(ACREASON_COUNT));
}

static bool ReadReplayHeaderV1(File file, AdminReplay replay)
{
	// Old replays only support runs
	replay.replayType = ReplayType_Run;
	int skipped;
	return SkipHeaderString(file) // GOKZ version
		&& ReadHeaderString(file, replay.map, sizeof(replay.map))
		&& file.ReadInt32(replay.course)
		&& file.ReadInt32(replay.mode)
		&& file.ReadInt32(skipped) // Style
		&& ReadHeaderFloat(file, replay.time)
		&& file.ReadInt32(replay.teleportsUsed)
		&& file.ReadInt32(replay.steamAccountID)
		&& SkipHeaderString(file) // SteamID2
		&& SkipHeaderString(file) // IP
		&& ReadHeaderString(file, replay.alias, sizeof(replay.alias));
}

static bool ReadReplayHeaderV2(File file, AdminReplay replay)
{
	int skipped;
	return file.ReadInt8(replay.replayType)
		&& SkipHeaderString(file) // GOKZ version
		&& ReadHeaderString(file, replay.map, sizeof(replay.map))
		&& file.ReadInt32(skipped) // Map file size
		&& file.ReadInt32(skipped) // Server IP
		&& file.ReadInt32(replay.timestamp)
		&& ReadHeaderString(file, replay.alias, sizeof(replay.alias))
		&& file.ReadInt32(replay.steamAccountID)
		&& file.ReadInt8(replay.mode)
		&& file.Seek(25, SEEK_CUR) // Style, sensitivity, m_yaw, tickrate, tick count, weapon and knife
		&& ReadReplayTypeHeader(file, replay);
}

static bool ReadReplayTypeHeader(File file, AdminReplay replay)
{
	switch (replay.replayType)
	{
		case ReplayType_Run:
		{
			return ReadHeaderFloat(file, replay.time)
				&& file.ReadInt8(replay.course)
				&& file.ReadInt32(replay.teleportsUsed);
		}
		case ReplayType_Cheater:
		{
			return file.ReadInt8(replay.acReason);
		}
		case ReplayType_Jump:
		{
			return file.ReadInt8(replay.jumpType)
				&& ReadHeaderFloat(file, replay.distance);
		}
	}
	return false;
}

static bool ReadHeaderFloat(File file, float &value)
{
	int bits;
	if (!file.ReadInt32(bits))
	{
		return false;
	}
	value = view_as<float>(bits);
	return true;
}

static bool ReadHeaderString(File file, char[] buffer, int maxlength)
{
	int length;
	if (!file.ReadUint8(length) || length >= maxlength || file.ReadString(buffer, maxlength, length) != length)
	{
		return false;
	}
	buffer[length] = '\0';
	return true;
}

static bool SkipHeaderString(File file)
{
	int length;
	return file.ReadUint8(length) && file.Seek(length, SEEK_CUR);
}
