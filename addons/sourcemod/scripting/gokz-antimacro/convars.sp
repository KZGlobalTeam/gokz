/*
	ConVars
	
	ConVars for server control over features of the plugin.
*/



ConVar gCV_gokz_autoban;
ConVar gCV_gokz_autoban_duration;



// =====[ PUBLIC ]=====

void CreateConVars()
{
	gCV_gokz_autoban = CreateConVar("gokz_autoban", "1", "Whether to autoban players when they are suspected of cheating.", _, true, 0.0, true, 1.0);
	gCV_gokz_autoban_duration = CreateConVar("gokz_autoban_duration", "0", "Duration of antimacro autobans in minutes (0 for permanent).", _, true, 0.0);
} 