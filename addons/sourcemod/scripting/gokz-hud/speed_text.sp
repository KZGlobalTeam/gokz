/*
	Speed Text
	
	Uses ShowSyncHudText to show current speed somewhere on the screen.
	
	This is updated every ~0.1s and whenever player has taken off 
	so that they get to see updated pre-speed as soon as possible.
*/



static Handle speedHudSynchronizer;



// =====[ EVENTS ]=====

void OnPluginStart_SpeedText()
{
	speedHudSynchronizer = CreateHudSynchronizer();
}

void OnPlayerRunCmdPost_SpeedText(int client, int cmdnum)
{
	if (cmdnum % 6 == 0 || Movement_GetTakeoffCmdNum(client) == cmdnum - 1)
	{
		UpdateSpeedText(client);
	}
}

void OnOptionChanged_SpeedText(int client, HUDOption option)
{
	if (option == HUDOption_SpeedText)
	{
		ClearSpeedText(client);
		UpdateSpeedText(client);
	}
}



// =====[ PRIVATE ]=====

static void UpdateSpeedText(int client)
{
	KZPlayer player = KZPlayer(client);
	
	if (player.fake
		 || player.speedText != SpeedText_Bottom)
	{
		return;
	}
	
	if (player.alive)
	{
		SpeedTextShow(player, player);
	}
	else
	{
		KZPlayer targetPlayer = KZPlayer(player.observerTarget);
		if (targetPlayer.id != -1 && !targetPlayer.fake)
		{
			SpeedTextShow(player, targetPlayer);
		}
	}
}

static void ClearSpeedText(int client)
{
	ClearSyncHud(client, speedHudSynchronizer);
}

static void SpeedTextShow(KZPlayer player, KZPlayer targetPlayer)
{
	if (targetPlayer.paused)
	{
		return;
	}
	
	int colour[4]; // RGBA
	if (targetPlayer.gokzHitPerf && !targetPlayer.onGround && !targetPlayer.onLadder && !targetPlayer.noclipping)
	{
		colour =  { 64, 255, 64, 0 };
	}
	else
	{
		colour =  { 255, 255, 255, 0 };
	}
	
	switch (player.speedText)
	{
		case SpeedText_Bottom:
		{
			// Set params based on the available screen space at max scaling HUD
			if (!IsDrawingInfoPanel(player.id))
			{
				SetHudTextParams(-1.0, 0.75, 1.0, colour[0], colour[1], colour[2], colour[3], 0, 1.0, 0.0, 0.0);
			}
			else
			{
				SetHudTextParams(-1.0, 0.65, 1.0, colour[0], colour[1], colour[2], colour[3], 0, 1.0, 0.0, 0.0);
			}
		}
	}
	
	if (targetPlayer.onGround || targetPlayer.onLadder || targetPlayer.noclipping)
	{
		ShowSyncHudText(player.id, speedHudSynchronizer, 
			"%.0f", 
			RoundFloat(targetPlayer.speed * 10) / 10.0);
	}
	else
	{
		ShowSyncHudText(player.id, speedHudSynchronizer, 
			"%.0f\n(%.0f)", 
			RoundFloat(targetPlayer.speed * 10) / 10.0, 
			RoundFloat(targetPlayer.gokzTakeoffSpeed * 10) / 10.0);
	}
} 