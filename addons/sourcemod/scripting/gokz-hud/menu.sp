/*
	Tracks whether a GOKZ HUD menu or panel element is being shown to the client.
*/



// Update the TP menu i.e. item text, item disabled/enabled
void CancelGOKZHUDMenu(int client)
{
	// Only cancel the menu if we know it's the TP menu
	if (gB_MenuShowing[client])
	{
		CancelClientMenu(client);
	}
}



// =====[ EVENTS ]=====

void OnPlayerSpawn_Menu(int client)
{
	CancelGOKZHUDMenu(client);
}

void OnOptionChanged_Menu(int client, HUDOption option)
{
	if (option == HUDOption_TPMenu || option == HUDOption_TimerText)
	{
		CancelGOKZHUDMenu(client);
	}
}

void OnTimerStart_Menu(int client)
{
	// Prevent the menu from getting cancelled every tick if player use start timer button zone.
	if (GOKZ_GetTime(client) > 0.0)
	{
		CancelGOKZHUDMenu(client);
	}
}

void OnTimerEnd_Menu(int client)
{
	CancelGOKZHUDMenu(client);
}

void OnTimerStopped_Menu(int client)
{
	CancelGOKZHUDMenu(client);
}

void OnPause_Menu(int client)
{
	CancelGOKZHUDMenu(client);
}

void OnResume_Menu(int client)
{
	CancelGOKZHUDMenu(client);
}

void OnMakeCheckpoint_Menu(int client)
{
	CancelGOKZHUDMenu(client);
}

void OnCountedTeleport_Menu(int client)
{
	CancelGOKZHUDMenu(client);
}

void OnJoinTeam_Menu(int client)
{
	CancelGOKZHUDMenu(client);
}

void OnStartPositionSet_Menu(int client)
{
	// Prevent the menu from getting cancelled every tick if player use start timer button zone.
	if (GOKZ_GetTime(client) > 0.0)
	{
		CancelGOKZHUDMenu(client);
	}
}

void OnPluginEnd_Menu()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			CancelGOKZHUDMenu(client);
		}
	}
}