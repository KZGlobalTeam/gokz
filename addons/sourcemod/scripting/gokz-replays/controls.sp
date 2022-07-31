/*
	Lets player control the replay bot.
*/

#define ITEM_INFO_PAUSE "pause"
#define ITEM_INFO_SKIP "skip"
#define ITEM_INFO_REWIND "rewind"
#define ITEM_INFO_FREECAM "freecam"

static int controllingPlayer[RP_MAX_BOTS];
static int botTeleports[RP_MAX_BOTS];
static bool showReplayControls[MAXPLAYERS + 1];



// =====[ PUBLIC ]=====

void OnPlayerRunCmdPost_ReplayControls(int client, int cmdnum)
{
	// Let the HUD plugin takes care of this if possible.
	if (cmdnum % 6 == 3 && !gB_GOKZHUD)
	{
		UpdateReplayControlMenu(client);
	}
}

bool UpdateReplayControlMenu(int client)
{
	if (!IsValidClient(client) || IsFakeClient(client))
	{
		return false;
	}
	
	int botClient = GetObserverTarget(client);
	int bot = GetBotFromClient(botClient);
	if (bot == -1)
	{
		return false;
	}
	
	if (!IsReplayBotControlled(bot, botClient) && !InBreather(bot))
	{
		CancelReplayControlsForBot(bot);
		controllingPlayer[bot] = client;
	}
	else if (controllingPlayer[bot] != client)
	{
		return false;
	}
	
	if (showReplayControls[client] &&	
		GOKZ_HUD_GetOption(client, HUDOption_ShowControls) == ReplayControls_Enabled)
	{
		// We have to update this often if bot uses teleports.
		if (GetClientMenu(client) == MenuSource_None || 
			GOKZ_HUD_GetMenuShowing(client) && GetClientAvgLoss(client, NetFlow_Both) > EPSILON || 
			GOKZ_HUD_GetMenuShowing(client) && GOKZ_HUD_GetOption(client, HUDOption_TimerText) == TimerText_TPMenu ||
			GOKZ_HUD_GetMenuShowing(client) && PlaybackGetTeleports(bot) > 0)
		{
			botTeleports[bot] = PlaybackGetTeleports(bot);
			ShowReplayControlMenu(client, bot);
		}
		return true;
	}
	return false;
}

void ShowReplayControlMenu(int client, int bot)
{
	char text[256];
	
	Menu menu = new Menu(MenuHandler_ReplayControls);
	menu.OptionFlags = MENUFLAG_NO_SOUND;
	menu.Pagination = MENU_NO_PAGINATION;
	menu.ExitButton = true;
	if (gB_GOKZHUD)
	{
		if (GOKZ_HUD_GetOption(client, HUDOption_ShowSpectators) != ShowSpecs_Disabled &&
			GOKZ_HUD_GetOption(client, HUDOption_SpecListPosition) == SpecListPosition_TPMenu)
		{
			HUDInfo info;
			GetPlaybackState(client, info);
			GOKZ_HUD_GetMenuSpectatorText(client, info, text, sizeof(text));
		}
		if (GOKZ_HUD_GetOption(client, HUDOption_TimerText) == TimerText_TPMenu)
		{
			Format(text, sizeof(text), "%s\n%T - %s", text, "Replay Controls - Title", client,
				GOKZ_FormatTime(GetPlaybackTime(bot), GOKZ_HUD_GetOption(client, HUDOption_TimerStyle) == TimerStyle_Precise));
		}
		else
		{
			Format(text, sizeof(text), "%s%T", text, "Replay Controls - Title", client);
		}
	}
	else
	{
		Format(text, sizeof(text), "%s%T", text, "Replay Controls - Title", client);
	}


	if (botTeleports[bot] > 0)
	{
		Format(text, sizeof(text), "%s\n%T", text, "Replay Controls - Teleports", client, botTeleports[bot]);
	}

	menu.SetTitle(text);
	
	if (PlaybackPaused(bot))
	{
		FormatEx(text, sizeof(text), "%T", "Replay Controls - Resume", client);
		menu.AddItem(ITEM_INFO_PAUSE, text);
	}
	else
	{
		FormatEx(text, sizeof(text), "%T", "Replay Controls - Pause", client);
		menu.AddItem(ITEM_INFO_PAUSE, text);
	}
	
	FormatEx(text, sizeof(text), "%T", "Replay Controls - Skip", client);
	menu.AddItem(ITEM_INFO_SKIP, text);
	
	FormatEx(text, sizeof(text), "%T\n ", "Replay Controls - Rewind", client);
	menu.AddItem(ITEM_INFO_REWIND, text);
	
	FormatEx(text, sizeof(text), "%T", "Replay Controls - Freecam", client);
	menu.AddItem(ITEM_INFO_FREECAM, text);
	
	menu.Display(client, MENU_TIME_FOREVER);

	if (gB_GOKZHUD)
	{
		GOKZ_HUD_SetMenuShowing(client, true);
	}
}

void ToggleReplayControls(int client)
{
	if (showReplayControls[client])
	{
		CancelReplayControls(client);
	}
	else
	{
		showReplayControls[client] = true;
	}
}

void EnableReplayControls(int client)
{
	showReplayControls[client] = true;
}

bool IsReplayBotControlled(int bot, int botClient)
{
	return IsValidClient(controllingPlayer[bot]) &&
				(GetObserverTarget(controllingPlayer[bot]) == botClient ||
				GetEntProp(controllingPlayer[bot], Prop_Send, "m_iObserverMode") == 6);
}

int MenuHandler_ReplayControls(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if (!IsValidClient(param1))
			{
				return;
			}

			int bot = GetBotFromClient(GetObserverTarget(param1));
			if (bot == -1 || controllingPlayer[bot] != param1)
			{
				return;
			}
			
			char info[16];
			menu.GetItem(param2, info, sizeof(info));
			if (StrEqual(info, ITEM_INFO_PAUSE, false))
			{
				PlaybackTogglePause(bot);
			}
			else if (StrEqual(info, ITEM_INFO_SKIP, false))
			{
				PlaybackSkipForward(bot);
			}
			else if (StrEqual(info, ITEM_INFO_REWIND, false))
			{
				PlaybackSkipBack(bot);
			}
			else if (StrEqual(info, ITEM_INFO_FREECAM, false))
			{
				SetEntProp(param1, Prop_Send, "m_iObserverMode", 6);
			}
			GOKZ_HUD_SetMenuShowing(param1, false);
		}
		case MenuAction_Cancel:
		{
			GOKZ_HUD_SetMenuShowing(param1, false);
			if (param2 == MenuCancel_Exit)
			{
				CancelReplayControls(param1);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

void CancelReplayControls(int client)
{
	if (IsValidClient(client) && showReplayControls[client])
	{
		CancelClientMenu(client);
		showReplayControls[client] = false;
	}
}

void CancelReplayControlsForBot(int bot)
{
	CancelReplayControls(controllingPlayer[bot]);
}
