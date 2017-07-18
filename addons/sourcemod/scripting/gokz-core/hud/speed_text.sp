/*
	Speed Text
	
	Uses ShowHudText to show current speed somewhere on the screen.
*/



// =========================  PUBLIC  ========================= //

void UpdateSpeedText(int client)
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
		if (targetPlayer.id != -1)
		{
			SpeedTextShow(player, targetPlayer);
		}
	}
}



// =========================  LISTENERS  ========================= //

void OnPlayerRunCmd_SpeedText(int client, int tickcount)
{
	if ((tickcount + client) % 3 == 0)
	{
		UpdateSpeedText(client);
	}
}



// =========================  PRIVATE  ========================= //

static void SpeedTextShow(KZPlayer player, KZPlayer targetPlayer)
{
	if (targetPlayer.paused)
	{
		return;
	}
	
	switch (player.speedText)
	{
		case SpeedText_Bottom:
		{
			if (targetPlayer.gokzHitPerf && !targetPlayer.onGround && !targetPlayer.onLadder && !targetPlayer.noclipping)
			{
				if (IsPlayerAlive(player.id))
				{
					SetHudTextParams(-1.0, 0.75, 0.5, 3, 204, 0, 0, 1, 0.0, 0.0, 0.0);
				}
				else
				{
					SetHudTextParams(-1.0, 0.595, 0.5, 3, 204, 0, 0, 0, 0.0, 0.0, 0.0);
				}
			}
			else if (IsPlayerAlive(player.id))
			{
				SetHudTextParams(-1.0, 0.75, 0.5, 255, 255, 255, 0, 0, 0.0, 0.0, 0.0);
			}
			else
			{
				SetHudTextParams(-1.0, 0.595, 0.5, 255, 255, 255, 0, 0, 0.0, 0.0, 0.0);
			}
		}
	}
	
	if (targetPlayer.onGround || targetPlayer.onLadder || targetPlayer.noclipping)
	{
		ShowHudText(player.id, 1, 
			"%.0f", 
			RoundFloat(targetPlayer.speed * 10) / 10.0);
	}
	else
	{
		ShowHudText(player.id, 1, 
			"%.0f\n(%.0f)", 
			RoundFloat(targetPlayer.speed * 10) / 10.0, 
			RoundFloat(targetPlayer.gokzTakeoffSpeed * 10) / 10.0);
	}
} 