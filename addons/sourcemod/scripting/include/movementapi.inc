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

	Jumpbug
	When the player is never seen as 'on ground' when bunnyhopping. This is achievable by 
	uncrouching and jumping at the same time. A jumpbug results in unusual behaviour such
	as maintaining horizontal speed and not receiving fall damage.

	Distbug
	A distbug can occur when a player lands close to the edge of a block. When calculating
	the landing position, the source engine will only consider either the horizontal or
	vertical speed on the very last tick, but not both. The GetNobugLandingOrigin native
	calculates the correct landing position of the player based on his actual trajectory
	using all components of the velocity instead.
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
 */
forward void Movement_OnStopTouchGround(int client, bool jumped);

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
 * If the player 'jumpbugs', then they will not call Movement_OnStopTouchGround
 * because their FL_ONGROUND flag was not detected as true prior to the jump.
 *
 * @param client		Client index.
 * @param jumpbug		Whether player 'jumpbugged'.
 */
forward void Movement_OnPlayerJump(int client, bool jumpbug);



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
}
#endif
