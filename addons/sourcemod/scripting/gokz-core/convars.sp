/*
	ConVars
	
	ConVars for server control over features of the plugin.
*/



ConVar gCV_ChatProcessing;
ConVar gCV_ChatPrefix;
ConVar gCV_ConnectionMessages;
ConVar gCV_DefaultMode;
ConVar gCV_gokz_player_models;
ConVar gCV_gokz_player_models_alpha;

ConVar gCV_DisableImmunityAlpha;
ConVar gCV_FullAlltalk;



// =========================  PUBLIC  ========================= //

void CreateConVars()
{
	gCV_ChatProcessing = CreateConVar("gokz_chat_processing", "1", "Whether GOKZ processes player chat messages.", _, true, 0.0, true, 1.0);
	gCV_ChatPrefix = CreateConVar("gokz_chat_prefix", "{grey}[{green}KZ{grey}] ", "Chat prefix used for GOKZ messages.");
	gCV_ConnectionMessages = CreateConVar("gokz_connection_messages", "1", "Whether GOKZ handles connection and disconnection messages.", _, true, 0.0, true, 1.0);
	gCV_DefaultMode = CreateConVar("gokz_default_mode", "1", "Default movement mode (0 = Vanilla, 1 = SimpleKZ, 2 = KZTimer).", _, true, 0.0, true, 2.0);
	gCV_gokz_player_models = CreateConVar("gokz_player_models", "1", "Whether GOKZ sets player's models upon spawning.", _, true, 0.0, true, 1.0);
	gCV_gokz_player_models_alpha = CreateConVar("gokz_player_models_alpha", "65", "Amount of alpha (transparency) to set player models to.", _, true, 0.0, true, 255.0);
	gCV_DisableImmunityAlpha = FindConVar("sv_disable_immunity_alpha");
	gCV_FullAlltalk = FindConVar("sv_full_alltalk");
	
	HookConVarChange(gCV_gokz_player_models_alpha, OnConVarChanged);
}



// =========================  LISTENERS  ========================= //

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar == gCV_gokz_player_models_alpha)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client) && IsPlayerAlive(client))
			{
				UpdatePlayerModelAlpha(client);
			}
		}
	}
} 