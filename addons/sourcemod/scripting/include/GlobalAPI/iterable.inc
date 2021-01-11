// ================== DOUBLE INCLUDE ========================= //

#if defined _GlobalAPI_Iterable_included_
#endinput
#endif
#define _GlobalAPI_Iterable_included_

// =========================================================== //

#include <json>

// =========================================================== //

/*
	Helper methodmap for JSON_Object arrays
*/
methodmap APIIterable < JSON_Object
{
   /**
 	* Creates a new APIIterable
 	*
 	* @param hItems				JSON_Object array handle
 	* @return					A new APIIterable handle
 	*/
	public APIIterable(JSON_Object hItems)
	{
		if (hItems.HasKey("result"))
		{
			return view_as<APIIterable>(hItems.GetObject("result"));
		}
		return view_as<APIIterable>(hItems);
	}
	
	/*
		Gets count of the items in the array
	*/
	property int Count
	{
		public get() { return this.Length; }
	}
	
   /**
 	* Gets an object from the array by index
 	*
 	* @note						This is an alias to GetObjectIndexed
 	* @param index				Index of the object we want to retrieve
 	* @return					JSON_Object handle to the object retrieved
 	*/
	public JSON_Object GetById(int index)
	{
		return this.GetObjectIndexed(index);
	}
}

// =========================================================== //