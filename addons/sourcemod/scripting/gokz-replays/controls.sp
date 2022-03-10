/*
	Lets player control the replay bot.
*/


static int controllingPlayer[RP_MAX_BOTS];
static int botTeleports[RP_MAX_BOTS];
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
		GOKZ_HUD_GetOption(client, HUDOption_ShowControls) == ReplayControls_Enabled &&
		(GetClientMenu(client) == MenuSource_None ||
		 GetClientAvgLoss(client, NetFlow_Both) > EPSILON || 
		 GOKZ_HUD_GetOption(client, HUDOption_TimerText) == TimerText_TPMenu))
	{
		botTeleports[bot] = PlaybackGetTeleports(bot);
		ShowReplayControlMenu(client, bot);
	}
}

void ShowReplayControlMenu(int client, int bot)
{
	char text[32];
	
	Panel panel = new Panel();
	
	if (GOKZ_HUD_GetOption(client, HUDOption_TimerText) == TimerText_TPMenu)
	{
		FormatEx(text, sizeof(text), "%T - %s", "Replay Controls - Title", client,
			GOKZ_FormatTime(GetPlaybackTime(bot), GOKZ_HUD_GetOption(client, HUDOption_TimerStyle) == TimerStyle_Precise));
		panel.SetTitle(text);
	}
	else
	{
		FormatEx(text, sizeof(text), "%T", "Replay Controls - Title", client);
		panel.SetTitle(text);
	}

	if(PlaybackGetTeleports(bot) > 0)
	{
		FormatEx(text, sizeof(text), "%T", "Replay Controls - Teleports", client, botTeleports[bot]);
		panel.DrawItem(text, ITEMDRAW_RAWLINE);
	}
	
	if (PlaybackPaused(bot))
	{
		FormatEx(text, sizeof(text), "%T", "Replay Controls - Resume", client);
		panel.DrawItem(text);
	}
	else
	{
		FormatEx(text, sizeof(text), "%T", "Replay Controls - Pause", client);
		panel.DrawItem(text);
	}
	
	FormatEx(text, sizeof(text), "%T", "Replay Controls - Skip", client);
	panel.DrawItem(text);
	
	FormatEx(text, sizeof(text), "%T", "Replay Controls - Rewind", client);
	panel.DrawItem(text);
	
	panel.DrawItem("", ITEMDRAW_SPACER);
	
	FormatEx(text, sizeof(text), "%T", "Replay Controls - Freecam", client);
	panel.DrawItem(text);

	panel.DrawItem("", ITEMDRAW_SPACER);

	FormatEx(text, sizeof(text), "%T", "Replay Controls - Exit", client);
	panel.DrawItem(text);
	
	panel.Send(client, PanelHandler_ReplayControls, MENU_TIME_FOREVER);
	delete panel;
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

int PanelHandler_ReplayControls(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if (!IsValidClient(param1))
			{
				return 0;
			}

			int bot = GetBotFromClient(GetObserverTarget(param1));
			if (bot == -1 || controllingPlayer[bot] != param1)
			{
				return 0;
			}
			
			// Pause/Resume
			if (param2 == 1)
			{
				PlaybackTogglePause(bot);
				ShowReplayControlMenu(param1, bot);
			}
			// Forward
			else if (param2 == 2)
			{
				PlaybackSkipForward(bot);
			}
			// Rewind
			else if (param2 == 3)
			{
				PlaybackSkipBack(bot);
			}
			// Freecam
			else if (param2 == 4)
			{
				SetEntProp(param1, Prop_Send, "m_iObserverMode", 6);
			}
			// Exit
			else if (param2 == 7)
			{
				CancelReplayControls(param1);
				delete menu;
			}
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
