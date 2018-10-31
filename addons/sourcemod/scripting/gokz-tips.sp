#include <sourcemod>

#include <gokz/core>

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
	LoadTranslations(TIPS_CORE);
	LoadTranslations(TIPS_LOCALRANKS);
	LoadTranslations(TIPS_REPLAYS);
	LoadTranslations(TIPS_JUMPSTATS);
	
	CreateConVars();
	
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



// =========================  GENERAL  ========================= //

public void OnMapStart()
{
	LoadTipPhrases();
}



// =========================  TIPS TIMER  ========================= //

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
		if (player.inGame && player.helpAndTips != HelpAndTips_Disabled)
		{
			GOKZ_PrintToChat(client, true, "%t", tip);
		}
	}
	
	gI_CurrentTip = NextIndex(gI_CurrentTip, g_TipPhrases.Length);
}



// =========================  PRIVATE  ========================= //

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