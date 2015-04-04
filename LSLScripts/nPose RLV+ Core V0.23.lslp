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

/*
USAGE

put this script into an object together with at least the following npose scripts:
- nPose Core
- nPose Dialog
- nPose menu
- nPose Slave
- nPose SAT/NOSAT handler

Add a NC called "BTN:-RLV-" with the following content:
LINKMSG|-8000|showmenu,%AVKEY%

Finished

Documentation:
https://github.com/LeonaMorro/nPose-RLV-Plugin/wiki
Bugs:
https://github.com/LeonaMorro/nPose-RLV-Plugin/issues
or IM slmember1 Resident (Leona)
*/


// linkMessage Numbers from -8000 to -8050 are assigned to the RLV+ Plugins
// linkMessage Numbers from -8000 to -8009 are assigned to the RLV+ Core Plugin
// linkMessage Numbers from -8010 to -8019 are assigned to the RLV+ RestrictionsMenu Plugin
// linkMessage Numbers from -8020 to -8047 are reserved for later use
// linkMessage Numbers from -8048 to -8049 are assigned to universal purposes


string PLUGIN_NAME="RLV_CORE";

// --- constants and configuration
integer DOMENU               = -800; // dialog control back to npose
integer DIALOG               = -900; // start dialog
integer DIALOG_RESPONSE      = -901; // eval dialog response
integer SENSOR_START         = -233;
integer SENSOR_END           = -234;
integer UPDATE_CURRENT_VICTIM= -237;
integer RLV_CORE             = -8000; //send commands to the RLV CORE
integer RLV_VICTIM_ADDED     = -8001; //if a someone is added to the victims list this message would be send
integer RLV_VICTIM_REMOVED    =-8002; //if a someone is removed from the victims list this message would be send
integer RLV_RESTRICTIONS_MENU= -8010; //send commands to the RLV RESTRICTIONS MENU
integer PLUGIN_PING          = -8048; //universal Plugin detection
integer PLUGIN_PONG          = -8049; //universal Plugin detection
integer RLV_CORE_DUMP_DEBUG_STRING = -8008; //TODO: remove this

integer OPTIONS              = -240;
integer MEM_USAGE            = 34334;
integer SEAT_UPDATE          = 35353;

integer RLV_RELAY_CHANNEL    = -1812221819;

string BACKBTN              ="^";
string MENU_RLV_MAIN        ="RLVMain";
string MENU_RLV_CAPTURE     ="→Capture";
string MENU_RLV_RESTRICTIONS="→Restrictions";
string MENU_RLV_VICTIMS     ="→Victims";
string MENU_RLV_TIMER       ="→Timer";
string BUTTON_RLV_RELEASE   ="Release";
string BUTTON_RLV_UNSIT     ="Unsit";

integer RLV_ASK_TIMEOUT=60;

string RLV_COMMAND_RELEASE="!release";
string RLV_COMMAND_VERSION="!version";
string RLV_COMMAND_PING="ping";
string RLV_COMMAND_PONG="!pong";

list TIMER_BUTTONS1 = [
	"+1d", "+6h", "+1h", "+15m", "+1m"
];
list TIMER_BUTTONS2 = [
	"-1d", "-6h", "-1h", "-15m", "-1m",
	"Reset"
];

string TIMER_NO_TIME="--:--:--";
string PROMPT_VICTIM="Selected Victim: ";
string PROMPT_TIMER="Timer: ";
string PROMPT_CAPTURE="Pick a victim to attempt capturing.";
string PROMPT_RELAY="RLV Relay: ";
string PROMPT_RELAY_YES="OK";
string PROMPT_RELAY_NO="NOT RECOGNIZED";
string NEW_LINE="\n";
string NO_VICTIM="NONE";

string PATH_SEPARATOR=":";
integer BUTTON_MAX_LENGHT=16;

// --- global variables

// options
integer RLV_captureRange = 10; // sensor range to find potential capture victims
integer RLV_trapTimer; //time in seconds, 0: disable the automatic timer start
integer RLV_grabTimer; //time in seconds, 0: disable the automatic timer start
list RLV_enabledSeats=["*"];

//handles
integer RlvPingListenHandle;

key MyUniqueId;

string  Path;           // contains dialog path for RLV
key     NPosetoucherID; // who touched me
string  NPosePath;      // which npose dialog to show when rlv part finished


key VictimKey=NULL_KEY; // contains active victim key
//integer currentVictimIndex=-1; //contains the VictimsList-index of the current victim

list VictimsList;
//integer VICTIMS_LIST_AVATAR_UUID=0;
integer VICTIMS_LIST_TIMER=1;
integer VICTIMS_LIST_RELAY=2; //version of the rlv relay protocol (0: means no relay detected)
integer VICTIMS_LIST_STRIDE=3;

list FreeVictimsList;
//integer FREE_VICTIMS_LIST_AVATAR_UUID=0;
integer FREE_VICTIMS_LIST_STRIDE=1;

list GrabList;
integer GRAB_LIST_MAX_ENTRIES=3;
//integer GRAB_LIST_AVATAR_UUID=0;
integer GRAB_LIST_TIMEOUT=1;
integer GRAB_LIST_STRIDE=2;

list RecaptureList;
integer RECAPTURE_LIST_MAX_ENTRIES=5;
///integer RECAPTURE_LIST_AVATAR_UUID=0;
integer RECAPTURE_LIST_TIMER=1;
integer RECAPTURE_LIST_TIMEOUT=2;
integer RECAPTURE_LIST_STRIDE=3;

list SensorList;
//integer SENSOR_LIST_AVATAR_NAME=0;
integer SENSOR_LIST_AVATAR_UUID=1;
integer SENSOR_LIST_STRIDE=2;

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

debug(list message) {
	llOwnerSay(llGetScriptName() + "\n##########\n#>" + llDumpList2String(message, "\n#>") + "\n##########");
}


addToVictimsList(key avatarUuid, integer timerTime) {
	if(timerTime>0) {
		timerTime+=llGetUnixTime();
	}
	else if(timerTime<0) {
		timerTime=0;
	}
	//slmember1: I don't have an idea how someone could get on the list twice, but to be sure that this will not happen ...
	removeFromVictimsList(avatarUuid);
	VictimsList+=[avatarUuid, timerTime, 0];
	llMessageLinked(LINK_SET, RLV_VICTIM_ADDED, (string)avatarUuid, "");
	//do Relay check and apply restrictions
	sendToRlvRelay(avatarUuid, RLV_COMMAND_VERSION + "|" + RlvBaseRestrictions, "");
	//the timer should be running if there is a victim in the list
	if(!TimerRunning) {
		llSetTimerEvent(1.0);
		TimerRunning=TRUE;
	}
}

removeFromVictimsList(key avatarUuid) {
	integer index;
	while(~(index=llListFindList(VictimsList, [avatarUuid]))) {
		VictimsList=llDeleteSubList(VictimsList, index, index + VICTIMS_LIST_STRIDE - 1);
		llMessageLinked(LINK_SET, RLV_VICTIM_REMOVED, (string)avatarUuid, "");
	}
	if(VictimKey==avatarUuid) {
		changeCurrentVictim(NULL_KEY);
	}
	//if there isn't a victim any more, we don't need a timer
	if(!llGetListLength(VictimsList) && TimerRunning) {
		llSetTimerEvent(0.0);
		TimerRunning=FALSE;
	}
}

changeCurrentVictim(key newVictimKey) {
	if(newVictimKey!=VictimKey) {
		if(newVictimKey==NULL_KEY || ~llListFindList(VictimsList, [newVictimKey])) {
			//this is a valid key
			VictimKey=newVictimKey;
			llMessageLinked( LINK_SET, UPDATE_CURRENT_VICTIM, (string)VictimKey, "" );
		}
	}
}

addToFreeVictimsList(key avatarUuid) {
	if(!~llListFindList(FreeVictimsList, [avatarUuid])) {
		FreeVictimsList+=avatarUuid;
	}
}

removeFromFreeVictimsList(key avatarUuid) {
	integer index;
	while(~(index=llListFindList(FreeVictimsList, [avatarUuid]))) {
		FreeVictimsList=llDeleteSubList(FreeVictimsList, index, index + FREE_VICTIMS_LIST_STRIDE - 1);
	}
}

addToGrabList(key avatarUuid) {
	if(!~llListFindList(GrabList, [avatarUuid])) {
		GrabList+=[avatarUuid, llGetUnixTime() + RLV_ASK_TIMEOUT];
		while (llGetListLength(GrabList) > GRAB_LIST_MAX_ENTRIES * GRAB_LIST_STRIDE) {
			GrabList=llList2List(GrabList, GRAB_LIST_STRIDE, -1);
		}
	}
}

removeFromGrabList(key avatarUuid) {
	integer index;
	while(~(index=llListFindList(GrabList, [avatarUuid]))) {
		GrabList=llDeleteSubList(GrabList, index, index + GRAB_LIST_STRIDE - 1);
	}
}

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

removeFromRecaptureList(key avatarUuid) {
	integer index;
	while(~(index=llListFindList(RecaptureList, [avatarUuid]))) {
		RecaptureList=llDeleteSubList(RecaptureList, index, index + RECAPTURE_LIST_STRIDE - 1);
	}
}
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

string stringReplace( string str, string search, string replace ) {
	return llDumpList2String(
	llParseStringKeepNulls( str, [ search ], [] ), replace );
}

showMenu( key targetKey, string prompt, list buttons, string menuPath) {
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

showMainMenu(key targetKey) {
	list buttons;
	integer toucherIsVictim=~llListFindList(VictimsList, [targetKey]);
	integer numberOfVictims=llGetListLength(VictimsList)/VICTIMS_LIST_STRIDE;

	if(!toucherIsVictim) {
		buttons+=[MENU_RLV_CAPTURE];
		if(isRestrictionsMenuAllowed(targetKey)) {
			buttons+=[MENU_RLV_RESTRICTIONS];
		}
		buttons+=[BUTTON_RLV_RELEASE, BUTTON_RLV_UNSIT];
	}
	if(isTimerMenuAllowed(targetKey)) {
		buttons+=[MENU_RLV_TIMER];
	}
	if(numberOfVictims) {
		buttons+=[MENU_RLV_VICTIMS];
	}
	showMenu(
		targetKey,
		getSelectedVictimPromt()
		+ PROMPT_RELAY + conditionalString(getVictimRelayVersion(VictimKey), PROMPT_RELAY_YES, PROMPT_RELAY_NO) + NEW_LINE
		+ getVictimTimerString(VictimKey),
		buttons,
		MENU_RLV_MAIN
	);
}

showTimerMenu(key targetKey) {
	if(isTimerMenuAllowed(targetKey)) {
		list buttons=TIMER_BUTTONS1;
		if(!~llListFindList(VictimsList, [targetKey])) {
			buttons+=TIMER_BUTTONS2;
		}
		showMenu(targetKey, getVictimTimerString(VictimKey), buttons, MENU_RLV_MAIN + PATH_SEPARATOR + MENU_RLV_TIMER);
	}
}

showVictimsMenu(key targetKey) {
	// get current list of names for victims menu buttons
	list victimsButtons;
	integer length = llGetListLength(VictimsList);
	integer n;
	for(; n < length; n+=VICTIMS_LIST_STRIDE) {
		victimsButtons += llGetSubString(llKey2Name(llList2Key(VictimsList, n)), 0, BUTTON_MAX_LENGHT - 1);
	}
	showMenu(targetKey, getSelectedVictimPromt() + "Select new active victim.", victimsButtons, MENU_RLV_MAIN + PATH_SEPARATOR + MENU_RLV_VICTIMS);
}


integer isTimerMenuAllowed(key targetKey) {
	//allowed if:
	//- a victim is selected
	//- and the target of the menu is not a victim, or the timer of the selected victim is already running
	return VictimKey!=NULL_KEY && (!~llListFindList(VictimsList, [targetKey]) || getVictimTimer(VictimKey));
}

integer isRestrictionsMenuAllowed(key targetKey) {
	//allowed if:
	//- a victim is selected
	//- and the toucher isn't a victim
	//- and the victims RLV is already detected
	//- and the RLV+ RestrictionsMenu Script is available
	return VictimKey!=NULL_KEY && !~llListFindList(VictimsList, [targetKey]) && getVictimRelayVersion(VictimKey) && RlvRestrictionsMenuAvailable;
}


// send rlv commands to the RLV relay, usable for common format (not ping)
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


removeVictimTimer(key avatarUuid) {
	integer index=llListFindList(VictimsList, [avatarUuid]);
	if(~index) {
		VictimsList=llListReplaceList(VictimsList, [0], index + VICTIMS_LIST_TIMER, index + VICTIMS_LIST_TIMER);
	}
}

addTimeToVictim(key avatarUuid, integer time) {
	integer index=llListFindList(VictimsList, [avatarUuid]);
	if(~index) {
		integer thisTime=llGetUnixTime();
		integer oldTime=llList2Integer(VictimsList, index + VICTIMS_LIST_TIMER);
		if(oldTime<thisTime) {
			oldTime=thisTime;
		}
		integer newTime=oldTime + time;
		// if used via menu, almost nobody like the timer to be triggered by substracting time.
		// To stop the timer they can use the Reset button
		if(newTime < thisTime + 30) {
			newTime=thisTime + 30;
		}
		VictimsList=llListReplaceList(VictimsList, [newTime], index + VICTIMS_LIST_TIMER, index + VICTIMS_LIST_TIMER);
		if(!TimerRunning) {
			llSetTimerEvent(1.0);
			TimerRunning=TRUE;
		}
	}
}

integer getVictimTimer(key avatarUuid) {
	integer index=llListFindList(VictimsList, [avatarUuid]);
	if(~index) {
		integer time=llList2Integer(VictimsList, index + VICTIMS_LIST_TIMER) - llGetUnixTime();
		if(time>0) {
			return time;
		}
	}
	return 0;
}

string getVictimTimerString(key avatarUuid) {
	string returnValue="Timer: ";
	integer runningTimeS=getVictimTimer(avatarUuid);
	if(!runningTimeS) {
		return returnValue + TIMER_NO_TIME + NEW_LINE;
	}
	integer runningTimeM=runningTimeS / 60;
	runningTimeS=runningTimeS % 60;
	integer runningTimeH=runningTimeM / 60;
	runningTimeM=runningTimeM % 60;
	integer runningTimeD=runningTimeH / 24;
	runningTimeH=runningTimeH % 24;
	
	return 
		returnValue
		+ conditionalString(runningTimeD, (string)runningTimeD + "d ", "")
		+ llGetSubString("0"+(string)runningTimeH, -2, -1)
		+ ":"
		+ llGetSubString("0"+(string)runningTimeM, -2, -1)
		+ ":"
		+ llGetSubString("0"+(string)runningTimeS, -2, -1)
	;
}

string conditionalString(integer conditon, string valueIfTrue, string valueIfFalse) {
	if(conditon) {
		return valueIfTrue;
	}
	return valueIfFalse;
}


string getSelectedVictimPromt() {
	return PROMPT_VICTIM + conditionalString(VictimKey!=NULL_KEY, llKey2Name(VictimKey), NO_VICTIM) + NEW_LINE;
}

integer getVictimRelayVersion(key targetKey) {
	integer index=llListFindList(VictimsList, [targetKey]);
	if(~index) {
		return llList2Integer(VictimsList, index + VICTIMS_LIST_RELAY);
	}
	return 0;
}
setVictimRelayVersion(key targetKey, integer relayVersion) {
	integer index=llListFindList(VictimsList, [targetKey]);
	if(~index) {
		VictimsList=llListReplaceList(VictimsList, [relayVersion], index + VICTIMS_LIST_RELAY, index + VICTIMS_LIST_RELAY);
	}
}

releaseAvatar(key targetKey) {
	sendToRlvRelay(targetKey, RLV_COMMAND_RELEASE, "");
	addToFreeVictimsList(targetKey);
	removeFromVictimsList(targetKey);
}

unsitAvatar(key targetKey) {
	sendToRlvRelay(targetKey, "@unsit=y", "");
	llSleep(0.75);
	sendToRlvRelay(targetKey, "@unsit=force", "");
	llSleep(0.75);
	releaseAvatar(targetKey);
}

// --- states

default {
	state_entry() {
		llListen( RLV_RELAY_CHANNEL, "", NULL_KEY, "");
		MyUniqueId=llGenerateKey();
		//anounce myself
		llMessageLinked(LINK_SET, PLUGIN_PONG, PLUGIN_NAME, "");
		//check the Restrictions Menu Plugin
		llMessageLinked(LINK_SET, PLUGIN_PING, PLUGIN_NAME_RLV_RESTRICTIONS_MENU, "");
	}

	link_message( integer sender, integer num, string str, key id ) {
		if(num==PLUGIN_PING) {
			if(str==PLUGIN_NAME) {
				llMessageLinked(LINK_SET, PLUGIN_PONG, PLUGIN_NAME, "");
			}
		}
		else if(num==PLUGIN_PONG) {
			if(str==PLUGIN_NAME_RLV_RESTRICTIONS_MENU) {
				RlvRestrictionsMenuAvailable=TRUE;
			}
		}
		else if(num==DIALOG_RESPONSE) {
			if(id==MyUniqueId) {
				//its for me
				list params = llParseString2List(str, ["|"], []);
				string selection = llList2String(params, 1);
				Path=llList2String(params, 3);
				NPosetoucherID=(key)llList2String(params, 2);
				list pathparts = llParseString2List( Path, [PATH_SEPARATOR], [] );
				
				integer toucherIsVictim=~llListFindList(VictimsList, [NPosetoucherID]);
	
				//llOwnerSay( "Path: '" + Path + "' Selection: " + selection );
	
				if(selection == BACKBTN) {
					// back button hit
					selection=llList2String(pathparts, -2);
					if(Path == MENU_RLV_MAIN) {
						//Path is at root menu, remenu nPose
						llMessageLinked( LINK_SET, DOMENU, NPosePath, NPosetoucherID );
						return;
					}
					else if(selection==MENU_RLV_MAIN) {
						//the menu changed to the Main/Root Menu, show it
						showMainMenu(NPosetoucherID);
						return;
					}
					else {
						//the menu changed to a menu below the Main Menu, correct the path and selection and continue in this event
						pathparts=llDeleteSubList(pathparts, -2, -1);
						Path = llDumpList2String(pathparts, PATH_SEPARATOR);
					}
				}
				if( Path == MENU_RLV_MAIN ) {
					if( selection == MENU_RLV_CAPTURE ) {
						//switch to the Capture Menu
						if(!~llListFindList(VictimsList, [NPosetoucherID])) {
							llSensor("", NULL_KEY, AGENT, RLV_captureRange, PI);
						}
						else {
							showMainMenu(NPosetoucherID);
						}
					}
					else if(selection==MENU_RLV_RESTRICTIONS) {
						//call the RLV_RESTRICTIONS_MENU script
						llMessageLinked(LINK_SET, RLV_RESTRICTIONS_MENU, "showMenu,"+(string)NPosetoucherID, "");
					}
					else if( selection == BUTTON_RLV_RELEASE) {
						//release victim and reshow Main Menu
						if(!~llListFindList(VictimsList, [NPosetoucherID])) {
							releaseAvatar(VictimKey);
						}
						showMainMenu( NPosetoucherID );
					}
					else if( selection == BUTTON_RLV_UNSIT ) {
						if(!~llListFindList(VictimsList, [NPosetoucherID])) {
							unsitAvatar(VictimKey);
						}
						showMainMenu(NPosetoucherID);
					}
					
					else if( selection == MENU_RLV_TIMER ) {
						//build and show the Timer Menu
						showTimerMenu(NPosetoucherID);
					}
					else if( selection == MENU_RLV_VICTIMS ) {
						//build and show the Victims Menu
						showVictimsMenu(NPosetoucherID);
					}
					return;
				}

				else if( Path == MENU_RLV_MAIN + PATH_SEPARATOR + MENU_RLV_CAPTURE ) {
					if(!~llListFindList(VictimsList, [NPosetoucherID])) {
						integer n=llListFindList(SensorList, [selection]);
						if(~n) {
							key avatarWorkingOn=llList2Key(SensorList, n + SENSOR_LIST_AVATAR_UUID);
							integer counter  = llGetNumberOfPrims();
							while(llGetAgentSize(llGetLinkKey(counter))) {
								if(avatarWorkingOn==llGetLinkKey(counter)) {
									//the avatar we want to capture is already sitting
									if(~llListFindList(VictimsList, [avatarWorkingOn])) {
										//The Avatar is in the victims list, this means he is sitting on an RLV enabled seat. Reapply RLV Base Restrictions.
										sendToRlvRelay(avatarWorkingOn, RlvBaseRestrictions, "");
										changeCurrentVictim(avatarWorkingOn);
										//send the user back to main Menu
										showMainMenu(NPosetoucherID);
										return;
									}
									else if(~llListFindList(FreeVictimsList, [avatarWorkingOn])) {
										//this is a previously released victim, regrab him
										removeFromFreeVictimsList(avatarWorkingOn);
										addToVictimsList(avatarWorkingOn, RLV_grabTimer);
										changeCurrentVictim(avatarWorkingOn);
										// send them back to the nPose menu cause current victim doesn't
										// update real time.  this will give time to update
										Path = "";
										llMessageLinked( LINK_SET, DOMENU, NPosePath, NPosetoucherID );
										return;
									}
									else {
										//he is NOT a victim .. that implies that he sits on a NON RLV enabled seat. Do nothing
										showMainMenu(NPosetoucherID);
										return;
									}
								}
								counter--;
							}
							//if we come to this point, the Avatar is not sitting. Make him sit.
							//he will become a real victim when sitting on a RLV enabled seat
							addToGrabList(avatarWorkingOn);
							sendToRlvRelay(avatarWorkingOn, "@sit:" + (string)llGetKey() + "=force", "");
		
							// send them back to the nPose menu cause current victim doesn't
							// update real time.  this will give time to update
							Path = "";
							llMessageLinked( LINK_SET, DOMENU, NPosePath, NPosetoucherID );
						}
					}
				}
				else if( Path == MENU_RLV_MAIN + PATH_SEPARATOR + MENU_RLV_TIMER ) {
					//timer
					if(isTimerMenuAllowed(NPosetoucherID)) {
						if(selection=="Reset") {
							removeVictimTimer(VictimKey);
						}
						else if(llGetSubString( selection, 0, 0 ) == "-" || llGetSubString( selection, 0, 0 ) == "+") {
							integer multiplier=60;
							string unit=llGetSubString( selection, -1, -1 );
							if(unit=="h") {
								multiplier=3600;
							}
							else if(unit=="d") {
								multiplier=86400;
							}
							else if(unit=="w") {
								multiplier=604800;
							}
							addTimeToVictim(VictimKey, multiplier * (integer)llGetSubString(selection, 0, -2));
						}
						showTimerMenu(NPosetoucherID);
					}
				}
	
				else if(Path == MENU_RLV_MAIN + PATH_SEPARATOR + MENU_RLV_VICTIMS) {
					// someone changed current victim..
					integer length = llGetListLength( VictimsList );
					integer n;
					for(; n < length; n+=VICTIMS_LIST_STRIDE ) {
						key avatarWorkingOn=llList2Key( VictimsList, n);
						if(llGetSubString(llKey2Name(avatarWorkingOn), 0, BUTTON_MAX_LENGHT - 1) == selection) {
							changeCurrentVictim(avatarWorkingOn);
						}
					}
					showMainMenu(NPosetoucherID);
				}
			}
		}

		// end of DIALOG_RESPONSE

		// messages comming in from BTN notecard commands
		// or other scripts linkMessages
		else if( num == RLV_CORE ) {
			list temp=llParseStringKeepNulls(str,[","], []);
			string cmd=llToLower(llStringTrim(llList2String(temp, 0), STRING_TRIM));
			key target=(key)stringReplace(llStringTrim(llList2String(temp, 1), STRING_TRIM), "%VICTIM%", (string)VictimKey);
			list params=llDeleteSubList(temp, 0, 1);
			
			if(target) {}
			else {
				target=VictimKey;
			}
			
			if(cmd=="showmenu") {
				string menuName=llToLower(llStringTrim(llList2String(params, 0), STRING_TRIM));
				if(menuName=="" || menuName=="main") {
					showMainMenu(target);
				}
				else if(menuName=="victims") {
					showVictimsMenu(target);
				}
				else if(menuName=="capture") {
					//TODO: slmember1: I think thats realy ugly
					if(!~llListFindList(VictimsList, [target])) {
						NPosetoucherID=target;
						llSensor("", NULL_KEY, AGENT, RLV_captureRange, PI);
					}
				}
				else if(menuName=="timer") {
					showTimerMenu(target);
				}
			}
			else if(cmd=="rlvcommand") {
				sendToRlvRelay(target, stringReplace(llList2String(params, 0), "/","|" ), "");
			}
			else if(cmd == "release") {
				releaseAvatar(target);
			}
			else if(cmd == "unsit") {
				unsitAvatar(target);
			}
			else if(cmd == "addtime") {
				addTimeToVictim(target, (integer)llList2String(params, 0));
			}
			else if(cmd == "resettime") {
				removeVictimTimer(target);
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
			else if(cmd=="setselectedvictim") {
				changeCurrentVictim(target);
			}
		} // end of RLV_RELAY_CHANNEL

		// Jesa: what does -802 mean? => constant
		// we get current nPose path and id here. use it to remenu nPose once we are finished.
		// slmember1: TODO: is that safe if multiple users clicking menu buttons?
		else if( num == -802) {
			NPosePath      = str;
			//toucher comes in the DIALOG_RESPONSE Message;
			//NPosetoucherID = id;
		}

		else if( num == SEAT_UPDATE ) {
			recaptureListRemoveTimedOutEntrys();
			grabListRemoveTimedOutEntrys();
			FreeNonRlvEnabledSeats=0;
			FreeRlvEnabledSeats=0;
			list slotsList = llParseStringKeepNulls( str, ["^"], [] );
			integer length = llGetListLength( slotsList );
			integer index;
			for(; index < length; index+=8) {
				key avatarWorkingOn=(key)llList2String(slotsList, index+4);
				integer seatNumber=index/8+1;
				integer isRlvEnabledSeat=~llListFindList(RLV_enabledSeats, ["*"]) || ~llListFindList(RLV_enabledSeats, [(string)seatNumber]);
				if(avatarWorkingOn) {
					if(isRlvEnabledSeat) {
						//This is a RLV enabled seat
						if(!~llListFindList(VictimsList, [avatarWorkingOn])) {
							//This avatar is currently no Vicitim
							if(~llListFindList(GrabList, [avatarWorkingOn])) {
								//Avatar is grabbed by someone
								addToVictimsList(avatarWorkingOn, RLV_grabTimer);
								changeCurrentVictim(avatarWorkingOn);
							}
							else if(~llListFindList(RecaptureList, [avatarWorkingOn])) {
								//Avatar is recaptured, due previously safeword or Logoff/Logon
								addToVictimsList(avatarWorkingOn, llList2Integer(RecaptureList, llListFindList(RecaptureList, [avatarWorkingOn]) + RECAPTURE_LIST_TIMER));
								changeCurrentVictim(avatarWorkingOn);
							}
							else if(~llListFindList(FreeVictimsList, [avatarWorkingOn])) {
								//the avatar ist free, do nothing
							}
							else {
								//Avatar sits down voluntary
								addToVictimsList(avatarWorkingOn, RLV_trapTimer);
								changeCurrentVictim(avatarWorkingOn);
							}
						}
					}
					else {
						//This is NOT a RLV enabled seat
						if(~llListFindList(VictimsList, [avatarWorkingOn]) || ~llListFindList(RecaptureList, [avatarWorkingOn])) {
							sendToRlvRelay(avatarWorkingOn, RLV_COMMAND_RELEASE, "");
						}
						removeFromVictimsList(avatarWorkingOn);
						removeFromFreeVictimsList(avatarWorkingOn);
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
				if(~llListFindList(GrabList, [avatarWorkingOn])) {
					removeFromGrabList(avatarWorkingOn);
				}
				if(~llListFindList(RecaptureList, [avatarWorkingOn])) {
					removeFromRecaptureList(avatarWorkingOn);
				}
			}
			//Garbage Collection
			length=llGetListLength(FreeVictimsList);
			index=0;
			for(; index < length; index+=FREE_VICTIMS_LIST_STRIDE) {
				key avatarWorkingOn=llList2Key(FreeVictimsList, index);
				if(!~llListFindList(slotsList, [(string)avatarWorkingOn])) {
					removeFromFreeVictimsList(avatarWorkingOn);
				}
			}

			//If there is a Avatar in victims list but
			//not sitting and not in freeVictims list, this means he escaped
			length=llGetListLength(VictimsList);
			index=0;
			for(; index < length; index+=VICTIMS_LIST_STRIDE) {
				key avatarWorkingOn=llList2Key(VictimsList, index);
				if(!~llListFindList(slotsList, [(string)avatarWorkingOn])) {
					if(getVictimRelayVersion(avatarWorkingOn)) {
						//if the avatar had an active RLV Relay while he becomes a victim, we could try to recapture him in the future
						addToRecaptureList(avatarWorkingOn, llList2Integer(VictimsList, index + VICTIMS_LIST_TIMER) - llGetUnixTime());
					}
					removeFromVictimsList(avatarWorkingOn);
					index-=VICTIMS_LIST_STRIDE;
					length-=VICTIMS_LIST_STRIDE;
				}
			}
		}
		else if (num==OPTIONS) {
			list optionsToSet = llParseStringKeepNulls(str, ["~"], []);
			integer length = llGetListLength(optionsToSet);
			integer n;
			for (; n<length; ++n){
				list optionsItems = llParseString2List(llList2String(optionsToSet, n), ["="], []);
				string optionItem = llToLower(llStringTrim(llList2String(optionsItems, 0), STRING_TRIM));
				string optionSetting = llStringTrim(llList2String(optionsItems, 1), STRING_TRIM);
				if (optionItem == "rlv_capturerange") {
					RLV_captureRange = (integer)optionSetting;
				}
				else if (optionItem == "rlv_traptimer") {
					RLV_trapTimer = (integer)optionSetting;
				}
				else if (optionItem == "rlv_grabtimer") {
					RLV_grabTimer = (integer)optionSetting;
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
			debug(["VictimsList"] + VictimsList);
			debug(["FreeVictimsList"] + FreeVictimsList);
			debug(["GrabList"] + GrabList);
			debug(["RecaptureList"] + RecaptureList);
		}
	} // link_message

	changed( integer change ) {
		if( change & CHANGED_OWNER ) {
			llResetScript();
		}
		else if(change & CHANGED_INVENTORY) {
			//check the Restrictions Menu Plugin
			RlvRestrictionsMenuAvailable=FALSE;
			llMessageLinked(LINK_SET, PLUGIN_PING, PLUGIN_NAME_RLV_RESTRICTIONS_MENU, "");
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
				if(command==RLV_COMMAND_VERSION) {
					setVictimRelayVersion(senderAvatarId, (integer)reply);
				}
				else if(command==RLV_COMMAND_RELEASE) {
					if(reply=="ok") {
						//the relay cancels the active session (perhaps by safewording), set the victim free
						if(~llListFindList(VictimsList, [senderAvatarId])) {
							addToFreeVictimsList(senderAvatarId);
						}
						removeFromVictimsList(senderAvatarId);
						removeFromGrabList(senderAvatarId);
						removeFromRecaptureList(senderAvatarId);
					}
				}
				else if(command==RLV_COMMAND_PING) {
					if(cmd_name==command && reply==command) {
						// if someone sends a ping message, that means that the Avatar was previously restricted by us.
						// so if we have a free sub seat we will answere
						// else we remove the avatar from the recapture list and he can do whatever he want
						// so what could happen after the Avatar is seated by his relay?
						// 1.) the avatar could be routed to a dom seat due to the fact that the dom seat is the next free seat (that should not happen if we define the sub seats at the begining of the slot list)
						// 2.) perhaps the avatar could cheat and not get seated, in this case we need a timeout in the recapture list, so we could remove after the timeout triggers. That is necessary because if he sits down somtime later, he could be in the recapture list and so the recapture timer would be aplied (and not the grab/trap timer)
						recaptureListRemoveTimedOutEntrys(); //this maybe shorten the list
						integer index=llListFindList(RecaptureList, [senderAvatarId]);
						if(~index) {
							//we know him and we want him
							if(FreeRlvEnabledSeats) {
								RecaptureList=llListReplaceList(RecaptureList, [llGetUnixTime() + RLV_ASK_TIMEOUT], index, index + RECAPTURE_LIST_STRIDE - 1);
								llSay(RLV_RELAY_CHANNEL, RLV_COMMAND_PING + "," + (string)senderAvatarId + "," + RLV_COMMAND_PONG);
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

	timer() {
		integer currentTime=llGetUnixTime();
		integer length=llGetListLength(VictimsList);
		integer index;
		for(; index<length; index+=VICTIMS_LIST_STRIDE) {
			integer time=llList2Integer(VictimsList, index + VICTIMS_LIST_TIMER);
			if(time && time<=currentTime) {
				key avatarWorkingOn=llList2Key(VictimsList, index);
				sendToRlvRelay(avatarWorkingOn, RLV_COMMAND_RELEASE, "");
				removeFromVictimsList(avatarWorkingOn);
				addToFreeVictimsList(avatarWorkingOn);
			}
		}
	}

	sensor(integer num) {
		// give menu the list of potential victims
		SensorList=[];
		integer n;
		for( n=0; n<num; ++n ) {
			SensorList += [llGetSubString(llDetectedName(n), 0, BUTTON_MAX_LENGHT - 1), llDetectedKey(n)];
		}
		showMenu(NPosetoucherID, PROMPT_CAPTURE, llList2ListStrided(SensorList, 0, -1, 2), MENU_RLV_MAIN + PATH_SEPARATOR + MENU_RLV_CAPTURE);
	}

	no_sensor() {
		SensorList=[];
		showMenu(NPosetoucherID, PROMPT_CAPTURE, [], MENU_RLV_MAIN + PATH_SEPARATOR + MENU_RLV_CAPTURE);
	}
} // state default
