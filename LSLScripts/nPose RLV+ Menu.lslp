//LICENSE:
//
//This script and the nPose scripts are licensed under the GPLv2
//(http://www.gnu.org/licenses/gpl-2.0.txt), with the following addendum:
//
//The nPose scripts are free to be copied, modified, and redistributed, subject
//to the following conditions:
// - If you distribute the nPose scripts, you must leave them full perms.
// - If you modify the nPose scripts and distribute the modifications, you
//   must also make your modifications full perms.
//
//"Full perms" means having the modify, copy, and transfer permissions enabled in
//Second Life and/or other virtual world platforms derived from Second Life (such
//as OpenSim).  If the platform should allow more fine-grained permissions, then
//"full perms" will mean the most permissive possible set of permissions allowed
//by the platform.
//
// Documentation:
// https://github.com/nPoseTeam/nPose-RLV-Plugin/wiki
// Report Bugs to:
// https://github.com/nPoseTeam/nPose-RLV-Plugin/issues
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


//LinkMessages
//integer RLV_MENU_NPOSE_PICK_SEAT_CHANGE_ACTIVE_VICTIM = -8009; //response from the nPose_pickSeat plugin
integer RLV_CORE_COMMAND             = -8010; //send commands to the RLV CORE
//integer RLV_CHANGE_SELECTED_VICTIM   = -8012; //can be used to change the current victim. The new current victim has to be in the victims list
integer RLV_VICTIMS_LIST_UPDATE      = -8013; //for internal use
integer RLV_CORE_PLUGIN_ACTION_RELAY = -8016; //for internal use
//integer RLV_CORE_PLUGIN_MENU_RELAY   = -8017; //for internal use

//integer RLV_MENU_DUMP_DEBUG_STRING = -8008; //TODO: remove this
//integer RLV_CORE_DUMP_DEBUG_STRING = -8018; //TODO: remove this

integer OPTIONS              = -240;
integer MEM_USAGE            = 34334;

//nPose Menu Plugin
//integer PLUGIN_MENU_REGISTER=-810;
integer PLUGIN_ACTION=-830;
integer PLUGIN_ACTION_DONE=-831;
integer PLUGIN_MENU=-832;
integer PLUGIN_MENU_DONE=-833;

integer PARAM_PATH=0;
integer PARAM_PAGE=1;
integer PARAM_PROMPT=2;
integer PARAM_BUTTONS=3;
integer PARAM_PLUGIN_LOCAL_PATH=4;
integer PARAM_PLUGIN_NAME=5;
integer PARAM_PLUGIN_MENU_PARAMS=6;
integer PARAM_PLUGIN_ACTION_PARAMS=7;


//RLV Relay timeouts
//integer RLV_RELAY_ASK_TIMEOUT = 60; //the time the user gets to react on a Relay permission request
integer RLV_RELAY_TIMEOUT     =  4; //the time to wait for an Relay response

//other
string STRING_NEW_LINE="\n";

string MY_PLUGIN_NAME="nPose_RLV+";

string STRING_PROMPT_VICTIM_CAPTION="Selected Victim: ";
string STRING_PROMPT_VICTIM_NONE="NONE";
string STRING_PROMPT_VICTIM_SELECT="Select new active victim.";
string STRING_PROMPT_CAPTURE_CAPTION="Choose someone to capture.";
string STRING_PROMPT_CAPTURE_NO_ONE_CAPTION="There seems to be no one in range to cpature.";
string STRING_PROMPT_RESTRICTIONS_CAPTION="Active restrictions are: ";
string STRING_PROMPT_RESTRICTIONS_NONE="NONE. Victim may be FREE.";
string STRING_PROMPT_RELAY_CAPTION="RLV Relay: ";
string STRING_PROMPT_RELAY_DETECTED="OK";
string STRING_PROMPT_RELAY_NOTDETECTED="NOT RECOGNIZED";
string STRING_PROMPT_TIMER_CAPTION="Timer: ";
string STRING_PROMPT_TIMER_ZERO="--:--:--";

string MENU_MAIN ="RLVMain";
string MENU_CAPTURE ="→Capture";
string MENU_RESTRICTIONS ="→Restrictions";
string MENU_UNDRESS ="→Undress";
string MENU_ATTACHMENTS ="→Attachments";
string MENU_VICTIMS ="→Victims";
string MENU_TIMER ="→Timer";
string MENU_BUTTON_RELEASE ="Release";
string MENU_BUTTON_UNSIT ="Unsit";

list RLV_RESTRICTIONS = [
	"→Chat/IM", "sendchat,chatshout,chatnormal,recvchat,recvemote,sendim,startim,recvim",
	"→Inventory", "showinv,viewnote,viewscript,viewtexture,edit,rez,unsharedwear,unsharedunwear",
	"→Touch", "fartouch,touchall,touchworld,touchattach",
	"→World", "shownames,showhovertextall,showworldmap,showminimap,showloc",
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
	"/*86400*/+1d", "/*21600*/+6h", "/*3600*/+1h", "/*900*/+15m", "/*60*/+1m"
];
list TIMER_BUTTONS2 = [
	"/*-86400*/-1d", "/*-21600*/-6h", "/*-3600*/-1h", "/*-900*/-15m", "/*-60*/-1m",
	"/*0*/Reset"
];


list VictimsList; //Avatars in this list are sitting on an rlvEnabled seat and are considered as restricted
//integer VICTIMS_LIST_AVATAR_UUID=0;
integer VICTIMS_LIST_TIMER=1;
integer VICTIMS_LIST_RELAY=2; //version of the rlv relay protocol (0: means no relay detected)
integer VICTIMS_LIST_STRIDE=3;

list SensorUsersListUser; //Avatars that uses the menu and are waiting for a Sensor answer
list SensorUsersListMenuParams; //Avatars that uses the menu and are waiting for a Sensor answer

list SelectedVictimListUser;
list SelectedVictimListVictim;

list UsersList; //Avatars that uses the menu and are waiting for a RLV answer
//integer USERS_LIST_CHANNEL=0
integer USERS_LIST_HANDLE=1;
integer USERS_LIST_MENU_TARGET=2;
integer USERS_LIST_MENU_PARAMS=3;
integer USERS_LIST_TIMEOUT=4;
integer USERS_LIST_STRIDE=5;

//Button comments marker
string MARKER_COMMENT_START = "/*";
string MARKER_COMMENT_END = "*/";

float RLV_grabRange=10.0;
integer OptionUseDisplayNames=1;

//helper
// pragma inline
string deleteNodes(string path, integer start, integer end) {
	return llDumpList2String(llDeleteSubList(llParseStringKeepNulls(path, [":"], []), start, end), ":");
}
//helper
// pragma inline
string getNodes(string path, integer start, integer end) {
	return llDumpList2String(llList2List(llParseStringKeepNulls(path, [":"], []), start, end), ":");
}
//helper
// NO pragma inline
string joinNodes(list nodes) {
	integer index;
	integer length=llGetListLength(nodes);
	list tempNodes;
	for(; index<length; index++) {
		string currentNodeString=llList2String(nodes, index);
		if(currentNodeString) {
			tempNodes+=llParseStringKeepNulls(currentNodeString, [":"], []);
		}
	}
	return llDumpList2String(tempNodes, ":");
}

//helper
//pragma inline
string getPluginBasePath(string path, string pluginLocalPath) {
	return getNodes(path, 0, -llGetListLength(llParseString2List(pluginLocalPath, [":"], []))-1);
}

//helper
//no pragma inline
string buildParamSet1(string path, integer page, string prompt, list additionalButtons, list pluginParams) {
	//pluginParams are: string pluginLocalPath, string pluginName, string pluginMenuParams, string pluginActionParams
	//We can't use colons in the promt, because they are used as a seperator in other messages
	//so we replace them with a UTF Symbol
	return llDumpList2String([
		path,
		page,
		llDumpList2String(llParseStringKeepNulls(prompt, [","], []), "‚"), // CAUTION: the 2nd "‚" is a UTF sign!
		llDumpList2String(additionalButtons, ",")
	] + llList2List(pluginParams + ["", "", "", ""], 0, 3), "|");
}

//no pragma inline
string getFirstComment(string text) {
	integer start=llSubStringIndex(text, MARKER_COMMENT_START);
	if(~start) {
		integer end=llSubStringIndex(text, MARKER_COMMENT_END);
		if(~end) {
			if(end>start) {
				return llGetSubString(text, start+llStringLength(MARKER_COMMENT_START), end-1);
			}
		}
	}
	return "";
}

//no pragma inline
key getSelectedVictim(key user) {
	//garbage Collection
	integer index=llGetListLength(SelectedVictimListVictim);
	for(; index; index--) {
		if(!~llListFindList(VictimsList, [llList2Key(SelectedVictimListVictim, index-1)])) {
			SelectedVictimListUser=llDeleteSubList(SelectedVictimListUser, index-1, index-1);
			SelectedVictimListVictim=llDeleteSubList(SelectedVictimListVictim, index-1, index-1);
		}
	}
	if(user) {
		//check if the user is known already
		index=getSelectedVictimUserIndex(user);
		if(!~index) {
			//user not known, check if the user is within the VictimsList
			index=getVictimIndex(user);
			if(~index) {
				//the user is a victim, so select himself
				index=setSelectedVictim(user, user);
			}
			else if(llGetListLength(VictimsList)>=VICTIMS_LIST_STRIDE) {
				//the user is not a vitim, but we have some victims in our list:
				//select the first available victim
				index=setSelectedVictim(user, (key)llList2String(VictimsList, 0));
			}
			else {
				return NULL_KEY;
			}
		}
		return llList2Key(SelectedVictimListVictim, index);
	}
	return NULL_KEY;
}

//no pragma inline
integer setSelectedVictim(key user, key victim) {
	//add
	if(user) {
		if(~getVictimIndex(victim)) {
			integer index=getSelectedVictimUserIndex(user);
			if(~index) {
				SelectedVictimListUser=llListReplaceList(SelectedVictimListUser, [user], index, index);
				SelectedVictimListVictim=llListReplaceList(SelectedVictimListVictim, [victim], index, index);
				return index;
			}
			else {
				SelectedVictimListUser+=user;
				SelectedVictimListVictim+=victim;
				return llGetListLength(SelectedVictimListUser)-1;
			}
		}
	}
	return -1;
}

//pragma inline
string getSelectedVictimPrompt(key selectedVictim) {
	return
		STRING_PROMPT_VICTIM_CAPTION +
		conditionalString(
			selectedVictim!=NULL_KEY,
			conditionalString(OptionUseDisplayNames, llGetDisplayName(selectedVictim), llKey2Name(selectedVictim)),
			STRING_PROMPT_VICTIM_NONE
		)
	;
}

//no pragma inline
string text2MenuText(string text) {
	//replaces a few characters that may cause problems
	text=llDumpList2String(llParseStringKeepNulls(text, ["`"], []), "‵");
	text=llDumpList2String(llParseStringKeepNulls(text, ["|"], []), "┃");
	text=llDumpList2String(llParseStringKeepNulls(text, ["/"], []), "⁄");
	text=llDumpList2String(llParseStringKeepNulls(text, [":"], []), "꞉");
	text=llDumpList2String(llParseStringKeepNulls(text, [","], []), "‚");
	return text;
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
integer getSelectedVictimUserIndex(key avatarUuid) {
	return llListFindList(SelectedVictimListUser, [avatarUuid]);
}

// pragma inline
integer getVictimIndex(key avatarUuid) {
	return llListFindList(VictimsList, [(string)avatarUuid]);
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

// pragma inline
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

// pragma inline
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
integer addToUsersList(key menuUser, string menuParams) {
	integer index=llListFindList(UsersList, [menuUser]) - USERS_LIST_MENU_TARGET;
	removeFromUsersList(index);
	integer channel=(integer)(llFrand(1000000000.0) + 1000000000.0); //RLVa needs positive Channel numbers
	UsersList+=[channel, llListen(channel, "", NULL_KEY, ""), menuUser, menuParams, llGetUnixTime() + RLV_RELAY_TIMEOUT];
	llSetTimerEvent(1.0);
	return channel;
}

// pragma inline
addToSensorUsersList(key id, string params) {
	integer index=llListFindList(SensorUsersListUser, [id]);
	if(~index) {
		SensorUsersListUser=llDeleteSubList(SensorUsersListUser, index, index);
		SensorUsersListMenuParams=llDeleteSubList(SensorUsersListMenuParams, index, index);
	}
	SensorUsersListUser+=id;
	SensorUsersListMenuParams+=params;
}

// pragma inline
integer isCaptureMenuAllowed(key targetKey, key victimKey) {
	//allowed if:
	//- the toucher isn't a victim
	//- and the RLV_grabRange is set
	return !~getVictimIndex(targetKey) && RLV_grabRange>0;
}

// pragma inline
integer isRestrictionsMenuAllowed(key targetKey, key victimKey) {
	//allowed if:
	//- a victim is selected
	//- and the toucher isn't a victim
	//- and the victims RLV is already detected
	return victimKey!=NULL_KEY && !~getVictimIndex(targetKey) && getVictimRelayVersion(victimKey);
}

// pragma inline
integer isReleaseButtonAllowed(key targetKey, key victimKey) {
	//allowed if:
	//- a victim is selected
	//- and the toucher isn't a victim
	return victimKey!=NULL_KEY && !~getVictimIndex(targetKey);
}

// pragma inline
integer isUnsitButtonAllowed(key targetKey, key victimKey) {
	//allowed if:
	//- a victim is selected
	//- and the toucher isn't a victim
	return victimKey!=NULL_KEY && !~getVictimIndex(targetKey);
}

// pragma inline
integer isSimpleTimerMenuAllowed(key targetKey, key victimKey) {
	//allowed if:
	//- a victim is selected
	//- and the target of the menu is not a victim, or the timer of the selected victim is already running
	return victimKey!=NULL_KEY && (!~getVictimIndex(targetKey) || getVictimTimer(victimKey));
}

// pragma inline
integer isAdvancedTimerMenuAllowed(key targetKey, key victimKey) {
	//allowed if:
	//- a victim is selected
	//- and the target of the menu is not a victim
	return victimKey!=NULL_KEY && !~getVictimIndex(targetKey);
}

// pragma inline
integer isVictimMenuAllowed(key targetKey, key victimKey) {
	//allowed if:
	//- a victim is selected and more than one entry in the vicitms list
	//- no victim is selected and one or more entries in the vicitms list
	return (llGetListLength(VictimsList) > VICTIMS_LIST_STRIDE || (llGetListLength(VictimsList)==VICTIMS_LIST_STRIDE && victimKey==NULL_KEY));
}

// pragma inline
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
	link_message( integer sender, integer num, string str, key id ) {
		if(num==RLV_VICTIMS_LIST_UPDATE) {
			VictimsList=llCSV2List(str);
		}
		else if(num==PLUGIN_ACTION || num==PLUGIN_MENU) {
			list params=llParseStringKeepNulls(str, ["|"], []);
			string pluginName=llList2String(params, PARAM_PLUGIN_NAME);
			if(pluginName==llToLower(MY_PLUGIN_NAME)) {
				//it is for me
				//extract the parameters from the list
				string path=llList2String(params, PARAM_PATH);
				integer page=(integer)llList2String(params, PARAM_PAGE);
				string prompt=llList2String(params, PARAM_PROMPT);
				string buttons=llList2String(params, PARAM_BUTTONS);
				string pluginLocalPath=llList2String(params, PARAM_PLUGIN_LOCAL_PATH);
				string pluginMenuParams=llList2String(params, PARAM_PLUGIN_MENU_PARAMS);
				string pluginActionParams=llList2String(params, PARAM_PLUGIN_ACTION_PARAMS);

				key selectedVictim=getSelectedVictim(id);
			
				if(num==PLUGIN_ACTION) {
					string pluginBasePath=getPluginBasePath(path, pluginLocalPath);
				
					string pluginLocalPathPart0=getNodes(pluginLocalPath, 0, 0);
					string pluginLocalPathPart1=getNodes(pluginLocalPath, 1, 1);
					string pluginLocalPathPart2=getNodes(pluginLocalPath, 2, 2);

					integer pipeActionThroughCore;

					//root menu
					if(pluginLocalPath=="") {
					}
					
					//root menu buttons
					else if(pluginLocalPath==MENU_BUTTON_UNSIT) {
						if(isUnsitButtonAllowed(id, selectedVictim)) {
							if(selectedVictim) {
								llMessageLinked(LINK_SET, RLV_CORE_COMMAND, "unsit," + (string)selectedVictim, NULL_KEY);
								pipeActionThroughCore=TRUE;
							}
						}
						path=pluginBasePath;
					}
					else if(pluginLocalPath==MENU_BUTTON_RELEASE) {
						if(isReleaseButtonAllowed(id, selectedVictim)) {
							if(selectedVictim) {
								llMessageLinked(LINK_SET, RLV_CORE_COMMAND, "release," + (string)selectedVictim, NULL_KEY);
								pipeActionThroughCore=TRUE;
							}
						}
						path=pluginBasePath;
					}
					else if(pluginLocalPathPart0==MENU_CAPTURE) {
						if(!isCaptureMenuAllowed(id, selectedVictim)) {
							path=pluginBasePath;
						}
						else if(pluginLocalPathPart1) {
							key avatarToCapture=(key)getFirstComment(pluginLocalPathPart1);
							if(avatarToCapture) {
								llMessageLinked(LINK_SET, RLV_CORE_COMMAND, "grab," + (string)avatarToCapture, NULL_KEY);
								pipeActionThroughCore=TRUE;
								//let the RLV do its work
								//TODO: If the relay is in ask mode this break doesn't give us enough time
								llSleep(2.0);
							}
							path=pluginBasePath;
						}
					}
					else if(pluginLocalPathPart0==MENU_RESTRICTIONS) {
						if(!isRestrictionsMenuAllowed(id, selectedVictim)) {
							path=pluginBasePath;
						}
						else if(pluginLocalPathPart2) {
							if(~llListFindList(ATTACHMENT_POINTS, [pluginLocalPathPart2])) {
								llMessageLinked(LINK_SET, RLV_CORE_COMMAND, "rlvCommand," + (string)selectedVictim + ",@remattach:" + pluginLocalPathPart2 + "=force", NULL_KEY);
							}
							else if(~llListFindList(CLOTHING_LAYERS, [pluginLocalPathPart2])) {
								llMessageLinked(LINK_SET, RLV_CORE_COMMAND, "rlvCommand," + (string)selectedVictim + ",@remoutfit:" + pluginLocalPathPart2 + "=force", NULL_KEY);
							}
							else if(llGetSubString(pluginLocalPathPart2, 0, 0)=="☐") {
								llMessageLinked(LINK_SET, RLV_CORE_COMMAND, "rlvCommand," + (string)selectedVictim + ",@" + llStringTrim(llDeleteSubString(pluginLocalPathPart2, 0, 1), STRING_TRIM) + "=n", NULL_KEY);
							}
							else if(llGetSubString(pluginLocalPathPart2, 0, 0)=="☑") {
								llMessageLinked(LINK_SET, RLV_CORE_COMMAND, "rlvCommand," + (string)selectedVictim + ",@" + llStringTrim(llDeleteSubString(pluginLocalPathPart2, 0, 1), STRING_TRIM) + "=y", NULL_KEY);
							}
							//let the RLV do its work
							//TODO: If the relay is in ask mode this break doesn't give us enough time
							llSleep(2.0);
							path=deleteNodes(path, -1, -1);
						}
					}
					else if(pluginLocalPathPart0==MENU_VICTIMS) {
						if(!isVictimMenuAllowed(id, selectedVictim)) {
							path=pluginBasePath;
						}
						else if(pluginLocalPathPart1) {
							key avatarToSelect=(key)getFirstComment(pluginLocalPathPart1);
							setSelectedVictim(id, avatarToSelect);
							path=pluginBasePath;
						}
					}
					else if(pluginLocalPathPart0==MENU_TIMER) {
						if(!isSimpleTimerMenuAllowed(id, selectedVictim)) {
							path=pluginBasePath;
						}
						else if(pluginLocalPathPart1) {
							integer time=(integer)getFirstComment(pluginLocalPathPart1);
							if(time>0 || isAdvancedTimerMenuAllowed(id, selectedVictim)) {
								if(!time) {
									setVictimTimer(selectedVictim, 0);
								}
								else {
									addTimeToVictim(selectedVictim, time);
								}
							}
							path=joinNodes([pluginBasePath, MENU_TIMER]);
						}
					}
					else {
						path=pluginBasePath;
					}
				
					string paramSet1=buildParamSet1(path, page, prompt, [buttons], [pluginLocalPath, pluginName, pluginMenuParams, pluginActionParams]);
					if(pipeActionThroughCore) {
						llMessageLinked(LINK_SET, RLV_CORE_PLUGIN_ACTION_RELAY, paramSet1, id);
					}
					else {
						//return the modified parameters
						llMessageLinked(LINK_SET, PLUGIN_ACTION_DONE, paramSet1, id);
					}
				}
				else if(num==PLUGIN_MENU) {
					list buttonsList=llParseString2List(buttons, [","], []);
					string selection=getNodes(pluginLocalPath, -1, -1);

					string promptSelectedVictim=getSelectedVictimPrompt(selectedVictim);
				
					string promptVictimMainInfo=
						conditionalString(
							selectedVictim!=NULL_KEY, 
							STRING_NEW_LINE
								+ STRING_PROMPT_RELAY_CAPTION
								+ conditionalString(getVictimRelayVersion(selectedVictim), STRING_PROMPT_RELAY_DETECTED, STRING_PROMPT_RELAY_NOTDETECTED)
								+ STRING_NEW_LINE
								+ getVictimTimerString(selectedVictim)
							,
							""
						)
					;
				
					if(pluginLocalPath=="") {
						//root level
						//set a prompt
						prompt=promptSelectedVictim + promptVictimMainInfo;
				
						//generate the buttons
						if(isCaptureMenuAllowed(id, selectedVictim)) {
							buttonsList+=[MENU_CAPTURE];
						}
						if(isRestrictionsMenuAllowed(id, selectedVictim)) {
							buttonsList+=[MENU_RESTRICTIONS];
						}
						if(isReleaseButtonAllowed(id, selectedVictim)) {
							buttonsList+=[MENU_BUTTON_RELEASE];
						}
						if(isUnsitButtonAllowed(id, selectedVictim)) {
							buttonsList+=[MENU_BUTTON_UNSIT];
						}
						if(isSimpleTimerMenuAllowed(id, selectedVictim)) {
							buttonsList+=[MENU_TIMER];
						}
						if(isVictimMenuAllowed(id, selectedVictim)) {
							buttonsList+=[MENU_VICTIMS];
						}
					}
					else if(pluginLocalPath==MENU_CAPTURE) {
						if(RLV_grabRange) {
							addToSensorUsersList(id, str);
							llSensor("", NULL_KEY, AGENT_BY_LEGACY_NAME, RLV_grabRange, PI);
							return;
						}
					}
					else if(pluginLocalPath==MENU_RESTRICTIONS) {
						integer channel=addToUsersList(id, str);
						llMessageLinked(LINK_SET, RLV_CORE_COMMAND, "rlvCommand,"+(string)selectedVictim+",@getstatus=" + (string)channel, NULL_KEY);
						return;
					}
					else if(pluginLocalPath==joinNodes([MENU_RESTRICTIONS, MENU_UNDRESS])) {
							integer channel=addToUsersList(id, str);
							llMessageLinked(LINK_SET, RLV_CORE_COMMAND, "rlvCommand,"+(string)selectedVictim+",@getoutfit=" + (string)channel, NULL_KEY);
							return;
					}
					else if(pluginLocalPath==joinNodes([MENU_RESTRICTIONS, MENU_ATTACHMENTS])) {
						integer channel=addToUsersList(id, str);
						llMessageLinked(LINK_SET, RLV_CORE_COMMAND, "rlvCommand,"+(string)selectedVictim+",@getattach=" + (string)channel, NULL_KEY);
						return;
					}
					else if(getNodes(pluginLocalPath, 0, 0)==MENU_RESTRICTIONS && ~llListFindList(RLV_RESTRICTIONS, [selection])) {
						integer channel=addToUsersList(id, str);
						llMessageLinked(LINK_SET, RLV_CORE_COMMAND, "rlvCommand,"+(string)selectedVictim+",@getstatus=" + (string)channel, NULL_KEY);
						return;
					}
					else if(pluginLocalPath==MENU_TIMER) {
						prompt+=STRING_NEW_LINE + getVictimTimerString(selectedVictim);
						buttonsList+=TIMER_BUTTONS1;
						if(isAdvancedTimerMenuAllowed(id, selectedVictim)) {
							buttonsList+=TIMER_BUTTONS2;
						}
						prompt=promptSelectedVictim + promptVictimMainInfo;
					}
					else if(pluginLocalPath==MENU_VICTIMS) {
						prompt+=promptSelectedVictim + STRING_NEW_LINE + STRING_PROMPT_VICTIM_SELECT;
						integer index;
						integer length=llGetListLength(VictimsList);
						for(; index<length; index+=VICTIMS_LIST_STRIDE) {
							key avatarKey=(key)llList2String(VictimsList, index);
							string avatarName;
							if(OptionUseDisplayNames) {
								avatarName=llGetDisplayName(avatarKey);
							}
							else {
								avatarName=llKey2Name(avatarKey);
							}
							avatarName=text2MenuText(avatarName);
							if(avatarKey==selectedVictim) {
								avatarName="⚫" + avatarName + "⚫";
							}
							buttonsList+=MARKER_COMMENT_START + (string)avatarKey + MARKER_COMMENT_END + avatarName;
						}
					}
				
				
					//return the modified parameters
					llMessageLinked(LINK_SET, PLUGIN_MENU_DONE, buildParamSet1(path, page, prompt, buttonsList, [pluginLocalPath, pluginName, pluginMenuParams, pluginActionParams]), id);
				}
			}
		}
		else if(num == OPTIONS) {
			//save new option(s) from LINKMSG
			list optionsToSet = llParseStringKeepNulls(str, ["~","|"], []);
			integer length = llGetListLength(optionsToSet);
			integer index;
			for(; index<length; ++index) {
				list optionsItems = llParseString2List(llList2String(optionsToSet, index), ["="], []);
				string optionItem = llToLower(llStringTrim(llList2String(optionsItems, 0), STRING_TRIM));
				string optionString = llList2String(optionsItems, 1);
				string optionSetting = llToLower(llStringTrim(optionString, STRING_TRIM));
				integer optionSettingFlag = optionSetting=="on" || (integer)optionSetting;

				if(optionItem == "rlv_grabrange") {RLV_grabRange = (float)optionSetting;}
				if(optionItem == "usedisplaynames") {OptionUseDisplayNames = optionSettingFlag;}
			}
		}

		else if( num == MEM_USAGE ) {
			llSay( 0, "Memory Used by " + llGetScriptName() + ": "
				+ (string)llGetUsedMemory() + " of " + (string)llGetMemoryLimit()
				+ ", Leaving " + (string)llGetFreeMemory() + " memory free." );
		}
	}
	listen(integer channel, string name, key id, string message) {
		integer indexUsersList;
		string prompt;
		list buttons;
		if(~(indexUsersList=llListFindList(UsersList, [channel]))) {
			key menuUser=llList2Key(UsersList, indexUsersList + USERS_LIST_MENU_TARGET);
			list menuParams=llParseStringKeepNulls(llList2String(UsersList, indexUsersList + USERS_LIST_MENU_PARAMS), ["|"], []);
			removeFromUsersList(indexUsersList);
			string localPath=llList2String(menuParams, PARAM_PLUGIN_LOCAL_PATH);
			string selection=getNodes(localPath, -1, -1);
			integer restrictionsListIndex=llListFindList(RLV_RESTRICTIONS, [selection]);
			if(localPath==MENU_RESTRICTIONS || ~restrictionsListIndex) {
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
				prompt=getSelectedVictimPrompt(getSelectedVictim(menuUser)) + STRING_NEW_LINE + STRING_NEW_LINE;
				prompt+=STRING_PROMPT_RESTRICTIONS_CAPTION + conditionalString(llGetListLength(activeRestrictions), STRING_NEW_LINE + llDumpList2String(activeRestrictions, ", "), STRING_PROMPT_RESTRICTIONS_NONE);
				
				if(localPath==MENU_RESTRICTIONS) {
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
			else if(localPath==joinNodes([MENU_RESTRICTIONS, MENU_ATTACHMENTS])) {
				buttons=ParseClothingOrAttachmentLayersWorn(message, ATTACHMENT_POINTS);
				prompt=STRING_NEW_LINE + "The following attachment points are worn:" + STRING_NEW_LINE
					+ llDumpList2String(buttons, ", ")
					+ STRING_NEW_LINE + STRING_NEW_LINE + "Click a button to try to detach this attachment" + STRING_NEW_LINE
					+ "(Beware some might be locked and can't be removed)"
				;
			}
			else if(localPath==joinNodes([MENU_RESTRICTIONS, MENU_UNDRESS])) {
				// gloves,jacket,pants,shirt,shoes,skirt,socks,underpants,undershirt,skin,eyes,hair,shape,alpha,tattoo
				buttons=ParseClothingOrAttachmentLayersWorn(message, CLOTHING_LAYERS);
				prompt=STRING_NEW_LINE + "The following clothing layers are worn:" + STRING_NEW_LINE
					+ llDumpList2String(buttons, ", ")
					+ STRING_NEW_LINE + STRING_NEW_LINE + "Click a button to try to detach this layer" + STRING_NEW_LINE
					+ "(Beware some might be locked and can't be removed)"
				;
			}
			llMessageLinked(LINK_SET, PLUGIN_MENU_DONE, buildParamSet1(
				llList2String(menuParams, PARAM_PATH),
				0,
				prompt,
				buttons,
				llList2List(menuParams, PARAM_PLUGIN_LOCAL_PATH, -1)
			), menuUser);
		}
	}
	sensor(integer num) {
		// give menu the list of potential victims
		list sensorList;
		integer index;
		for(; index<num; index++) {
			key avatar=llDetectedKey(index);
			if(!~getVictimIndex(avatar)) {
				string prefix = MARKER_COMMENT_START + (string)avatar + MARKER_COMMENT_END;
				if(OptionUseDisplayNames) {
					sensorList+=prefix + text2MenuText(llGetDisplayName(avatar));
				}
				else {
					sensorList+=prefix + text2MenuText(llKey2Name(avatar));
				}
			}
		}
		integer length=llGetListLength(SensorUsersListUser);
		for(index=0; index<length; index++) {
			list params=llParseStringKeepNulls(llList2String(SensorUsersListMenuParams, index), ["|"], []);
			llMessageLinked(LINK_SET, PLUGIN_MENU_DONE, buildParamSet1(
				llList2String(params, PARAM_PATH),
				0,
				STRING_PROMPT_CAPTURE_CAPTION,
				sensorList,
				llList2List(params, PARAM_PLUGIN_LOCAL_PATH, -1)
			), llList2Key(SensorUsersListUser, index));
		}
		SensorUsersListUser=[];
		SensorUsersListMenuParams=[];
	}

	no_sensor() {
		integer length=llGetListLength(SensorUsersListUser);
		integer index;
		for(; index<length; index++) {
			list params=llParseStringKeepNulls(llList2String(SensorUsersListMenuParams, index), ["|"], []);
			llMessageLinked(LINK_SET, PLUGIN_MENU_DONE, buildParamSet1(
				llList2String(params, PARAM_PATH),
				0,
				STRING_PROMPT_CAPTURE_NO_ONE_CAPTION,
				[],
				llList2List(params, PARAM_PLUGIN_LOCAL_PATH, -1)
			), llList2Key(SensorUsersListUser, index));
		}
		SensorUsersListUser=[];
		SensorUsersListMenuParams=[];
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
	on_rez(integer start_param) {
		llResetScript();
	}
}
