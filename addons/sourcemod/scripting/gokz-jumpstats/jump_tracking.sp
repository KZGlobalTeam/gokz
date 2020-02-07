/*
	Tracking of jump type, speed, strafes and more.
*/



// =====[ STRUCTS ]=====

enum struct Pose
{
	float position[3];
	float orientation[3];
	float velocity[3];
	float speed;
}



// =====[ GLOBAL VARIABLES ]=====

static int entityTouchCount[MAXPLAYERS + 1];
static bool validCmd[MAXPLAYERS + 1]; // Whether no illegal action is detected	
static const float playerMins[3] =  { -16.0, -16.0, 0.0 };
static const float playerMaxs[3] =  { 16.0, 16.0, 0.0 };
static bool beginJumpstat[MAXPLAYERS + 1];
static const Jump emptyJump;



// =====[ DEFINITIONS ]=====

// We cannot return enum structs and it's annoying
// The modulo operator is broken, so we can't access this using negative numbers (https://github.com/alliedmodders/sourcepawn/issues/456)
#define pose(%1) (poseHistory[this.jumper][(this.poseIndex + (%1)) % JS_FAILSTATS_MAX_TRACKED_TICKS])



// =====[ TRACKING ]=====

// We cannot put that into the tracker struct
Pose poseHistory[MAXPLAYERS + 1][JS_FAILSTATS_MAX_TRACKED_TICKS];

enum struct JumpTracker
{
	Jump jump;
	int jumper;
	int jumpoffTick;
	int poseIndex;
	int strafeDirection;
	int lastJumpTick;
	int lastType;
	int lastWPressedTick;
	int syncTicks;
	bool failstatBlockDetected;
	bool failstatCalculcated;
	float failstatBlockHeight;
	float takeoffOrigin[3];
	float position[3];
	
	void Init(int jumper)
	{
		this.jumper = jumper;
		this.jump.jumper = jumper;
	}
	
	void Reset(bool jumped, bool ladderJump)
	{
		// Reset all stats
		this.jump = emptyJump;
		this.jump.jumper = this.jumper;
		this.syncTicks = 0;
		this.strafeDirection = StrafeDirection_None;
		this.lastType = this.jump.type;
		
		// Reset pose history
		this.poseIndex = 0;
		
		// This is the only instance where we need jumped and ladderJump so we
		// might as well do that here already.
		this.jump.type = this.DetermineType(jumped, ladderJump);
	}
	
	void Begin()
	{
		// Initialize stats
		this.jump.releaseW = 100;
		Movement_GetTakeoffOrigin(this.jumper, this.takeoffOrigin);
		
		// Initialize failstats
		this.failstatBlockDetected = this.jump.type != JumpType_LadderJump;
		this.failstatCalculcated = false;
		this.failstatBlockHeight = this.takeoffOrigin[2];
		
		// Update the takeoff speed with the correct value
		this.jump.preSpeed = GOKZ_GetTakeoffSpeed(this.jumper);
		poseHistory[this.jumper][0].speed = this.jump.preSpeed;
		
		// Notify everyone about the takeoff
		Call_OnTakeoff(this.jumper, this.jump.type);
		
		// Measure first tick of jumpstat
		this.Update();
		
		// We don't need that until the next begin
		this.lastJumpTick = GetGameTickCount();
	}
	
	void Update()
	{
		this.UpdatePoseHistory();
		
		float speed = pose(0).speed;
		
		this.jump.height = FloatMax(this.jump.height, this.position[2] - this.takeoffOrigin[2]);
		this.jump.maxSpeed = FloatMax(this.jump.maxSpeed, speed);
		this.jump.crouchTicks += Movement_GetDucking(this.jumper) ? 1 : 0;
		this.syncTicks += speed > pose(-1).speed ? 1 : 0;
		this.jump.durationTicks++;
		
		this.UpdateStrafes();
		this.UpdateFailstat();
		
		this.lastType = this.jump.type;
	}
	
	void End()
	{
		// Measure last tick of jumpstat
		this.Update();
		
		// Try to prevent a form of booster abuse
		if (this.jump.type != JumpType_LadderJump && this.jump.durationTicks > 100)
		{
			this.Invalidate();
			return;
		}
		
		// Fix the edgebug for the current position
		Movement_GetNobugLandingOrigin(this.jumper, this.position);
		
		// Calculate the last stats
		this.jump.distance = this.CalcDistance();
		this.jump.sync = float(this.syncTicks) / float(this.jump.durationTicks) * 100.0;
		this.jump.offset = this.position[2] - this.takeoffOrigin[2];
		this.jump.duration = this.jump.durationTicks * GetTickInterval();
		
		// Make sure the ladder has no offset for ladder jumps
		if (this.jump.type == JumpType_LadderJump)
		{
			this.TraceLadderOffset(this.position[2]);
		}
		
		this.EndBlockDistance();
		
		Call_OnLanding(this.jump);
	}
	
	void UpdatePoseHistory()
	{
		this.poseIndex++;
		this.UpdatePose(pose(0));
	}
	
	void UpdatePose(Pose p)
	{
		Movement_GetOrigin(this.jumper, p.position);
		Movement_GetVelocity(this.jumper, p.velocity);
		Movement_GetEyeAngles(this.jumper, p.orientation);
		p.speed = GetVectorHorizontalLength(p.velocity);
		
		// We use the current position in a lot of places, so we store it
		// separately to avoid calling 'pose' all the time.
		CopyVector(p.position, this.position);
	}
	
	// Calculation functions
	
	void UpdateStrafes()
	{
		// Strafe direction
		if (Movement_GetTurningLeft(this.jumper) && this.strafeDirection != StrafeDirection_Left)
		{
			this.strafeDirection = StrafeDirection_Left;
			this.jump.strafes++;
		}
		else if (Movement_GetTurningRight(this.jumper) && this.strafeDirection != StrafeDirection_Right)
		{
			this.strafeDirection = StrafeDirection_Right;
			this.jump.strafes++;
		}
		
		// Overlap / Deadair
		int buttons = Movement_GetButtons(this.jumper);
		int overlap = buttons & IN_MOVERIGHT && buttons & IN_MOVELEFT ? 1 : 0;
		int deadair = !(buttons & IN_MOVERIGHT) && !(buttons & IN_MOVELEFT) ? 1 : 0;
		
		// Sync / Gain / Loss
		float deltaSpeed = pose(0).speed - pose(-1).speed;
		bool gained = deltaSpeed > EPSILON;
		bool lost = deltaSpeed < -EPSILON;
		
		// Width
		float width = FloatAbs(CalcDeltaAngle(pose(0).orientation[1], pose(-1).orientation[1]));
		
		// Overall stats
		this.jump.overlap += overlap;
		this.jump.deadair += deadair;
		this.jump.width += width;
		
		// Individual stats
		if (this.jump.strafes >= JS_MAX_TRACKED_STRAFES)
		{
			return;
		}
		
		int i = this.jump.strafes;
		this.jump.strafes_ticks[i]++;
		
		this.jump.strafes_overlap[i] += overlap;
		this.jump.strafes_deadair[i] += deadair;
		this.jump.strafes_loss[i] += lost ? -1 * deltaSpeed : 0.0;
		this.jump.strafes_width[i] += width;
		
		if (gained)
		{
			this.jump.strafes_gainTicks[i]++;
			this.jump.strafes_gain[i] += deltaSpeed;
		}
	}
	
	void UpdateWRelease()
	{
		if (Movement_GetButtons(this.jumper) & IN_FORWARD || Movement_GetButtons(this.jumper) & IN_BACK)
		{
			this.lastWPressedTick = GetGameTickCount();
		}
		else if (this.jump.releaseW > 99)
		{
			this.jump.releaseW = this.lastWPressedTick - this.jumpoffTick;
		}
	}
	
	void UpdateFailstat()
	{
		int coordDist, distSign;
		float failstatPosition[3], block[3];
		
		// Get the coordinate system orientation.
		this.GetCoordOrientation(this.position, this.takeoffOrigin, coordDist, distSign);
		
		// For ladderjumps we have to find the landing block early so we know at which point the jump failed.
		// For this, we search for the block 10 units above the takeoff origin, assuming the player already
		// traveled a significant enough distance in the direction of the block at this time.
		if (!this.failstatBlockDetected && 
			this.position[2] - this.takeoffOrigin[2] < 10.0 && 
			this.jump.height > 10.0)
		{
			this.failstatBlockDetected = true;
			
			float traceStart[3];
			
			CopyVector(this.takeoffOrigin, traceStart);
			traceStart[2] -= 5.0;
			CopyVector(traceStart, block);
			traceStart[coordDist] += JS_MIN_LAJ_BLOCK_DISTANCE;
			block[coordDist] += JS_MAX_LAJ_FAILSTAT_DISTANCE;
			
			Handle trace = TR_TraceHullFilterEx(traceStart, block, playerMins, playerMaxs, MASK_PLAYERSOLID, TraceEntityFilterPlayers);
			if (!TR_DidHit(trace))
			{
				this.failstatCalculcated = true;
				delete trace;
				return;
			}
			TR_GetEndPosition(block, trace);
			delete trace;
			
			block[2] += 5.0;
			this.failstatBlockHeight = this.FindBlockHeight(block, distSign * 17.0, coordDist, 10.0) - 0.031250;
		}
		
		// Only do that calculation once.
		if (this.position[2] >= this.failstatBlockHeight || this.failstatCalculcated)
		{
			return;
		}
		
		// Mark the calculation as done.
		this.failstatCalculcated = true;
		
		// Calculate the true origin where the player would have hit the ground.
		this.GetFailOrigin(this.failstatBlockHeight, failstatPosition);
		
		// Calculate the jump distance.
		this.jump.distance = FloatAbs(GetVectorHorizontalDistance(failstatPosition, this.takeoffOrigin));
		
		// Construct the maximum landing origin, assuming the player reached
		// at least the middle of the gap.
		CopyVector(this.takeoffOrigin, block);
		block[coordDist] = 2 * failstatPosition[coordDist] - this.takeoffOrigin[coordDist];
		block[!coordDist] = failstatPosition[!coordDist]; 
		block[2] = this.failstatBlockHeight;
		
		if ((this.lastType == JumpType_LongJump || 
				this.lastType == JumpType_Bhop || 
				this.lastType == JumpType_MultiBhop || 
				this.lastType == JumpType_Ladderhop || 
				this.lastType == JumpType_WeirdJump)
			 && this.jump.distance >= JS_MIN_BLOCK_DISTANCE)
		{
			// Add the player model to the distance.
			this.jump.distance += 32.0;
			
			this.CalcBlockStats(block, true);
		}
		else if (this.lastType == JumpType_LadderJump && this.jump.distance >= JS_MIN_LAJ_BLOCK_DISTANCE)
		{
			this.CalcLadderBlockStats(block, true);
		}
		else
		{
			return;
		}
		
		if (this.jump.block > 0)
		{
			// Calculate the last stats
			this.jump.sync = float(this.syncTicks) / float(this.jump.durationTicks) * 100.0;
			this.jump.offset = failstatPosition[2] - this.takeoffOrigin[2];
			this.jump.duration = this.jump.durationTicks * GetTickInterval();
			
			// Temporarily validate the jump.
			int currentType = this.jump.type;
			this.jump.type = this.lastType;
			
			// Call the callback for the reporting.
			Call_OnFailstat(this.jump);
			
			// Restore previous jump type so we don't mess with jump invalidation.
			this.jump.type = currentType;
		}
	}
	
	void GetFailOrigin(float planeHeight, float result[3])
	{
		float newVel[3], oldVel[3];
		
		// Calculate the actual velocity.
		CopyVector(pose(-1).velocity, oldVel);
		ScaleVector(oldVel, GetTickInterval());
		
		// Calculate at which percentage of the velocity vector we hit the plane.
		float scale = (planeHeight - pose(-1).position[2]) / oldVel[2];
		
		// Calculate the position we hit the plane.
		CopyVector(oldVel, newVel);
		ScaleVector(newVel, scale);
		AddVectors(pose(-1).position, newVel, result);
	}
	
	void GetCoordOrientation(const float vec1[3], const float vec2[3], int &coordDist, int &distSign)
	{
		coordDist = FloatAbs(vec1[0] - vec2[0]) < FloatAbs(vec1[1] - vec2[1]);
		distSign = vec1[coordDist] > vec2[coordDist] ? 1 : -1;
	}
	
	bool TraceLadderOffset(float landingHeight)
	{
		float traceOrigin[3], traceEnd[3], ladderTop[3], ladderNormal[3];
		
		// Get normal vector of the ladder.
		GetEntPropVector(this.jumper, Prop_Send, "m_vecLadderNormal", ladderNormal);
		
		// 10 units is the furthest away from the ladder surface you can get while still being on the ladder.
		traceOrigin[0] = this.takeoffOrigin[0] - 10.0 * ladderNormal[0];
		traceOrigin[1] = this.takeoffOrigin[1] - 10.0 * ladderNormal[1];
		traceOrigin[2] = this.takeoffOrigin[2] + 5;
		
		CopyVector(traceOrigin, traceEnd);
		traceEnd[2] = this.takeoffOrigin[2] - 10;
		
		Handle trace = TR_TraceHullFilterEx(traceOrigin, traceEnd, playerMins, playerMaxs, CONTENTS_LADDER, TraceEntityFilterPlayers);
		TR_GetEndPosition(ladderTop, trace);
		if (!TR_DidHit(trace) || FloatAbs(ladderTop[2] - landingHeight - 0.031250) > EPSILON)
		{
			this.Invalidate();
			return false;
		}
		delete trace;
		return true;
	}
	
	void EndBlockDistance()
	{
		if ((this.jump.type == JumpType_LongJump || 
				this.jump.type == JumpType_Bhop || 
				this.jump.type == JumpType_MultiBhop || 
				this.jump.type == JumpType_Ladderhop || 
				this.jump.type == JumpType_WeirdJump)
			 && this.jump.distance >= JS_MIN_BLOCK_DISTANCE)
		{
			this.CalcBlockStats(this.position);
		}
		else if (this.jump.type == JumpType_LadderJump && this.jump.distance >= JS_MIN_LAJ_BLOCK_DISTANCE)
		{
			this.CalcLadderBlockStats(this.position);
		}
	}
	
	void CalcBlockStats(float landingOrigin[3], bool checkOffset = false)
	{
		Handle trace;
		int coordDist, coordDev, distSign;
		float middle[3], startBlock[3], endBlock[3], sweepBoxMin[3], sweepBoxMax[3];
		
		// Get the orientation of the block.
		this.GetCoordOrientation(landingOrigin, this.takeoffOrigin, coordDist, distSign);
		coordDev = !coordDist;
		
		// We can't make measurements from within an entity, so we assume the
		// player had a remotely reasonable edge and that the middle of the jump
		// is not over a block and then start measuring things out from there.
		middle[coordDist] = (this.takeoffOrigin[coordDist] + landingOrigin[coordDist]) / 2;
		middle[coordDev] = (this.takeoffOrigin[coordDev] + landingOrigin[coordDev]) / 2;
		middle[2] = this.takeoffOrigin[2] - 1.0;
		
		// Get the deviation.
		this.jump.deviation = FloatAbs(landingOrigin[coordDev] - this.takeoffOrigin[coordDev]);
		
		// Setup a sweeping line that starts in the middle and tries to search for the smallest
		// block within the deviation of the player.
		sweepBoxMin[coordDist] = 0.0;
		sweepBoxMin[coordDev] = -this.jump.deviation - 16.0;
		sweepBoxMin[2] = 0.0;
		sweepBoxMax[coordDist] = 0.0;
		sweepBoxMax[coordDev] = this.jump.deviation + 16.0;
		sweepBoxMax[2] = 0.0;
		
		// Modify the takeoff and landing origins to line up with the middle and respect
		// the bounding box of the player.
		startBlock[coordDist] = this.takeoffOrigin[coordDist] - distSign * 16.0;
		endBlock[coordDist] = landingOrigin[coordDist] + distSign * 16.0;
		startBlock[coordDev] = middle[coordDev];
		endBlock[coordDev] = middle[coordDev];
		startBlock[2] = middle[2];
		endBlock[2] = middle[2];
		
		// Search for the starting block.
		trace = TR_TraceHullFilterEx(middle, startBlock, sweepBoxMin, sweepBoxMax, MASK_PLAYERSOLID, TraceEntityFilterPlayers);
		TR_GetEndPosition(startBlock, trace);
		if (!TR_DidHit(trace))
		{
			return;
		}
		delete trace;
		
		// Search for the ending block.
		trace = TR_TraceHullFilterEx(middle, endBlock, sweepBoxMin, sweepBoxMax, MASK_PLAYERSOLID, TraceEntityFilterPlayers);
		TR_GetEndPosition(endBlock, trace);
		if (!TR_DidHit(trace))
		{
			return;
		}
		delete trace;
		
		// Make sure the edges of the blocks are parallel.
		if (!this.BlockAreEdgesParallel(startBlock, endBlock, this.jump.deviation + 32.0, coordDist, coordDev))
		{
			return;
		}
		
		// Needed for failstats, but you need the endBlock position for that, so we do it here.
		if (checkOffset)
		{
			endBlock[2] += 1.0;
			if (FloatAbs(this.FindBlockHeight(endBlock, float(distSign), coordDist, 1.0) - landingOrigin[2] - 0.031250) > EPSILON)
			{
				return;
			}
		}
		
		// Calculate distance and edge.
		this.jump.block = RoundFloat(FloatAbs(endBlock[coordDist] - startBlock[coordDist]));
		this.jump.edge = FloatAbs(startBlock[coordDist] - this.takeoffOrigin[coordDist] + 16.0 * distSign);
		
		if (this.jump.block < JS_MIN_BLOCK_DISTANCE)
		{
			this.jump.block = 0;
		}
	}
	
	void CalcLadderBlockStats(float landingOrigin[3], bool checkOffset = false)
	{
		Handle trace;
		int coordDist, coordDev, distSign;
		float sweepBoxMin[3], sweepBoxMax[3], blockPosition[3], ladderPosition[3], normalVector[3], endBlock[3], middle[3];
		
		// Get the orientation of the block.
		this.GetCoordOrientation(landingOrigin, this.takeoffOrigin, coordDist, distSign);
		coordDev = !coordDist;
		
		// Get the deviation.
		this.jump.deviation = FloatAbs(landingOrigin[coordDev] - this.takeoffOrigin[coordDev]);
		
		// Make sure the ladder is aligned.
		GetEntPropVector(this.jumper, Prop_Send, "m_vecLadderNormal", normalVector);
		if (FloatAbs(FloatAbs(normalVector[coordDist]) - 1.0) > EPSILON)
		{
			return;
		}
		
		// Make sure we'll find the block and ladder.
		CopyVector(this.takeoffOrigin, ladderPosition);
		CopyVector(landingOrigin, endBlock);
		endBlock[2] -= 1.0;
		ladderPosition[2] = endBlock[2];
		
		// Setup a line to search for the ladder.
		sweepBoxMin[coordDist] = 0.0;
		sweepBoxMin[coordDev] = -20.0;
		sweepBoxMin[2] = 0.0;
		sweepBoxMax[coordDist] = 0.0;
		sweepBoxMax[coordDev] = 20.0;
		sweepBoxMax[2] = 0.0;
		middle[coordDist] = ladderPosition[coordDist] + distSign * JS_MIN_LAJ_BLOCK_DISTANCE;
		middle[coordDev] = endBlock[coordDev];
		middle[2] = ladderPosition[2];
		
		// Search for the ladder.
		trace = TR_TraceHullFilterEx(ladderPosition, middle, sweepBoxMin, sweepBoxMax, MASK_PLAYERSOLID, TraceEntityFilterPlayers);
		TR_GetEndPosition(ladderPosition, trace);
		if (!TR_DidHit(trace))
		{
			return;
		}
		delete trace;
		
		// Find the block.
		endBlock[coordDist] += distSign * 16.0;
		trace = TR_TraceRayFilterEx(middle, endBlock, MASK_SOLID, RayType_EndPoint, TraceEntityFilterPlayers);
		TR_GetEndPosition(blockPosition, trace);
		TR_GetPlaneNormal(trace, normalVector);
		if (!TR_DidHit(trace) || FloatAbs(FloatAbs(normalVector[coordDist]) - 1.0) > EPSILON)
		{
			return;
		}
		delete trace;
		
		// Needed for failstats, but you need the blockPosition for that, so we do it here.
		if (checkOffset)
		{
			blockPosition[2] += 1.0;
			if (!this.TraceLadderOffset(this.FindBlockHeight(blockPosition, float(distSign), coordDist, 1.0) - 0.031250))
			{
				return;
			}
		}
		
		// Calculate distance and edge.
		this.jump.block = RoundFloat(FloatAbs(blockPosition[coordDist] - ladderPosition[coordDist]));
		this.jump.edge = FloatAbs(this.takeoffOrigin[coordDist] - ladderPosition[coordDist]) - 16.0;
		
		if (this.jump.block < JS_MIN_LAJ_BLOCK_DISTANCE)
		{
			this.jump.block = 0;
		}
	}
	
	bool BlockAreEdgesParallel(const float startBlock[3], const float endBlock[3], float deviation, int coordDist, int coordDev)
	{
		float start[3], end[3], offset;
		
		// We use very short rays to find the blocks where they're supposed to be and use
		// their normals to determine whether they're parallel or not.
		offset = startBlock[coordDist] > endBlock[coordDist] ? 0.1 : -0.1;
		
		// We search for the blocks on both sides of the player, on one of the sides
		// there has to be a valid block.
		start[coordDist] = startBlock[coordDist] - offset;
		start[coordDev] = startBlock[coordDev] - deviation;
		start[2] = startBlock[2];
		
		end[coordDist] = startBlock[coordDist] + offset;
		end[coordDev] = startBlock[coordDev] - deviation;
		end[2] = startBlock[2];
		
		if (this.BlockTraceAligned(start, end, coordDist))
		{
			start[coordDist] = endBlock[coordDist] + offset;
			end[coordDist] = endBlock[coordDist] - offset;
			if (this.BlockTraceAligned(start, end, coordDist))
			{
				return true;
			}
			start[coordDist] = startBlock[coordDist] - offset;
			end[coordDist] = startBlock[coordDist] + offset;
		}
		
		start[coordDev] = startBlock[coordDev] + deviation;
		end[coordDev] = startBlock[coordDev] + deviation;
		
		if (this.BlockTraceAligned(start, end, coordDist))
		{
			start[coordDist] = endBlock[coordDist] + offset;
			end[coordDist] = endBlock[coordDist] - offset;
			if (this.BlockTraceAligned(start, end, coordDist))
			{
				return true;
			}
		}
		
		return false;
	}
	
	// Check if the blocks are aligned to the coordinate system.
	bool BlockTraceAligned(const float origin[3], const float end[3], int coordDist)
	{
		float normalVector[3];
		Handle trace = TR_TraceRayFilterEx(origin, end, MASK_SOLID, RayType_EndPoint, TraceEntityFilterPlayers);
		if (!TR_DidHit(trace))
		{
			delete trace;
			return false;
		}
		TR_GetPlaneNormal(trace, normalVector);
		delete trace;
		return FloatAbs(FloatAbs(normalVector[coordDist]) - 1.0) <= EPSILON;
	}
	
	float FindBlockHeight(const float origin[3], float offset, int coord, float searchArea)
	{
		float block[3], traceStart[3], traceEnd[3], normalVector[3];
		
		// Setup the trace.
		CopyVector(origin, traceStart);
		traceStart[coord] += offset;
		CopyVector(traceStart, traceEnd);
		traceStart[2] += searchArea;
		traceEnd[2] -= searchArea;
		// Find the block height.
		Handle trace = TR_TraceRayFilterEx(traceStart, traceEnd, MASK_PLAYERSOLID, RayType_EndPoint, TraceEntityFilterPlayers);
		TR_GetPlaneNormal(trace, normalVector);
		if (!TR_DidHit(trace) || FloatAbs(normalVector[2] - 1.0) > EPSILON)
		{
			delete trace;
			return -99999999999999999999.0; // Let's hope that's wrong enough
		}
		TR_GetEndPosition(block, trace);
		delete trace;
		
		return block[2];
	}
	
	float CalcDistance()
	{
		float distance = GetVectorHorizontalDistance(this.takeoffOrigin, this.position);
		
		// Check whether the distance is NaN
		if (distance != distance)
		{
			this.Invalidate();
			return distance;
		}
		
		if (this.jump.type != JumpType_LadderJump)
		{
			distance += 32.0;
		}
		return distance;
	}
	
	int DetermineType(bool jumped, bool ladderJump)
	{
		if (entityTouchCount[this.jumper] > 0)
		{
			return JumpType_Invalid;
		}
		else if (ladderJump)
		{
			if (GetGameTickCount() - this.lastJumpTick <= JS_MAX_BHOP_GROUND_TICKS)
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
		else if (this.HitBhop())
		{
			if (FloatAbs(this.jump.offset) < EPSILON) // Check for no offset
			{
				switch (this.jump.type)
				{
					case JumpType_LongJump:return JumpType_Bhop;
					case JumpType_Bhop:return JumpType_MultiBhop;
					case JumpType_MultiBhop:return JumpType_MultiBhop;
					default:return JumpType_Other;
				}
			}
			// Check for weird jump
			else if (this.jump.type == JumpType_Fall && this.ValidWeirdJumpDropDistance())
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
	
	bool HitBhop()
	{
		return Movement_GetTakeoffCmdNum(this.jumper) - Movement_GetLandingCmdNum(this.jumper) <= JS_MAX_BHOP_GROUND_TICKS;
	}
	
	bool ValidWeirdJumpDropDistance()
	{
		if (this.jump.offset < -1 * JS_MAX_WEIRDJUMP_FALL_OFFSET)
		{
			// Don't bother telling them if they fell a very far distance
			if (!GetJumpstatsDisabled(this.jumper) && this.jump.offset >= -2 * JS_MAX_WEIRDJUMP_FALL_OFFSET)
			{
				GOKZ_PrintToChat(this.jumper, true, "%t", "Dropped Too Far (Weird Jump)", -1 * this.jump.offset, JS_MAX_WEIRDJUMP_FALL_OFFSET);
			}
			return false;
		}
		return true;
	}
	
	void Invalidate()
	{
		if (this.jump.type != JumpType_Invalid)
		{
			this.jump.type = JumpType_Invalid;
			Call_OnJumpInvalidated(this.jumper);
		}
	}
	
	void UpdateOnGround()
	{
		// Using Movement_GetTakeoffTick or doing it only in Begin() is unreliable
		// for some reason.
		this.jumpoffTick = GetGameTickCount();
		
		// We want acurate values to measure the first tick
		this.UpdatePose(poseHistory[this.jumper][0]);
	}
}

static JumpTracker jumpTrackers[MAXPLAYERS + 1];



// =====[ EVENTS ]=====

void OnJumpValidated_JumpTracking(int client, bool jumped, bool ladderJump)
{
	if (!validCmd[client])
	{
		return;
	}
	
	// We do not begin the jumpstat here but in OnPlayerRunCmdPost, because at this point
	// GOKZ_GetTakeoffSpeed does not have the correct value yet. We need this value to
	// ensure proper measurement of the first tick's sync, gain and loss, though.
	// Both events happen during the same tick, so we do not lose any measurements.
	beginJumpstat[client] = true;
	jumpTrackers[client].Reset(jumped, ladderJump);
}

void OnStartTouchGround_JumpTracking(int client)
{
	jumpTrackers[client].End();
	//EndFailstatAlways(client);
}

void OnPlayerRunCmd_JumpTracking(int client, int buttons)
{
	if (!IsPlayerAlive(client))
	{
		return;
	}
	
	// Don't bother checking if player is already in air and jumpstat is already invalid
	if (Movement_GetOnGround(client) || jumpTrackers[client].jump.type != JumpType_Invalid)
	{
		UpdateValidCmd(client, buttons);
	}
}

public void OnPlayerRunCmdPost_JumpTracking(int client, int cmdnum)
{
	if (!IsPlayerAlive(client))
	{
		return;
	}
	
	if (!Movement_GetOnGround(client))
	{
		// First tick is done when the jumpstat begins to ensure it is measured
		if (beginJumpstat[client])
		{
			beginJumpstat[client] = false;
			jumpTrackers[client].Begin();
		}
		else if (jumpTrackers[client].jump.type != JumpType_Invalid)
		{
			jumpTrackers[client].Update();
		}
		//UpdateFailstatsAlways(client);
	}
	
	if (Movement_GetOnGround(client) || Movement_GetMovetype(client) == MOVETYPE_LADDER)
	{
		jumpTrackers[client].UpdateOnGround();
	}
	
	// We always have to track this, no matter if in the air or not
	jumpTrackers[client].UpdateWRelease();
}

void OnStartTouch_JumpTracking(int client)
{
	entityTouchCount[client]++;
	if (!Movement_GetOnGround(client))
	{
		jumpTrackers[client].Invalidate();
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
		jumpTrackers[client].Invalidate();
	}
}

// TODO Why?
void OnJumpInvalidated_JumpTracking(int client)
{
	jumpTrackers[client].Invalidate();
}

void OnOptionChanged_JumpTracking(int client, const char[] option)
{
	if (StrEqual(option, gC_CoreOptionNames[Option_Mode]))
	{
		jumpTrackers[client].Invalidate();
	}
}

void OnClientPutInServer_JumpTracking(int client)
{
	entityTouchCount[client] = 0;
	jumpTrackers[client].Init(client);
}

void InvalidateJumpstat(int client)
{
	jumpTrackers[client].Invalidate();
}



// =====[ CHECKS ]=====

static void UpdateValidCmd(int client, int buttons)
{
	if (!CheckGravity(client)
		 || !CheckBaseVelocity(client)
		 || !CheckInWater(client)
		 || !CheckTurnButtons(buttons))
	{
		InvalidateJumpstat(client);
		validCmd[client] = false;
	}
	else
	{
		validCmd[client] = true;
	}
}

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

static bool CheckTurnButtons(int buttons)
{
	// Don't allow +left or +right turns binds
	return !(buttons & (IN_LEFT | IN_RIGHT));
}



// =====[ HELPER FUNCTIONS ]=====


float GetStrafeSync(Jump jump, int strafe)
{
	if (strafe < JS_MAX_TRACKED_STRAFES)
	{
		return float(jump.strafes_gainTicks[strafe]) 
			 / float(jump.strafes_ticks[strafe])
			 * 100.0;
	}
	else
	{
		return 0.0;
	}
}

float GetStrafeAirtime(Jump jump, int strafe)
{
	if (strafe < JS_MAX_TRACKED_STRAFES)
	{
		return float(jump.strafes_ticks[strafe]) 
			 / float(jump.durationTicks)
			 * 100.0;
	}
	else
	{
		return 0.0;
	}
}

/*
static void UpdateFailstatsAlways(int client)
{
	failstatListIndex[client] = (failstatListIndex[client] + 1) % JS_FAILSTATS_MAX_TRACKED_TICKS;
	Movement_GetOrigin(client, failstatPosList[client][failstatListIndex[client]]);
	Movement_GetVelocity(client, failstatVelList[client][failstatListIndex[client]]);
}

void OnTeleport_FailstatAlways(int client)
{
	// Prevent TP shenanigans that would trigger failstats
	jumpTypeLast[client] = JumpType_Invalid;
	
	if (GOKZ_JS_GetOption(client, JSOption_FailstatsAlways) == JSToggleOption_Enabled &&
		GetBlockDistance(client) == 0)
	{
		FailstatAlways(client);
	}
}

static void EndFailstatAlways(int client)
{
	if (GOKZ_JS_GetOption(client, JSOption_FailstatsAlways) == JSToggleOption_Disabled ||
		GetBlockDistance(client) > 0)
	{
		return;
	}

	float origin[3], takeoff[3];
	
	Movement_GetOrigin(client, origin);
	Movement_GetTakeoffOrigin(client, takeoff);
	
	if (origin[2] < takeoff[2] - EPSILON)
	{
		FailstatAlways(client);
	}
}

static void FailstatAlways(int client)
{
	float takeoffOrigin[3], takeoffOrientation[3], origin[3], orientation[3], tracePos[3], traceEnd[3];
	float edge;
	Handle trace;
	
	if (Movement_GetMovetype(client) != MOVETYPE_WALK)
	{
		return;
	}
	
	// Get takeoff and current positions and orientations
	Movement_GetOrigin(client, origin);
	Movement_GetEyeAngles(client, orientation);
	GetAngleVectors(orientation, orientation, NULL_VECTOR, NULL_VECTOR);
	Movement_GetTakeoffOrigin(client, takeoffOrigin);
	Movement_GetTakeoffVelocity(client, takeoffOrientation);
	
	edge = -1.0;
	
	// Normalize and align the orientation
	FailstatAlignNormalizeVector(orientation);
	FailstatAlignNormalizeVector(takeoffOrientation);
	
	// Make sure we hit the jumpoff block
	takeoffOrigin[2] -= 1.0;
	CopyVector(takeoffOrigin, tracePos);
	
	// Assume that the edge is less than 20 units away
	FailstatAddScaledVectors(tracePos, takeoffOrientation, 20.0);
	
	// Search for the edge
	trace = TR_TraceRayFilterEx(tracePos, takeoffOrigin, MASK_PLAYERSOLID, RayType_EndPoint, TraceEntityFilterPlayers);
	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(tracePos, trace);
		edge = GetVectorHorizontalDistance(tracePos, takeoffOrigin);
	}
	delete trace;
	
	// Assume that the end block is no less than 40 units away
	CopyVector(origin, tracePos);
	FailstatAddScaledVectors(tracePos, orientation, 40.0);
	
	// Assume you hit the block if you're crouched
	trace = TR_TraceHullFilterEx(origin, tracePos, view_as<float>({0.0, 0.0, 0.0}), view_as<float>({0.0, 0.0, 54.0}),
		MASK_PLAYERSOLID, TraceEntityFilterPlayers);
	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(tracePos, trace);
		delete trace;
		
		AddVectors(tracePos, orientation, tracePos);
		
		// Assume you're no more than 54 units (crouch height) below the block
		tracePos[2] = origin[2] + 54.0;
		
		CopyVector(tracePos, traceEnd);
		traceEnd[2] -= 54.0;
		
		// Search for the block
		trace = TR_TraceRayFilterEx(tracePos, traceEnd, MASK_PLAYERSOLID, RayType_EndPoint, TraceEntityFilterPlayers);
		if (TR_DidHit(trace))
		{
			TR_GetEndPosition(tracePos, trace);
			
			// Search for the last tick the player was above the height of the block
			int i;
			for (i = failstatListIndex[client]; i < JS_FAILSTATS_MAX_TRACKED_TICKS; i += 1)
			{
				if (failstatPosList[client][i % JS_FAILSTATS_MAX_TRACKED_TICKS][2] >= tracePos[2])
				{
					break;
				}
			}
			failstatListIndex[client] = i;
			
			// Get the distance the player would have left to the block from when he
			// was at the same height during his jump
			FailstatGetFailOrigin(client, tracePos[2], traceEnd);
			
			Call_OnFailstatAlways(client, FloatAbs(tracePos[0] - traceEnd[0]) - 1.0, FloatAbs(tracePos[1] - traceEnd[1]) - 1.0,
				edge, GetStrafesCurrent(client), GetSyncCurrent(client), GOKZ_GetTakeoffSpeed(client),
				GetMaxSpeedCurrent(client), GetWRelease(client), GetCrouchTicksCurrent(client), GetStrafeTotalWidth(client),
				GetStrafeTotalOverlap(client), GetStrafeTotalDeadair(client));
		}
	}
	delete trace;
}

static void FailstatAlignNormalizeVector(float vec[3])
{
	if (vec[0] > vec[1])
	{
		vec[0] = vec[0] > 0.0 ? 1.0 : -1.0;
		vec[1] = 0.0;
	}
	else
	{
		vec[0] = 0.0;
		vec[1] = vec[1] > 0.0 ? 1.0 : -1.0;
	}
}

static void FailstatAddScaledVectors(float dest[3], const float src[3], float scale)
{
	dest[0] = scale * src[0];
	dest[1] = scale * src[1];
	dest[2] = scale * src[2];
}
*/





