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

to show a menu to a user, the following steps are done:
1.) showMenu: the initial step, if there are informations needed but missing they will be gathered and the proceess continues with the next step
2.) displayMenu: here the permissions are checked. If permissions are not ok, the main menu will be rendered
3.) renderMenu: the final step: sending the DIALOG linkMessage to nPose
*/


$import LSLScripts.constants.lslm ();

string PLUGIN_NAME="RLV_RESTRICTIONS_MENU";

string STRING_PROMPT_VICTIM_CAPTION="Selected Victim: ";
string STRING_PROMPT_VICTIM_NONE="NONE";
string STRING_PROMPT_VICTIM_SELECT="Select new active victim.";
string STRING_PROMPT_RESTRICTIONS_CAPTION="Active restrictions are: ";
string STRING_PROMPT_RESTRICTIONS_NONE="NONE. Victim may be FREE.";
string STRING_PROMPT_RELAY_CAPTION="RLV Relay: ";
string STRING_PROMPT_RELAY_DETECTED="OK";
string STRING_PROMPT_RELAY_NOTDETECTED="NOT RECOGNIZED";
string STRING_PROMPT_TIMER_CAPTION="Timer: ";
string STRING_PROMPT_TIMER_ZERO="--:--:--";

string MENU_BUTTON_BACK ="^";
string MENU_MAIN           ="RLVMain";
string MENU_CAPTURE        ="→Capture";
string MENU_RESTRICTIONS   ="→Restrictions";
string MENU_UNDRESS        ="→Undress";
string MENU_ATTACHMENTS    ="→Attachments";
string MENU_VICTIMS        ="→Victims";
string MENU_TIMER          ="→Timer";
string MENU_BUTTON_RELEASE ="Release";
string MENU_BUTTON_UNSIT   ="Unsit";

string PATH_SEPARATOR=":";
integer BUTTON_MAX_LENGHT=16;


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

list TIMER_BUTTONS1 = [
	"+1d", "+6h", "+1h", "+15m", "+1m"
];
list TIMER_BUTTONS2 = [
	"-1d", "-6h", "-1h", "-15m", "-1m",
	"Reset"
];


key	MyUniqueId;

integer rlvResponseChannel;
integer rlvResponseHandle;

key VictimKey=NULL_KEY;  // contains active victim key

list VictimsList; //Avatars in this list are sitting on an rlvEnabled seat and are considered as restricted
//integer VICTIMS_LIST_AVATAR_UUID=0;
integer VICTIMS_LIST_TIMER=1;
integer VICTIMS_LIST_RELAY=2; //version of the rlv relay protocol (0: means no relay detected)
integer VICTIMS_LIST_STRIDE=3;

list SensorList; //a temp list for grabbing
//integer SENSOR_LIST_AVATAR_NAME=0;
integer SENSOR_LIST_AVATAR_UUID=1;
integer SENSOR_LIST_STRIDE=2;

list UsersList; //Avatars that uses the menu
//integer USERS_LIST_CHANNEL=0
integer USERS_LIST_HANDLE=1;
integer USERS_LIST_MENU_TARGET=2;
integer USERS_LIST_MENU_NAME=3;
integer USERS_LIST_TIMEOUT=4;
integer USERS_LIST_STRIDE=5;

key sensorUserKey;

// using the NPosePath and NPoseButtonName as a global string instead of storing it for every user, means
// that there can only be one RLV button in the menu tree. That seems to be OK for me.
string NPosePath;
string NPoseButtonName;

float RLV_grabRange=10.0;


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
	return llListFindList(VictimsList, [(string)avatarUuid]);
}

// NO pragma inline
integer getVictimRelayVersion(key avatarUuid) {
	integer relayVersion;
	integer index=getVictimIndex(avatarUuid);
	if(~index) {
		relayVersion=llList2Integer(VictimsList, index + VICTIMS_LIST_RELAY);
	}
	return relayVersion;
}

// NO pragma inline
integer getVictimTimer(key avatarUuid) {
	integer time;
	integer index=getVictimIndex(avatarUuid);
	if(~index) {
		time=llList2Integer(VictimsList, index + VICTIMS_LIST_TIMER) - llGetUnixTime();
		if(time<0) {
			time=0;
		}
	}
	return time;
}

// pragma inline
addTimeToVictim(key avatarUuid, integer time) {
	integer index=getVictimIndex(avatarUuid);
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
		setVictimTimer(avatarUuid, newTime);
	}
}

// NO pragma inline
setVictimTimer(key avatarUuid, integer time) {
	integer index=getVictimIndex(avatarUuid);
	if(~index) {
		VictimsList=llListReplaceList(VictimsList, [time], index + VICTIMS_LIST_TIMER, index + VICTIMS_LIST_TIMER);
		llMessageLinked(LINK_SET, RLV_CORE_COMMAND, "setTimer," + (string)avatarUuid + "," + (string)time, NULL_KEY);
	}
}

// NO pragma inline
string getVictimTimerString(key avatarUuid) {
	string returnValue="Timer: ";
	integer runningTimeS=getVictimTimer(avatarUuid);
	if(!runningTimeS) {
		return returnValue + STRING_PROMPT_TIMER_ZERO + STRING_NEW_LINE;
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

// NO pragma inline
string conditionalString(integer conditon, string valueIfTrue, string valueIfFalse) {
	string ret=valueIfFalse;
	if(conditon) {
		ret=valueIfTrue;
	}
	return ret;
}

// NO pragma inline
removeFromUsersList(integer index) {
	if(~index) {
		llListenRemove(llList2Integer(UsersList, index + USERS_LIST_HANDLE));
		UsersList=llDeleteSubList(UsersList, index, index + USERS_LIST_STRIDE - 1);
	}
	if(!llGetListLength(UsersList)) {
		llSetTimerEvent(0.0);
	}
}

// NO pragma inline
integer addToUsersList(key menuTarget, string menuName) {
	integer index=llListFindList(UsersList, [menuTarget, menuName]) - USERS_LIST_MENU_TARGET;
	removeFromUsersList(index);
	integer channel=(integer)(llFrand(1000000000.0) + 1000000000.0); //RLVa needs positive Channel numbers
	UsersList+=[channel, llListen(channel, "", NULL_KEY, ""), menuTarget, menuName, llGetUnixTime() + RLV_RELAY_TIMEOUT];
	llSetTimerEvent(1.0);
	return channel;
}

// NO pragma inline
init() {
	MyUniqueId=llGenerateKey();
	llListenRemove(rlvResponseHandle);
	rlvResponseChannel=(integer)(llFrand(-1000000000.0) - 1000000000.0);
	rlvResponseHandle=llListen(rlvResponseChannel, "", NULL_KEY, "");
}

// NO pragma inline
showMenu(key menuTarget, string menuName) {
	if(menuName==MENU_CAPTURE) {
		if(RLV_grabRange) {
			sensorUserKey=menuTarget;
			llSensor("", NULL_KEY, AGENT_BY_LEGACY_NAME, RLV_grabRange, PI);
		}
		else {
			displayMenu(menuTarget, menuName, "", []);
		}
	}
	else if(menuName==MENU_RESTRICTIONS) {
		integer channel=addToUsersList(menuTarget, menuName);
		llMessageLinked(LINK_SET, RLV_CORE_COMMAND, "rlvCommand,%VICTIM%,@getstatus=" + (string)channel, NULL_KEY);
	}
	else if(menuName==MENU_UNDRESS) {
		integer channel=addToUsersList(menuTarget, menuName);
		llMessageLinked(LINK_SET, RLV_CORE_COMMAND, "rlvCommand,%VICTIM%,@getoutfit=" + (string)channel, NULL_KEY);
	}
	else if(menuName==MENU_ATTACHMENTS) {
		integer channel=addToUsersList(menuTarget, menuName);
		llMessageLinked(LINK_SET, RLV_CORE_COMMAND, "rlvCommand,%VICTIM%,@getattach=" + (string)channel, NULL_KEY);
	}
	else if(~llListFindList(RLV_RESTRICTIONS, [menuName])) {
		integer channel=addToUsersList(menuTarget, menuName);
		llMessageLinked(LINK_SET, RLV_CORE_COMMAND, "rlvCommand,%VICTIM%,@getstatus=" + (string)channel, NULL_KEY);
	}
	else {
		if(menuName=="") {
			menuName=MENU_MAIN;
		}
		displayMenu(menuTarget, menuName, "", []);
	}
}

// NO pragma inline
displayMenu(key menuTarget, string menuName, string additionalPrompt, list additionalButtons) {
	list buttons;
	string prompt=getSelectedVictimPromt();

	integer index=llListFindList(UsersList, [menuTarget, menuName]) - USERS_LIST_MENU_TARGET;
	removeFromUsersList(index);

	if(menuName==MENU_VICTIMS) {
		if(isVictimMenuAllowed(menuTarget)) {
			// get current list of names for victims menu buttons
			integer length = llGetListLength(VictimsList);
			integer n;
			for(; n < length; n+=VICTIMS_LIST_STRIDE) {
				buttons += llGetSubString(llKey2Name(llList2Key(VictimsList, n)), 0, BUTTON_MAX_LENGHT - 1);
			}
			renderMenu(menuTarget, prompt + STRING_PROMPT_VICTIM_SELECT, buttons, MENU_MAIN + PATH_SEPARATOR + MENU_VICTIMS);
		}
		else {
			menuName=MENU_MAIN;
		}
	}
	else if(menuName==MENU_CAPTURE) {
		if(isCaptureMenuAllowed(menuTarget)) {
			renderMenu(menuTarget, STRING_PROMPT_VICTIM_SELECT, additionalButtons, MENU_MAIN + PATH_SEPARATOR + MENU_CAPTURE);
		}
		else {
			menuName=MENU_MAIN;
		}
	}
	else if(menuName==MENU_TIMER) {
		if(isTimerMenuAllowed(menuTarget)) {
			buttons=TIMER_BUTTONS1;
			if(!~getVictimIndex(menuTarget)) {
				buttons+=TIMER_BUTTONS2;
			}
			renderMenu(menuTarget, prompt + getVictimTimerString(VictimKey), buttons, MENU_MAIN + PATH_SEPARATOR + MENU_TIMER);
		}
		else {
			menuName=MENU_MAIN;
		}
	}
	else if(menuName==MENU_RESTRICTIONS || menuName==MENU_UNDRESS || menuName==MENU_ATTACHMENTS || ~llListFindList(RLV_RESTRICTIONS, [menuName])) {
		if(isRestrictionsMenuAllowed(menuTarget)) {
			string path=MENU_MAIN + PATH_SEPARATOR + MENU_RESTRICTIONS;
			if(menuName!=MENU_RESTRICTIONS) {
				path+=PATH_SEPARATOR + menuName;
			}
			renderMenu(menuTarget, prompt + additionalPrompt, additionalButtons, path);
		}
		else {
			menuName=MENU_MAIN;
		}
	}
	
	//The Main Menu is also a Fallback menu
	if(menuName==MENU_MAIN) {
		if(isCaptureMenuAllowed(menuTarget)) {
			buttons+=[MENU_CAPTURE];
		}
		if(isRestrictionsMenuAllowed(menuTarget)) {
			buttons+=[MENU_RESTRICTIONS];
		}
		if(isReleaseButtonAllowed(menuTarget)) {
			buttons+=[MENU_BUTTON_RELEASE];
		}
		if(isUnsitButtonAllowed(menuTarget)) {
			buttons+=[MENU_BUTTON_UNSIT];
		}
		if(isTimerMenuAllowed(menuTarget)) {
			buttons+=[MENU_TIMER];
		}
		if(isVictimMenuAllowed(menuTarget)) {
			buttons+=[MENU_VICTIMS];
		}
		if(VictimKey) {
			prompt
				+=STRING_PROMPT_RELAY_CAPTION + conditionalString(getVictimRelayVersion(VictimKey), STRING_PROMPT_RELAY_DETECTED, STRING_PROMPT_RELAY_NOTDETECTED) + STRING_NEW_LINE
				+ getVictimTimerString(VictimKey)
			;
		}
		renderMenu(
			menuTarget,
			prompt,
			buttons,
			MENU_MAIN
		);
	}
}

// NO pragma inline
renderMenu(key targetKey, string prompt, list buttons, string menuPath) {
	if(targetKey) {
		//make the path global
		menuPath=NPosePath + PATH_SEPARATOR + NPoseButtonName + llDeleteSubString(menuPath, 0, llStringLength(MENU_MAIN)-1);
		llMessageLinked( LINK_SET, DIALOG,
			(string)targetKey
			+ "|" +
			prompt + STRING_NEW_LINE + menuPath + STRING_NEW_LINE
			+ "|" +
			(string)0
			+ "|" +
			llDumpList2String(buttons, "`")
			+ "|" +
			MENU_BUTTON_BACK
			+ "|" +
			menuPath
			, MyUniqueId
		);
	}
}

// pragma inline
string getSelectedVictimPromt() {
	if(VictimKey) {
		return STRING_PROMPT_VICTIM_CAPTION + llKey2Name(VictimKey) + STRING_NEW_LINE;
	}
	else {
		return STRING_PROMPT_VICTIM_CAPTION + STRING_PROMPT_VICTIM_NONE + STRING_NEW_LINE;
	}
}

// pragma inline
integer isCaptureMenuAllowed(key targetKey) {
	//allowed if:
	//- the toucher isn't a victim
	return !~getVictimIndex(targetKey) && RLV_grabRange>0;
}

// pragma inline
integer isRestrictionsMenuAllowed(key targetKey) {
	//allowed if:
	//- a victim is selected
	//- and the toucher isn't a victim
	//- and the victims RLV is already detected
	return VictimKey!=NULL_KEY && !~getVictimIndex(targetKey) && getVictimRelayVersion(VictimKey);
}

// pragma inline
integer isReleaseButtonAllowed(key targetKey) {
	//allowed if:
	//- a victim is selected
	//- and the toucher isn't a victim
	return VictimKey!=NULL_KEY && !~getVictimIndex(targetKey);
}

// pragma inline
integer isUnsitButtonAllowed(key targetKey) {
	//allowed if:
	//- a victim is selected
	//- and the toucher isn't a victim
	return VictimKey!=NULL_KEY && !~getVictimIndex(targetKey);
}

// pragma inline
integer isTimerMenuAllowed(key targetKey) {
	//allowed if:
	//- a victim is selected
	//- and the target of the menu is not a victim, or the timer of the selected victim is already running
	return VictimKey!=NULL_KEY && (!~getVictimIndex(targetKey) || getVictimTimer(VictimKey));
}

// pragma inline
integer isVictimMenuAllowed(key targetKey) {
	//allowed if:
	//- a victim is selected and more than one entry in the vicitms list
	//- no victim is selected and one or more entries in the vicitms list
	return (llGetListLength(VictimsList) > VICTIMS_LIST_STRIDE || (llGetListLength(VictimsList)==VICTIMS_LIST_STRIDE && VictimKey==NULL_KEY));
}

// NO pragma inline
list ParseClothingOrAttachmentLayersWorn(string wornFlags, list allNames) {
	list layersWorn;
	integer length=llStringLength(wornFlags);
	integer i;
	for(; i < length; i+=1) {
		if(llGetSubString(wornFlags, i, i)=="1") {
			string layerName = llList2String(allNames, i);
			if(layerName) {
				layersWorn += [layerName];
			}
		}
	}
	return layersWorn;
}



default {
	state_entry() {
		init();
	}
	link_message( integer sender, integer num, string str, key id ) {
		if( num == -802) {
			NPosePath=str;
			NPoseButtonName=MENU_MAIN;
		}
		else if(num==CHANGE_SELECTED_VICTIM) {
			VictimKey=(key)str;
		}
		else if(num==UPDATE_VICTIMS_LIST) {
			VictimsList=llCSV2List(str);
		}
		else if(num==RLV_MENU_COMMAND) {
			list temp=llParseStringKeepNulls(str,[","], []);
			string cmd=llToLower(llStringTrim(llList2String(temp, 0), STRING_TRIM));
			key target=(key)stringReplace(llStringTrim(llList2String(temp, 1), STRING_TRIM), "%VICTIM%", (string)VictimKey);
			list params=llDeleteSubList(temp, 0, 1);
			
			if(target) {}
			else {
				target=VictimKey;
			}
			
			if(cmd=="showmenu") {
				showMenu(target, llList2String(params, 0));
			}
		}
		else if(num==DIALOG_RESPONSE) {
			if(id==MyUniqueId) {
				//its for me
				list params = llParseString2List(str, ["|"], []);
				string selection = llList2String(params, 1);
				key toucher=(key)llList2String(params, 2);
				string path=llList2String(params, 3);
				//make the path local
				if(!llSubStringIndex(path, NPosePath + PATH_SEPARATOR)) {
					path=llDeleteSubString(path, 0, llStringLength(NPosePath + PATH_SEPARATOR) - 1);
				}
				if(!llSubStringIndex(path, NPoseButtonName)) {
					path=MENU_MAIN + llDeleteSubString(path, 0, llStringLength(NPoseButtonName) - 1);
				}
				list pathParts = llParseString2List( path, [PATH_SEPARATOR], [] );
				if(selection == MENU_BUTTON_BACK) {
					// back button hit
					selection=llList2String(pathParts, -2);
					if(path==MENU_MAIN) {
						//Path is at root menu, remenu nPose
						llMessageLinked( LINK_SET, DOMENU, NPosePath, toucher);
						return;
					}
					else if(selection==MENU_MAIN) {
						//the menu changed to the Main/Root Menu, show it
						showMenu(toucher, MENU_MAIN);
						return;
					}
					else {
						//the menu changed to a menu below the Main Menu, correct the path and selection and continue in this event
						pathParts=llDeleteSubList(pathParts, -2, -1);
						path = llDumpList2String(pathParts, PATH_SEPARATOR);
					}
				}
				if(
					selection==MENU_MAIN
					|| selection==MENU_ATTACHMENTS
					|| selection==MENU_CAPTURE
					|| selection==MENU_RESTRICTIONS
					|| selection==MENU_TIMER
					|| selection==MENU_UNDRESS
					|| selection==MENU_VICTIMS
					|| ~llListFindList(RLV_RESTRICTIONS, [selection])
				) {
					//a Menu should be shown
					showMenu(toucher, selection);
				}
				else {
					//a action button is pressed
					if(path==MENU_MAIN) {
						if(selection==MENU_BUTTON_UNSIT || selection==MENU_BUTTON_RELEASE) {
							if(selection==MENU_BUTTON_UNSIT && isUnsitButtonAllowed(toucher)) {
								llMessageLinked(LINK_SET, RLV_CORE_COMMAND, "unsit,%VICTIM%", NULL_KEY);
								llSleep(1.0);
							}
							else if(selection==MENU_BUTTON_RELEASE && isReleaseButtonAllowed(toucher)) {
								llMessageLinked(LINK_SET, RLV_CORE_COMMAND, "release,%VICTIM%", NULL_KEY);
								llSleep(1.0);
							}
							llMessageLinked(LINK_SET, RLV_MENU_COMMAND, "showMenu," + (string)toucher + "," + MENU_MAIN, NULL_KEY);
						}
					}
					else if (!llSubStringIndex(path, MENU_MAIN + PATH_SEPARATOR + MENU_RESTRICTIONS)){
						if(isRestrictionsMenuAllowed(toucher)) {
							//must be a undress, attachment, or restrictions button
							if(~llListFindList(ATTACHMENT_POINTS, [selection])) {
								llMessageLinked(LINK_SET, RLV_CORE_COMMAND, "rlvCommand,%VICTIM%,@remattach:" + selection + "=force", NULL_KEY);
								llSleep( 0.5 );
								showMenu(toucher, MENU_ATTACHMENTS);
							}
							else if(~llListFindList(CLOTHING_LAYERS, [selection])) {
								llMessageLinked(LINK_SET, RLV_CORE_COMMAND, "rlvCommand,%VICTIM%,@remoutfit:" + selection + "=force", NULL_KEY);
								llSleep( 0.5 );
								showMenu(toucher, MENU_UNDRESS);
							}
							else if(llGetSubString(selection, 0, 0)=="☐") {
								llMessageLinked(LINK_SET, RLV_CORE_COMMAND, "rlvCommand,%VICTIM%,@" + llStringTrim(llDeleteSubString(selection, 0, 1), STRING_TRIM) + "=n", NULL_KEY);
								llSleep( 0.5 );
								showMenu(toucher, llList2String(pathParts, -1));
							}
							else if(llGetSubString(selection, 0, 0)=="☑") {
								llMessageLinked(LINK_SET, RLV_CORE_COMMAND, "rlvCommand,%VICTIM%,@" + llStringTrim(llDeleteSubString(selection, 0, 1), STRING_TRIM) + "=y", NULL_KEY);
								llSleep( 0.5 );
								showMenu(toucher, llList2String(pathParts, -1));
							}
						}
					}
					else if(path==MENU_MAIN + PATH_SEPARATOR + MENU_CAPTURE) {
						if(isCaptureMenuAllowed(toucher)) {
							integer index=llListFindList(SensorList, [selection]);
							if(~index) {
								key avatarWorkingOn=llList2Key(SensorList, index + SENSOR_LIST_AVATAR_UUID);
								llMessageLinked(LINK_SET, RLV_CORE_COMMAND, "grab," + (string)avatarWorkingOn, NULL_KEY);
								if(toucher==avatarWorkingOn) {
									//we don't remenu immediately because the victims list should be updated before the new menu is shown
									//If the relay is in ask mode this break doesn't give us enough time
									llSleep(2.0);
								}
							}
							llMessageLinked(LINK_SET, DOMENU, NPosePath, toucher );
						}
					}
					else if(path==MENU_MAIN + PATH_SEPARATOR + MENU_VICTIMS) {
						if(isVictimMenuAllowed(toucher)) {
							// someone changed current victim..
							integer length=llGetListLength(VictimsList);
							integer index;
							for(; index < length; index+=VICTIMS_LIST_STRIDE ) {
								key avatarWorkingOn=llList2Key( VictimsList, index);
								if(llGetSubString(llKey2Name(avatarWorkingOn), 0, BUTTON_MAX_LENGHT - 1) == selection) {
									VictimKey=avatarWorkingOn;
									llMessageLinked(LINK_SET, CHANGE_SELECTED_VICTIM, (string)VictimKey, "");
								}
							}
						}
						showMenu(toucher, MENU_MAIN);
					}
					else if(path==MENU_MAIN + PATH_SEPARATOR + MENU_TIMER) {
						if(isTimerMenuAllowed(toucher)) {
							if(selection=="Reset") {
								setVictimTimer(VictimKey, 0);
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
							showMenu(toucher, MENU_TIMER);
						}
					}
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
				if (optionItem == "rlv_grabrange") {
					RLV_grabRange = (float)optionSetting;
				}
			}
		}

		else if( num == MEM_USAGE ) {
			llSay( 0, "Memory Used by " + llGetScriptName() + ": "
				+ (string)llGetUsedMemory() + " of " + (string)llGetMemoryLimit()
				+ ", Leaving " + (string)llGetFreeMemory() + " memory free." );
		}
		else if(num==RLV_MENU_DUMP_DEBUG_STRING) {
			if(str=="l") {
				debug(
					  ["VictimsList"] + VictimsList
					+ ["####", "SensorList"] + SensorList
					+ ["####", "UsersList"] + UsersList
				);
			}
			else if(str=="o") {
				debug(
					  ["RLV_grabRange", RLV_grabRange]
				);
			} 
		}
	}
	listen(integer channel, string name, key id, string message) {
		integer indexUsersList;
		string prompt;
		list buttons;
		if(~(indexUsersList=llListFindList(UsersList, [channel]))) {
			key menuTarget=llList2Key(UsersList, indexUsersList + USERS_LIST_MENU_TARGET);
			string menuName=llList2String(UsersList, indexUsersList + USERS_LIST_MENU_NAME);
			removeFromUsersList(indexUsersList);
			integer restrictionsListIndex=llListFindList(RLV_RESTRICTIONS, [menuName]);
			if(menuName==MENU_RESTRICTIONS || ~restrictionsListIndex) {
				list activeRestrictions = llParseString2List( message, [ "/" ], [] );
				integer index;
				integer length=llGetListLength(activeRestrictions);
				for(; index<length; index++) {
					string restrictionWorkingOn=llList2String(activeRestrictions, index);
					if(~llSubStringIndex(restrictionWorkingOn, ":") || ~llListFindList(IGNORED_RLV_RESTRICTIONS, [restrictionWorkingOn])) {
						activeRestrictions=llDeleteSubList(activeRestrictions, index, index);
						--index;
						--length;
					}
				}
				prompt=STRING_PROMPT_RESTRICTIONS_CAPTION + conditionalString(llGetListLength(activeRestrictions), llDumpList2String(activeRestrictions, ", "), STRING_PROMPT_RESTRICTIONS_NONE);
				
				if(menuName==MENU_RESTRICTIONS) {
					buttons=[MENU_UNDRESS, MENU_ATTACHMENTS];
					length=llGetListLength(RLV_RESTRICTIONS);
					for(index=0; index<length; index+=2) {
						buttons+=llList2String(RLV_RESTRICTIONS, index);
					}
				}
				else {
					prompt+=STRING_NEW_LINE 
						+ STRING_NEW_LINE + "☑ ... set restriction active"
						+ STRING_NEW_LINE + "☐ ... set restriction inactive"
						+ STRING_NEW_LINE + "(Maybe not all retrictions can't be set inactive)"
					;
					list availibleRestrictions=llCSV2List(llList2String(RLV_RESTRICTIONS, restrictionsListIndex+1));
					length=llGetListLength(availibleRestrictions);
					for(index=0; index<length; index++) {
						string restrictionWorkingOn=llList2String(availibleRestrictions, index);
						if(~llListFindList(activeRestrictions, [restrictionWorkingOn])) {
							buttons += ["☑ " + restrictionWorkingOn];
						}
						else {
							buttons += ["☐ " + restrictionWorkingOn];
						}
					}
				}
			}
			else if(menuName==MENU_ATTACHMENTS) {
				buttons=ParseClothingOrAttachmentLayersWorn(message, ATTACHMENT_POINTS);
				prompt="The following attachment points are worn:\n"
					+ llDumpList2String(buttons, ", ")
					+ "\n\nClick a button to try to detach this attachment\n"
					+ "(Beware some might be locked and can't be removed)\n"
				;
			}
			else if(menuName==MENU_UNDRESS) {
				// gloves,jacket,pants,shirt,shoes,skirt,socks,underpants,undershirt,skin,eyes,hair,shape,alpha,tattoo
				buttons=ParseClothingOrAttachmentLayersWorn(message, CLOTHING_LAYERS);
				prompt = "The following clothing layers are worn:\n"
					+ llDumpList2String(buttons, ", ")
					+ "\n\nClick a button to try to detach this layer\n"
					+ "(Beware some might be locked and can't be removed)\n"
				;
			}
			displayMenu(menuTarget, menuName, prompt, buttons);
		}
	}
	sensor(integer num) {
		// give menu the list of potential victims
		SensorList=[];
		integer index;
		for(; index<num; index++) {
			if(!~getVictimIndex(llDetectedKey(index))) {
				SensorList += [llGetSubString(llDetectedName(index), 0, BUTTON_MAX_LENGHT - 1), llDetectedKey(index)];
			}
		}
		displayMenu(sensorUserKey, MENU_CAPTURE, "", llList2ListStrided(SensorList, 0, -1, 2));
	}

	no_sensor() {
		SensorList=[];
		displayMenu(sensorUserKey, MENU_CAPTURE, "", []);
	}
	on_rez(integer start_param) {
		init();
	}
	changed( integer change ) {
		if( change & CHANGED_OWNER ) {
			llResetScript();
		}
	}
	timer() {
		integer length=llGetListLength(UsersList);
		integer index;
		integer currentTime=llGetUnixTime();
		for(; index<length; index+=USERS_LIST_STRIDE) {
			if(currentTime>llList2Integer(UsersList, index + USERS_LIST_TIMEOUT)) {
				removeFromUsersList(index);
				index-=USERS_LIST_STRIDE;
				length-=USERS_LIST_STRIDE;
			}
		}
	}
}
