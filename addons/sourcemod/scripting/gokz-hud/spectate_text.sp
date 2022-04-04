/*	
	Responsible for spectator list on the HUD.
*/

#define SPECATATOR_LIST_MAX_COUNT 5

// =====[ PUBLIC ]=====

char[] FormatSpectatorTextForMenu(KZPlayer player, HUDInfo info)
{
	int specCount;
	char spectatorTextString[224];
	if (player.GetHUDOption(HUDOption_SpectatorList) >= SpectatorList_Simple)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (gI_ObserverTarget[i] == info.ID)
			{
				specCount++;
				if (player.GetHUDOption(HUDOption_SpectatorList) == SpectatorList_Advanced)
				{
					char buffer[64];
					if (specCount < SPECATATOR_LIST_MAX_COUNT)
					{
						GetClientName(i, buffer, sizeof(buffer));
						Format(spectatorTextString, sizeof(spectatorTextString), "%s\n%s", spectatorTextString, buffer);
					}
					else if (specCount == SPECATATOR_LIST_MAX_COUNT)
					{
						StrCat(spectatorTextString, sizeof(spectatorTextString), "\n...");
					}
				}
			}
		}
		if (specCount > 0)
		{			
			if (player.GetHUDOption(HUDOption_SpectatorList) == SpectatorList_Advanced)
			{
				Format(spectatorTextString, sizeof(spectatorTextString), "%t\n ", "Spectator List - Menu (Advanced)", specCount, spectatorTextString);
			}
			else
			{
				Format(spectatorTextString, sizeof(spectatorTextString), "%t\n ", "Spectator List - Menu (Simple)", specCount);
			}
		}
		else
		{
			FormatEx(spectatorTextString, sizeof(spectatorTextString), "");
		}
	}
	return spectatorTextString;
}

char[] FormatSpectatorTextForInfoPanel(KZPlayer player, KZPlayer targetPlayer)
{
	int specCount;
	char spectatorTextString[160];
	if (player.GetHUDOption(HUDOption_SpectatorList) >= SpectatorList_Simple)
	{
		// TODO: Make faster logic
		for (int i = 1; i <= MaxClients; i++)
		{
			if (gI_ObserverTarget[i] == targetPlayer.ID)
			{
				specCount++;
				if (player.GetHUDOption(HUDOption_SpectatorList) == SpectatorList_Advanced)
				{
					char buffer[64];
					if (specCount < SPECATATOR_LIST_MAX_COUNT)
					{
						GetClientName(i, buffer, sizeof(buffer));
						if (specCount == 1)
						{
							Format(spectatorTextString, sizeof(spectatorTextString), "%s", buffer);
						}
						else
						{
							Format(spectatorTextString, sizeof(spectatorTextString), "%s, %s", spectatorTextString, buffer);
						}
					}
					else if (specCount == SPECATATOR_LIST_MAX_COUNT)
					{
						Format(spectatorTextString, sizeof(spectatorTextString), " ...");
					}
				}
			}
		}
		if (specCount > 0)
		{
			if (player.GetHUDOption(HUDOption_SpectatorList) == SpectatorList_Advanced)
			{
				Format(spectatorTextString, sizeof(spectatorTextString), "%t\n", "Spectator List - Info Panel (Advanced)", specCount, spectatorTextString);
			}
			else
			{
				Format(spectatorTextString, sizeof(spectatorTextString), "%t\n", "Spectator List - Info Panel (Simple)", specCount);
			}
		}
		else
		{
			FormatEx(spectatorTextString, sizeof(spectatorTextString), "");
		}
	}
	return spectatorTextString;
}

void UpdateSpectatorList()
{
	for (int client = 1; client < MaxClients; client++)
	{
		if (IsValidClient(client) && !IsFakeClient(client))
		{
			gI_ObserverTarget[client] = GetObserverTarget(client);
		}
		else
		{
			gI_ObserverTarget[client] = -1;
		}
	}
}