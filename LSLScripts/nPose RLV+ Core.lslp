$import LSLScripts.constantsRlvPlugin.lslm ();

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
//
// USAGE
// put this script into an object together with at least the following npose scripts:
// - nPose Core
// - nPose Dialog
// - nPose menu
// - nPose Slave
// - nPose RLV+ MENU
// 
// Add a NC called "BTN:-RLV-" with the following content:
// LINKMSG|-8000|showmenu,%AVKEY%
// 
// Done.
// 
// Documentation:
// https://github.com/LeonaMorro/nPose-RLV-Plugin/wiki
// Report Bugs to:
// https://github.com/LeonaMorro/nPose-RLV-Plugin/issues
// or IM slmember1 Resident (Leona)

/*
linkMessage Numbers from -8000 to -8050 are assigned to the RLV+ Plugins
linkMessage Numbers from -8000 to -8009 are assigned to the RLV+ Core Plugin
linkMessage Numbers from -8010 to -8019 are assigned to the RLV+ RestrictionsMenu Plugin
linkMessage Numbers from -8020 to -8047 are reserved for later use
linkMessage Numbers from -8048 to -8049 are assigned to universal purposes
*/


string PLUGIN_NAME="RLV_CORE";

integer ACTIVE_TRAP_SCAN_INTERVALL=3;
integer ACTIVE_TRAP_COOLDOWN_INTERVALL=60;

// options
integer RLV_trapTimer; //time in seconds, 0: disable the automatic timer start
integer RLV_grabTimer; //time in seconds, 0: disable the automatic timer start
list RLV_enabledSeats=["*"];

//handles
integer RlvPingListenHandle;

key MyUniqueId;

key VictimKey=NULL_KEY; // contains active victim key
//integer currentVictimIndex=-1; //contains the VictimsList-index of the current victim

//a sitting avatar is either in the VvictimsList or in the FreeVictimsList or in the DomList

list VictimsList; //Avatars in this list are sitting on an rlvEnabled seat and are considered as restricted
//integer VICTIMS_LIST_AVATAR_UUID=0;
integer VICTIMS_LIST_TIMER=1;
integer VICTIMS_LIST_RELAY=2; //version of the rlv relay protocol (0: means no relay detected)
integer VICTIMS_LIST_STRIDE=3;

list FreeVictimsList; //Avatars in this list are sitting on an rlvEnabled seat but are NOT considered as restricted
//integer FREE_VICTIMS_LIST_AVATAR_UUID=0;
integer FREE_VICTIMS_LIST_STRIDE=1;

list DomList; //Avatars in this list are sitting on an nonRrlvEnabled seat
//integer DOM_LIST_AVATAR_UUID=0;
integer DOM_LIST_STRIDE=1;

list GrabList; //Avatars in this list are scheduled to be grabbed
integer GRAB_LIST_MAX_ENTRIES=3;
//integer GRAB_LIST_AVATAR_UUID=0;
integer GRAB_LIST_TIMEOUT=1;
integer GRAB_LIST_STRIDE=2;

list RecaptureList; //Avatars in this list are scheduled to be recaptured
integer RECAPTURE_LIST_MAX_ENTRIES=5;
///integer RECAPTURE_LIST_AVATAR_UUID=0;
integer RECAPTURE_LIST_TIMER=1;
integer RECAPTURE_LIST_TIMEOUT=2;
integer RECAPTURE_LIST_STRIDE=3;

list TrapIgnoreList; //Avatars in this list are not tried to be grabbed due an active trap
///integer TRAP_IGNORE_LIST_AVATAR_UUID=0;
integer TRAP_IGNORE_LIST_TIMEOUT=1;
integer TRAP_IGNORE_LIST_STRIDE=2;

integer FreeRlvEnabledSeats;
integer FreeNonRlvEnabledSeats;


// for RLV base restrictions and reading them from a notecard
string RlvBaseRestrictions="@unsit=n|@sittp=n|@tploc=n|@tplure=n|@tplm=n|@acceptpermission=add|@editobj:%MYKEY%=add";
key NcQueryId;

//added for timer
integer TimerRunning;

string PLUGIN_NAME_RLV_RESTRICTIONS_MENU="RLV_RESTRICTIONS_MENU";
integer RlvRestrictionsMenuAvailable;

// --- functions
integer getTrapIgnoreIndex(key avatarUuid) {
	return llListFindList(TrapIgnoreList, [avatarUuid]);
}

trapIgnoreListRemoveTimedOutValues() {
	integer currentTime=llGetUnixTime();
	integer length=llGetListLength(TrapIgnoreList);
	integer index;
	for(; index<length; index+=TRAP_IGNORE_LIST_STRIDE) {
		integer timeout=llList2Integer(TrapIgnoreList, index + TRAP_IGNORE_LIST_TIMEOUT);
		if(timeout && timeout<currentTime) {
			TrapIgnoreList=llDeleteSubList(TrapIgnoreList, index, index + TRAP_IGNORE_LIST_STRIDE - 1);
			index-=TRAP_IGNORE_LIST_STRIDE;
			length-=TRAP_IGNORE_LIST_STRIDE;
		}
	}
}

removeFromTrapIgnoreList(key avatarUuid) {
	integer index=getTrapIgnoreIndex(avatarUuid);
	if(~index) {
		TrapIgnoreList=llDeleteSubList(TrapIgnoreList, index, index + TRAP_IGNORE_LIST_STRIDE - 1);
	}
}

addToTrapIgnoreList(key avatarUuid) {
	TrapIgnoreList+=[avatarUuid, llGetUnixTime() + ACTIVE_TRAP_COOLDOWN_INTERVALL];
}


// NO pragma inline
debug(list message) {
	llOwnerSay(llGetScriptName() + "\n##########\n#>" + llDumpList2String(message, "\n#>") + "\n##########");
}

// pragma inline
string stringReplace( string str, string search, string replace ) {
	return llDumpList2String(llParseStringKeepNulls( str, [ search ], [] ), replace );
}

// pragma inline
integer getVictimIndex(key avatarUuid) {
	return llListFindList(VictimsList, [avatarUuid]);
}
// pragma inline
integer getFreeVictimIndex(key avatarUuid) {
	return llListFindList(FreeVictimsList, [avatarUuid]);
}
// pragma inline
integer getDomIndex(key avatarUuid) {
	return llListFindList(DomList, [avatarUuid]);
}

// pragma inline
integer getGrabIndex(key avatarUuid) {
	return llListFindList(GrabList, [avatarUuid]);
}

// pragma inline
integer getRecaptureIndex(key avatarUuid) {
	return llListFindList(RecaptureList, [avatarUuid]);
}

// NO pragma inline
addToVictimsList(key avatarUuid, integer timerTime) {
	removeFromVictimsList(avatarUuid);
	removeFromFreeVictimsList(avatarUuid);
	removeFromDomList(avatarUuid);

	if(timerTime>0) {
		timerTime+=llGetUnixTime();
	}
	else if(timerTime<0) {
		timerTime=0;
	}
	VictimsList+=[avatarUuid, timerTime, 0];
	llMessageLinked(LINK_SET, UPDATE_VICTIMS_LIST, llList2CSV(VictimsList), "");
//	llMessageLinked(LINK_SET, RLV_VICTIM_ADDED, (string)avatarUuid, "");
	//do Relay check and apply restrictions
	sendToRlvRelay(avatarUuid, RLV_RELAY_API_COMMAND_VERSION + "|" + RlvBaseRestrictions, "");
	//the timer should be running if there is a victim in the list
	if(!TimerRunning) {
		llSetTimerEvent(1.0);
		TimerRunning=TRUE;
	}
}

// NO pragma inline
removeFromVictimsList(key avatarUuid) {
	integer isChanged;
	integer index;
	while(~(index=getVictimIndex(avatarUuid))) {
		VictimsList=llDeleteSubList(VictimsList, index, index + VICTIMS_LIST_STRIDE - 1);
//		llMessageLinked(LINK_SET, RLV_VICTIM_REMOVED, (string)avatarUuid, "");
		isChanged=TRUE;
	}
	if(isChanged) {
		llMessageLinked(LINK_SET, UPDATE_VICTIMS_LIST, llList2CSV(VictimsList), "");
		if(VictimKey==avatarUuid) {
			changeCurrentVictim(NULL_KEY);
		}
		//if there isn't a victim any more, we don't need a timer
		if(!llGetListLength(VictimsList) && TimerRunning) {
			llSetTimerEvent(0.0);
			TimerRunning=FALSE;
		}
	}
}

// NO pragma inline
changeCurrentVictim(key newVictimKey) {
	if(newVictimKey!=VictimKey) {
		if(newVictimKey==NULL_KEY || ~getVictimIndex(newVictimKey)) {
			//this is a valid key
			VictimKey=newVictimKey;
			llMessageLinked( LINK_SET, CHANGE_SELECTED_VICTIM, (string)VictimKey, "" );
		}
	}
}

// pragma inline
addToDomList(key avatarUuid) {
	removeFromVictimsList(avatarUuid);
	removeFromFreeVictimsList(avatarUuid);
	removeFromDomList(avatarUuid);
	DomList+=[avatarUuid];
}

// NO pragma inline
removeFromDomList(key avatarUuid) {
	integer index;
	while(~(index=getDomIndex(avatarUuid))) {
		DomList=llDeleteSubList(DomList, index, index + DOM_LIST_STRIDE - 1);
	}
}

// NO pragma inline
addToFreeVictimsList(key avatarUuid) {
	removeFromVictimsList(avatarUuid);
	removeFromFreeVictimsList(avatarUuid);
	removeFromDomList(avatarUuid);
	FreeVictimsList+=avatarUuid;
}

// NO pragma inline
removeFromFreeVictimsList(key avatarUuid) {
	integer index;
	while(~(index=getFreeVictimIndex(avatarUuid))) {
		FreeVictimsList=llDeleteSubList(FreeVictimsList, index, index + FREE_VICTIMS_LIST_STRIDE - 1);
	}
}

// pragma inline
addToGrabList(key avatarUuid) {
	if(!~getGrabIndex(avatarUuid)) {
		GrabList+=[avatarUuid, llGetUnixTime() + RLV_RELAY_ASK_TIMEOUT];
		while (llGetListLength(GrabList) > GRAB_LIST_MAX_ENTRIES * GRAB_LIST_STRIDE) {
			GrabList=llList2List(GrabList, GRAB_LIST_STRIDE, -1);
		}
	}
}

// pragma inline
removeFromGrabList(key avatarUuid) {
	integer index;
	while(~(index=getGrabIndex(avatarUuid))) {
		GrabList=llDeleteSubList(GrabList, index, index + GRAB_LIST_STRIDE - 1);
	}
}

// pragma inline
grabListRemoveTimedOutEntrys() {
	integer currentTime=llGetUnixTime();
	integer length=llGetListLength(GrabList);
	integer index;
	for(; index<length; index+=GRAB_LIST_STRIDE) {
		integer timeout=llList2Integer(GrabList, index + GRAB_LIST_TIMEOUT);
		if(timeout<currentTime) {
			GrabList=llDeleteSubList(GrabList, index, index + GRAB_LIST_STRIDE - 1);
			index-=GRAB_LIST_STRIDE;
			length-=GRAB_LIST_STRIDE;
		}
	}
}

// pragma inline
addToRecaptureList(key avatarUuid, integer timerTime) {
	if(timerTime<0) {
		timerTime=0;
	}
	recaptureListRemoveTimedOutEntrys();
	//slmember1: I don't have an idea how someone could get on the list twice, but to be sure that this will not happen ...
	removeFromRecaptureList(avatarUuid);
	RecaptureList+=[avatarUuid, timerTime, 0];
	while (llGetListLength(RecaptureList) > RECAPTURE_LIST_MAX_ENTRIES * RECAPTURE_LIST_STRIDE) {
		RecaptureList=llList2List(RecaptureList, RECAPTURE_LIST_STRIDE, -1);
	}
}

// pragma inline
removeFromRecaptureList(key avatarUuid) {
	integer index;
	while(~(index=getRecaptureIndex(avatarUuid))) {
		RecaptureList=llDeleteSubList(RecaptureList, index, index + RECAPTURE_LIST_STRIDE - 1);
	}
}

// NO pragma inline
recaptureListRemoveTimedOutEntrys() {
	integer currentTime=llGetUnixTime();
	integer length=llGetListLength(RecaptureList);
	integer index;
	for(; index<length; index+=RECAPTURE_LIST_STRIDE) {
		integer timeout=llList2Integer(RecaptureList, index + RECAPTURE_LIST_TIMEOUT);
		if(timeout && timeout<currentTime) {
			RecaptureList=llDeleteSubList(RecaptureList, index, index + RECAPTURE_LIST_STRIDE - 1);
			index-=RECAPTURE_LIST_STRIDE;
			length-=RECAPTURE_LIST_STRIDE;
		}
	}
}

// send rlv commands to the RLV relay, usable for common format (not ping)
// NO pragma inline
sendToRlvRelay(key victim, string rlvCommand, string identifier) {
	if(rlvCommand) {
		if(victim) {
			llSay(RLV_RELAY_CHANNEL,
				conditionalString(llStringLength(identifier), identifier, (string)MyUniqueId) + ","
				+ (string)victim + ","
				+ stringReplace(rlvCommand, "%MYKEY%", (string)llGetKey())
			);
		}
	}
}


setVictimTimer(key avatarUuid, integer time) {
	integer index=getVictimIndex(avatarUuid);
	if(~index) {
		VictimsList=llListReplaceList(VictimsList, [time], index + VICTIMS_LIST_TIMER, index + VICTIMS_LIST_TIMER);
		llMessageLinked(LINK_SET, UPDATE_VICTIMS_LIST, llList2CSV(VictimsList), "");
	}
}

// NO pragma inline
integer getVictimTimer(key avatarUuid) {
	integer index=getVictimIndex(avatarUuid);
	if(~index) {
		integer time=llList2Integer(VictimsList, index + VICTIMS_LIST_TIMER) - llGetUnixTime();
		if(time>0) {
			return time;
		}
	}
	return 0;
}

// pragma inline
string conditionalString(integer conditon, string valueIfTrue, string valueIfFalse) {
	string ret=valueIfFalse;
	if(conditon) {
		ret=valueIfTrue;
	}
	return ret;
}

// pragma inline
integer getVictimRelayVersion(key avatarUuid) {
	integer relayVersion;
	integer index=getVictimIndex(avatarUuid);
	if(~index) {
		relayVersion=llList2Integer(VictimsList, index + VICTIMS_LIST_RELAY);
	}
	return relayVersion;
}

// pragma inline
setVictimRelayVersion(key avatarUuid, integer relayVersion) {
	integer index=getVictimIndex(avatarUuid);
	if(~index) {
		VictimsList=llListReplaceList(VictimsList, [relayVersion], index + VICTIMS_LIST_RELAY, index + VICTIMS_LIST_RELAY);
		llMessageLinked(LINK_SET, UPDATE_VICTIMS_LIST, llList2CSV(VictimsList), "");
	}
}

// pragma inline
releaseAvatar(key targetKey) {
	addToFreeVictimsList(targetKey);
	removeFromVictimsList(targetKey);
	sendToRlvRelay(targetKey, RLV_RELAY_API_COMMAND_RELEASE, "");
}

// pragma inline
unsitAvatar(key targetKey) {
	removeFromVictimsList(targetKey);
	addToFreeVictimsList(targetKey);
	sendToRlvRelay(targetKey, "@unsit=y", "");
	llSleep(0.75);
	sendToRlvRelay(targetKey, "@unsit=force", "");
	llSleep(0.75);
	sendToRlvRelay(targetKey, RLV_RELAY_API_COMMAND_RELEASE, "");
}

grabAvatar(key targetKey) {
	if(~getVictimIndex(targetKey)) {
		//the Avatar is in the victims list, this means he is sitting on an RLV enabled seat. Reapply RLV Base Restrictions
		sendToRlvRelay(targetKey, RlvBaseRestrictions, "");
		changeCurrentVictim(targetKey);
		//send the user back to main Menu
	}
	else if(~getFreeVictimIndex(targetKey)) {
		//this is a previously released victim, regrab him
		addToVictimsList(targetKey, RLV_grabTimer);
		changeCurrentVictim(targetKey);
	}
	else if(~getDomIndex(targetKey)) {
		//he is NOT a victim .. that implies that he sits on a NON RLV enabled seat. Do nothing
	}
	else {
		//the Avatar is not sitting. Make him sit.
		//he will become a real victim when sitting on a RLV enabled seat
		addToGrabList(targetKey);
		sendToRlvRelay(targetKey, "@sit:" + (string)llGetKey() + "=force", "");
	}
}


default {
	state_entry() {
		llListen(RLV_RELAY_CHANNEL, "", NULL_KEY, "");
		MyUniqueId=llGenerateKey();
	}

	link_message( integer sender, integer num, string str, key id ) {
		// messages comming in from BTN notecard commands
		// or other scripts linkMessages
		if(num==CHANGE_SELECTED_VICTIM) {
			changeCurrentVictim((key)str);
		}
		else if(num==RLV_CORE_COMMAND) {
			list temp=llParseStringKeepNulls(str,[","], []);
			string cmd=llToLower(llStringTrim(llList2String(temp, 0), STRING_TRIM));
			key target=(key)stringReplace(llStringTrim(llList2String(temp, 1), STRING_TRIM), "%VICTIM%", (string)VictimKey);
			list params=llDeleteSubList(temp, 0, 1);
			
			if(target) {}
			else {
				target=VictimKey;
			}
			
			if(cmd=="rlvcommand") {
				sendToRlvRelay(target, stringReplace(llList2String(params, 0), "/","|" ), "");
			}
			else if(cmd=="release") {
				releaseAvatar(target);
			}
			else if(cmd=="unsit") {
				unsitAvatar(target);
			}
			else if(cmd=="settimer") {
				setVictimTimer(target, (integer)llList2String(params, 0));
			}
			else if(cmd=="grab") {
				grabAvatar(target);
			}
			else if(cmd == "read") {
				string rlvRestrictionsNotecard=llList2String(params, 0);
				if(llGetInventoryType(rlvRestrictionsNotecard )==INVENTORY_NOTECARD) {
					NcQueryId=llGetNotecardLine(rlvRestrictionsNotecard, 0);
				}
				else {
					llWhisper( 0, "Error: rlvRestrictions Notecard " + rlvRestrictionsNotecard + " not found" );
				}
			}
		}

		else if(num==SEAT_UPDATE) {
			recaptureListRemoveTimedOutEntrys();
			grabListRemoveTimedOutEntrys();
			trapIgnoreListRemoveTimedOutValues();
			FreeNonRlvEnabledSeats=0;
			FreeRlvEnabledSeats=0;
			list slotsList=llParseStringKeepNulls(str, ["^"], []);
			integer length=llGetListLength(slotsList);
			integer index;
			for(; index<length; index+=8) {
				key avatarWorkingOn=(key)llList2String(slotsList, index+4);
				removeFromTrapIgnoreList(avatarWorkingOn);
				integer seatNumber=index/8+1;
				integer isRlvEnabledSeat=~llListFindList(RLV_enabledSeats, ["*"]) || ~llListFindList(RLV_enabledSeats, [(string)seatNumber]);
				if(avatarWorkingOn) {
					if(isRlvEnabledSeat) {
						//This is a RLV enabled seat
						if(!~getVictimIndex(avatarWorkingOn)) {
							//This avatar is currently no Vicitim
							if(~getGrabIndex(avatarWorkingOn)) {
								//Avatar is grabbed by someone
								addToVictimsList(avatarWorkingOn, RLV_grabTimer);
								changeCurrentVictim(avatarWorkingOn);
							}
							else if(~getRecaptureIndex(avatarWorkingOn)) {
								//Avatar is recaptured, due previously safeword or Logoff/Logon
								addToVictimsList(avatarWorkingOn, llList2Integer(RecaptureList, getRecaptureIndex(avatarWorkingOn) + RECAPTURE_LIST_TIMER));
								changeCurrentVictim(avatarWorkingOn);
							}
							else if(~getFreeVictimIndex(avatarWorkingOn)) {
								//the avatar is free, do nothing
							}
							else if(~getDomIndex(avatarWorkingOn)) {
								//the avatar is comming from a noneRlvEnabled seat
								addToFreeVictimsList(avatarWorkingOn);
							}
							else {
								//Avatar sits down voluntary
								addToVictimsList(avatarWorkingOn, RLV_trapTimer);
								changeCurrentVictim(avatarWorkingOn);
							}
						}
					}
					else {
						//This is a NOT RLV enabled seat
						if(~getVictimIndex(avatarWorkingOn) || ~getRecaptureIndex(avatarWorkingOn)) {
							sendToRlvRelay(avatarWorkingOn, RLV_RELAY_API_COMMAND_RELEASE, "");
						}
						addToDomList(avatarWorkingOn);
					}
				}
				else {
					//this is a free seat
					if(isRlvEnabledSeat) {
						FreeRlvEnabledSeats++;
					}
					else {
						FreeNonRlvEnabledSeats++;
					}
				}
				//Garbage Collection
				removeFromGrabList(avatarWorkingOn);
				removeFromRecaptureList(avatarWorkingOn);
			}
			// If there is an Avatar in FreeVictim list but not sitting that means the Avatar just stand up
			length=llGetListLength(FreeVictimsList);
			index=0;
			for(; index < length; index+=FREE_VICTIMS_LIST_STRIDE) {
				key avatarWorkingOn=llList2Key(FreeVictimsList, index);
				if(!~llListFindList(slotsList, [(string)avatarWorkingOn])) {
					removeFromFreeVictimsList(avatarWorkingOn);
					addToTrapIgnoreList(avatarWorkingOn);
				}
			}
			// If there is an Avatar in Dom list but not sitting that means the Avatar just stand up
			length=llGetListLength(DomList);
			index=0;
			for(; index < length; index+=DOM_LIST_STRIDE) {
				key avatarWorkingOn=llList2Key(DomList, index);
				if(!~llListFindList(slotsList, [(string)avatarWorkingOn])) {
					removeFromDomList(avatarWorkingOn);
					addToTrapIgnoreList(avatarWorkingOn);
				}
			}

			//If there is a Avatar in victims list but not sitting, this means he escaped
			length=llGetListLength(VictimsList);
			index=0;
			for(; index < length; index+=VICTIMS_LIST_STRIDE) {
				key avatarWorkingOn=llList2Key(VictimsList, index);
				if(!~llListFindList(slotsList, [(string)avatarWorkingOn])) {
					if(getVictimRelayVersion(avatarWorkingOn)) {
						//if the avatar had an active RLV Relay while he becomes a victim, we could try to recapture him in the future
						//this usually means, that the avator logged off
						addToRecaptureList(avatarWorkingOn, llList2Integer(VictimsList, index + VICTIMS_LIST_TIMER) - llGetUnixTime());
					}
					removeFromVictimsList(avatarWorkingOn);
					addToTrapIgnoreList(avatarWorkingOn);
					index-=VICTIMS_LIST_STRIDE;
					length-=VICTIMS_LIST_STRIDE;
				}
			}
		}
		else if (num==OPTIONS) {
			list optionsToSet = llParseStringKeepNulls(str, ["~"], []);
			integer length = llGetListLength(optionsToSet);
			integer index;
			for (; index<length; index++){
				list optionsItems = llParseString2List(llList2String(optionsToSet, index), ["="], []);
				string optionItem = llToLower(llStringTrim(llList2String(optionsItems, 0), STRING_TRIM));
				string optionSetting = llStringTrim(llList2String(optionsItems, 1), STRING_TRIM);
				if (optionItem == "rlv_grabtimer") {
					RLV_grabTimer = (integer)optionSetting;
				}
				else if (optionItem == "rlv_traptimer") {
					RLV_trapTimer = (integer)optionSetting;
				}
				else if (optionItem == "rlv_traprange") {
					if((float)optionSetting) {
						llSensorRepeat("", NULL_KEY, AGENT_BY_LEGACY_NAME, (float)optionSetting, PI, ACTIVE_TRAP_SCAN_INTERVALL);
					}
					else {
						llSensorRemove();
					}
				}
				else if (optionItem == "rlv_enabledseats") {
					RLV_enabledSeats = llParseString2List(optionSetting, ["/"], []);
				}
			}
		}
		else if( num == MEM_USAGE ) {
			llSay( 0, "Memory Used by " + llGetScriptName() + ": "
				+ (string)llGetUsedMemory() + " of " + (string)llGetMemoryLimit()
				+ ", Leaving " + (string)llGetFreeMemory() + " memory free." );
		}
		else if(num==RLV_CORE_DUMP_DEBUG_STRING) {
			if(str=="l") {
				debug(
					  ["VictimsList"] + VictimsList
					+ ["####", "FreeVictimsList"] + FreeVictimsList
					+ ["####", "DomList"] + DomList
					+ ["####", "GrabList"] + GrabList
					+ ["####", "RecaptureList"] + RecaptureList
					+ ["####", "TrapIgnoreList"] + TrapIgnoreList
				);
			}
			else if(str=="o") {
				debug(
					  ["RLV_trapTimer", RLV_trapTimer, "####", "RLV_grabTimer", RLV_grabTimer, "####", "RLV_enabledSeats"] + RLV_enabledSeats
				);
			} 
		}
	} // link_message

	changed( integer change ) {
		if( change & CHANGED_OWNER ) {
			llResetScript();
		}
	}

	dataserver( key id, string data ) {
		if( id == NcQueryId ) {
			RlvBaseRestrictions = stringReplace( data, "/", "|" );
		}
	}

	listen(integer channel, string name, key id, string message) {
		if( channel == RLV_RELAY_CHANNEL ) {
			list messageParts=llParseStringKeepNulls(message, [","], []);
			if((key)llList2String(messageParts, 1)==llGetKey()) {
				//this message seems to be for us
				string cmd_name=llList2String(messageParts, 0);
				string command=llList2String(messageParts, 2);
				string reply=llList2String(messageParts, 3);
				key senderAvatarId=llGetOwnerKey(id);
				if(command==RLV_RELAY_API_COMMAND_VERSION) {
					setVictimRelayVersion(senderAvatarId, (integer)reply);
				}
				else if(command==RLV_RELAY_API_COMMAND_RELEASE) {
					if(reply=="ok") {
						//the relay cancels the active session (perhaps by safewording), set the victim free
						if(~getVictimIndex(senderAvatarId)) {
							addToFreeVictimsList(senderAvatarId);
						}
						removeFromVictimsList(senderAvatarId);
						removeFromGrabList(senderAvatarId);
						removeFromRecaptureList(senderAvatarId);
					}
				}
				else if(command==RLV_RELAY_API_COMMAND_PING) {
					if(cmd_name==command && reply==command) {
						// if someone sends a ping message, that means that the Avatar was previously restricted by us.
						// so if we have a free sub seat we will answere
						// else we remove the avatar from the recapture list and he can do whatever he want
						// so what could happen after the Avatar is seated by his relay?
						// 1.) the avatar could be routed to a dom seat due to the fact that the dom seat is the next free seat (that should not happen if we define the sub seats at the begining of the slot list)
						// 2.) perhaps the avatar could cheat and not get seated, in this case we need a timeout in the recapture list, so we could remove after the timeout triggers. That is necessary because if he sits down somtime later, he could be in the recapture list and so the recapture timer would be aplied (and not the grab/trap timer)
						recaptureListRemoveTimedOutEntrys(); //this maybe shorten the list
						integer index=getRecaptureIndex(senderAvatarId);
						if(~index) {
							//we know him and we want him
							if(FreeRlvEnabledSeats) {
								RecaptureList=llListReplaceList(RecaptureList, [llGetUnixTime() + RLV_RELAY_ASK_TIMEOUT], index, index + RECAPTURE_LIST_STRIDE - 1);
								llSay(RLV_RELAY_CHANNEL, RLV_RELAY_API_COMMAND_PING + "," + (string)senderAvatarId + "," + RLV_RELAY_API_COMMAND_PONG);
							}
							else {
								removeFromRecaptureList(senderAvatarId);
							}
						}
					}
				}
			}
		}
	} // listen
	
	sensor(integer num_detected) {
		if(FreeRlvEnabledSeats) {
			trapIgnoreListRemoveTimedOutValues();
			integer index;
			for(; index<num_detected; index++) {
				key avatarWorkingOn=llDetectedKey(index);
				if(
					   !~getVictimIndex(avatarWorkingOn)
					&& !~getFreeVictimIndex(avatarWorkingOn)
					&& !~getDomIndex(avatarWorkingOn)
					&& !~getGrabIndex(avatarWorkingOn)
					&& !~getRecaptureIndex(avatarWorkingOn)
					&& !~getTrapIgnoreIndex(avatarWorkingOn)
				) {
					sendToRlvRelay(avatarWorkingOn, "@sit:" + (string)llGetKey() + "=force", "");
					addToTrapIgnoreList(avatarWorkingOn);
				}
			}
		}
	}

	timer() {
		integer currentTime=llGetUnixTime();
		integer length=llGetListLength(VictimsList);
		integer index;
		for(; index<length; index+=VICTIMS_LIST_STRIDE) {
			integer time=llList2Integer(VictimsList, index + VICTIMS_LIST_TIMER);
			if(time && time<=currentTime) {
				key avatarWorkingOn=llList2Key(VictimsList, index);
				sendToRlvRelay(avatarWorkingOn, RLV_RELAY_API_COMMAND_RELEASE, "");
				addToFreeVictimsList(avatarWorkingOn);
			}
		}
	}
} // state default
