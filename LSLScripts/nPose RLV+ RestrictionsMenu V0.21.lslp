//LICENSE:
//
//This script and the nPose scripts are licensed under the GPLv2
//(http://www.gnu.org/licenses/gpl-2.0.txt), with the following addendum:
//
//The nPose scripts are free to be copied, modified, and redistributed, subject
//to the following conditions:
//    - If you distribute the nPose scripts, you must leave them full perms.
//    - If you modify the nPose scripts and distribute the modifications, you
//      must also make your modifications full perms.
//
//"Full perms" means having the modify, copy, and transfer permissions enabled in
//Second Life and/or other virtual world platforms derived from Second Life (such
//as OpenSim).  If the platform should allow more fine-grained permissions, then
//"full perms" will mean the most permissive possible set of permissions allowed
//by the platform.

// linkMessage Numbers from -8000 to -8050 are assigned to the RLV+ Plugins
// linkMessage Numbers from -8000 to -8009 are assigned to the RLV+ Core Plugin
// linkMessage Numbers from -8010 to -8019 are assigned to the RLV+ RestrictionsMenu Plugin
// linkMessage Numbers from -8020 to -8047 are reserved for later use
// linkMessage Numbers from -8048 to -8049 are assigned to universal purposes

string PLUGIN_NAME="RLV_RESTRICTIONS_MENU";

// --- constants and configuration
integer DIALOG               = -900; // start dialog
integer DIALOG_RESPONSE      = -901; // eval dialog response
integer UPDATE_CURRENT_VICTIM= -237;
//integer OPTIONS              = -240;
integer MEM_USAGE            = 34334;
integer RLV_CORE             = -8000;
integer RLV_RESTRICTIONS_MENU= -8010;
integer PLUGIN_PING          = -8048;
integer PLUGIN_PONG          = -8049;

integer RLV_RELAY_CHANNEL    = -1812221819;

string BACKBTN                    ="^";
string MENU_RLV_RESTRICTIONS_MAIN ="RLVRestrictions";
string MENU_RLV_UNDRESS           ="→Undress";
string MENU_RLV_ATTACHMENTS       ="→Attachments";

// the following rlv restrictions can be controlled with this plugin
list   RLV_RESTRICTIONS = [
	"→Chat/IM",   "sendchat,chatshout,chatnormal,recvchat,recvemote,sendim,startim,recvim",
	"→Inventory", "showinv,viewnote,viewscript,viewtexture,edit,rez,unsharedwear,unsharedunwear",
	"→Touch",     "fartouch,touchall,touchworld,touchattach",
	"→World",     "shownames,showhovertextall,showworldmap,showminimap,showloc",
	"→Debug/Env", "setgroup,setdebug,setenv"
];

list IGNORED_RLV_RESTRICTIONS = [
	"acceptpermission", "detach"//, "unsit", "sittp", "tploc", "tplure", "tplm"
];

list CLOTHING_LAYERS = [
	"gloves", "jacket", "pants", "shirt", "shoes", "skirt", "socks",
	"underpants", "undershirt", "", "", "", "", "alpha", "tattoo"
];

list ATTACHMENT_POINTS = [
	"", "chest", "skull", "left shoulder", "right shoulder", "left hand",
	"right hand", "left foot", "right foot", "spine", "pelvis", "mouth", "chin",
	"left ear", "right ear", "left eyeball", "right eyeball", "nose",
	"r upper arm", "r forearm", "l upper arm", "l forearm", "right hip",
	"r upper leg", "r lower leg", "left hip", "l upper leg", "l lower leg",
	"stomach", "left pec", "right pec", "", "", "", "", "", "", "", "", "neck",
	"root"
];

string PROMPT_VICTIM="Selected Victim: ";
string PROMPT_RESTRICTIONS="Active restrictions are: ";
string NO_RESTRICTIONS="NONE. Victim may be FREE.";
string NEW_LINE="\n";
string NO_VICTIM="NONE";

string PATH_SEPARATOR=":";

// --- global variables

// options

// random channel for RLV responses
integer RlvReplyChannel;
integer RlvReplyChannelClothing;
integer RlvReplyChannelAttachment;
//handles
integer RlvReplyListenHandle;

key MyUniqueId;

string  Path;           // contains dialog path for RLV
key     NPosetoucherID; // who touched me

key VictimKey;  // contains active victim key


// --- functions

debug(list message) {
	llOwnerSay(llGetScriptName() + "\n##########\n#>" + llDumpList2String(message, "\n#>") + "\n##########");
}


string StringReplace( string str, string search, string replace ) {
	return llDumpList2String(
	llParseStringKeepNulls( str, [ search ], [] ), replace );
}

ShowMenu( key targetKey, string prompt, list buttons, string menuPath) {
	if(targetKey) {
		llMessageLinked( LINK_SET, DIALOG,
			(string)targetKey
			+ "|" +
			prompt + "\n" + menuPath + "\n"
			+ "|" +
			(string)0
			+ "|" +
			llDumpList2String( buttons, "`" )
			+ "|" +
			llDumpList2String( [ BACKBTN ], "`" )
			+ "|" +
			menuPath
			, MyUniqueId
		);
	}
}

// send rlv commands to the RLV relay, usable for common format (not ping)
SendToRlvRelay(key victim, string rlvCommand, string identifier) {
	if(!llStringLength(identifier)) {
		identifier=(string)MyUniqueId;
	}
	if(rlvCommand) {
		if(victim) {
			llSay( RLV_RELAY_CHANNEL, identifier + "," + (string)victim + "," + StringReplace(rlvCommand, "%MYKEY%", (string)llGetKey()));
		}
	}
}

QueryRlvGetStatus() {
	// query list of current RLV restrictions
	llListenRemove( RlvReplyListenHandle );
	RlvReplyChannel = 10000 + (integer)llFrand(30000);
	RlvReplyListenHandle = llListen( RlvReplyChannel, "", NULL_KEY, "" );
	SendToRlvRelay( VictimKey, "@getstatus=" + (string)RlvReplyChannel, "");
	// => continue in event listen
}

QueryWornClothes() {
	// query list of current RLV restrictions
	llListenRemove( RlvReplyListenHandle );
	RlvReplyChannelClothing = 10000 + (integer)llFrand(30000);
	RlvReplyListenHandle = llListen( RlvReplyChannelClothing, "", NULL_KEY, "" );
	SendToRlvRelay( VictimKey, "@getoutfit=" + (string)RlvReplyChannelClothing,"");
	// => continue in event listen
}

QueryWornAttachments() {
	// query list of current RLV restrictions
	llListenRemove( RlvReplyListenHandle );
	RlvReplyChannelAttachment = 10000 + (integer)llFrand(30000);
	RlvReplyListenHandle = llListen( RlvReplyChannelAttachment, "", NULL_KEY, "" );
	SendToRlvRelay( VictimKey, "@getattach=" + (string)RlvReplyChannelAttachment,"");
	// => continue in event listen
}


list ParseClothingOrAttachmentLayersWorn( string message, list names ) {
	integer length = llStringLength( message );
	list    layersWorn = [];
	integer i;
	for( i=0; i < length; i+=1 )
	{
		string isWorn = llGetSubString( message, i, i );
		if( isWorn == "1" )
		{
			string layerName = llList2String( names, i );
			if( layerName != "" )
			{
				layersWorn += [ layerName ];
			}
		}
	}
	return layersWorn;
}

string getSelectedVictimPromt() {
	if(VictimKey) {
		return PROMPT_VICTIM + llKey2Name(VictimKey) + NEW_LINE;
	}
	else {
		return PROMPT_VICTIM + NO_VICTIM + NEW_LINE;
	}
}

// --- states

default {
	state_entry() {
		MyUniqueId=llGenerateKey();
		//anounce myself
		llMessageLinked(LINK_SET, PLUGIN_PONG, PLUGIN_NAME, "");
	}

	link_message( integer sender, integer num, string str, key id ) {
		if(num==PLUGIN_PING) {
			if(str==PLUGIN_NAME) {
				llMessageLinked(LINK_SET, PLUGIN_PONG, PLUGIN_NAME, "");
			}
		}
		else if(num==UPDATE_CURRENT_VICTIM) {
			VictimKey=(key)str;
		}
		else if(num==DIALOG_RESPONSE) {
			if(id==MyUniqueId) {
				//its for me
				list params = llParseString2List(str, ["|"], []);
				string selection = llList2String(params, 1);
				Path=llList2String(params, 3);
				NPosetoucherID=(key)llList2String(params, 2);
				list pathparts = llParseString2List( Path, [PATH_SEPARATOR], [] );
				
				//llOwnerSay( "Path: '" + Path + "' Selection: " + selection );
	
				if(selection == BACKBTN) {
					// back button hit
					selection=llList2String(pathparts, -2);
					if(Path == MENU_RLV_RESTRICTIONS_MAIN) {
						//Path is at root menu, remenu RLV CORE
						llMessageLinked(LINK_SET, RLV_CORE, "showMenu,"+(string)NPosetoucherID, "");
						return;
					}
					else if(selection==MENU_RLV_RESTRICTIONS_MAIN) {
						//the menu changed to the Main/Root Menu, show it
						Path=MENU_RLV_RESTRICTIONS_MAIN;
						QueryRlvGetStatus();
						return;
					}
					else {
						//the menu changed to a menu below the Main Menu, correct the path and selection and continue in this event
						pathparts=llDeleteSubList(pathparts, -2, -1);
						Path = llDumpList2String(pathparts, PATH_SEPARATOR);
					}
				}
				if(Path==MENU_RLV_RESTRICTIONS_MAIN) {
					if( selection == MENU_RLV_UNDRESS ) {
						Path += PATH_SEPARATOR + selection;
						QueryWornClothes();
					}
					else if( selection == MENU_RLV_ATTACHMENTS ) {
						Path += PATH_SEPARATOR + selection;
						QueryWornAttachments();
					}
	
					// restriction group menu selected?
					else if( ~llListFindList( RLV_RESTRICTIONS, [ selection ] ) ) {
						Path += PATH_SEPARATOR + selection;
						QueryRlvGetStatus();
					}
					return;
				} // Path == MENU_RLV_MAIN

				else if( Path == MENU_RLV_RESTRICTIONS_MAIN + PATH_SEPARATOR + MENU_RLV_UNDRESS) {
					//undress somthing and reshow the menu
					if(~llListFindList( CLOTHING_LAYERS, [ selection ])) {
						SendToRlvRelay( VictimKey, "@remoutfit:" + selection + "=force", "");
						llSleep( 0.5 );
						QueryWornClothes();
					}
				}
				else if( Path == MENU_RLV_RESTRICTIONS_MAIN + PATH_SEPARATOR + MENU_RLV_ATTACHMENTS) {
					//detach somthing and reshow the menu
					if( ~llListFindList( ATTACHMENT_POINTS, [ selection ] ) ) {
						SendToRlvRelay( VictimKey, "@remattach:" + selection + "=force", "");
						llSleep( 0.5 );
						QueryWornAttachments();
					}
				}
				else {
					if(llGetSubString( selection, 0, 0 ) == "☐") {
						// add RLV restriction
						SendToRlvRelay( VictimKey, "@" + llDeleteSubString( selection, 0, 1 ) + "=n", "");
						QueryRlvGetStatus();
					}
					else if(llGetSubString( selection, 0, 0 ) == "☑") {
						// remove RLV restriction
						SendToRlvRelay( VictimKey, "@" + llDeleteSubString( selection, 0, 1 ) + "=y", "");
						QueryRlvGetStatus();
					}
					else {
						//unknown Menu option
					}
				}
			}
		}
		// end of DIALOG_RESPONSE
		else if( num == RLV_RESTRICTIONS_MENU ) {
			list temp=llParseStringKeepNulls(str,[","], []);
			string cmd=llToLower(llStringTrim(llList2String(temp, 0), STRING_TRIM));
			key target=(key)StringReplace(llStringTrim(llList2String(temp, 1), STRING_TRIM), "%VICTIM%", (string)VictimKey);
			list params=llDeleteSubList(temp, 0, 1);
			
			if(target) {}
			else {
				target=VictimKey;
			}
			
			if(cmd=="showmenu") {
				Path=MENU_RLV_RESTRICTIONS_MAIN;
				NPosetoucherID=target;
				QueryRlvGetStatus();
			}
		}

		else if( num == MEM_USAGE )
		{
			llSay( 0, "Memory Used by " + llGetScriptName() + ": "
				+ (string)llGetUsedMemory() + " of " + (string)llGetMemoryLimit()
				+ ", Leaving " + (string)llGetFreeMemory() + " memory free." );
		}



	} // link_message

	changed( integer change ) {
		if( change & CHANGED_OWNER ) {
			llResetScript();
		}
	}

	listen( integer channel, string name, key id, string message ) {
		if( channel == RlvReplyChannel ) {
			//get the restrictions
			llListenRemove(RlvReplyListenHandle);
			list activeRestrictions = llParseString2List( message, [ "/" ], [] );

			list usedRestrictions = [];
			integer length = llGetListLength( activeRestrictions );
			integer index;
			for(; index < length; index++ ) {
				string restrictionName = llList2String( activeRestrictions, index );
				if(~llSubStringIndex(restrictionName, ":")) {
//					debug(["ignoring: " + restrictionName]);
				}
				else if(~llListFindList(IGNORED_RLV_RESTRICTIONS, [restrictionName])) {
//					debug(["ignoring: " + restrictionName]);
				}
				else {
					usedRestrictions += [restrictionName];
				}
			}

			//build the menu this could be:
			//MENU_RLV_MAIN:MENU_RLV_RESTRICTIONS
			//MENU_RLV_MAIN:MENU_RLV_RESTRICTIONS:"- Chat/IM"
			//MENU_RLV_MAIN:MENU_RLV_RESTRICTIONS:"- Inventory"
			//MENU_RLV_MAIN:MENU_RLV_RESTRICTIONS:"- Touch"
			//MENU_RLV_MAIN:MENU_RLV_RESTRICTIONS:"- World"
			//MENU_RLV_MAIN:MENU_RLV_RESTRICTIONS:"- Debug/Env"
			//MENU_RLV_MAIN:MENU_RLV_RESTRICTIONS:or whatever

			string prompt = getSelectedVictimPromt() + PROMPT_RESTRICTIONS;
			if(usedRestrictions) {
				prompt += llDumpList2String( usedRestrictions, ", ");
			}
			else {
				prompt += NO_RESTRICTIONS;
			}
			
			//create the buttons
			list buttons;
			if( Path == MENU_RLV_RESTRICTIONS_MAIN) {
				buttons=[MENU_RLV_UNDRESS, MENU_RLV_ATTACHMENTS];
				length = llGetListLength( RLV_RESTRICTIONS );
				for(index=0; index < length; index+=2) {
					buttons += [llList2String(RLV_RESTRICTIONS, index)];
				}
			}
			else {
				// must be a submenu
				prompt+=NEW_LINE 
					+ NEW_LINE + "☑ ... set restriction active"
					+ NEW_LINE + "☐ ... set restriction inactive"
					+ NEW_LINE + "(Maybe not all retrictions can't be set inactive)"
				;
				list pathparts=llParseString2List( Path, [PATH_SEPARATOR], [] );
				string restrictionGroup=llList2String( pathparts, -1);
				integer restrictionIndex = llListFindList( RLV_RESTRICTIONS, [ restrictionGroup ] );
				if( ~restrictionIndex ) {
					list restrictions = llCSV2List(llList2String(RLV_RESTRICTIONS, restrictionIndex + 1));
					length = llGetListLength( restrictions );
					for(index=0; index<length; index++) {
						string restrictionName = llList2String( restrictions, index);
						if(~llListFindList(usedRestrictions, [restrictionName])) {
							buttons += ["☑ " + restrictionName];
						}
						else {
							buttons += ["☐ " + restrictionName];
						}
					}
				}
			}
			ShowMenu(NPosetoucherID, prompt, buttons, Path);
		}
		else if(channel == RlvReplyChannelClothing) {
			llListenRemove(RlvReplyListenHandle);
			// gloves,jacket,pants,shirt,shoes,skirt,socks,underpants,undershirt,skin,eyes,hair,shape,alpha,tattoo
			list clothingLayersWorn = ParseClothingOrAttachmentLayersWorn( message, CLOTHING_LAYERS );
			string title = "The following clothing layers are worn:\n"
				+ llDumpList2String( clothingLayersWorn, ", " )
				+ "\n\nClick a button to try to detach this layer\n"
				+ "(Beware some might be locked and can't be removed)\n"
			;
			ShowMenu( NPosetoucherID, title, clothingLayersWorn, Path );
		}

		else if(channel == RlvReplyChannelAttachment) {
			llListenRemove(RlvReplyListenHandle);
			// none,chest,skull,left shoulder,right shoulder,left hand,right hand,left foot,right foot,spine,
			// pelvis,mouth,chin,left ear,right ear,left eyeball,right eyeball,nose,r upper arm,r forearm,
			// l upper arm,l forearm,right hip,r upper leg,r lower leg,left hip,l upper leg,l lower leg,stomach,left pec,
			// right pec,center 2,top right,top,top left,center,bottom left,bottom,bottom right,neck,root
			list attachmentPointsWorn = ParseClothingOrAttachmentLayersWorn( message, ATTACHMENT_POINTS );
			string title = "The following attachment points are worn:\n"
				+ llDumpList2String( attachmentPointsWorn, ", " )
				+ "\n\nClick a button to try to detach this attachment\n"
				+ "(Beware some might be locked and can't be removed)\n"
			;
			ShowMenu( NPosetoucherID, title, attachmentPointsWorn, Path);
		}


	} // listen

	timer() {
	}
/*
Documentation:
https://github.com/LeonaMorro/nPose-RLV-Plugin/wiki
Bugreports:
https://github.com/LeonaMorro/nPose-RLV-Plugin/issues
or IM slmember1 Resident (Leona)
*/
}
