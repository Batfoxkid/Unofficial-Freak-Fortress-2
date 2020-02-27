/*
	Top Module
*/

#if !defined _tf2attributes_included
  #endinput
#endif

#define FF2_TF2ATTRIBUTES

bool TF2Attributes;

void TF2Attributes_Pre()
{
	MarkNativeAsOptional("TF2Attrib_SetByDefIndex");
	MarkNativeAsOptional("TF2Attrib_RemoveByDefIndex");
}

void TF2Attributes_Setup()
{
	TF2Attributes = LibraryExists("tf2attributes");
}