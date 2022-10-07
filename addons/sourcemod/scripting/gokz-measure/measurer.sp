// =====[ PUBLIC ]=====

void MeasureGetPos(int client, int arg)
{
	float origin[3];
	float angles[3];
	
	GetClientEyePosition(client, origin);
	GetClientEyeAngles(client, angles);
	
	MeasureGetPosEx(client, arg, origin, angles);
}

void MeasureResetPos(int client)
{
	delete gH_P2PRed[client];
	delete gH_P2PGreen[client];

	gB_MeasurePosSet[client][0] = false;
	gB_MeasurePosSet[client][1] = false;
	
	gF_MeasurePos[client][0][0] = 0.0; // This is stupid.
	gF_MeasurePos[client][0][1] = 0.0;
	gF_MeasurePos[client][0][2] = 0.0;
	gF_MeasurePos[client][1][0] = 0.0;
	gF_MeasurePos[client][1][1] = 0.0;
	gF_MeasurePos[client][1][2] = 0.0;
}

bool MeasureBlock(int client)
{
	float angles[3];
	MeasureGetPos(client, 0);
	GetVectorAngles(gF_MeasureNormal[client][0], angles);
	MeasureGetPosEx(client, 1, gF_MeasurePos[client][0], angles);
	AddVectors(gF_MeasureNormal[client][0], gF_MeasureNormal[client][1], angles);
	if (GetVectorLength(angles, true) > EPSILON || 
		FloatAbs(gF_MeasureNormal[client][0][2]) > EPSILON || 
		FloatAbs(gF_MeasureNormal[client][1][2]) > EPSILON)
	{
		GOKZ_PrintToChat(client, true, "%t", "Measure Failure (Blocks not aligned)");
		GOKZ_PlayErrorSound(client);
		return false;
	}
	GOKZ_PrintToChat(client, true, "%t", "Block Measure Result", RoundFloat(GetVectorHorizontalDistance(gF_MeasurePos[client][0], gF_MeasurePos[client][1])));
	MeasureBeam(client, gF_MeasurePos[client][0], gF_MeasurePos[client][1], 5.0, 0.2, 200, 200, 200);
	return true;
}

bool MeasureDistance(int client, float minDistToMeasureBlock = -1.0)
{
	// Find Distance
	if (gB_MeasurePosSet[client][0] && gB_MeasurePosSet[client][1])
	{
		float horizontalDist = GetVectorHorizontalDistance(gF_MeasurePos[client][0], gF_MeasurePos[client][1]);
		float effectiveDist = CalcEffectiveDistance(gF_MeasurePos[client][0], gF_MeasurePos[client][1]);
		float verticalDist = gF_MeasurePos[client][1][2] - gF_MeasurePos[client][0][2];
		if (minDistToMeasureBlock >= 0.0 && (horizontalDist <= minDistToMeasureBlock && verticalDist <= minDistToMeasureBlock))
		{
			return MeasureBlock(client);
		}
		else
		{
			GOKZ_PrintToChat(client, true, "%t", "Measure Result", horizontalDist, effectiveDist, verticalDist);
			MeasureBeam(client, gF_MeasurePos[client][0], gF_MeasurePos[client][1], 5.0, 0.2, 200, 200, 200);
		}
		return true;
	}
	else
	{
		GOKZ_PrintToChat(client, true, "%t", "Measure Failure (Points Not Set)");
		GOKZ_PlayErrorSound(client);
		return false;
	}
}

// =====[ TIMERS ]=====

public Action Timer_P2PRed(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (IsValidClient(client))
	{
		P2PXBeam(client, 0);
	}
	return Plugin_Continue;
}

public Action Timer_P2PGreen(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (IsValidClient(client))
	{
		P2PXBeam(client, 1);
	}
	return Plugin_Continue;
}

public Action Timer_DeletePoints(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (!gB_Measuring[client])
	{
		MeasureResetPos(client);
	}
	return Plugin_Continue;
}


// =====[ PRIVATES ]=====
static void P2PXBeam(int client, int arg)
{
	float Origin0[3];
	float Origin1[3];
	float Origin2[3];
	float Origin3[3];
	
	Origin0[0] = (gF_MeasurePos[client][arg][0] + 8.0);
	Origin0[1] = (gF_MeasurePos[client][arg][1] + 8.0);
	Origin0[2] = gF_MeasurePos[client][arg][2];
	
	Origin1[0] = (gF_MeasurePos[client][arg][0] - 8.0);
	Origin1[1] = (gF_MeasurePos[client][arg][1] - 8.0);
	Origin1[2] = gF_MeasurePos[client][arg][2];
	
	Origin2[0] = (gF_MeasurePos[client][arg][0] + 8.0);
	Origin2[1] = (gF_MeasurePos[client][arg][1] - 8.0);
	Origin2[2] = gF_MeasurePos[client][arg][2];
	
	Origin3[0] = (gF_MeasurePos[client][arg][0] - 8.0);
	Origin3[1] = (gF_MeasurePos[client][arg][1] + 8.0);
	Origin3[2] = gF_MeasurePos[client][arg][2];
	
	if (arg == 0)
	{
		MeasureBeam(client, Origin0, Origin1, 0.97, 0.2, 0, 255, 0);
		MeasureBeam(client, Origin2, Origin3, 0.97, 0.2, 0, 255, 0);
	}
	else
	{
		MeasureBeam(client, Origin0, Origin1, 0.97, 0.2, 255, 0, 0);
		MeasureBeam(client, Origin2, Origin3, 0.97, 0.2, 255, 0, 0);
	}
}

static void MeasureGetPosEx(int client, int arg, float origin[3], float angles[3])
{
	Handle trace = TR_TraceRayFilterEx(origin, angles, MASK_PLAYERSOLID, RayType_Infinite, TraceEntityFilterPlayers, client);
	
	if (!TR_DidHit(trace))
	{
		delete trace;
		GOKZ_PrintToChat(client, true, "%t", "Measure Failure (Not Aiming at Solid)");
		GOKZ_PlayErrorSound(client);
		return;
	}
	
	TR_GetEndPosition(gF_MeasurePos[client][arg], trace);
	TR_GetPlaneNormal(trace, gF_MeasureNormal[client][arg]);
	delete trace;
	
	if (arg == 0)
	{
		delete gH_P2PRed[client];
		gB_MeasurePosSet[client][0] = true;
		gH_P2PRed[client] = CreateTimer(1.0, Timer_P2PRed, GetClientUserId(client), TIMER_REPEAT);
		P2PXBeam(client, 0);
	}
	else
	{
		delete gH_P2PGreen[client];
		gH_P2PGreen[client] = null;
		gB_MeasurePosSet[client][1] = true;
		P2PXBeam(client, 1);
		gH_P2PGreen[client] = CreateTimer(1.0, Timer_P2PGreen, GetClientUserId(client), TIMER_REPEAT);
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