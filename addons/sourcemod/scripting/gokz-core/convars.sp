/*
	ConVars
	
	ConVars for server control over features of the plugin.
*/



ConVar gCV_gokz_chat_prefix;
ConVar gCV_sv_full_alltalk;



// =========================  PUBLIC  ========================= //

void CreateConVars()
{
	gCV_gokz_chat_prefix = CreateConVar("gokz_chat_prefix", "{grey}[{green}KZ{grey}] ", "Chat prefix used for GOKZ messages.");
	gCV_sv_full_alltalk = FindConVar("sv_full_alltalk");
	
	// Remove unwanted flags from constantly changed mode convars - replication is done manually in mode plugins
	for (int i = 0; i < MODECVAR_COUNT; i++)
	{
		FindConVar(gC_ModeCVars[i]).Flags &= ~FCVAR_NOTIFY;
		FindConVar(gC_ModeCVars[i]).Flags &= ~FCVAR_REPLICATED;
	}
} 