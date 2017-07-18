/*
	Mapping API - Prefix
	
	Detects the map's prefix.
*/



static int currentMapPrefix;



// =========================  PUBLIC  ========================= //

int GetCurrentMapPrefix()
{
	return currentMapPrefix;
}



// =========================  LISTENERS  ========================= //

void OnMapStart_Prefix()
{
	char map[64], mapPieces[5][64], mapPrefix[1][64];
	GetCurrentMap(map, sizeof(map));
	int lastPiece = ExplodeString(map, "/", mapPieces, sizeof(mapPieces), sizeof(mapPieces[]));
	ExplodeString(mapPieces[lastPiece - 1], "_", mapPrefix, sizeof(mapPrefix), sizeof(mapPrefix[]));
	if (StrEqual(mapPrefix[0], "kzpro", false))
	{
		currentMapPrefix = MapPrefix_KZPro;
	}
	else
	{
		currentMapPrefix = MapPrefix_Other;
	}
} 