/*
	Lets player control the replay bot.
*/


static int controllingPlayer[RP_MAX_BOTS];
static bool showReplayControls[MAXPLAYERS + 1];



// =====[ PUBLIC ]=====

void OnPlayerRunCmdPost_ReplayControls(int client, int cmdnum)
{
	if (cmdnum % 6 == 3)
	{
		UpdateReplayControlMenu(client);
	}
}

void UpdateReplayControlMenu(int client)
{
	if (!IsValidClient(client) || IsFakeClient(client))
	{
		return;
	}
	
	int botClient = GetObserverTarget(client);
	int bot = GetBotFromClient(botClient);
	if (bot == -1)
	{
		return;
	}
	
	if (!IsReplayBotControlled(bot, botClient) && !InBreather(bot))
	{
		CancelReplayControlsForBot(bot);
		controllingPlayer[bot] = client;
	}
	else if (controllingPlayer[bot] != client)
	{
		return;
	}
	
	if (showReplayControls[client] &&
		(GetClientMenu(client) == MenuSource_None ||
		 GetClientAvgLoss(client, NetFlow_Both) > EPSILON ||
		 GOKZ_HUD_GetOption(client, HUDOption_TimerText) == TimerText_TPMenu))
	{
		ShowReplayControlMenu(client, bot);
	}
}

void ShowReplayControlMenu(int client, int bot)
{
	char text[32];
	
	Menu menu = new Menu(MenuHandler_ReplayControls);
	menu.OptionFlags = MENUFLAG_NO_SOUND;
	menu.Pagination = MENU_NO_PAGINATION;
	menu.ExitButton = true;
	
	if (GOKZ_HUD_GetOption(client, HUDOption_TimerText) == TimerText_TPMenu)
	{
		menu.SetTitle("%T - %s", "Replay Controls - Title", client,
			GOKZ_FormatTime(GetPlaybackTime(bot), GOKZ_HUD_GetOption(client, HUDOption_TimerStyle) == TimerStyle_Precise));
	}
	else
	{
		menu.SetTitle("%T", "Replay Controls - Title", client);
	}
	
	if (PlaybackPaused(bot))
	{
		FormatEx(text, sizeof(text), "%T", "Replay Controls - Resume", client);
		menu.AddItem("rp_resume", text);
	}
	else
	{
		FormatEx(text, sizeof(text), "%T", "Replay Controls - Pause", client);
		menu.AddItem("rp_pause", text);
	}
	
	FormatEx(text, sizeof(text), "%T", "Replay Controls - Skip", client);
	menu.AddItem("rp_skip", text);
	
	FormatEx(text, sizeof(text), "%T", "Replay Controls - Rewind", client);
	menu.AddItem("rp_back", text);
	
	menu.AddItem("rp_spacer", "", ITEMDRAW_SPACER);
	
	FormatEx(text, sizeof(text), "%T", "Replay Controls - Freecam", client);
	menu.AddItem("rp_freecam", text);
	
	menu.Display(client, MENU_TIME_FOREVER);
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
	if (!IsValidClient(param1))
	{
		return 0;
	}
	
	switch (action)
	{
		case MenuAction_Select:
		{
			int bot = GetBotFromClient(GetObserverTarget(param1));
			if (bot == -1 || controllingPlayer[bot] != param1)
			{
				return 0;
			}
			
			char item[32];
			menu.GetItem(param2, item, sizeof(item));
			if (StrEqual(item, "rp_pause"))
			{
				PlaybackPause(bot);
				ShowReplayControlMenu(param1, bot);
			}
			if (StrEqual(item, "rp_resume"))
			{
				PlaybackResume(bot);
				ShowReplayControlMenu(param1, bot);
			}
			else if (StrEqual(item, "rp_skip"))
			{
				PlaybackSkipForward(bot);
			}
			else if (StrEqual(item, "rp_back"))
			{
				PlaybackSkipBack(bot);
			}
			else if (StrEqual(item, "rp_freecam"))
			{
				SetEntProp(param1, Prop_Send, "m_iObserverMode", 6);
			}
		}
		
		case MenuAction_Cancel:
		{
			showReplayControls[param1] = param2 != MenuCancel_Exit;
		}
		
		case MenuAction_End:
		{
			showReplayControls[param1] = false;
			delete menu;
		}
	}
	
	return 0;
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
