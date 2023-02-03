#include <sourcemod>

#include <gokz/core>
#include <gokz/tips>

#include <autoexecconfig>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <updater>

#include <gokz/kzplayer>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ Tips", 
	author = "DanZay", 
	description = "Prints tips to chat periodically based on loaded plugins", 
	version = GOKZ_VERSION, 
	url = GOKZ_SOURCE_URL
};

#define UPDATER_URL GOKZ_UPDATER_BASE_URL..."gokz-tips.txt"

bool gC_PluginsWithTipsLoaded[TIPS_PLUGINS_COUNT];
ArrayList g_TipPhrases;
int gI_CurrentTip;
Handle gH_TipTimer;
TopMenu gTM_Options;
TopMenuObject gTMO_CatGeneral;
TopMenuObject gTMO_ItemTips;
ConVar gCV_gokz_tips_interval;



// =====[ PLUGIN EVENTS ]=====

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("gokz-tips");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("gokz-common.phrases");
	LoadTranslations("gokz-tips.phrases");
	LoadTranslations("gokz-tips-tips.phrases");
	LoadTranslations("gokz-tips-core.phrases");

	// Load translations of tips for other GOKZ plugins
	char translation[PLATFORM_MAX_PATH];
	for (int i = 0; i < TIPS_PLUGINS_COUNT; i++)
	{
		FormatEx(translation, sizeof(translation), "gokz-tips-%s.phrases", gC_PluginsWithTips[i]);
		LoadTranslations(translation);
	}

	CreateConVars();
	RegisterCommands();
	CreateTipsTimer();
}

public void OnAllPluginsLoaded()
{
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATER_URL);
	}

	char gokzPlugin[PLATFORM_MAX_PATH];
	for (int i = 0; i < TIPS_PLUGINS_COUNT; i++)
	{
		FormatEx(gokzPlugin, sizeof(gokzPlugin), "gokz-%s", gC_PluginsWithTips[i]);
		gC_PluginsWithTipsLoaded[i] = LibraryExists(gokzPlugin);
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

	char gokzPlugin[PLATFORM_MAX_PATH];
	for (int i = 0; i < TIPS_PLUGINS_COUNT; i++)
	{
		FormatEx(gokzPlugin, sizeof(gokzPlugin), "gokz-%s", gC_PluginsWithTips[i]);
		gC_PluginsWithTipsLoaded[i] = gC_PluginsWithTipsLoaded[i] || StrEqual(name, gokzPlugin);
	}
}

public void OnLibraryRemoved(const char[] name)
{
	char gokzPlugin[PLATFORM_MAX_PATH];
	for (int i = 0; i < TIPS_PLUGINS_COUNT; i++)
	{
		FormatEx(gokzPlugin, sizeof(gokzPlugin), "gokz-%s", gC_PluginsWithTips[i]);
		gC_PluginsWithTipsLoaded[i] = gC_PluginsWithTipsLoaded[i] && !StrEqual(name, gokzPlugin);
	}
}



// =====[ CLIENT EVENTS ]=====

public void GOKZ_OnOptionChanged(int client, const char[] option, any newValue)
{
	OnOptionChanged_Options(client, option, newValue);
}



// =====[ OTHER EVENTS ]=====

public void OnMapStart()
{
	LoadTipPhrases();
}

public void GOKZ_OnOptionsMenuReady(TopMenu topMenu)
{
	OnOptionsMenuReady_Options();
	OnOptionsMenuReady_OptionsMenu(topMenu);
}



// =====[ CONVARS ]=====

void CreateConVars()
{
	AutoExecConfig_SetFile("gokz-tips", "sourcemod/gokz");
	AutoExecConfig_SetCreateFile(true);

	gCV_gokz_tips_interval = AutoExecConfig_CreateConVar("gokz_tips_interval", "75", "How often GOKZ tips are printed to chat in seconds.", _, true, 1.0, false);
	gCV_gokz_tips_interval.AddChangeHook(OnConVarChanged);

	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar == gCV_gokz_tips_interval)
	{
		CreateTipsTimer();
	}
}



// =====[ TIPS ]=====

void LoadTipPhrases()
{
	if (g_TipPhrases == null)
	{
		g_TipPhrases = new ArrayList(64, 0);
	}
	else
	{
		g_TipPhrases.Clear();
	}

	char tipsPath[PLATFORM_MAX_PATH];

	BuildPath(Path_SM, tipsPath, sizeof(tipsPath), "translations/%s", TIPS_TIPS);
	LoadTipPhrasesFromFile(tipsPath);

	BuildPath(Path_SM, tipsPath, sizeof(tipsPath), "translations/%s", TIPS_CORE);
	LoadTipPhrasesFromFile(tipsPath);

	// Load tips for other loaded GOKZ plugins
	for (int i = 0; i < TIPS_PLUGINS_COUNT; i++)
	{
		if (gC_PluginsWithTipsLoaded[i])
		{
			BuildPath(Path_SM, tipsPath, sizeof(tipsPath), "translations/gokz-tips-%s.phrases.txt", gC_PluginsWithTips[i]);
			LoadTipPhrasesFromFile(tipsPath);
		}
	}

	ShuffleTipPhrases();
}

void LoadTipPhrasesFromFile(const char[] filePath)
{
	KeyValues kv = new KeyValues("Phrases");
	if (!kv.ImportFromFile(filePath))
	{
		SetFailState("Failed to load file: \"%s\".", filePath);
	}

	char phraseName[64];
	kv.GotoFirstSubKey(true);
	do
	{
		kv.GetSectionName(phraseName, sizeof(phraseName));
		g_TipPhrases.PushString(phraseName);
	} while (kv.GotoNextKey(true));

	delete kv;
}

void ShuffleTipPhrases()
{
	for (int i = g_TipPhrases.Length - 1; i >= 1; i--)
	{
		int j = GetRandomInt(0, i);
		char tempStringI[64];
		g_TipPhrases.GetString(i, tempStringI, sizeof(tempStringI));
		char tempStringJ[64];
		g_TipPhrases.GetString(j, tempStringJ, sizeof(tempStringJ));
		g_TipPhrases.SetString(i, tempStringJ);
		g_TipPhrases.SetString(j, tempStringI);
	}
}

void CreateTipsTimer()
{
	if (gH_TipTimer != null)
	{
		delete gH_TipTimer;
	}
	gH_TipTimer = CreateTimer(gCV_gokz_tips_interval.FloatValue, Timer_PrintTip, _, TIMER_REPEAT);
}

public Action Timer_PrintTip(Handle timer)
{
	char tip[256];
	g_TipPhrases.GetString(gI_CurrentTip, tip, sizeof(tip));

	for (int client = 1; client <= MaxClients; client++)
	{
		KZPlayer player = KZPlayer(client);
		if (player.InGame && player.Tips != Tips_Disabled)
		{
			GOKZ_PrintToChat(client, true, "%t", tip);
		}
	}

	gI_CurrentTip = NextIndex(gI_CurrentTip, g_TipPhrases.Length);
	return Plugin_Continue;
}



// =====[ OPTIONS ]=====

void OnOptionsMenuReady_Options()
{
	RegisterOption();
}

void RegisterOption()
{
	GOKZ_RegisterOption(TIPS_OPTION_NAME, TIPS_OPTION_DESCRIPTION, 
		OptionType_Int, Tips_Enabled, 0, TIPS_COUNT - 1);
}

void OnOptionChanged_Options(int client, const char[] option, any newValue)
{
	if (StrEqual(option, TIPS_OPTION_NAME))
	{
		switch (newValue)
		{
			case Tips_Disabled:
			{
				GOKZ_PrintToChat(client, true, "%t", "Option - Tips - Disable");
			}
			case Tips_Enabled:
			{
				GOKZ_PrintToChat(client, true, "%t", "Option - Tips - Enable");
			}
		}
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
	gTMO_ItemTips = gTM_Options.AddItem(TIPS_OPTION_NAME, TopMenuHandler_Tips, gTMO_CatGeneral);
}

public void TopMenuHandler_Tips(TopMenu topmenu, TopMenuAction action, TopMenuObject topobj_id, int param, char[] buffer, int maxlength)
{
	if (topobj_id != gTMO_ItemTips)
	{
		return;
	}

	if (action == TopMenuAction_DisplayOption)
	{
		if (GOKZ_GetOption(param, TIPS_OPTION_NAME) == Tips_Disabled)
		{
			FormatEx(buffer, maxlength, "%T - %T", 
				"Options Menu - Tips", param, 
				"Options Menu - Disabled", param);
		}
		else
		{
			FormatEx(buffer, maxlength, "%T - %T", 
				"Options Menu - Tips", param, 
				"Options Menu - Enabled", param);
		}
	}
	else if (action == TopMenuAction_SelectOption)
	{
		GOKZ_CycleOption(param, TIPS_OPTION_NAME);
		gTM_Options.Display(param, TopMenuPosition_LastCategory);
	}
}



// =====[ COMMANDS ]=====

void RegisterCommands()
{
	RegConsoleCmd("sm_tips", CommandToggleTips, "[KZ] Toggle seeing help and tips.");
}

public Action CommandToggleTips(int client, int args)
{
	if (GOKZ_GetOption(client, TIPS_OPTION_NAME) == Tips_Disabled)
	{
		GOKZ_SetOption(client, TIPS_OPTION_NAME, Tips_Enabled);
	}
	else
	{
		GOKZ_SetOption(client, TIPS_OPTION_NAME, Tips_Disabled);
	}
	return Plugin_Handled;
} 