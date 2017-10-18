/*
	ConVars
	
	ConVars for server control over features of the plugin.
*/



ConVar gCV_gokz_chat_processing;
ConVar gCV_gokz_chat_prefix;
ConVar gCV_gokz_connection_messages;
ConVar gCV_gokz_player_models;
ConVar gCV_gokz_player_models_alpha;
ConVar gCV_sv_disable_immunity_alpha;
ConVar gCV_sv_full_alltalk;



// =========================  PUBLIC  ========================= //

void CreateConVars()
{
	gCV_gokz_chat_processing = CreateConVar("gokz_chat_processing", "1", "Whether GOKZ processes player chat messages.", _, true, 0.0, true, 1.0);
	gCV_gokz_chat_prefix = CreateConVar("gokz_chat_prefix", "{grey}[{green}KZ{grey}] ", "Chat prefix used for GOKZ messages.");
	gCV_gokz_connection_messages = CreateConVar("gokz_connection_messages", "1", "Whether GOKZ handles connection and disconnection messages.", _, true, 0.0, true, 1.0);
	gCV_gokz_player_models = CreateConVar("gokz_player_models", "1", "Whether GOKZ sets player's models upon spawning.", _, true, 0.0, true, 1.0);
	gCV_gokz_player_models_alpha = CreateConVar("gokz_player_models_alpha", "65", "Amount of alpha (transparency) to set player models to.", _, true, 0.0, true, 255.0);
	gCV_sv_disable_immunity_alpha = FindConVar("sv_disable_immunity_alpha");
	gCV_sv_full_alltalk = FindConVar("sv_full_alltalk");
	
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