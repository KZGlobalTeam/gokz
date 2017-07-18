/*
	Measure Menu
	
	Lets players measure the distance between two points.
	
	Credits to DaFox (https://forums.alliedmods.net/showthread.php?t=88830?t=88830)
*/



static Menu measureMenu[MAXPLAYERS + 1];
static int glowSprite;
static bool measurePosSet[MAXPLAYERS + 1][2];
static float measurePos[MAXPLAYERS + 1][2][3];
static Handle P2PRed[MAXPLAYERS + 1];
static Handle P2PGreen[MAXPLAYERS + 1];



// =========================  PUBLIC  ========================= //

void CreateMenusMeasure()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		measureMenu[client] = new Menu(MenuHandler_Measure);
	}
}

void DisplayMeasureMenu(int client)
{
	MeasureResetPos(client);
	MeasureMenuUpdate(client, measureMenu[client]);
	measureMenu[client].Display(client, MENU_TIME_FOREVER);
}



// =========================  LISTENERS  ========================= //

void OnMapStart_Measure()
{
	glowSprite = PrecacheModel("materials/sprites/bluelaser1.vmt", true);
}



// =========================  HANDLER  ========================= //

public int MenuHandler_Measure(Handle menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 0: // Point A (Green)
			{
				MeasureGetPos(param1, 0);
			}
			case 1: // Point B (Red)
			{
				MeasureGetPos(param1, 1);
			}
			case 2:
			{  // Find Distance
				if (measurePosSet[param1][0] && measurePosSet[param1][1])
				{
					float horizontalDist = GetVectorHorizontalDistance(measurePos[param1][0], measurePos[param1][1]);
					float verticalDist = measurePos[param1][1][2] - measurePos[param1][0][2];
					GOKZ_PrintToChat(param1, true, "%t", "Measure Result", horizontalDist, verticalDist);
					MeasureBeam(param1, measurePos[param1][0], measurePos[param1][1], 5.0, 2.0, 200, 200, 200);
				}
				else
				{
					GOKZ_PrintToChat(param1, true, "%t", "Measure Failure (Points Not Set)");
					PlayErrorSound(param1);
				}
			}
		}
		DisplayMenu(measureMenu[param1], param1, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_Cancel)
	{
		MeasureResetPos(param1);
	}
}



// =========================  PRIVATE  ========================= //

static void MeasureMenuUpdate(int client, Menu menu)
{
	menu.SetTitle("%T", "Measure Menu - Title", client);
	
	char temp[32];
	menu.RemoveAllItems();
	FormatEx(temp, sizeof(temp), "%T", "Measure Menu - Point A", client);
	menu.AddItem("", temp);
	FormatEx(temp, sizeof(temp), "%T", "Measure Menu - Point B", client);
	menu.AddItem("", temp);
	FormatEx(temp, sizeof(temp), "%T", "Measure Menu - Get Distance", client);
	menu.AddItem("", temp);
}

static void MeasureGetPos(int client, int arg)
{
	float origin[3];
	float angles[3];
	
	GetClientEyePosition(client, origin);
	GetClientEyeAngles(client, angles);
	
	Handle trace = TR_TraceRayFilterEx(origin, angles, MASK_SHOT, RayType_Infinite, TraceFilterPlayers, client);
	
	if (!TR_DidHit(trace))
	{
		CloseHandle(trace);
		GOKZ_PrintToChat(client, true, "%t", "Measure Failure (Not Aiming at Solid)");
		PlayErrorSound(client);
		return;
	}
	
	TR_GetEndPosition(origin, trace);
	CloseHandle(trace);
	
	measurePos[client][arg][0] = origin[0];
	measurePos[client][arg][1] = origin[1];
	measurePos[client][arg][2] = origin[2];
	
	if (arg == 0)
	{
		if (P2PRed[client] != INVALID_HANDLE)
		{
			CloseHandle(P2PRed[client]);
			P2PRed[client] = INVALID_HANDLE;
		}
		measurePosSet[client][0] = true;
		P2PRed[client] = CreateTimer(1.0, Timer_P2PRed, GetClientUserId(client), TIMER_REPEAT);
		P2PXBeam(client, 0);
	}
	else
	{
		if (P2PGreen[client] != INVALID_HANDLE)
		{
			CloseHandle(P2PGreen[client]);
			P2PGreen[client] = INVALID_HANDLE;
		}
		measurePosSet[client][1] = true;
		P2PXBeam(client, 1);
		P2PGreen[client] = CreateTimer(1.0, Timer_P2PGreen, GetClientUserId(client), TIMER_REPEAT);
	}
}

public bool TraceFilterPlayers(int entity, int contentsMask)
{
	return (entity > MaxClients);
}

public Action Timer_P2PRed(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (IsValidClient(client))
	{
		P2PXBeam(client, 0);
	}
}

public Action Timer_P2PGreen(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (IsValidClient(client))
	{
		P2PXBeam(client, 1);
	}
}

static void MeasureBeam(int client, float vecStart[3], float vecEnd[3], float life, float width, int r, int g, int b)
{
	TE_Start("BeamPoints");
	TE_WriteNum("m_nModelIndex", glowSprite);
	TE_WriteNum("m_nHaloIndex", 0);
	TE_WriteNum("m_nStartFrame", 0);
	TE_WriteNum("m_nFrameRate", 0);
	TE_WriteFloat("m_fLife", life);
	TE_WriteFloat("m_fWidth", width);
	TE_WriteFloat("m_fEndWidth", width);
	TE_WriteNum("m_nFadeLength", 0);
	TE_WriteFloat("m_fAmplitude", 0.0);
	TE_WriteNum("m_nSpeed", 0);
	TE_WriteNum("r", r);
	TE_WriteNum("g", g);
	TE_WriteNum("b", b);
	TE_WriteNum("a", 255);
	TE_WriteNum("m_nFlags", 0);
	TE_WriteVector("m_vecStartPoint", vecStart);
	TE_WriteVector("m_vecEndPoint", vecEnd);
	TE_SendToClient(client);
}

static void MeasureResetPos(int client)
{
	if (P2PRed[client] != INVALID_HANDLE)
	{
		CloseHandle(P2PRed[client]);
		P2PRed[client] = INVALID_HANDLE;
	}
	if (P2PGreen[client] != INVALID_HANDLE)
	{
		CloseHandle(P2PGreen[client]);
		P2PGreen[client] = INVALID_HANDLE;
	}
	measurePosSet[client][0] = false;
	measurePosSet[client][1] = false;
	
	measurePos[client][0][0] = 0.0; // This is stupid.
	measurePos[client][0][1] = 0.0;
	measurePos[client][0][2] = 0.0;
	measurePos[client][1][0] = 0.0;
	measurePos[client][1][1] = 0.0;
	measurePos[client][1][2] = 0.0;
}

static void P2PXBeam(int client, int arg)
{
	float Origin0[3];
	float Origin1[3];
	float Origin2[3];
	float Origin3[3];
	
	Origin0[0] = (measurePos[client][arg][0] + 8.0);
	Origin0[1] = (measurePos[client][arg][1] + 8.0);
	Origin0[2] = measurePos[client][arg][2];
	
	Origin1[0] = (measurePos[client][arg][0] - 8.0);
	Origin1[1] = (measurePos[client][arg][1] - 8.0);
	Origin1[2] = measurePos[client][arg][2];
	
	Origin2[0] = (measurePos[client][arg][0] + 8.0);
	Origin2[1] = (measurePos[client][arg][1] - 8.0);
	Origin2[2] = measurePos[client][arg][2];
	
	Origin3[0] = (measurePos[client][arg][0] - 8.0);
	Origin3[1] = (measurePos[client][arg][1] + 8.0);
	Origin3[2] = measurePos[client][arg][2];
	
	if (arg == 0)
	{
		MeasureBeam(client, Origin0, Origin1, 0.97, 2.0, 0, 255, 0);
		MeasureBeam(client, Origin2, Origin3, 0.97, 2.0, 0, 255, 0);
	}
	else
	{
		MeasureBeam(client, Origin0, Origin1, 0.97, 2.0, 255, 0, 0);
		MeasureBeam(client, Origin2, Origin3, 0.97, 2.0, 255, 0, 0);
	}
} 