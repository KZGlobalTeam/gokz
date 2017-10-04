#include <sourcemod>

#include <gokz/core>
#undef REQUIRE_PLUGIN
#include <updater>



public Plugin myinfo = 
{
	name = "GOKZ Tips", 
	author = "DanZay", 
	description = "GOKZ Tips Module", 
	version = GOKZ_VERSION, 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

#define UPDATE_URL "http://dzy.crabdance.com/updater/gokz-tips.txt"

#define TIPS_CORE "gokz-tips-core.phrases.txt"
#define TIPS_LOCALRANKS "gokz-tips-localranks.phrases.txt"
#define TIPS_REPLAYS "gokz-tips-replays.phrases.txt"

bool gB_GOKZLocalRanks;
bool gB_GOKZReplays;
ConVar gCV_gokz_tips_interval;
ArrayList g_TipPhrases;
int gI_CurrentTip;
Handle gH_TipTimer;



// =========================  PLUGIN  ========================= //

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
	LoadTranslations("gokz-tips-core.phrases");
	LoadTranslations("gokz-tips-localranks.phrases");
	LoadTranslations("gokz-tips-replays.phrases");
	
	CreateConVars();
	
	AutoExecConfig(true, "gokz-tips", "sourcemod/gokz");
	
	CreateTipsTimer();
}

public void OnAllPluginsLoaded()
{
	gB_GOKZLocalRanks = LibraryExists("gokz-localranks");
	gB_GOKZReplays = LibraryExists("gokz-replays");
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public void OnLibraryAdded(const char[] name)
{
	gB_GOKZLocalRanks = gB_GOKZLocalRanks || StrEqual(name, "gokz-localranks");
	gB_GOKZReplays = gB_GOKZReplays || StrEqual(name, "gokz-replays");
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public void OnLibraryRemoved(const char[] name)
{
	gB_GOKZLocalRanks = gB_GOKZLocalRanks && !StrEqual(name, "gokz-localranks");
	gB_GOKZReplays = gB_GOKZReplays && !StrEqual(name, "gokz-replays");
}



// =========================  GENERAL  ========================= //

public void OnMapStart()
{
	LoadTipPhrases();
}



// =========================  PRIVATE  ========================= //

static void CreateConVars()
{
	gCV_gokz_tips_interval = CreateConVar("gokz_tips_interval", "60", "How often GOKZ tips are printed to chat.", _, true, 30.0, false);
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
	
	ShuffleTipPhrases();
}

void LoadTipPhrasesFromFile(const char[] filePath)
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
		KZPlayer player = new KZPlayer(client);
		if (player.inGame && player.helpAndTips != HelpAndTips_Disabled)
		{
			GOKZ_PrintToChat(client, true, "%t", tip);
		}
	}
	
	gI_CurrentTip = NextIndex(gI_CurrentTip, g_TipPhrases.Length);
} 