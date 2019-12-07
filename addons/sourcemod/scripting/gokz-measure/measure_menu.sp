/*
	Lets players measure the distance between two points.
	Credits to DaFox (https://forums.alliedmods.net/showthread.php?t=88830?t=88830)
*/



#define ITEM_INFO_POINT_A "a"
#define ITEM_INFO_POINT_B "b"
#define ITEM_INFO_GET_DISTANCE "get"
#define ITEM_INFO_GET_BLOCK_DISTANCE "block"

static bool measurePosSet[MAXPLAYERS + 1][2];
static float measurePos[MAXPLAYERS + 1][2][3];
static float measureNormal[MAXPLAYERS + 1][2][3];
static Handle P2PRed[MAXPLAYERS + 1];
static Handle P2PGreen[MAXPLAYERS + 1];



// =====[ PUBLIC ]=====

void DisplayMeasureMenu(int client, bool reset = true)
{
	if (reset)
	{
		MeasureResetPos(client);
	}
	
	Menu menu = new Menu(MenuHandler_Measure);
	menu.SetTitle("%T", "Measure Menu - Title", client);
	MeasureMenuAddItems(client, menu);
	menu.Display(client, MENU_TIME_FOREVER);
}



// =====[ EVENTS ]=====

public int MenuHandler_Measure(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[16];
		menu.GetItem(param2, info, sizeof(info));
		
		if (StrEqual(info, ITEM_INFO_POINT_A, false))
		{
			MeasureGetPos(param1, 0);
		}
		else if (StrEqual(info, ITEM_INFO_POINT_B, false))
		{
			MeasureGetPos(param1, 1);
		}
		else if (StrEqual(info, ITEM_INFO_GET_DISTANCE, false))
		{
			// Find Distance
			if (measurePosSet[param1][0] && measurePosSet[param1][1])
			{
				float horizontalDist = GetVectorHorizontalDistance(measurePos[param1][0], measurePos[param1][1]);
				float effectiveDist = CalcEffectiveDistance(measurePos[param1][0], measurePos[param1][1]);
				float verticalDist = measurePos[param1][1][2] - measurePos[param1][0][2];
				GOKZ_PrintToChat(param1, true, "%t", "Measure Result", horizontalDist, effectiveDist, verticalDist);
				MeasureBeam(param1, measurePos[param1][0], measurePos[param1][1], 5.0, 2.0, 200, 200, 200);
			}
			else
			{
				GOKZ_PrintToChat(param1, true, "%t", "Measure Failure (Points Not Set)");
				GOKZ_PlayErrorSound(param1);
			}
		}
		else if (StrEqual(info, ITEM_INFO_GET_BLOCK_DISTANCE, false))
		{
			float angles[3];
			MeasureGetPos(param1, 0);
			GetVectorAngles(measureNormal[param1][0], angles);
			MeasureGetPosEx(param1, 1, measurePos[param1][0], angles);
			AddVectors(measureNormal[param1][0], measureNormal[param1][1], angles);
			if (GetVectorLength(angles, true) > EPSILON || 
				FloatAbs(measureNormal[param1][0][2]) > EPSILON || 
				FloatAbs(measureNormal[param1][1][2]) > EPSILON)
			{
				GOKZ_PrintToChat(param1, true, "%t", "Measure Failure (Blocks not aligned)");
				GOKZ_PlayErrorSound(param1);
				DisplayMeasureMenu(param1, false);
				return;
			}
			GOKZ_PrintToChat(param1, true, "%t", "Block Measure Result", RoundFloat(GetVectorHorizontalDistance(measurePos[param1][0], measurePos[param1][1])));
			MeasureBeam(param1, measurePos[param1][0], measurePos[param1][1], 5.0, 2.0, 200, 200, 200);
		}
		
		DisplayMeasureMenu(param1, false);
	}
	else if (action == MenuAction_Cancel)
	{
		MeasureResetPos(param1);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}



// =====[ PRIVATE ]=====

static void MeasureMenuAddItems(int client, Menu menu)
{
	char display[32];
	
	FormatEx(display, sizeof(display), "%T", "Measure Menu - Point A", client);
	menu.AddItem(ITEM_INFO_POINT_A, display);
	FormatEx(display, sizeof(display), "%T", "Measure Menu - Point B", client);
	menu.AddItem(ITEM_INFO_POINT_B, display);
	FormatEx(display, sizeof(display), "%T\n ", "Measure Menu - Get Distance", client);
	menu.AddItem(ITEM_INFO_GET_DISTANCE, display);
	FormatEx(display, sizeof(display), "%T", "Measure Menu - Get Block Distance", client);
	menu.AddItem(ITEM_INFO_GET_BLOCK_DISTANCE, display);
}

static void MeasureGetPos(int client, int arg)
{
	float origin[3];
	float angles[3];
	
	GetClientEyePosition(client, origin);
	GetClientEyeAngles(client, angles);
	
	MeasureGetPosEx(client, arg, origin, angles);
}

static void MeasureGetPosEx(int client, int arg, float origin[3], float angles[3])
{
	Handle trace = TR_TraceRayFilterEx(origin, angles, MASK_PLAYERSOLID, RayType_Infinite, TraceFilterPlayers, client);
	
	if (!TR_DidHit(trace))
	{
		delete trace;
		GOKZ_PrintToChat(client, true, "%t", "Measure Failure (Not Aiming at Solid)");
		GOKZ_PlayErrorSound(client);
		return;
	}
	
	TR_GetEndPosition(measurePos[client][arg], trace);
	TR_GetPlaneNormal(trace, measureNormal[client][arg]);
	delete trace;
	
	if (arg == 0)
	{
		if (P2PRed[client] != null)
		{
			delete P2PRed[client];
			P2PRed[client] = null;
		}
		measurePosSet[client][0] = true;
		P2PRed[client] = CreateTimer(1.0, Timer_P2PRed, GetClientUserId(client), TIMER_REPEAT);
		P2PXBeam(client, 0);
	}
	else
	{
		if (P2PGreen[client] != null)
		{
			delete P2PGreen[client];
			P2PGreen[client] = null;
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
	TE_WriteNum("m_nModelIndex", gI_BeamModel);
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
	if (P2PRed[client] != null)
	{
		delete P2PRed[client];
		P2PRed[client] = null;
	}
	if (P2PGreen[client] != null)
	{
		delete P2PGreen[client];
		P2PGreen[client] = null;
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

// Calculates the minimum equivalent jumpstat distance to go between the two points
static float CalcEffectiveDistance(const float pointA[3], const float pointB[3])
{
	float Ax = FloatMin(pointA[0], pointB[0]);
	float Bx = FloatMax(pointA[0], pointB[0]);
	float Ay = FloatMin(pointA[1], pointB[1]);
	float By = FloatMax(pointA[1], pointB[1]);
	
	if (Bx - Ax < 32.0)
	{
		Ax = Bx;
	}
	else
	{
		Ax = Ax + 16.0;
		Bx = Bx - 16.0;
	}
	
	if (By - Ay < 32.0)
	{
		Ay = By;
	}
	else
	{
		Ay = Ay + 16.0;
		By = By - 16.0;
	}
	
	return SquareRoot(Pow(Ax - Bx, 2.0) + Pow(Ay - By, 2.0)) + 32.0;
}
