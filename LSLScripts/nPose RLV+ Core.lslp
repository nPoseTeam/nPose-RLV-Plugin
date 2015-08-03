$import LSLScripts.constantsRlvPlugin.lslm ();

// Theese scripts are licensed under the GPLv2 (http://www.gnu.org/licenses/gpl-2.0.txt),
// with the following addendum:
//
// These scripts are free to be copied, modified, and redistributed, subject to the following conditions:
// - If you distribute these scripts, you must leave them full perms.
// - If you modify these scripts and distribute the modifications, you must also make your modifications full perms.
//
// "Full perms" means having the modify, copy, and transfer permissions enabled in Second Life 
// and/or other virtual world platforms derived from Second Life (such as OpenSim).
// If the platform should allow more fine-grained permissions, then "full perms" will mean
// the most permissive possible set of permissions allowed by the platform.
//
// Documentation:
// https://github.com/LeonaMorro/nPose-RLV-Plugin/wiki
// Report Bugs to:
// https://github.com/LeonaMorro/nPose-RLV-Plugin/issues
// or IM slmember1 Resident (Leona)


string PLUGIN_NAME="RLV_CORE";

integer ACTIVE_TRAP_SCAN_INTERVALL=3;
integer ACTIVE_TRAP_COOLDOWN_INTERVALL=60;

// options
integer RLV_trapTimer; //time in seconds, 0: disable the automatic timer start
integer RLV_grabTimer; //time in seconds, 0: disable the automatic timer start
integer RLV_collisionTrap; //0: disabbled, 1:enabled
list RLV_enabledSeats=["*"];

//handles
integer RlvPingListenHandle;

//other
key MyUniqueId;

key VictimKey=NULL_KEY; // contains active victim key

//lists
//a sitting avatar is either in the VictimsList or in the FreeVictimsList or in the DomList

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

list TrapIgnoreList; //Avatars in this list should not be grabbed by an active trap
///integer TRAP_IGNORE_LIST_AVATAR_UUID=0;
integer TRAP_IGNORE_LIST_TIMEOUT=1;
integer TRAP_IGNORE_LIST_STRIDE=2;

integer FreeRlvEnabledSeats;
integer FreeNonRlvEnabledSeats;

list SlotList;

// for RLV base restrictions and reading them from a notecard
string RlvBaseRestrictions="@unsit=n|@sittp=n|@tploc=n|@tplure=n|@tplm=n|@acceptpermission=add|@editobj:%MYKEY%=add";

//added for timer
integer TimerRunning;



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
	removeFromAllLists(avatarUuid);
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

//pragma inline
sendUserPermissionUpdate() {
	llMessageLinked(
		LINK_SET,
		RLV_VICTIMS_LIST_UPDATE,
		llList2CSV(VictimsList),
		""
	);
	llMessageLinked(
		LINK_SET,
		USER_PERMISSION_UPDATE,
		llList2CSV([USER_PERMISSION_VICTIM, USER_PERMISSION_TYPE_LIST, llDumpList2String(llList2ListStrided(VictimsList, 0, -1, VICTIMS_LIST_STRIDE), "|")]),
		""
	);
}

// NO pragma inline
addToVictimsList(key avatarUuid, integer timerTime) {
	removeFromAllLists(avatarUuid);

	if(timerTime>0) {
		timerTime+=llGetUnixTime();
	}
	else if(timerTime<0) {
		timerTime=0;
	}
	VictimsList+=[avatarUuid, timerTime, 0];
	sendUserPermissionUpdate();
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
		sendUserPermissionUpdate();
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
			llMessageLinked( LINK_SET, RLV_CHANGE_SELECTED_VICTIM, (string)VictimKey, "" );
		}
	}
}

// pragma inline
addToDomList(key avatarUuid) {
	removeFromAllLists(avatarUuid);
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
	removeFromAllLists(avatarUuid);
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
	removeFromAllLists(avatarUuid);
	GrabList+=[avatarUuid, llGetUnixTime() + RLV_RELAY_ASK_TIMEOUT];
	while (llGetListLength(GrabList) > GRAB_LIST_MAX_ENTRIES * GRAB_LIST_STRIDE) {
		GrabList=llList2List(GrabList, GRAB_LIST_STRIDE, -1);
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
	removeFromAllLists(avatarUuid);
	recaptureListRemoveTimedOutEntrys();
	if(timerTime<0) {
		timerTime=0;
	}
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

// NO pragma inline
removeFromAllLists(key avatarUuid) {
	removeFromVictimsList(avatarUuid);
	removeFromFreeVictimsList(avatarUuid);
	removeFromDomList(avatarUuid);
	removeFromGrabList(avatarUuid);
	removeFromRecaptureList(avatarUuid);
	removeFromTrapIgnoreList(avatarUuid);
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
		llMessageLinked(LINK_SET, RLV_VICTIMS_LIST_UPDATE, llList2CSV(VictimsList), "");
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
		llMessageLinked(LINK_SET, RLV_VICTIMS_LIST_UPDATE, llList2CSV(VictimsList), "");
	}
}

// pragma inline
releaseAvatar(key targetKey) {
	if(~getVictimIndex(targetKey)) {
		addToFreeVictimsList(targetKey);
	}
	sendToRlvRelay(targetKey, RLV_RELAY_API_COMMAND_RELEASE, "");
}

// pragma inline
unsitAvatar(key targetKey) {
	releaseAvatar(targetKey);
	llSleep(1.5);
	llUnSit(targetKey);
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
		if(num==RLV_CHANGE_SELECTED_VICTIM) {
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
			else if(cmd=="read") {
				llMessageLinked(LINK_SET, NC_READER_REQUEST, llList2String(params, 0), MyUniqueId);
			}
		}
		
		else if(num==NC_READER_RESPONSE) {
			if(id==MyUniqueId) {
				//stript the first 3 values
				str=llDumpList2String(llList2List(llParseStringKeepNulls(str, [NC_READER_CONTENT_SEPARATOR], []), 3, -1), "");
				RlvBaseRestrictions = stringReplace( str, "/", "|" );
			}
		}

		else if(num==SEAT_UPDATE) {
			recaptureListRemoveTimedOutEntrys();
			grabListRemoveTimedOutEntrys();
			trapIgnoreListRemoveTimedOutValues();
			FreeNonRlvEnabledSeats=0;
			FreeRlvEnabledSeats=0;
			SlotList=llParseStringKeepNulls(str, ["^"], []);
			integer length=llGetListLength(SlotList);
			integer index;
			for(; index<length; index+=8) {
				key avatarWorkingOn=(key)llList2String(SlotList, index+4);
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
			}
			
			list tempList;
			// If there is an Avatar in FreeVictim list but not sitting that means the Avatar just stand up
			tempList=FreeVictimsList;
			length=llGetListLength(tempList);
			index=0;
			for(; index < length; index+=FREE_VICTIMS_LIST_STRIDE) {
				key avatarWorkingOn=llList2Key(tempList, index);
				if(!~llListFindList(SlotList, [(string)avatarWorkingOn])) {
					addToTrapIgnoreList(avatarWorkingOn);
				}
			}
			// If there is an Avatar in Dom list but not sitting that means the Avatar just stand up
			tempList=DomList;
			length=llGetListLength(tempList);
			index=0;
			for(; index < length; index+=DOM_LIST_STRIDE) {
				key avatarWorkingOn=llList2Key(tempList, index);
				if(!~llListFindList(SlotList, [(string)avatarWorkingOn])) {
					addToTrapIgnoreList(avatarWorkingOn);
				}
			}

			//If there is a Avatar in victims list but not sitting, this means he escaped
			tempList=VictimsList;
			length=llGetListLength(tempList);
			index=0;
			for(; index < length; index+=VICTIMS_LIST_STRIDE) {
				key avatarWorkingOn=llList2Key(tempList, index);
				if(!~llListFindList(SlotList, [(string)avatarWorkingOn])) {
					if(getVictimRelayVersion(avatarWorkingOn)) {
						//if the avatar had an active RLV Relay while he becomes a victim, we could try to recapture him in the future
						//this usually means, that the avator logged off
						addToRecaptureList(avatarWorkingOn, llList2Integer(tempList, index + VICTIMS_LIST_TIMER) - llGetUnixTime());
					}
					else {
						addToTrapIgnoreList(avatarWorkingOn);
					}
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
				else if (optionItem == "rlv_collisiontrap") {
					RLV_collisionTrap=(integer) optionSetting;
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
					  ["RLV_trapTimer", RLV_trapTimer, "####", "RLV_grabTimer", RLV_grabTimer, "####", "RLV_collisionTrap", RLV_collisionTrap, "####", "RLV_enabledSeats"] + RLV_enabledSeats
				);
			} 
		}
	} // link_message

	changed( integer change ) {
		if( change & CHANGED_OWNER ) {
			llResetScript();
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
						//this could be:
						//a.) The answere to an !release message
						//b.) A safeword attemp
						if(~getVictimIndex(senderAvatarId)) {
							//the relay cancels the active session (perhaps by safewording), set the victim free
							addToFreeVictimsList(senderAvatarId);
						}
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
								RecaptureList=llListReplaceList(RecaptureList, [llGetUnixTime() + RLV_RELAY_ASK_TIMEOUT], index + RECAPTURE_LIST_TIMEOUT, index + RECAPTURE_LIST_TIMEOUT);
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
	
	collision_start(integer num_detected) {
		key avatarWorkingOn=llDetectedKey(0);
		if(RLV_collisionTrap && FreeRlvEnabledSeats && llGetAgentSize(avatarWorkingOn)!=ZERO_VECTOR) {
			trapIgnoreListRemoveTimedOutValues();
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
					return; //only get one Avatar per cycle
				}
			}
		}
	}

	timer() {
		integer currentTime=llGetUnixTime();
		list tempList=VictimsList;
		integer length=llGetListLength(tempList);
		integer index;
		for(; index<length; index+=VICTIMS_LIST_STRIDE) {
			integer time=llList2Integer(tempList, index + VICTIMS_LIST_TIMER);
			if(time && time<=currentTime) {
				key avatarWorkingOn=llList2Key(tempList, index);
				sendToRlvRelay(avatarWorkingOn, RLV_RELAY_API_COMMAND_RELEASE, "");
				addToFreeVictimsList(avatarWorkingOn);
			}
		}
	}
} // state default
