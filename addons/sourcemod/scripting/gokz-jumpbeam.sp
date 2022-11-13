#include <sourcemod>

#include <sdktools>

#include <gokz/core>
#include <gokz/jumpbeam>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <updater>

#include <gokz/kzplayer>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ Jump Beam", 
	author = "DanZay", 
	description = "Provides option to leave behind a trail when in midair", 
	version = GOKZ_VERSION, 
	url = GOKZ_SOURCE_URL
};

#define UPDATER_URL GOKZ_UPDATER_BASE_URL..."gokz-jumpbeam.txt"

float gF_OldOrigin[MAXPLAYERS + 1][3];
bool gB_OldDucking[MAXPLAYERS + 1];
int gI_BeamModel;
TopMenu gTM_Options;
TopMenuObject gTMO_CatGeneral;
TopMenuObject gTMO_ItemsJB[JBOPTION_COUNT];



// =====[ PLUGIN EVENTS ]=====

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("gokz-jumpbeam");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("gokz-common.phrases");
	LoadTranslations("gokz-jumpbeam.phrases");
}

public void OnAllPluginsLoaded()
{
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATER_URL);
	}
	
	TopMenu topMenu;
	if (LibraryExists("gokz-core") && ((topMenu = GOKZ_GetOptionsTopMenu()) != null))
	{
		GOKZ_OnOptionsMenuReady(topMenu);
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATER_URL);
	}
}



// =====[ CLIENT EVENTS ]=====

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	if (!IsValidClient(client))
	{
		return;
	}

	OnPlayerRunCmdPost_JumpBeam(client);
	UpdateOldVariables(client);
}



// =====[ OTHER EVENTS ]=====

public void OnMapStart()
{
	gI_BeamModel = PrecacheModel("materials/sprites/laserbeam.vmt", true);
}

public void GOKZ_OnOptionsMenuReady(TopMenu topMenu)
{
	OnOptionsMenuReady_Options();
	OnOptionsMenuReady_OptionsMenu(topMenu);
}



// =====[ GENERAL ]=====

void UpdateOldVariables(int client)
{
	if (IsPlayerAlive(client))
	{
		Movement_GetOrigin(client, gF_OldOrigin[client]);
		gB_OldDucking[client] = Movement_GetDucking(client);
	}
}



// =====[ JUMP BEAM ]=====

void OnPlayerRunCmdPost_JumpBeam(int targetClient)
{
	// In this case, spectators are handled from the target 
	// client's OnPlayerRunCmd call, otherwise the jump 
	// beam will be all broken up.
	
	KZPlayer targetPlayer = KZPlayer(targetClient);
	
	if (targetPlayer.Fake || !targetPlayer.Alive || targetPlayer.OnGround || !targetPlayer.ValidJump)
	{
		return;
	}
	
	// Send to self
	SendJumpBeam(targetPlayer, targetPlayer);
	
	// Send to spectators
	for (int client = 1; client <= MaxClients; client++)
	{
		KZPlayer player = KZPlayer(client);
		if (player.InGame && !player.Alive && player.ObserverTarget == targetClient)
		{
			SendJumpBeam(player, targetPlayer);
		}
	}
}

void SendJumpBeam(KZPlayer player, KZPlayer targetPlayer)
{
	if (player.JBType == JBType_Disabled)
	{
		return;
	}
	
	switch (player.JBType)
	{
		case JBType_Feet:SendFeetJumpBeam(player, targetPlayer);
		case JBType_Head:SendHeadJumpBeam(player, targetPlayer);
		case JBType_FeetAndHead:
		{
			SendFeetJumpBeam(player, targetPlayer);
			SendHeadJumpBeam(player, targetPlayer);
		}
		case JBType_Ground:SendGroundJumpBeam(player, targetPlayer);
	}
}

void SendFeetJumpBeam(KZPlayer player, KZPlayer targetPlayer)
{
	float origin[3], beamStart[3], beamEnd[3];
	int beamColour[4];
	targetPlayer.GetOrigin(origin);
	
	beamStart = gF_OldOrigin[targetPlayer.ID];
	beamEnd = origin;
	GetJumpBeamColour(targetPlayer, beamColour);
	
	TE_SetupBeamPoints(beamStart, beamEnd, gI_BeamModel, 0, 0, 0, JB_BEAM_LIFETIME, 0.25, 0.25, 10, 0.0, beamColour, 0);
	TE_SendToClient(player.ID);
}

void SendHeadJumpBeam(KZPlayer player, KZPlayer targetPlayer)
{
	float origin[3], beamStart[3], beamEnd[3];
	int beamColour[4];
	targetPlayer.GetOrigin(origin);
	
	beamStart = gF_OldOrigin[targetPlayer.ID];
	beamEnd = origin;
	if (gB_OldDucking[targetPlayer.ID])
	{
		beamStart[2] = beamStart[2] + 54.0;
	}
	else
	{
		beamStart[2] = beamStart[2] + 72.0;
	}
	if (targetPlayer.Ducking)
	{
		beamEnd[2] = beamEnd[2] + 54.0;
	}
	else
	{
		beamEnd[2] = beamEnd[2] + 72.0;
	}
	GetJumpBeamColour(targetPlayer, beamColour);
	
	TE_SetupBeamPoints(beamStart, beamEnd, gI_BeamModel, 0, 0, 0, JB_BEAM_LIFETIME, 0.25, 0.25, 10, 0.0, beamColour, 0);
	TE_SendToClient(player.ID);
}

void SendGroundJumpBeam(KZPlayer player, KZPlayer targetPlayer)
{
	float origin[3], takeoffOrigin[3], beamStart[3], beamEnd[3];
	int beamColour[4];
	targetPlayer.GetOrigin(origin);
	targetPlayer.GetTakeoffOrigin(takeoffOrigin);
	
	beamStart = gF_OldOrigin[targetPlayer.ID];
	beamEnd = origin;
	beamStart[2] = takeoffOrigin[2] + 0.1;
	beamEnd[2] = takeoffOrigin[2] + 0.1;
	GetJumpBeamColour(targetPlayer, beamColour);
	
	TE_SetupBeamPoints(beamStart, beamEnd, gI_BeamModel, 0, 0, 0, JB_BEAM_LIFETIME, 0.25, 0.25, 10, 0.0, beamColour, 0);
	TE_SendToClient(player.ID);
}

void GetJumpBeamColour(KZPlayer targetPlayer, int colour[4])
{
	if (targetPlayer.Ducking)
	{
		colour =  { 255, 0, 0, 110 }; // Red
	}
	else
	{
		colour =  { 0, 255, 0, 110 }; // Green
	}
}



// =====[ OPTIONS ]=====

void OnOptionsMenuReady_Options()
{
	RegisterOptions();
}

void RegisterOptions()
{
	for (JBOption option; option < JBOPTION_COUNT; option++)
	{
		GOKZ_RegisterOption(gC_JBOptionNames[option], gC_JBOptionDescriptions[option], 
			OptionType_Int, gI_JBOptionDefaultValues[option], 0, gI_JBOptionCounts[option] - 1);
	}
}



// =====[ OPTIONS MENU ]=====

void OnOptionsMenuReady_OptionsMenu(TopMenu topMenu)
{
	if (gTM_Options == topMenu)
	{
		return;
	}
	
	gTM_Options = topMenu;
	gTMO_CatGeneral = gTM_Options.FindCategory(GENERAL_OPTION_CATEGORY);
	
	for (int option = 0; option < view_as<int>(JBOPTION_COUNT); option++)
	{
		gTMO_ItemsJB[option] = gTM_Options.AddItem(gC_JBOptionNames[option], TopMenuHandler_General, gTMO_CatGeneral);
	}
}

public void TopMenuHandler_General(TopMenu topmenu, TopMenuAction action, TopMenuObject topobj_id, int param, char[] buffer, int maxlength)
{
	JBOption option = JBOPTION_INVALID;
	for (int i = 0; i < view_as<int>(JBOPTION_COUNT); i++)
	{
		if (topobj_id == gTMO_ItemsJB[i])
		{
			option = view_as<JBOption>(i);
			break;
		}
	}
	
	if (option == JBOPTION_INVALID)
	{
		return;
	}
	
	if (action == TopMenuAction_DisplayOption)
	{
		switch (option)
		{
			case JBOption_Type:
			{
				FormatEx(buffer, maxlength, "%T - %T", 
					gC_JBOptionPhrases[option], param, 
					gC_JBTypePhrases[GOKZ_JB_GetOption(param, option)], param);
			}
		}
	}
	else if (action == TopMenuAction_SelectOption)
	{
		switch (option)
		{
			default:
			{
				GOKZ_JB_CycleOption(param, option);
				gTM_Options.Display(param, TopMenuPosition_LastCategory);
			}
		}
	}
} 