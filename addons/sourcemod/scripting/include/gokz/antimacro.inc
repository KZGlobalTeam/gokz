/* 	
	GOKZ Antimacro Include File
	
	Website: https://bitbucket.org/kztimerglobalteam/gokz
*/

#if defined _gokz_antimacro_included_
#endinput
#endif
#define _gokz_antimacro_included_



// =========================  ENUMERATIONS  ========================= //

enum AMReason
{
	AMReason_BhopMacro, 
	AMReason_BhopHack
};



// =========================  FORWARDS  ========================= //

/**
 * Called when gokz-antimacro suspects a player of cheating.
 *
 * @param client		Client index.
 * @param reason		Reason for suspicion.
 * @param notes			Additional reasoning, description etc.
 * @param stats			Data supporting the suspicion e.g. scroll pattern.
 * @noreturn
 */
forward void GOKZ_AM_OnPlayerSuspected(int client, AMReason reason, const char[] notes, const char[] stats);



// =========================  NATIVES  ========================= //

/**
 * Gets the number of recent bhop samples available for the player.
 *
 * @param client		Client index.
 * @return				Number of bhop samples available.
 */
native int GOKZ_AM_GetSampleSize(int client);

/**
 * Gets whether the player hit a perfect bhop for a number of 
 * recent bhops. Buffer must be large enough to fit the sample
 * size.
 *
 * @param client		Client index.
 * @param buffer		Buffer for perfect bhop booleans, with the first element being the most recent bhop.
 * @param sampleSize	Maximum recent bhop samples.
 * @return				Number of bhop samples.
 */
native int GOKZ_AM_GetHitPerf(int client, bool[] buffer, int sampleSize);

/**
 * Gets the player's number of perfect bhops out of a sample 
 * size of bhops.
 *
 * @param client		Client index.
 * @param sampleSize	Maximum recent bhop samples to include in calculation.
 * @return				Player's number of perfect bhops.
 */
native int GOKZ_AM_GetPerfCount(int client, int sampleSize);

/**
 * Gets the player's ratio of perfect bhops to normal bhops.
 *
 * @param client		Client index.
 * @param sampleSize	Maximum recent bhop samples to include in calculation.
 * @return				Player's ratio of perfect bhops to normal bhops.
 */
native float GOKZ_AM_GetPerfRatio(int client, int sampleSize);

/**
 * Gets the player's jump input counts for a number of recent 
 * bhops. Buffer must be large enough to fit the sample size.
 *
 * @param client		Client index.
 * @param buffer		Buffer for jump input counts, with the first element being the most recent bhop.
 * @param sampleSize	Maximum recent bhop samples.
 * @return				Number of bhop samples.
 */
native int GOKZ_AM_GetJumpInputs(int client, int[] buffer, int sampleSize);

/**
 * Gets the player's average number of jump inputs for a number 
 * of recent bhops.
 *
 * @param client		Client index.
 * @param sampleSize	Maximum recent bhop samples to include in calculation.
 * @return				Player's average number of jump inputs.
 */
native float GOKZ_AM_GetAverageJumpInputs(int client, int sampleSize);

/**
 * Gets the player's jump input counts prior to a number of recent 
 * bhops. Buffer must be large enough to fit the sample size. 
 * Includes the jump input that resulted in the jump.
 *
 * @param client		Client index.
 * @param buffer		Buffer for jump input counts, with the first element being the most recent bhop.
 * @param sampleSize	Maximum recent bhop samples.
 * @return				Number of bhop samples.
 */
native int GOKZ_AM_GetPreJumpInputs(int client, int[] buffer, int sampleSize);

/**
 * Gets the player's jump input counts after a number of recent 
 * bhops. Buffer must be large enough to fit the sample size. 
 * Excludes the jump input that resulted in the jump.
 *
 * @param client		Client index.
 * @param buffer		Buffer for jump input counts, with the first element being the most recent bhop.
 * @param sampleSize	Maximum recent bhop samples.
 * @return				Number of bhop samples.
 */
native int GOKZ_AM_GetPostJumpInputs(int client, int[] buffer, int sampleSize);



// =========================  DEPENDENCY  ========================= //

public SharedPlugin __pl_gokz_antimacro = 
{
	name = "gokz-antimacro", 
	file = "gokz-antimacro.smx", 
	#if defined REQUIRE_PLUGIN
	required = 1, 
	#else
	required = 0, 
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_gokz_antimacro_SetNTVOptional()
{
	MarkNativeAsOptional("GOKZ_AM_GetSampleSize");
	MarkNativeAsOptional("GOKZ_AM_GetHitPerf");
	MarkNativeAsOptional("GOKZ_AM_GetPerfCount");
	MarkNativeAsOptional("GOKZ_AM_GetPerfRatio");
	MarkNativeAsOptional("GOKZ_AM_GetJumpInputs");
	MarkNativeAsOptional("GOKZ_AM_GetAverageJumpInputs");
	MarkNativeAsOptional("GOKZ_AM_GetPreJumpInputs");
	MarkNativeAsOptional("GOKZ_AM_GetPostJumpInputs");
}
#endif