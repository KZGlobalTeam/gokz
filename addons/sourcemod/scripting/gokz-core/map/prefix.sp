/*
	Mapping API - Prefix
	
	Detects the map's prefix.
*/



static int currentMapPrefix;



// =====[ PUBLIC ]=====

int GetCurrentMapPrefix()
{
	return currentMapPrefix;
}



// =====[ LISTENERS ]=====

void OnMapStart_Prefix()
{
	char map[PLATFORM_MAX_PATH], mapPrefix[PLATFORM_MAX_PATH];
	GetCurrentMapDisplayName(map, sizeof(map));
	
	// Get all characters before the first '_' character
	for (int i = 0; i < sizeof(mapPrefix); i++)
	{
		if (map[i] == '\0' || map[i] == '_')
		{
			break;
		}
		
		mapPrefix[i] = map[i];
	}
	
	if (StrEqual(mapPrefix[0], "kzpro", false))
	{
		currentMapPrefix = MapPrefix_KZPro;
	}
	else
	{
		currentMapPrefix = MapPrefix_Other;
	}
} 