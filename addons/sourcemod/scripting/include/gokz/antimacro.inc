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
	AMReason_BhopMacro
};



// =========================  FORWARDS  ========================= //

/**
 * Called when gokz-antimacro suspects a player of cheating.
 *
 * @param client		Client index.
 * @param reason		Reason for suspicion.
 * @param details		Additional details e.g. scroll pattern.
 * @noreturn
 */
forward void GOKZ_AM_OnPlayerSuspected(int client, AMReason reason, const char[] details);



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



// =========================  STOCKS  ========================= //

/**
 * Increment an index, looping back to 0 if the max value is reached.
 *
 * @param index			Current index.
 * @param buffer		Max value of index.
 * @return				Current index incremented, or 0 if max value is reached.
 */
stock int NextIndex(int index, int max)
{
	index++;
	if (index == max)
	{
		return 0;
	}
	return index;
}

/**
 * Reorders an array with current index at the front, and previous 
 * values after, including looping back to the end after reaching
 * the start of the array.
 *
 * @param input			Array to reorder.
 * @param inputSize		Size of input array.
 * @param buffer		Output buffer.
 * @param bufferSize	Size of buffer.
 * @param index			Index of current/most recent value of input array.
 * @noreturn
 */
stock void SortByRecent(const int[] input, int inputSize, int[] buffer, int bufferSize, int index)
{
	int reorderedIndex = 0;
	for (int i = index; reorderedIndex < bufferSize && i >= 0; i--)
	{
		buffer[reorderedIndex] = input[i];
		reorderedIndex++;
	}
	for (int i = inputSize - 1; reorderedIndex < bufferSize && i > index; i--)
	{
		buffer[reorderedIndex] = input[i];
		reorderedIndex++;
	}
}



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
}
#endif