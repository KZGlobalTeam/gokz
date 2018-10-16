#include <sourcemod>

#include <sdktools>

#include <gokz/core>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <updater>



public Plugin myinfo = 
{
	name = "GOKZ Jump Beam", 
	author = "DanZay", 
	description = "GOKZ Jump Beam Module", 
	version = GOKZ_VERSION, 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

#define UPDATE_URL "http://updater.gokz.org/gokz-jumpbeam.txt"

float gF_OldOrigin[MAXPLAYERS + 1][3];
bool gB_OldDucking[MAXPLAYERS + 1];



// =========================  PLUGIN  ========================= //

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("This plugin is only for CS:GO.");
	}
	RegPluginLibrary("gokz-jumpbeam");
	return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}



// =========================  CLIENT  ========================= //

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	OnPlayerRunCmd_JumpBeam(client);
	UpdateOldVariables(client);
}

static void UpdateOldVariables(int client)
{
	if (IsPlayerAlive(client))
	{
		Movement_GetOrigin(client, gF_OldOrigin[client]);
		gB_OldDucking[client] = Movement_GetDucking(client);
	}
}



// =========================  OTHER  ========================= //

public void OnMapStart()
{
	PrecacheJumpBeamModels();
}



// =========================  JUMP BEAM  ========================= //

#define JUMP_BEAM_LIFETIME 4.0

static int jumpBeam;

void PrecacheJumpBeamModels()
{
	jumpBeam = PrecacheModel("materials/sprites/laser.vmt", true);
}

void OnPlayerRunCmd_JumpBeam(int targetClient)
{
	// In this case, spectators are handled from the target 
	// client's OnPlayerRunCmd call, otherwise the jump 
	// beam will be all broken up.
	
	KZPlayer targetPlayer = new KZPlayer(targetClient);
	
	if (targetPlayer.fake || !targetPlayer.alive || targetPlayer.onGround || !targetPlayer.validJump)
	{
		return;
	}
	
	// Send to self
	SendJumpBeam(targetPlayer, targetPlayer);
	
	// Send to spectators
	for (int client = 1; client <= MaxClients; client++)
	{
		KZPlayer player = new KZPlayer(client);
		if (player.inGame && !player.alive && player.observerTarget == targetClient)
		{
			SendJumpBeam(player, targetPlayer);
		}
	}
}

static void SendJumpBeam(KZPlayer player, KZPlayer targetPlayer)
{
	if (player.jumpBeam == JumpBeam_Disabled)
	{
		return;
	}
	
	switch (player.jumpBeam)
	{
		case JumpBeam_Feet:SendFeetJumpBeam(player, targetPlayer);
		case JumpBeam_Head:SendHeadJumpBeam(player, targetPlayer);
		case JumpBeam_FeetAndHead:
		{
			SendFeetJumpBeam(player, targetPlayer);
			SendHeadJumpBeam(player, targetPlayer);
		}
		case JumpBeam_Ground:SendGroundJumpBeam(player, targetPlayer);
	}
}

static void SendFeetJumpBeam(KZPlayer player, KZPlayer targetPlayer)
{
	float origin[3], beamStart[3], beamEnd[3];
	int beamColour[4];
	targetPlayer.GetOrigin(origin);
	
	beamStart = gF_OldOrigin[targetPlayer.id];
	beamEnd = origin;
	GetJumpBeamColour(targetPlayer, beamColour);
	
	TE_SetupBeamPoints(beamStart, beamEnd, jumpBeam, 0, 0, 0, JUMP_BEAM_LIFETIME, 3.0, 3.0, 10, 0.0, beamColour, 0);
	TE_SendToClient(player.id);
}

static void SendHeadJumpBeam(KZPlayer player, KZPlayer targetPlayer)
{
	float origin[3], beamStart[3], beamEnd[3];
	int beamColour[4];
	targetPlayer.GetOrigin(origin);
	
	beamStart = gF_OldOrigin[targetPlayer.id];
	beamEnd = origin;
	if (gB_OldDucking[targetPlayer.id])
	{
		beamStart[2] = beamStart[2] + 54.0;
	}
	else
	{
		beamStart[2] = beamStart[2] + 72.0;
	}
	if (targetPlayer.ducking)
	{
		beamEnd[2] = beamEnd[2] + 54.0;
	}
	else
	{
		beamEnd[2] = beamEnd[2] + 72.0;
	}
	GetJumpBeamColour(targetPlayer, beamColour);
	
	TE_SetupBeamPoints(beamStart, beamEnd, jumpBeam, 0, 0, 0, JUMP_BEAM_LIFETIME, 3.0, 3.0, 10, 0.0, beamColour, 0);
	TE_SendToClient(player.id);
}

static void SendGroundJumpBeam(KZPlayer player, KZPlayer targetPlayer)
{
	float origin[3], takeoffOrigin[3], beamStart[3], beamEnd[3];
	int beamColour[4];
	targetPlayer.GetOrigin(origin);
	targetPlayer.GetTakeoffOrigin(takeoffOrigin);
	
	beamStart = gF_OldOrigin[targetPlayer.id];
	beamEnd = origin;
	beamStart[2] = takeoffOrigin[2] + 0.1;
	beamEnd[2] = takeoffOrigin[2] + 0.1;
	GetJumpBeamColour(targetPlayer, beamColour);
	
	TE_SetupBeamPoints(beamStart, beamEnd, jumpBeam, 0, 0, 0, JUMP_BEAM_LIFETIME, 3.0, 3.0, 10, 0.0, beamColour, 0);
	TE_SendToClient(player.id);
}

static void GetJumpBeamColour(KZPlayer targetPlayer, int colour[4])
{
	if (targetPlayer.ducking)
	{
		colour =  { 255, 0, 0, 110 }; // Red
	}
	else
	{
		colour =  { 0, 255, 0, 110 }; // Green
	}
} 