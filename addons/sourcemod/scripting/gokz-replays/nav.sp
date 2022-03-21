/*
	Ensures that there is .nav file for the map so the server
	does not to auto-generating one.
*/



// =====[ EVENTS ]=====

void OnMapStart_Nav()
{
	if (!CheckForNavFile())
	{
		GenerateNavFile();
	}
}



// =====[ PRIVATE ]=====

static bool CheckForNavFile()
{
	// Make sure there's a nav file
	// Credit to shavit's simple bhop timer - https://github.com/shavitush/bhoptimer

	char mapPath[PLATFORM_MAX_PATH];
	GetCurrentMap(mapPath, sizeof(mapPath));

	char navFilePath[PLATFORM_MAX_PATH];
	FormatEx(navFilePath, PLATFORM_MAX_PATH, "maps/%s.nav", mapPath);

	return FileExists(navFilePath);
}

static void GenerateNavFile()
{
	// Generate (copy a) .nav file for the map
	// Credit to shavit's simple bhop timer - https://github.com/shavitush/bhoptimer

	char mapPath[PLATFORM_MAX_PATH];
	GetCurrentMap(mapPath, sizeof(mapPath));

	char[] navFilePath = new char[PLATFORM_MAX_PATH];
	FormatEx(navFilePath, PLATFORM_MAX_PATH, "maps/%s.nav", mapPath);

	if (!FileExists(RP_NAV_FILE))
	{
		SetFailState("Failed to load file: \"%s\". Check that it exists.", RP_NAV_FILE);
	}
	File_Copy(RP_NAV_FILE, navFilePath);
	ForceChangeLevel(gC_CurrentMap, "[gokz-replays] Generate .nav file.");
}

/*
 * Copies file source to destination
 * Based on code of javalia:
 * http://forums.alliedmods.net/showthread.php?t=159895
 *
 * Credit to shavit's simple bhop timer - https://github.com/shavitush/bhoptimer
 *
 * @param source		Input file
 * @param destination	Output file
 */
static bool File_Copy(const char[] source, const char[] destination)
{
	File file_source = OpenFile(source, "rb");

	if (file_source == null)
	{
		return false;
	}

	File file_destination = OpenFile(destination, "wb");

	if (file_destination == null)
	{
		delete file_source;

		return false;
	}

	int[] buffer = new int[32];
	int cache = 0;

	while (!IsEndOfFile(file_source))
	{
		cache = ReadFile(file_source, buffer, 32, 1);

		file_destination.Write(buffer, cache, 1);
	}

	delete file_source;
	delete file_destination;

	return true;
} 