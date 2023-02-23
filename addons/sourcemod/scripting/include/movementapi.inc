/*
	MovementAPI Plugin Include

	Website: https://github.com/danzayau/MovementAPI
*/

#if defined _movementapi_included_
  #endinput
#endif
#define _movementapi_included_

#include <movement>



/*
	Terminology

	Takeoff
	Becoming airborne, including jumping, falling, getting off a ladder and leaving noclip.

	Landing
	Leaving the air, including landing on the ground, grabbing a ladder and entering noclip.

	Perfect Bunnyhop (Perf)
	When the player has jumped in the tick after landing and keeps their speed.

 	Duckbug/Crouchbug
	When the player sucessfully lands due to uncrouching from mid air and not by falling 
	down. This causes no stamina loss or fall damage upon landing.

	Jumpbug
 	This is achieved by duckbugging and jumping at the same time. The player is never seen 
	as 'on ground' when bunnyhopping from a tick by tick perspective. A jumpbug inherits 
	the same behavior as a duckbug/crouchbug, along with its effects such as maintaining 
	speed due to no stamina loss.

	Distbug
	Landing behavior varies depending on whether the player lands close to the edge of a 
	block or not:

    1. If the player lands close to the edge of a block, this causes the jump duration to 
	be one tick longer and the player can "slide" on the ground during the landing tick, 
	using the position post-tick as landing position becomes inaccurate.

    2. On the other hand, if the player does not land close to the edge, the player will 
	be considered on the ground one tick earlier, using this position as landing position 
	is not accurate as the player has yet to be fully on the ground.
 
    In scenario 1, GetNobugLandingOrigin calculates the correct landing position of the 
	player before the sliding effect takes effect.

    In scenario 2, GetNobugLandingOrigin attempts to extrapolate the player's fully on 
	ground position to make landing positions consistent across scenarios.
*/



// =====[ FORWARDS ]=====

/**
 * Called when a player's movetype changes.
 *
 * @param client		Client index.
 * @param oldMovetype	Player's old movetype.
 * @param newMovetype	Player's new movetype.
 */
forward void Movement_OnChangeMovetype(int client, MoveType oldMovetype, MoveType newMovetype);

/**
 * Called when a player touches the ground.
 *
 * @param client		Client index.
 */
forward void Movement_OnStartTouchGround(int client);

/**
 * Called when a player leaves the ground.
 *
 * @param client		Client index.
 * @param jumped		Whether player jumped to leave ground.
 * @param ladderJump	Whether player jumped from a ladder.
 * @param jumpbug		Whether player performed a jumpbug.
 */
forward void Movement_OnStopTouchGround(int client, bool jumped, bool ladderJump, bool jumpbug);

/**
 * Called when a player starts ducking.
 *
 * @param client		Client index.
 */
forward void Movement_OnStartDucking(int client);

/**
 * Called when a player stops ducking.
 *
 * @param client		Client index.
 */
forward void Movement_OnStopDucking(int client);

/**
 * Called when a player jumps (player_jump event), including 'jumpbugs'.
 * Setting velocity when this is called may not be effective.
 *
 * @param client		Client index.
 * @param jumpbug		Whether player 'jumpbugged'.
 */
forward void Movement_OnPlayerJump(int client, bool jumpbug);

/**
 * Called before PlayerMove movement function is called.
 * Modifying origin or velocity parameters will change player's origin and velocity accordingly.
 *
 * @param client       Client index.
 * @param origin       Player origin.
 * @param velocity     Player velocity.
 * @return             Plugin_Changed if origin or velocity is changed, Plugin_Continue otherwise.
 */
forward Action Movement_OnPlayerMovePre(int client, float origin[3], float velocity[3]);

/**
 * Called after PlayerMove movement function is called.
 * Modifying origin or velocity parameters will change player's origin and velocity accordingly.
 *
 * @param client       Client index.
 * @param origin       Player origin.
 * @param velocity     Player velocity.
 * @return             Plugin_Changed if origin or velocity is changed, Plugin_Continue otherwise.
 */
forward Action Movement_OnPlayerMovePost(int client, float origin[3], float velocity[3]);

/**
 * Called before Duck movement function is called.
 * Modifying origin or velocity parameters will change player's origin and velocity accordingly.
 *
 * @param client       Client index.
 * @param origin       Player origin.
 * @param velocity     Player velocity.
 * @return             Plugin_Changed if origin or velocity is changed, Plugin_Continue otherwise.
 */
forward Action Movement_OnDuckPre(int client, float origin[3], float velocity[3]);

/**
 * Called after Duck movement function is called.
 * Modifying origin or velocity parameters will change player's origin and velocity accordingly.
 *
 * @param client       Client index.
 * @param origin       Player origin.
 * @param velocity     Player velocity.
 * @return             Plugin_Changed if origin or velocity is changed, Plugin_Continue otherwise.
 */
forward Action Movement_OnDuckPost(int client, float origin[3], float velocity[3]);

/**
 * Called before LadderMove movement function is called.
 * Modifying origin or velocity parameters will change player's origin and velocity accordingly.
 *
 * @param client       Client index.
 * @param origin       Player origin.
 * @param velocity     Player velocity.
 * @return             Plugin_Changed if origin or velocity is changed, Plugin_Continue otherwise.
 */
forward Action Movement_OnLadderMovePre(int client, float origin[3], float velocity[3]);

/**
 * Called after LadderMove movement function is called.
 * Modifying origin or velocity parameters will change player's origin and velocity accordingly.
 *
 * @param client       Client index.
 * @param origin       Player origin.
 * @param velocity     Player velocity.
 * @return             Plugin_Changed if origin or velocity is changed, Plugin_Continue otherwise.
 */
forward Action Movement_OnLadderMovePost(int client, float origin[3], float velocity[3]);

/**
 * Called before FullLadderMove movement function is called.
 * Modifying origin or velocity parameters will change player's origin and velocity accordingly.
 *
 * @param client       Client index.
 * @param origin       Player origin.
 * @param velocity     Player velocity.
 * @return             Plugin_Changed if origin or velocity is changed, Plugin_Continue otherwise.
 */
forward Action Movement_OnFullLadderMovePre(int client, float origin[3], float velocity[3]);

/**
 * Called after FullLadderMove movement function is called.
 * Modifying origin or velocity parameters will change player's origin and velocity accordingly.
 *
 * @param client       Client index.
 * @param origin       Player origin.
 * @param velocity     Player velocity.
 * @return             Plugin_Changed if origin or velocity is changed, Plugin_Continue otherwise.
 */
forward Action Movement_OnFullLadderMovePost(int client, float origin[3], float velocity[3]);

/**
 * Called after the player jumps, but before jumping stamina is applied and takeoff variables are not set yet.
 * Modifying origin or velocity parameters will change player's origin and velocity accordingly.
 *
 * @param client       Client index.
 * @param origin       Player origin.
 * @param velocity     Player velocity.
 * @return             Plugin_Changed if origin or velocity is changed, Plugin_Continue otherwise.
 */
forward Action Movement_OnJumpPre(int client, float origin[3], float velocity[3]);

/**
 * Called after the player jumps and after jumping stamina is applied and takeoff variables are already set here.
 * Modifying origin or velocity parameters will change player's origin and velocity accordingly.
 *
 * @param client       Client index.
 * @param origin       Player origin.
 * @param velocity     Player velocity.
 * @return             Plugin_Changed if origin or velocity is changed, Plugin_Continue otherwise.
 */
forward Action Movement_OnJumpPost(int client, float origin[3], float velocity[3]);

/**
 * Called before AirAccelerate movement function is called.
 * Modifying origin or velocity parameters will change player's origin and velocity accordingly.
 *
 * @param client       Client index.
 * @param origin       Player origin.
 * @param velocity     Player velocity.
 * @return             Plugin_Changed if origin or velocity is changed, Plugin_Continue otherwise.
 */
forward Action Movement_OnAirAcceleratePre(int client, float origin[3], float velocity[3]);

/**
 * Called after AirAccelerate movement function is called.
 * Modifying origin or velocity parameters will change player's origin and velocity accordingly.
 *
 * @param client       Client index.
 * @param origin       Player origin.
 * @param velocity     Player velocity.
 * @return             Plugin_Changed if origin or velocity is changed, Plugin_Continue otherwise.
 */
forward Action Movement_OnAirAcceleratePost(int client, float origin[3], float velocity[3]);

/**
 * Called before WalkMove movement function is called.
 * Modifying origin or velocity parameters will change player's origin and velocity accordingly.
 *
 * @param client       Client index.
 * @param origin       Player origin.
 * @param velocity     Player velocity.
 * @return             Plugin_Changed if origin or velocity is changed, Plugin_Continue otherwise.
 */
forward Action Movement_OnWalkMovePre(int client, float origin[3], float velocity[3]);

/**
 * Called after WalkMove movement function is called.
 * Modifying origin or velocity parameters will change player's origin and velocity accordingly.
 *
 * @param client       Client index.
 * @param origin       Player origin.
 * @param velocity     Player velocity.
 * @return             Plugin_Changed if origin or velocity is changed, Plugin_Continue otherwise.
 */
forward Action Movement_OnWalkMovePost(int client, float origin[3], float velocity[3]);

/**
 * Called before CategorizePosition movement function is called.
 * Modifying origin or velocity parameters will change player's origin and velocity accordingly.
 *
 * @param client       Client index.
 * @param origin       Player origin.
 * @param velocity     Player velocity.
 * @return             Plugin_Changed if origin or velocity is changed, Plugin_Continue otherwise.
 */
forward Action Movement_OnCategorizePositionPre(int client, float origin[3], float velocity[3]);

/**
 * Called after CategorizePosition movement function is called.
 * Modifying origin or velocity parameters will change player's origin and velocity accordingly.
 *
 * @param client       Client index.
 * @param origin       Player origin.
 * @param velocity     Player velocity.
 * @return             Plugin_Changed if origin or velocity is changed, Plugin_Continue otherwise.
 */
forward Action Movement_OnCategorizePositionPost(int client, float origin[3], float velocity[3]);

// =====[ NATIVES ]=====

/**
 * Gets whether a player's last takeoff was a jump.
 *
 * @param client		Client index.
 * @return				Whether player's last takeoff was a jump.
 */
native bool Movement_GetJumped(int client);

/**
 * Gets whether a player's last takeoff was a perfect bunnyhop.
 *
 * @param client		Client index.
 * @return				Whether player's last takeoff was a perfect bunnyhop.
 */
native bool Movement_GetHitPerf(int client);

/**
 * Gets a player's origin at the time of their last takeoff.
 *
 * @param client		Client index.
 * @param result		Resultant vector.
 */
native void Movement_GetTakeoffOrigin(int client, float result[3]);

/**
 * Gets a player's velocity at the time of their last takeoff.
 *
 * If sv_enablebunnyhopping is 0, CS:GO may adjust the player's 
 * velocity after the takeoff velocity has already been measured.
 *
 * @param client		Client index.
 * @param result		Resultant vector.
 */
native void Movement_GetTakeoffVelocity(int client, float result[3]);

/**
 * Gets a player's horizontal speed at the time of their last takeoff.
 *
 * If sv_enablebunnyhopping is 0, CS:GO may adjust the player's 
 * velocity after the takeoff velocity has already been measured.
 *
 * @param client		Client index.
 * @return				Player's last takeoff speed.
 */
native float Movement_GetTakeoffSpeed(int client);

/**
 * Gets a player's 'tickcount' at the time of their last takeoff.
 *
 * @param client		Client index.
 * @return				Player's last takeoff 'tickcount'.
 */
native int Movement_GetTakeoffTick(int client);

/**
 * Gets a player's 'cmdnum' at the time of their last takeoff.
 *
 * @param client		Client index.
 * @return				Player's last takeoff 'cmdnum'.
 */
native int Movement_GetTakeoffCmdNum(int client);

/**
 * Gets a player's origin at the time of their last landing with the distbug fixed.
 *
 * @param client		Client index.
 * @param result		Resultant vector.
 */
native void Movement_GetNobugLandingOrigin(int client, float result[3]);

/**
 * Gets a player's origin at the time of their last landing.
 *
 * @param client		Client index.
 * @param result		Resultant vector.
 */
native void Movement_GetLandingOrigin(int client, float result[3]);

/**
 * Gets a player's velocity at the time of their last landing.
 *
 * @param client		Client index.
 * @param result		Resultant vector.
 */
native void Movement_GetLandingVelocity(int client, float result[3]);

/**
 * Gets a player's horizontal speed at the time of their last landing.
 *
 * @param client		Client index.
 * @return				Last landing speed of the player (horizontal).
 */
native float Movement_GetLandingSpeed(int client);

/**
 * Gets a player's 'tickcount' at the time of their last landing.
 *
 * @param client		Client index.
 * @return				Player's last landing 'tickcount'.
 */
native int Movement_GetLandingTick(int client);

/**
 * Gets a player's 'cmdnum' at the time of their last landing.
 *
 * @param client		Client index.
 * @return				Player's last landing 'cmdnum'.
 */
native int Movement_GetLandingCmdNum(int client);

/**
 * Gets whether a player is turning their aim horizontally.
 *
 * @param client		Client index.
 * @return				Whether player is turning their aim horizontally.
 */
native bool Movement_GetTurning(int client);

/**
 * Gets whether a player is turning their aim left.
 *
 * @param client		Client index.
 * @return				Whether player is turning their aim left.
 */
native bool Movement_GetTurningLeft(int client);

/**
 * Gets whether a player is turning their aim right.
 *
 * @param client		Client index.
 * @return				Whether player is turning their aim right.
 */
native bool Movement_GetTurningRight(int client);

/**
 * Gets result of CCSPlayer::GetPlayerMaxSpeed(client), which
 * is the player's max speed as limited by their weapon.
 *
 * @param client		Client index.
 * @return				Player's max speed as limited by their weapon.
 */
native float Movement_GetMaxSpeed(int client);

/**
 * Gets whether a player duckbugged on this tick.
 *
 * @param client		Client index.
 * @return     			Whether a player duckbugged on this tick.
 */
native bool Movement_GetDuckbugged(int client);

/**
 * Gets whether a player jumpbugged on this tick.
 *
 * @param client		Client index.
 * @return     			Whether a player jumpbugged on this tick.
 */
native bool Movement_GetJumpbugged(int client);

/**
 * Get the player's origin during movement processing.
 *
 * @param client     Client index.
 * @param result     Resultant vector.
 */
native void Movement_GetProcessingOrigin(int client, float result[3]);

/**
 * Get the player's velocity during movement processing.
 *
 * @param client     Param description
 * @param result     Resultant vector.
 */
native void Movement_GetProcessingVelocity(int client, float result[3]);

/**
 * Set the player's takeoff origin.
 *
 * @param client     Client index.
 * @param origin	 Desired origin.
 */
native void Movement_SetTakeoffOrigin(int client, float origin[3]);

/**
 * Set the player's takeoff velocity.
 *
 * @param client     Client index.
 * @param origin	 Desired velocity.
 */
native void Movement_SetTakeoffVelocity(int client, float velocity[3]);

/**
 * Set the player's landing origin.
 *
 * @param client     Client index.
 * @param origin	 Desired origin.
 */
native void Movement_SetLandingOrigin(int client, float origin[3]);

/**
 * Set the player's landing velocity.
 *
 * @param client     Client index.
 * @param origin	 Desired velocity.
 */
native void Movement_SetLandingVelocity(int client, float velocity[3]);

// =====[ METHODMAP ]=====

methodmap MovementAPIPlayer < MovementPlayer {
	
	public MovementAPIPlayer(int client) {
		return view_as<MovementAPIPlayer>(MovementPlayer(client));
	}
	
	property bool Jumped {
		public get() {
			return Movement_GetJumped(this.ID);
		}
	}
	
	property bool HitPerf {
		public get() {
			return Movement_GetHitPerf(this.ID);
		}
	}
	
	public void GetTakeoffOrigin(float buffer[3]) {
		Movement_GetTakeoffOrigin(this.ID, buffer);
	}
	
	public void GetTakeoffVelocity(float buffer[3]) {
		Movement_GetTakeoffVelocity(this.ID, buffer);
	}

	public void SetTakeoffOrigin(float buffer[3])
	{
		Movement_SetTakeoffOrigin(this.ID, buffer);
	}
	
	public void SetTakeoffVelocity(float buffer[3])
	{
		Movement_SetTakeoffVelocity(this.ID, buffer);
	}
	
	property float TakeoffSpeed {
		public get() {
			return Movement_GetTakeoffSpeed(this.ID);
		}
	}
	
	property int TakeoffTick {
		public get() {
			return Movement_GetTakeoffTick(this.ID);
		}
	}
	
	property int TakeoffCmdNum {
		public get() {
			return Movement_GetTakeoffCmdNum(this.ID);
		}
	}
	
	public void GetLandingOrigin(float buffer[3]) {
		Movement_GetLandingOrigin(this.ID, buffer);
	}
	
	public void GetLandingVelocity(float buffer[3]) {
		Movement_GetLandingVelocity(this.ID, buffer);
	}
	
	public void SetLandingOrigin(float buffer[3])
	{
		Movement_SetLandingOrigin(this.ID, buffer);
	}
	
	public void SetLandingVelocity(float buffer[3])
	{
		Movement_SetLandingVelocity(this.ID, buffer);
	}
	
	property float LandingSpeed {
		public get() {
			return Movement_GetLandingSpeed(this.ID);
		}
	}
	
	property int LandingTick {
		public get() {
			return Movement_GetLandingTick(this.ID);
		}
	}
	
	property int LandingCmdNum {
		public get() {
			return Movement_GetLandingCmdNum(this.ID);
		}
	}
	
	property bool Turning {
		public get() {
			return Movement_GetTurning(this.ID);
		}
	}
	
	property bool TurningLeft {
		public get() {
			return Movement_GetTurningLeft(this.ID);
		}
	}
	
	property bool TurningRight {
		public get() {
			return Movement_GetTurningRight(this.ID);
		}
	}
	
	property float MaxSpeed {
		public get() {
			return Movement_GetMaxSpeed(this.ID);
		}
	}

	public void GetProcessingVelocity(float buffer[3])
	{
		Movement_GetProcessingVelocity(this.ID, buffer);
	}
	
	public void GetProcessingOrigin(float buffer[3])
	{
		Movement_GetProcessingOrigin(this.ID, buffer);
	}
}



// =====[ DEPENDENCY ]=====

public SharedPlugin __pl_movementapi = 
{
	name = "movementapi", 
	file = "movementapi.smx", 
	#if defined REQUIRE_PLUGIN
	required = 1, 
	#else
	required = 0, 
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_movementapi_SetNTVOptional()
{
	MarkNativeAsOptional("Movement_GetJumped");
	MarkNativeAsOptional("Movement_GetHitPerf");
	MarkNativeAsOptional("Movement_GetTakeoffOrigin");
	MarkNativeAsOptional("Movement_GetTakeoffVelocity");
	MarkNativeAsOptional("Movement_GetTakeoffSpeed");
	MarkNativeAsOptional("Movement_GetTakeoffTick");
	MarkNativeAsOptional("Movement_GetTakeoffCmdNum");
	MarkNativeAsOptional("Movement_GetLandingOrigin");
	MarkNativeAsOptional("Movement_GetLandingVelocity");
	MarkNativeAsOptional("Movement_GetLandingSpeed");
	MarkNativeAsOptional("Movement_GetLandingTick");
	MarkNativeAsOptional("Movement_GetLandingCmdNum");
	MarkNativeAsOptional("Movement_GetTurning");
	MarkNativeAsOptional("Movement_GetTurningLeft");
	MarkNativeAsOptional("Movement_GetTurningRight");
	MarkNativeAsOptional("Movement_GetMaxSpeed");
	MarkNativeAsOptional("Movement_GetProcessingOrigin");
	MarkNativeAsOptional("Movement_GetProcessingVelocity");
	MarkNativeAsOptional("Movement_SetTakeoffOrigin");
	MarkNativeAsOptional("Movement_SetTakeoffVelocity");
	MarkNativeAsOptional("Movement_SetLandingOrigin");
	MarkNativeAsOptional("Movement_SetLandingVelocity");
}
#endif