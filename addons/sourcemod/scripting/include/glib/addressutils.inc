#if defined _addressutils_included
#endinput
#endif
#define _addressutils_included

methodmap AddressBase
{
	property Address Address
	{
		public get() { return view_as<Address>(this); }
	}
}

//-==Operator overloadings
stock Address operator+(Address l, int r)
{
	return l + view_as<Address>(r);
}

stock Address operator+(int l, Address r)
{
	return view_as<Address>(l) + r;
}

stock Address operator-(Address l, int r)
{
	return l - view_as<Address>(r);
}

stock Address operator-(int l, Address r)
{
	return view_as<Address>(l) - r;
}

stock Address operator*(Address l, int r)
{
	return l * view_as<Address>(r);
}

stock Address operator*(int l, Address r)
{
	return view_as<Address>(l) * r;
}

stock Address operator/(Address l, int r)
{
	return l / view_as<Address>(r);
}

stock Address operator/(int l, Address r)
{
	return view_as<Address>(l) / r;
}
//Operator overloadings==-