/*
	Tracking of jump type, speed, strafes and more.
*/



static float lastTickSpeed[MAXPLAYERS + 1]; // Last recorded horizontal speed
static int lastPlayerJumpTick[MAXPLAYERS + 1];
static int entityTouchCount[MAXPLAYERS + 1];
static bool validCmd[MAXPLAYERS + 1]; // Whether no illegal action is detected



// =====[ EVENTS ]=====

void OnJumpValidated_JumpTracking(int client, bool jumped, bool ladderJump)
{
	if (!validCmd[client])
	{
		return;
	}
	
	BeginJumpstat(client, jumped, ladderJump);
}

void OnStartTouchGround_JumpTracking(int client)
{
	EndJumpstat(client);
}

void OnPlayerRunCmd_JumpTracking(int client)
{
	if (!IsPlayerAlive(client))
	{
		return;
	}
	
	// Don't bother checking if player is already in air and jumpstat is already invalid
	if (Movement_GetOnGround(client) || GetValidJumpstat(client))
	{
		UpdateValidCmd(client);
	}
}

void OnPlayerRunCmdPost_JumpTracking(int client, int cmdnum)
{
	if (!IsPlayerAlive(client))
	{
		return;
	}
	
	if (!Movement_GetOnGround(client) && GetValidJumpstat(client))
	{
		// First tick is done when the jumpstat begins to ensure it is measured
		if (cmdnum != Movement_GetTakeoffCmdNum(client))
		{
			UpdateJumpstat(client);
		}
	}
	
	UpdateWRelease(client);
	lastTickSpeed[client] = Movement_GetSpeed(client);
}

void OnStartTouch_JumpTracking(int client)
{
	entityTouchCount[client]++;
	if (!Movement_GetOnGround(client))
	{
		InvalidateJumpstat(client);
	}
}

void OnEndTouch_JumpTracking(int client)
{
	entityTouchCount[client]--;
}

void OnPlayerJump_JumpTracking(int client, bool jumpbug)
{
	if (jumpbug)
	{
		InvalidateJumpstat(client);
	}
	lastPlayerJumpTick[client] = GetGameTickCount();
}

void OnJumpInvalidated_JumpTracking(int client)
{
	InvalidateJumpstat(client);
}

void OnOptionChanged_JumpTracking(int client, const char[] option)
{
	if (StrEqual(option, gC_CoreOptionNames[Option_Mode]))
	{
		InvalidateJumpstat(client);
	}
}

void OnClientPutInServer_JumpTracking(int client)
{
	entityTouchCount[client] = 0;
}



// =====[ GENERAL ]=====

static void BeginJumpstat(int client, bool jumped, bool ladderJump)
{
	BeginType(client, jumped, ladderJump);
	BeginHeight(client);
	BeginMaxSpeed(client);
	BeginStrafes(client);
	BeginSync(client);
	BeginDuration(client);
	BeginFailstat(client);
	
	Call_OnTakeoff(client, GetTypeCurrent(client));
	
	UpdateJumpstat(client); // Measure first tick of jumpstat
}

static void EndJumpstat(int client)
{
	UpdateJumpstat(client); // Measure last tick of jumpstat
	
	EndType(client);
	EndDistance(client);
	EndOffset(client);
	EndBlockDistance(client);
	EndHeight(client);
	EndMaxSpeed(client);
	EndStrafes(client);
	EndSync(client);
	EndDuration(client);
	
	Call_OnLanding(client, GetType(client), GetDistance(client), GetOffset(client), GetHeight(client), 
		GOKZ_GetTakeoffSpeed(client), GetMaxSpeed(client), GetStrafes(client), GetSync(client), GetDuration(client),
		GetBlockDistance(client), GetStrafeTotalWidth(client), GetStrafeTotalOverlap(client),
		GetStrafeTotalDeadair(client), GetBlockDeviation(client), GetBlockEdge(client), GetWRelease(client));
}

static void UpdateJumpstat(int client)
{
	UpdateHeight(client);
	UpdateMaxSpeed(client);
	UpdateStrafes(client);
	UpdateSync(client);
	UpdateDuration(client);
	UpdateFailstat(client);
}

static void UpdateValidCmd(int client)
{
	if (!CheckGravity(client) || !CheckBaseVelocity(client) || !CheckInWater(client))
	{
		InvalidateJumpstat(client);
		validCmd[client] = false;
	}
	else
	{
		validCmd[client] = true;
	}
}



// =====[ CHECKS ]=====

static bool CheckGravity(int client)
{
	float gravity = Movement_GetGravity(client);
	// Allow 1.0 and 0.0 gravity as both values appear during normal gameplay
	if (FloatAbs(gravity - 1.0) > EPSILON && FloatAbs(gravity) > EPSILON)
	{
		return false;
	}
	return true;
}

static bool CheckBaseVelocity(int client)
{
	float baseVelocity[3];
	Movement_GetBaseVelocity(client, baseVelocity);
	if (FloatAbs(baseVelocity[0]) > EPSILON || FloatAbs(baseVelocity[1]) > EPSILON || FloatAbs(baseVelocity[2]) > EPSILON)
	{
		return false;
	}
	return true;
}

static bool CheckInWater(int client)
{
	int waterLevel = GetEntProp(client, Prop_Data, "m_nWaterLevel");
	return waterLevel == 0;
}



// =====[ TYPE ]=====

/*
	Jump type is determined at the beginning of a takeoff.
	A jump may be determined to be invalid
	
	A takeoff occurs when the player stops touching the ground, with
	the exception of ladderjumps, which occur when the player leaves
	a ladderJump.
	
	A brief description of each jump type:
		LongJump - Normal jump.
		Bhop - Bunnyhop after landing a non-bunnyhop type jump.
		MultiBhop - Bunnyhop after landing a bunnyhop type jump.
		WeirdJump - Bhop, except the previous jump was of the Fall type.
		LadderJump - Taking off from a ladderJump.
		Fall - Becoming airborne without jumping, i.e. walking/falling down.
		Other - Jump type can't be determined, or the player touched something.
		Invalid - Jump was deemed invalid e.g. because of teleportation.
		
	Note: If the previous jump had a height offset, a bunnyhop after
	it will be of the Other type.
*/

static int jumpTypeLast[MAXPLAYERS + 1] =  { JumpType_Invalid, ... };
static int jumpTypeCurrent[MAXPLAYERS + 1] =  { JumpType_Invalid, ... };

int GetType(int client)
{
	return jumpTypeLast[client];
}

int GetTypeCurrent(int client)
{
	return jumpTypeCurrent[client];
}

bool GetValidJumpstat(int client)
{
	return jumpTypeCurrent[client] != JumpType_Invalid;
}

void InvalidateJumpstat(int client)
{
	if (GetValidJumpstat(client))
	{
		jumpTypeLast[client] = JumpType_Invalid;
		jumpTypeCurrent[client] = JumpType_Invalid;
		Call_OnJumpInvalidated(client);
	}
}

static void BeginType(int client, bool jumped, bool ladderJump)
{
	jumpTypeCurrent[client] = DetermineType(client, jumped, ladderJump);
}

static void EndType(int client)
{
	jumpTypeLast[client] = jumpTypeCurrent[client];
}

static int DetermineType(int client, bool jumped, bool ladderJump)
{
	if (entityTouchCount[client] > 0)
	{
		return JumpType_Invalid;
	}
	else if (ladderJump)
	{
		if (GetGameTickCount() - lastPlayerJumpTick[client] <= JS_MAX_BHOP_GROUND_TICKS)
		{
			return JumpType_Ladderhop;
		}
		else
		{
			return JumpType_LadderJump;
		}
	}
	else if (!jumped)
	{
		return JumpType_Fall;
	}
	else if (HitBhop(client))
	{
		if (FloatAbs(GetOffset(client)) < EPSILON) // Check for no offset
		{
			switch (GetType(client))
			{
				case JumpType_LongJump:return JumpType_Bhop;
				case JumpType_Bhop:return JumpType_MultiBhop;
				case JumpType_MultiBhop:return JumpType_MultiBhop;
				default:return JumpType_Other;
			}
		}
		// Check for weird jump
		else if (GetType(client) == JumpType_Fall && ValidWeirdJumpDropDistance(client))
		{
			return JumpType_WeirdJump;
		}
		else
		{
			return JumpType_Other;
		}
	}
	return JumpType_LongJump;
}

static bool HitBhop(int client)
{
	return Movement_GetTakeoffCmdNum(client) - Movement_GetLandingCmdNum(client) <= JS_MAX_BHOP_GROUND_TICKS;
}

static bool ValidWeirdJumpDropDistance(int client)
{
	float offset = GetOffset(client);
	if (offset < -1 * JS_MAX_WEIRDJUMP_FALL_OFFSET)
	{
		// Don't bother telling them if they fell a very far distance
		if (!GetJumpstatsDisabled(client) && offset >= -2 * JS_MAX_WEIRDJUMP_FALL_OFFSET)
		{
			GOKZ_PrintToChat(client, true, "%t", "Dropped Too Far (Weird Jump)", -1 * offset, JS_MAX_WEIRDJUMP_FALL_OFFSET);
		}
		return false;
	}
	return true;
}



// =====[ W RELEASE ]=====

static int releaseWCurrent[MAXPLAYERS + 1];
static int releaseWLast[MAXPLAYERS + 1];
static bool releaseWGroundTouched[MAXPLAYERS + 1];

int GetWRelease(int client)
{
	return releaseWLast[client];
}

static void UpdateWRelease(int client)
{
	if(Movement_GetOnGround(client) || Movement_GetOnLadder(client))
	{
		releaseWGroundTouched[client] = true;
		if(Movement_GetButtons(client) & (IN_FORWARD | IN_BACK))
		{
			releaseWCurrent[client] = 0;
		}
		else
		{
			releaseWCurrent[client]--;
		}
	}
	else
	{
		if(Movement_GetButtons(client) & (IN_FORWARD | IN_BACK))
		{
			releaseWCurrent[client]++;
		}
		else
		{
			if(releaseWGroundTouched[client])
			{
				releaseWGroundTouched[client] = false;
				releaseWLast[client] = releaseWCurrent[client];
			}
		}
	}
}



// =====[ DISTANCE ]=====

/*
	Jump distance is the horizontal distance of the jump.
	
	It is measured intuitively, describing the gap between two blocks
	(along the x or y axis) that the player was able to jump. This is
	done by adding 32.0, the size of the player collision box, to the
	distance between the takeoff and landing origins.
*/

static float distanceLast[MAXPLAYERS + 1];

float GetDistance(int client)
{
	return distanceLast[client];
}

static void EndDistance(int client)
{
	distanceLast[client] = CalcDistance(client);
}

static float CalcDistance(int client)
{
	float takeoffOrigin[3], landingOrigin[3], distance;
	Movement_GetTakeoffOrigin(client, takeoffOrigin);
	Movement_GetNobugLandingOrigin(client, landingOrigin);
	distance = GetVectorHorizontalDistance(takeoffOrigin, landingOrigin);
	if (GetType(client) != JumpType_LadderJump)
	{
		distance += 32.0;
	}
	return distance;
}



// =====[ BLOCK DISTANCE ]=====

/*
	The block distance is calculated if the player jumps from one block
	to another. For this, the blocks need parallel edges that the player
	jumps across.
 */

static int blockDistance[MAXPLAYERS + 1];
static float blockEdge[MAXPLAYERS + 1];
static float blockDeviation[MAXPLAYERS + 1];

int GetBlockDistance(int client)
{
	return blockDistance[client];
}

float GetBlockDeviation(int client)
{
	return blockDeviation[client];
}

float GetBlockEdge(int client)
{
	return blockEdge[client];
}

static void EndBlockDistance(int client)
{
	blockDistance[client] = 0;
	blockEdge[client] = 0.0;
	blockDeviation[client] = 0.0;
	
	int jumpType = GetType(client);
	if (jumpType == JumpType_LongJump || 
		jumpType == JumpType_Bhop || 
		jumpType == JumpType_MultiBhop || 
		jumpType == JumpType_Ladderhop || 
		jumpType == JumpType_WeirdJump)
	{
		Handle trace;
		int coordDist, coordDev;
		float takeoffOrigin[3], landingOrigin[3], middle[3];
		float startBlock[3], endBlock[3], sweepBoxMin[3], sweepBoxMax[3];
		
		// Not doing the calculations in the obvious cases.
		if(GetDistance(client) < JS_MIN_BLOCK_DISTANCE)
		{
			return;
		}
		
		Movement_GetTakeoffOrigin(client, takeoffOrigin);
		Movement_GetNobugLandingOrigin(client, landingOrigin);
		
		// Get the orientation of the block.
		coordDist = FloatAbs(landingOrigin[0] - takeoffOrigin[0]) < FloatAbs(landingOrigin[1] - takeoffOrigin[1]);
		coordDev = !coordDist;
		
		// Get the deviation.
		blockDeviation[client] = FloatAbs(landingOrigin[coordDev] - takeoffOrigin[coordDev]);
		
		// We can't make measurements from within an entity, so we assume the
		// player had a remotely reasonable edge and that the middle of the jump
		// is not over a block and then start measuring things out from there.
		middle[coordDist] = (takeoffOrigin[coordDist] + landingOrigin[coordDist]) / 2;
		middle[coordDev] = (takeoffOrigin[coordDev] + landingOrigin[coordDev]) / 2;
		middle[2] = takeoffOrigin[2] - 1.0;
		
		// Setup a sweeping line that starts in the middle and tries to search for the smallest
		// block within the deviation of the player.
		sweepBoxMin[coordDist] = 0.0;
		sweepBoxMin[coordDev] = -blockDeviation[client] - 16.0;
		sweepBoxMin[2] = 0.0;
		sweepBoxMax[coordDist] = 0.0;
		sweepBoxMax[coordDev] = blockDeviation[client] + 16.0;
		sweepBoxMax[2] = 0.0;
		
		// Modify the takeoff and landing origins to line up with the middle and respect
		// the bounding box of the player.
		if(takeoffOrigin[coordDist] > landingOrigin[coordDist])
		{
			takeoffOrigin[coordDist] += 16.0;
			landingOrigin[coordDist] -= 16.0;
		}
		else
		{
			takeoffOrigin[coordDist] -= 16.0;
			landingOrigin[coordDist] += 16.0;
		}
		takeoffOrigin[coordDev] = middle[coordDev];
		landingOrigin[coordDev] = middle[coordDev];
		takeoffOrigin[2] = middle[2];
		landingOrigin[2] = middle[2];
		
		// Search for the starting block.
		trace = TR_TraceHullEx(middle, takeoffOrigin, sweepBoxMin, sweepBoxMax, MASK_SOLID);
		if(!TR_DidHit(trace))
		{
			CloseHandle(trace);
			return;
		}
		TR_GetEndPosition(startBlock, trace);
		CloseHandle(trace);
		
		// Search for the ending block.
		trace = TR_TraceHullEx(middle, landingOrigin, sweepBoxMin, sweepBoxMax, MASK_SOLID);
		if(!TR_DidHit(trace))
		{
			CloseHandle(trace);
			return;
		}
		TR_GetEndPosition(endBlock, trace);
		CloseHandle(trace);
		
		// Make sure the edges of the blocks are parallel.
		if(!BlockAreEdgesParallel(startBlock, endBlock, blockDeviation[client] + 32.0, coordDist, coordDev))
		{
			return;
		}
		
		// Calculate distance and edge.
		blockDistance[client] = RoundFloat(FloatAbs(endBlock[coordDist] - startBlock[coordDist]));
		blockEdge[client] = FloatAbs(startBlock[coordDist] - takeoffOrigin[coordDist]);
		
		if(blockDistance[client] < JS_MIN_BLOCK_DISTANCE)
		{
			blockDistance[client] = 0;
		}
	}
	else if (jumpType == JumpType_LadderJump)
	{
		Handle trace;
		int coordDist, coordDev, distSign;
		float takeoffOrigin[3], landingOrigin[3];
		float sweepBoxMin[3], sweepBoxMax[3], blockPosition[3], traceEnd[3], ladderPosition[3];
		
		// Not doing the calculations in the obvious cases.
		if(GetDistance(client) < JS_MIN_LAJ_BLOCK_DISTANCE)
		{
			return;
		}
		
		Movement_GetTakeoffOrigin(client, takeoffOrigin);
		Movement_GetNobugLandingOrigin(client, landingOrigin);
		
		// Get the orientation of the block.
		coordDist = FloatAbs(landingOrigin[0] - takeoffOrigin[0]) < FloatAbs(landingOrigin[1] - takeoffOrigin[1]);
		coordDev = !coordDist;
		distSign = landingOrigin[coordDist] > takeoffOrigin[coordDist] ? 1 : -1;
		
		// Get the deviation.
		blockDeviation[client] = FloatAbs(landingOrigin[coordDev] - takeoffOrigin[coordDev]);
		
		// Make sure we don't collide with the player model.
		takeoffOrigin[2] -= 5.0;
		landingOrigin[2] = takeoffOrigin[2];
		
		// Setup a line to search for the ladder.
		sweepBoxMin[coordDist] = 0.0;
		sweepBoxMin[coordDev] = -20.0;
		sweepBoxMin[2] = 0.0;
		sweepBoxMax[coordDist] = 0.0;
		sweepBoxMax[coordDev] = 20.0;
		sweepBoxMax[2] = 0.0;
		traceEnd[coordDist] = takeoffOrigin[coordDist] + distSign * JS_MIN_LAJ_BLOCK_DISTANCE;
		traceEnd[coordDev] = takeoffOrigin[coordDev];
		traceEnd[2] = takeoffOrigin[2];
		
		// Should serve as a very primitive check to make sure that
		// non-aligned ladders can't be abused.
		takeoffOrigin[coordDist] += distSign * 15.9;
		
		// Search for the ladder.
		trace = TR_TraceHullEx(takeoffOrigin, traceEnd, sweepBoxMin, sweepBoxMax, MASK_ALL);
		if(!TR_DidHit(trace))
		{
			CloseHandle(trace);
			return;
		}
		TR_GetEndPosition(ladderPosition, trace);
		CloseHandle(trace);
		
		// This should indicate a malaligned ladder.
		if(FloatAbs(ladderPosition[coordDist] - takeoffOrigin[coordDist]) < EPSILON)
		{
			return;
		}

		// Find the block.
		landingOrigin[coordDist] += distSign * 16.0;
		
		if(!BlockTraceAlignedPos(traceEnd, landingOrigin, blockPosition, coordDist))
		{
			return;
		}
		
		// Calculate distance and edge.
		blockDistance[client] = RoundFloat(FloatAbs(blockPosition[coordDist] - ladderPosition[coordDist]));
		blockEdge[client] = FloatAbs(takeoffOrigin[coordDist] - ladderPosition[coordDist]) - 0.1;
	}
}

static bool BlockAreEdgesParallel(const float startBlock[3], const float endBlock[3], float deviation, int coordDist, int coordDev)
{
	float start[3], end[3], offset;
	
	// We use very short rays to find the blocks where they're supposed to be and use
	// their normals to determine whether they're parallel or not.
	offset = startBlock[coordDist] > endBlock[coordDist] ? 0.1 : -0.1;
	
	start[coordDist] = startBlock[coordDist] - offset;
	start[coordDev] = startBlock[coordDev] - deviation;
	start[2] = startBlock[2];
	
	end[coordDist] = startBlock[coordDist] + offset;
	end[coordDev] = startBlock[coordDev] - deviation;
	end[2] = startBlock[2];
	
	if(BlockTraceAligned(start, end, coordDist))
	{
		start[coordDist] = endBlock[coordDist] + offset;
		end[coordDist] = endBlock[coordDist] - offset;
		if(BlockTraceAligned(start, end, coordDist))
		{
			return true;
		}
		start[coordDist] = startBlock[coordDist] - offset;
		end[coordDist] = startBlock[coordDist] + offset;
	}
	
	start[coordDev] = startBlock[coordDev] + deviation;
	end[coordDev] = startBlock[coordDev] + deviation;
	
	if(BlockTraceAligned(start, end, coordDist))
	{
		start[coordDist] = endBlock[coordDist] + offset;
		end[coordDist] = endBlock[coordDist] - offset;
		if(BlockTraceAligned(start, end, coordDist))
		{
			return true;
		}
	}
	
	return false;
}

static bool BlockTraceAligned(const float origin[3], const float end[3], int coordDist)
{
	float normalVector[3];
	Handle trace = TR_TraceRayEx(origin, end, MASK_SOLID, RayType_EndPoint);
	if(!TR_DidHit(trace))
	{
		return false;
	}
	TR_GetPlaneNormal(trace, normalVector);
	if(FloatAbs(FloatAbs(normalVector[coordDist]) - EPSILON) == 1.0)
	{
		return false;
	}
	CloseHandle(trace);
	return true;
}

static bool BlockTraceAlignedPos(const float origin[3], const float end[3], float positionVector[3], int coordDist)
{
	float normalVector[3];
	Handle trace = TR_TraceRayEx(origin, end, MASK_SOLID, RayType_EndPoint);
	if(!TR_DidHit(trace))
	{
		return false;
	}
	TR_GetPlaneNormal(trace, normalVector);
	if(FloatAbs(FloatAbs(normalVector[coordDist]) - EPSILON) == 1.0)
	{
		return false;
	}
	TR_GetEndPosition(positionVector, trace);
	CloseHandle(trace);
	return true;
}



// =====[ FAILSTATS ]=====
static float failstatDistance[MAXPLAYERS + 1];

float GetFailstat(int client)
{
	return failstatDistance[client];
}

static void BeginFailstat(int client)
{
	failstatDistance[client] = -1.0;
}

static void UpdateFailstat(int client)
{
	int jumpType = GetTypeCurrent(client);
	if (jumpType == JumpType_LongJump || 
		jumpType == JumpType_Bhop || 
		jumpType == JumpType_MultiBhop || 
		jumpType == JumpType_Ladderhop || 
		jumpType == JumpType_WeirdJump)
	{
		Handle trace;
		int coordDist, coordDev;
		float takeoffOrigin[3], landingOrigin[3], middle[3];
		float startBlock[3], endBlock[3], sweepBoxMin[3], sweepBoxMax[3];
	
		Movement_GetTakeoffOrigin(client, takeoffOrigin);
		Movement_GetOrigin(client, middle);
		
		// Only do that calculation once.
		if (middle[2] >= takeoffOrigin[2] || failstatDistance[client] >= 0.0)
		{
			return;
		}
		failstatDistance[client] = 0.0;
		middle[2] -= 1.0;
		
		// Get the orientation of the block.
		coordDist = FloatAbs(middle[0] - takeoffOrigin[0]) < FloatAbs(middle[1] - takeoffOrigin[1]);
		coordDev = !coordDist;
			
		// Get the deviation.
		blockDeviation[client] = FloatAbs(middle[coordDev] - takeoffOrigin[coordDev]);
		
		// Setup a sweeping line that starts in the middle and tries to search for the smallest
		// block within the deviation of the player.
		sweepBoxMin[coordDist] = 0.0;
		sweepBoxMin[coordDev] = -blockDeviation[client] - 16.0;
		sweepBoxMin[2] = 0.0;
		sweepBoxMax[coordDist] = 0.0;
		sweepBoxMax[coordDev] = blockDeviation[client] + 16.0;
		sweepBoxMax[2] = 0.0;
		
		// Modify the takeoff origin to line up with the middle and respect
		// the bounding box of the player.
		takeoffOrigin[coordDist] += takeoffOrigin[coordDist] > middle[coordDist] ? 16.0 : -16.0;
		takeoffOrigin[coordDev] = middle[coordDev];
		takeoffOrigin[2] = middle[2];
		
		// Search for the starting block.
		trace = TR_TraceHullEx(middle, takeoffOrigin, sweepBoxMin, sweepBoxMax, MASK_SOLID);
		if(!TR_DidHit(trace))
		{
			CloseHandle(trace);
			return;
		}
		TR_GetEndPosition(startBlock, trace);
		CloseHandle(trace);
		
		// Construct the maximum landing origin, assuming the player reached
		// at least the middle of the gap.
		landingOrigin[coordDist] = 2 * middle[coordDist] - takeoffOrigin[coordDist];
		landingOrigin[coordDev] = middle[coordDev];
		landingOrigin[2] = middle[2];
		
		// Search for the ending block.
		trace = TR_TraceHullEx(middle, landingOrigin, sweepBoxMin, sweepBoxMax, MASK_SOLID);
		if(!TR_DidHit(trace))
		{
			CloseHandle(trace);
			return;
		}
		TR_GetEndPosition(endBlock, trace);
		CloseHandle(trace);
		
		// Make sure the edges of the blocks are parallel.
		if(!BlockAreEdgesParallel(startBlock, endBlock, blockDeviation[client] + 32.0, coordDist, coordDev))
		{
			return;
		}
		
		// Calculate distance and edge.
		blockDistance[client] = RoundFloat(FloatAbs(endBlock[coordDist] - startBlock[coordDist]));
		blockEdge[client] = FloatAbs(startBlock[coordDist] - takeoffOrigin[coordDist]);
		failstatDistance[client] = FloatAbs(middle[coordDist] - takeoffOrigin[coordDist]) + 16.0;
		
		// Call the callback for the reporting.
		Call_OnFailstat(client, GetTypeCurrent(client), GetFailstat(client), GetHeightCurrent(client),
			GOKZ_GetTakeoffSpeed(client), GetMaxSpeedCurrent(client), GetStrafesCurrent(client), GetSyncCurrent(client),
			GetDurationCurrent(client), GetBlockDistance(client), GetStrafeTotalWidth(client), GetStrafeTotalOverlap(client),
			GetStrafeTotalDeadair(client), GetBlockDeviation(client), GetBlockEdge(client), GetWRelease(client));
	}
}



// =====[ OFFSET ]=====

static float offsetLast[MAXPLAYERS + 1];

float GetOffset(int client)
{
	return offsetLast[client];
}

static void EndOffset(int client)
{
	float takeoffOrigin[3], landingOrigin[3];
	Movement_GetTakeoffOrigin(client, takeoffOrigin);
	Movement_GetNobugLandingOrigin(client, landingOrigin);
	offsetLast[client] = landingOrigin[2] - takeoffOrigin[2];
}



// =====[ DURATION ]=====

static int durationTicksLast[MAXPLAYERS + 1];
static int durationTicksCurrent[MAXPLAYERS + 1];

float GetDuration(int client)
{
	return durationTicksLast[client] * GetTickInterval();
}

float GetDurationCurrent(int client)
{
	return durationTicksCurrent[client] * GetTickInterval();
}

int GetDurationTicks(int client)
{
	return durationTicksLast[client];
}

static void BeginDuration(int client)
{
	durationTicksCurrent[client] = 0;
}

static void EndDuration(int client)
{
	durationTicksLast[client] = durationTicksCurrent[client];
}

static int GetDurationTicksCurrent(int client)
{
	return durationTicksCurrent[client];
}

static void UpdateDuration(int client)
{
	durationTicksCurrent[client]++;
}



// =====[ HEIGHT ]=====

static float heightLast[MAXPLAYERS + 1];
static float heightCurrent[MAXPLAYERS + 1];

float GetHeight(int client)
{
	return heightLast[client];
}

float GetHeightCurrent(int client)
{
	return heightCurrent[client];
}

static void BeginHeight(int client)
{
	heightCurrent[client] = 0.0;
}

static void EndHeight(int client)
{
	heightLast[client] = heightCurrent[client];
}

static float UpdateHeight(int client)
{
	float takeoffOrigin[3], origin[3];
	Movement_GetTakeoffOrigin(client, takeoffOrigin);
	Movement_GetOrigin(client, origin);
	heightCurrent[client] = FloatMax(heightCurrent[client], origin[2] - takeoffOrigin[2]);
}



// =====[ MAX SPEED ]=====

static float maxSpeedLast[MAXPLAYERS + 1];
static float maxSpeedCurrent[MAXPLAYERS + 1];

float GetMaxSpeed(int client)
{
	return maxSpeedLast[client];
}

float GetMaxSpeedCurrent(int client)
{
	return maxSpeedCurrent[client];
}

static void BeginMaxSpeed(int client)
{
	maxSpeedCurrent[client] = 0.0;
}

static void EndMaxSpeed(int client)
{
	maxSpeedLast[client] = maxSpeedCurrent[client];
}

static void UpdateMaxSpeed(int client)
{
	maxSpeedCurrent[client] = FloatMax(maxSpeedCurrent[client], Movement_GetSpeed(client));
}



// =====[ STRAFES ]=====

static int strafesLast[MAXPLAYERS + 1];
static int strafesCurrent[MAXPLAYERS + 1];
static int strafesDirection[MAXPLAYERS + 1];
static int strafesTicks[MAXPLAYERS + 1][JS_MAX_TRACKED_STRAFES];
static int strafesGainTicks[MAXPLAYERS + 1][JS_MAX_TRACKED_STRAFES];
static float strafesGain[MAXPLAYERS + 1][JS_MAX_TRACKED_STRAFES];
static float strafesLoss[MAXPLAYERS + 1][JS_MAX_TRACKED_STRAFES];
static float strafesWidth[MAXPLAYERS + 1][JS_MAX_TRACKED_STRAFES];
static float strafesLastAngle[MAXPLAYERS + 1];
static float strafesTotalWidth[MAXPLAYERS + 1];
static int strafesTotalDeadair[MAXPLAYERS + 1];
static int strafesTotalOverlap[MAXPLAYERS + 1];
static int strafesDeadair[MAXPLAYERS + 1][JS_MAX_TRACKED_STRAFES];
static int strafesOverlap[MAXPLAYERS + 1][JS_MAX_TRACKED_STRAFES];

int GetStrafes(int client)
{
	return strafesLast[client];
}

int GetStrafesCurrent(int client)
{
	return strafesCurrent[client];
}

float GetStrafeAirtime(int client, int strafe)
{
	return float(strafesTicks[client][strafe]) / float(GetDurationTicks(client)) * 100.0;
}

float GetStrafeSync(int client, int strafe)
{
	return float(strafesGainTicks[client][strafe]) / float(strafesTicks[client][strafe]) * 100.0;
}

float GetStrafeGain(int client, int strafe)
{
	return strafesGain[client][strafe];
}

float GetStrafeLoss(int client, int strafe)
{
	return strafesLoss[client][strafe];
}

float GetStrafeWidth(int client, int strafe)
{
	return strafesWidth[client][strafe];
}

float GetStrafeTotalWidth(int client)
{
	return strafesTotalWidth[client];
}

int GetStrafeTotalOverlap(int client)
{
	return strafesTotalOverlap[client];
}

int GetStrafeTotalDeadair(int client)
{
	return strafesTotalDeadair[client];
}

int GetStrafeOverlap(int client, int strafe)
{
	return strafesOverlap[client][strafe];
}

int GetStrafeDeadair(int client, int strafe)
{
	return strafesDeadair[client][strafe];
}

static void BeginStrafes(int client)
{
	strafesCurrent[client] = 0;
	strafesTotalDeadair[client] = 0;
	strafesTotalOverlap[client] = 0;
	strafesTotalWidth[client] = 0.0;
	strafesDirection[client] = StrafeDirection_None;
	float angles[3];
	Movement_GetEyeAngles(client, angles);
	strafesLastAngle[client] = angles[1];
	for (int strafe = 0; strafe < JS_MAX_TRACKED_STRAFES; strafe++)
	{
		strafesTicks[client][strafe] = 0;
		strafesGainTicks[client][strafe] = 0;
		strafesGain[client][strafe] = 0.0;
		strafesLoss[client][strafe] = 0.0;
		strafesWidth[client][strafe] = 0.0;
		strafesDeadair[client][strafe] = 0;
		strafesOverlap[client][strafe] = 0;
	}
}

static void EndStrafes(int client)
{
	strafesLast[client] = strafesCurrent[client];
	strafesTotalWidth[client] += strafesWidth[client][strafesCurrent[client]];
}

static void UpdateStrafes(int client)
{
	KZPlayer player = KZPlayer(client);
	if (player.TurningLeft && strafesDirection[player.ID] != StrafeDirection_Left)
	{
		strafesDirection[player.ID] = StrafeDirection_Left;
		strafesTotalWidth[client] += strafesWidth[client][strafesCurrent[client]];
		strafesCurrent[player.ID]++;
	}
	else if (player.TurningRight && strafesDirection[player.ID] != StrafeDirection_Right)
	{
		strafesDirection[player.ID] = StrafeDirection_Right;
		strafesTotalWidth[client] += strafesWidth[client][strafesCurrent[client]];
		strafesCurrent[player.ID]++;
	}
	
	int buttons = Movement_GetButtons(client);
	if (buttons & IN_MOVERIGHT && buttons & IN_MOVELEFT)
	{
		strafesTotalOverlap[client]++;
		strafesOverlap[client][strafesCurrent[client]]++;
	}
	else if (!(buttons & IN_MOVERIGHT) && !(buttons & IN_MOVELEFT))
	{
		strafesTotalDeadair[client]++;
		strafesDeadair[client][strafesCurrent[client]]++;
	}
	
	if (strafesCurrent[client] < JS_MAX_TRACKED_STRAFES)
	{
		strafesTicks[client][strafesCurrent[client]]++;
		if (player.Speed > lastTickSpeed[client])
		{
			strafesGainTicks[client][strafesCurrent[client]]++;
			strafesGain[client][strafesCurrent[client]] += player.Speed - lastTickSpeed[client];
		}
		else
		{
			strafesLoss[client][strafesCurrent[client]] += lastTickSpeed[client] - player.Speed;
		}
		float angles[3];
		Movement_GetEyeAngles(client, angles);
		strafesWidth[client][strafesCurrent[client]] += FloatAbs(CalcDeltaAngle(angles[1], strafesLastAngle[client]));
		strafesLastAngle[client] = angles[1];
	}
}



// =====[ SYNC ]=====

/*
	Sync is calculated as the percentage of time spent gaining
	speed during the jump. Maintaining current speed negatively
	affects sync.
*/

static float syncLast[MAXPLAYERS + 1];
static int syncGainTicksCurrent[MAXPLAYERS + 1];

float GetSync(int client)
{
	return syncLast[client];
}

float GetSyncCurrent(int client)
{
	return float(syncGainTicksCurrent[client]) / float(GetDurationTicksCurrent(client)) * 100.0;
}

static void BeginSync(int client)
{
	syncGainTicksCurrent[client] = 0;
}

static void EndSync(int client)
{
	syncLast[client] = float(syncGainTicksCurrent[client]) / float(GetDurationTicksCurrent(client)) * 100.0;
}

static void UpdateSync(int client)
{
	float speed = Movement_GetSpeed(client);
	if (speed > lastTickSpeed[client])
	{
		syncGainTicksCurrent[client]++;
	}
}
