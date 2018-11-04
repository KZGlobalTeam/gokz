#include <sourcemod>

#include <gokz/core>
#include <gokz/tips>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <updater>

#include <gokz/methodmap>



public Plugin myinfo = 
{
	name = "GOKZ Tips", 
	author = "DanZay", 
	description = "GOKZ Tips Module", 
	version = GOKZ_VERSION, 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

#define UPDATE_URL "http://updater.gokz.org/gokz-tips.txt"

#define TIPS_CORE "gokz-tips-core.phrases.txt"
#define TIPS_LOCALRANKS "gokz-tips-localranks.phrases.txt"
#define TIPS_REPLAYS "gokz-tips-replays.phrases.txt"
#define TIPS_JUMPSTATS "gokz-tips-jumpstats.phrases.txt"

bool gB_GOKZLocalRanks;
bool gB_GOKZReplays;
bool gB_GOKZJumpstats;
ConVar gCV_gokz_tips_interval;
ArrayList g_TipPhrases;
int gI_CurrentTip;
Handle gH_TipTimer;
TopMenu gTM_Options;
TopMenuObject gTMO_CatGeneral;
TopMenuObject gTMO_ItemTips;



// =====[ PLUGIN EVENTS ]=====

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("This plugin is only for CS:GO.");
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("gokz-common.phrases");
	LoadTranslations("gokz-tips.phrases");
	LoadTranslations(TIPS_CORE);
	LoadTranslations(TIPS_LOCALRANKS);
	LoadTranslations(TIPS_REPLAYS);
	LoadTranslations(TIPS_JUMPSTATS);
	
	CreateConVars();
	CreateCommands();
	
	AutoExecConfig(true, "gokz-tips", "sourcemod/gokz");
	
	CreateTipsTimer();
}

public void OnAllPluginsLoaded()
{
	gB_GOKZLocalRanks = LibraryExists("gokz-localranks");
	gB_GOKZReplays = LibraryExists("gokz-replays");
	gB_GOKZJumpstats = LibraryExists("gokz-jumpstats");
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	
	OnAllPluginsLoaded_Options();
	OnAllPluginsLoaded_OptionsMenu();
}

public void OnLibraryAdded(const char[] name)
{
	gB_GOKZLocalRanks = gB_GOKZLocalRanks || StrEqual(name, "gokz-localranks");
	gB_GOKZReplays = gB_GOKZReplays || StrEqual(name, "gokz-replays");
	gB_GOKZJumpstats = gB_GOKZJumpstats || StrEqual(name, "gokz-jumpstats");
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public void OnLibraryRemoved(const char[] name)
{
	gB_GOKZLocalRanks = gB_GOKZLocalRanks && !StrEqual(name, "gokz-localranks");
	gB_GOKZReplays = gB_GOKZReplays && !StrEqual(name, "gokz-replays");
	gB_GOKZJumpstats = gB_GOKZJumpstats && !StrEqual(name, "gokz-jumpstats");
}



// =====[ OTHER EVENTS ]=====

public void OnMapStart()
{
	LoadTipPhrases();
}

public void GOKZ_OnOptionsMenuReady(TopMenu topMenu)
{
	OnOptionsMenuReady_OptionsMenu(topMenu);
}

public void GOKZ_OnOptionChanged(int client, const char[] option, any newValue)
{
	OnOptionChanged_Options(client, option, newValue);
}



// =====[ TIPS TIMER ]=====

static void CreateTipsTimer()
{
	if (gH_TipTimer != null)
	{
		gH_TipTimer.Close();
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
		if (player.inGame && player.tips != Tips_Disabled)
		{
			GOKZ_PrintToChat(client, true, "%t", tip);
		}
	}
	
	gI_CurrentTip = NextIndex(gI_CurrentTip, g_TipPhrases.Length);
}



// =====[ OPTIONS ]=====

void OnAllPluginsLoaded_Options()
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

void OnAllPluginsLoaded_OptionsMenu()
{
	// Handle late loading
	TopMenu topMenu;
	if (LibraryExists("gokz-core") && ((topMenu = GOKZ_GetOptionsTopMenu()) != null))
	{
		GOKZ_OnOptionsMenuReady(topMenu);
	}
}

void OnOptionsMenuReady_OptionsMenu(TopMenu topMenu)
{
	if (gTM_Options == topMenu)
	{
		return;
	}
	
	gTM_Options = topMenu;
	gTMO_CatGeneral = gTM_Options.FindCategory(OPTIONS_MENU_CAT_GENERAL);
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

void CreateCommands()
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



// =====[ PRIVATE ]=====

static void CreateConVars()
{
	gCV_gokz_tips_interval = CreateConVar("gokz_tips_interval", "75", "How often GOKZ tips are printed to chat in seconds.", _, true, 5.0, false);
	gCV_gokz_tips_interval.AddChangeHook(OnConVarChanged);
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar == gCV_gokz_tips_interval)
	{
		CreateTipsTimer();
	}
}

static void LoadTipPhrases()
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
	
	BuildPath(Path_SM, tipsPath, sizeof(tipsPath), "translations/%s", TIPS_CORE);
	LoadTipPhrasesFromFile(tipsPath);
	
	if (gB_GOKZLocalRanks)
	{
		BuildPath(Path_SM, tipsPath, sizeof(tipsPath), "translations/%s", TIPS_LOCALRANKS);
		LoadTipPhrasesFromFile(tipsPath);
	}
	
	if (gB_GOKZReplays)
	{
		BuildPath(Path_SM, tipsPath, sizeof(tipsPath), "translations/%s", TIPS_REPLAYS);
		LoadTipPhrasesFromFile(tipsPath);
	}
	
	if (gB_GOKZJumpstats)
	{
		BuildPath(Path_SM, tipsPath, sizeof(tipsPath), "translations/%s", TIPS_JUMPSTATS);
		LoadTipPhrasesFromFile(tipsPath);
	}
	
	ShuffleTipPhrases();
}

static void LoadTipPhrasesFromFile(const char[] filePath)
{
	KeyValues kv = new KeyValues("Phrases");
	if (!kv.ImportFromFile(filePath))
	{
		SetFailState("Couldn't load file: %s", filePath);
	}
	
	char phraseName[64];
	kv.GotoFirstSubKey(true);
	do
	{
		kv.GetSectionName(phraseName, sizeof(phraseName));
		g_TipPhrases.PushString(phraseName);
	} while (kv.GotoNextKey(true));
}

static void ShuffleTipPhrases()
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