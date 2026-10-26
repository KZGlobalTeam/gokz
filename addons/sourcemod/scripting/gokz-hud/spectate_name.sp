/*
	Keeps the game's spectator panel showing the spectated player's current name and clan tag.
*/

static char lastName[MAXPLAYERS + 1][MAX_NAME_LENGTH];
static char lastClanTag[MAXPLAYERS + 1][32];
static bool nameChanged[MAXPLAYERS + 1];



// =====[ EVENTS ]=====

void OnGameFrame_SpectateName()
{
	for (int target = 1; target <= MaxClients; target++)
	{
		// A check later, so the new name or tag has reached the spectators first
		if (nameChanged[target])
		{
			nameChanged[target] = false;
			RefreshSpectators(target);
		}

		char name[MAX_NAME_LENGTH], clanTag[32];
		if (IsClientInGame(target))
		{
			GetClientName(target, name, sizeof(name));
			CS_GetClientClanTag(target, clanTag, sizeof(clanTag));
		}
		if (!StrEqual(name, lastName[target]) || !StrEqual(clanTag, lastClanTag[target]))
		{
			nameChanged[target] = true;
			strcopy(lastName[target], sizeof(lastName[]), name);
			strcopy(lastClanTag[target], sizeof(lastClanTag[]), clanTag);
		}
	}
}



// =====[ PRIVATE ]=====

// The panel only redraws the name when the spectated entity changes
static void RefreshSpectators(int target)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (gI_ObserverTarget[client] == target)
		{
			Event event = CreateEvent("spec_target_updated", true);
			event.SetInt("userid", GetClientUserId(client));
			event.FireToClient(client);
			event.Cancel();
		}
	}
}
