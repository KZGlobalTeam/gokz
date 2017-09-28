/*
	Speed Text
	
	Uses ShowSyncHudText to show current speed somewhere on the screen.
	
	This is updated every ~0.1s and whenever player has taken off 
	so that they get to see updated pre-speed as soon as possible.
*/



static Handle speedHudSynchronizer;



// =========================  PUBLIC  ========================= //

void CreateHudSynchronizerSpeedText()
{
	speedHudSynchronizer = CreateHudSynchronizer();
}



// =========================  LISTENERS  ========================= //

void OnPlayerRunCmd_SpeedText(int client, int cmdnum)
{
	if (cmdnum % 12 == 0 || Movement_GetTakeoffCmdNum(client) == cmdnum - 1)
	{
		UpdateSpeedText(client);
	}
}

void OnOptionChanged_SpeedText(int client, Option option)
{
	if (option == Option_SpeedText)
	{
		ClearSpeedText(client);
		UpdateSpeedText(client);
	}
}



// =========================  PRIVATE  ========================= //

static void UpdateSpeedText(int client)
{
	KZPlayer player = new KZPlayer(client);
	
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
		KZPlayer targetPlayer = new KZPlayer(player.observerTarget);
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
		colour =  { 3, 204, 0, 0 };
	}
	else
	{
		colour =  { 235, 235, 235, 0 };
	}
	
	switch (player.speedText)
	{
		case SpeedText_Bottom:
		{
			if (IsPlayerAlive(player.id))
			{
				SetHudTextParams(-1.0, 0.75, 2.5, colour[0], colour[1], colour[2], colour[3], 0, 0.0, 0.0, 0.0);
			}
			else
			{
				SetHudTextParams(-1.0, 0.595, 2.5, colour[0], colour[1], colour[2], colour[3], 0, 0.0, 0.0, 0.0);
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