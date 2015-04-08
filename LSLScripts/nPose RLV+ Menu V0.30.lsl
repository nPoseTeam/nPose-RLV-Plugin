// LSL script generated - patched Render.hs (0.1.6.2): LSLScripts.nPose RLV+ Menu V0.30.lslp Wed Apr  8 18:21:10 Mitteleuropäische Sommerzeit 2015


string STRING_PROMPT_VICTIM_CAPTION = "Selected Victim: ";
string STRING_PROMPT_VICTIM_NONE = "NONE";
string STRING_PROMPT_VICTIM_SELECT = "Select new active victim.";
string STRING_PROMPT_RESTRICTIONS_CAPTION = "Active restrictions are: ";
string STRING_PROMPT_RESTRICTIONS_NONE = "NONE. Victim may be FREE.";
string STRING_PROMPT_RELAY_CAPTION = "RLV Relay: ";
string STRING_PROMPT_RELAY_DETECTED = "OK";
string STRING_PROMPT_RELAY_NOTDETECTED = "NOT RECOGNIZED";
string STRING_PROMPT_TIMER_ZERO = "--:--:--";

string STRING_NEW_LINE = "\n";

string MENU_BUTTON_BACK = "^";
string MENU_MAIN = "RLVMain";
string MENU_CAPTURE = "→Capture";
string MENU_RESTRICTIONS = "→Restrictions";
string MENU_UNDRESS = "→Undress";
string MENU_ATTACHMENTS = "→Attachments";
string MENU_VICTIMS = "→Victims";
string MENU_TIMER = "→Timer";
string MENU_BUTTON_RELEASE = "Release";
string MENU_BUTTON_UNSIT = "Unsit";

string PATH_SEPARATOR = ":";


list RLV_RESTRICTIONS = ["→Chat/IM","sendchat,chatshout,chatnormal,recvchat,recvemote,sendim,startim,recvim","→Inventory","showinv,viewnote,viewscript,viewtexture,edit,rez,unsharedwear,unsharedunwear","→Touch","fartouch,touchall,touchworld,touchattach","→World","shownames,showhovertextall,showworldmap,showminimap,showloc","→Debug/Env","setgroup,setdebug,setenv"];

list IGNORED_RLV_RESTRICTIONS = ["acceptpermission","detach"];

list CLOTHING_LAYERS = ["gloves","jacket","pants","shirt","shoes","skirt","socks","underpants","undershirt","","","","","alpha","tattoo"];

list ATTACHMENT_POINTS = ["","chest","skull","left shoulder","right shoulder","left hand","right hand","left foot","right foot","spine","pelvis","mouth","chin","left ear","right ear","left eyeball","right eyeball","nose","r upper arm","r forearm","l upper arm","l forearm","right hip","r upper leg","r lower leg","left hip","l upper leg","l lower leg","stomach","left pec","right pec","","","","","","","","","neck","root"];

list TIMER_BUTTONS1 = ["+1d","+6h","+1h","+15m","+1m"];
list TIMER_BUTTONS2 = ["-1d","-6h","-1h","-15m","-1m","Reset"];


key MyUniqueId;

integer rlvResponseChannel;
integer rlvResponseHandle;

key VictimKey = NULL_KEY;

list VictimsList;

list SensorList;

list UsersList;

key sensorUserKey;

string NPosePath;

float RLV_grabRange = 10.0;

debug(list message){
    llOwnerSay(llGetScriptName() + "\n##########\n#>" + llDumpList2String(message,"\n#>") + "\n##########");
}

string stringReplace(string str,string search,string replace){
    return llDumpList2String(llParseStringKeepNulls(str,[search],[]),replace);
}

integer getVictimIndex(key avatarUuid){
    return llListFindList(VictimsList,[(string)avatarUuid]);
}

integer getVictimRelayVersion(key avatarUuid){
    integer relayVersion;
    integer index = getVictimIndex(avatarUuid);
    if (~index) {
        relayVersion = llList2Integer(VictimsList,index + 2);
    }
    debug(["getVictimRelayVersion",avatarUuid,index,relayVersion] + VictimsList);
    return relayVersion;
}
integer getVictimTimer(key avatarUuid){
    integer index = getVictimIndex(avatarUuid);
    if (~index) {
        integer time = llList2Integer(VictimsList,index + 1) - llGetUnixTime();
        if (time > 0) {
            return time;
        }
    }
    return 0;
}

addTimeToVictim(key avatarUuid,integer time){
    integer index = getVictimIndex(avatarUuid);
    if (~index) {
        integer thisTime = llGetUnixTime();
        integer oldTime = llList2Integer(VictimsList,index + 1);
        if (oldTime < thisTime) {
            oldTime = thisTime;
        }
        integer newTime = oldTime + time;
        if (newTime < thisTime + 30) {
            newTime = thisTime + 30;
        }
        setVictimTimer(avatarUuid,newTime);
    }
}

setVictimTimer(key avatarUuid,integer time){
    integer index = getVictimIndex(avatarUuid);
    if (~index) {
        VictimsList = llListReplaceList(VictimsList,[time],index + 1,index + 1);
        llMessageLinked(-1,-8010,"setTimer," + (string)avatarUuid + "," + (string)time,NULL_KEY);
    }
}


// NO pragma inline
string getVictimTimerString(key avatarUuid){
    string returnValue = "Timer: ";
    integer runningTimeS = getVictimTimer(avatarUuid);
    if (!runningTimeS) {
        return returnValue + STRING_PROMPT_TIMER_ZERO + STRING_NEW_LINE;
    }
    integer runningTimeM = runningTimeS / 60;
    runningTimeS = runningTimeS % 60;
    integer runningTimeH = runningTimeM / 60;
    runningTimeM = runningTimeM % 60;
    integer runningTimeD = runningTimeH / 24;
    runningTimeH = runningTimeH % 24;
    return returnValue + conditionalString(runningTimeD,(string)runningTimeD + "d ","") + llGetSubString("0" + (string)runningTimeH,-2,-1) + ":" + llGetSubString("0" + (string)runningTimeM,-2,-1) + ":" + llGetSubString("0" + (string)runningTimeS,-2,-1);
}

removeFromUsersList(integer index){
    if (~index) {
        llListenRemove(llList2Integer(UsersList,index + 1));
        UsersList = llDeleteSubList(UsersList,index,index + 5 - 1);
    }
    if (!llGetListLength(UsersList)) {
        llSetTimerEvent(0.0);
    }
}
integer addToUsersList(key menuTarget,string menuName){
    integer index = llListFindList(UsersList,[menuTarget,menuName]) - 2;
    removeFromUsersList(index);
    integer channel = (integer)(llFrand(1.0e9) + 1.0e9);
    UsersList += [channel,llListen(channel,"",NULL_KEY,""),menuTarget,menuName,llGetUnixTime() + 4];
    llSetTimerEvent(1.0);
    return channel;
}

init(){
    MyUniqueId = llGenerateKey();
    llListenRemove(rlvResponseHandle);
    rlvResponseChannel = (integer)(llFrand(-1.0e9) - 1.0e9);
    rlvResponseHandle = llListen(rlvResponseChannel,"",NULL_KEY,"");
}

showMenu(key menuTarget,string menuName){
    debug(["showMenu",menuTarget,menuName]);
    if (menuName == MENU_CAPTURE) {
        if (RLV_grabRange) {
            sensorUserKey = menuTarget;
            llSensor("",NULL_KEY,1,RLV_grabRange,3.14159265);
        }
        else  {
            displayMenu(menuTarget,menuName,"",[]);
        }
    }
    else  if (menuName == MENU_RESTRICTIONS) {
        integer channel = addToUsersList(menuTarget,menuName);
        llMessageLinked(-1,-8010,"rlvCommand,%VICTIM%,@getstatus=" + (string)channel,NULL_KEY);
    }
    else  if (menuName == MENU_UNDRESS) {
        integer channel = addToUsersList(menuTarget,menuName);
        llMessageLinked(-1,-8010,"rlvCommand,%VICTIM%,@getoutfit=" + (string)channel,NULL_KEY);
    }
    else  if (menuName == MENU_ATTACHMENTS) {
        integer channel = addToUsersList(menuTarget,menuName);
        llMessageLinked(-1,-8010,"rlvCommand,%VICTIM%,@getattach=" + (string)channel,NULL_KEY);
    }
    else  if (~llListFindList(RLV_RESTRICTIONS,[menuName])) {
        integer channel = addToUsersList(menuTarget,menuName);
        llMessageLinked(-1,-8010,"rlvCommand,%VICTIM%,@getstatus=" + (string)channel,NULL_KEY);
    }
    else  {
        if (menuName == "") {
            menuName = MENU_MAIN;
        }
        displayMenu(menuTarget,menuName,"",[]);
    }
}

displayMenu(key menuTarget,string menuName,string additionalPrompt,list additionalButtons){
    debug(["displayMenu",menuTarget,menuName,additionalPrompt + "---"] + additionalButtons);
    list buttons;
    string prompt = getSelectedVictimPromt();
    integer index = llListFindList(UsersList,[menuTarget,menuName]) - 2;
    removeFromUsersList(index);
    if (menuName == MENU_VICTIMS) {
        if (isVictimMenuAllowed(menuTarget)) {
            integer length = llGetListLength(VictimsList);
            integer n;
            for (; n < length; n += 3) {
                buttons += llGetSubString(llKey2Name(llList2Key(VictimsList,n)),0,15);
            }
            renderMenu(menuTarget,prompt + STRING_PROMPT_VICTIM_SELECT,buttons,MENU_MAIN + PATH_SEPARATOR + MENU_VICTIMS);
        }
        else  {
            menuName = MENU_MAIN;
        }
    }
    else  if (menuName == MENU_CAPTURE) {
        if (isCaptureMenuAllowed(menuTarget)) {
            renderMenu(menuTarget,STRING_PROMPT_VICTIM_SELECT,additionalButtons,MENU_MAIN + PATH_SEPARATOR + MENU_CAPTURE);
        }
        else  {
            menuName = MENU_MAIN;
        }
    }
    else  if (menuName == MENU_TIMER) {
        if (isTimerMenuAllowed(menuTarget)) {
            buttons = TIMER_BUTTONS1;
            if (!~getVictimIndex(menuTarget)) {
                buttons += TIMER_BUTTONS2;
            }
            renderMenu(menuTarget,prompt + getVictimTimerString(VictimKey),buttons,MENU_MAIN + PATH_SEPARATOR + MENU_TIMER);
        }
        else  {
            menuName = MENU_MAIN;
        }
    }
    else  if (menuName == MENU_RESTRICTIONS || menuName == MENU_UNDRESS || menuName == MENU_ATTACHMENTS || ~llListFindList(RLV_RESTRICTIONS,[menuName])) {
        if (isRestrictionsMenuAllowed(menuTarget)) {
            string path = MENU_MAIN + PATH_SEPARATOR + MENU_RESTRICTIONS;
            if (menuName != MENU_RESTRICTIONS) {
                path += PATH_SEPARATOR + menuName;
            }
            renderMenu(menuTarget,prompt + additionalPrompt,additionalButtons,path);
        }
        else  {
            menuName = MENU_MAIN;
        }
    }
    if (menuName == MENU_MAIN) {
        if (isCaptureMenuAllowed(menuTarget)) {
            buttons += [MENU_CAPTURE];
        }
        if (isRestrictionsMenuAllowed(menuTarget)) {
            buttons += [MENU_RESTRICTIONS];
        }
        if (isReleaseButtonAllowed(menuTarget)) {
            buttons += [MENU_BUTTON_RELEASE];
        }
        if (isUnsitButtonAllowed(menuTarget)) {
            buttons += [MENU_BUTTON_UNSIT];
        }
        if (isTimerMenuAllowed(menuTarget)) {
            buttons += [MENU_TIMER];
        }
        if (isVictimMenuAllowed(menuTarget)) {
            buttons += [MENU_VICTIMS];
        }
        if (VictimKey) {
            prompt += STRING_PROMPT_RELAY_CAPTION + conditionalString(getVictimRelayVersion(VictimKey),STRING_PROMPT_RELAY_DETECTED,STRING_PROMPT_RELAY_NOTDETECTED) + STRING_NEW_LINE + getVictimTimerString(VictimKey);
        }
        renderMenu(menuTarget,prompt,buttons,MENU_MAIN);
    }
}

renderMenu(key targetKey,string prompt,list buttons,string menuPath){
    if (targetKey) {
        llMessageLinked(-1,-900,(string)targetKey + "|" + prompt + STRING_NEW_LINE + menuPath + STRING_NEW_LINE + "|" + "0" + "|" + llDumpList2String(buttons,"`") + "|" + MENU_BUTTON_BACK + "|" + menuPath,MyUniqueId);
    }
}

string getSelectedVictimPromt(){
    if (VictimKey) {
        return STRING_PROMPT_VICTIM_CAPTION + llKey2Name(VictimKey) + STRING_NEW_LINE;
    }
    else  {
        return STRING_PROMPT_VICTIM_CAPTION + STRING_PROMPT_VICTIM_NONE + STRING_NEW_LINE;
    }
}

integer isCaptureMenuAllowed(key targetKey){
    return !~getVictimIndex(targetKey) && RLV_grabRange > 0;
}
integer isRestrictionsMenuAllowed(key targetKey){
    return VictimKey != NULL_KEY && !~getVictimIndex(targetKey) && getVictimRelayVersion(VictimKey);
}
integer isReleaseButtonAllowed(key targetKey){
    return VictimKey != NULL_KEY && !~getVictimIndex(targetKey);
}
integer isUnsitButtonAllowed(key targetKey){
    return VictimKey != NULL_KEY && !~getVictimIndex(targetKey);
}
integer isTimerMenuAllowed(key targetKey){
    return VictimKey != NULL_KEY && (!~getVictimIndex(targetKey) || getVictimTimer(VictimKey));
}
integer isVictimMenuAllowed(key targetKey){
    return llGetListLength(VictimsList) > 3 || (llGetListLength(VictimsList) == 3 && VictimKey == NULL_KEY);
}


string conditionalString(integer conditon,string valueIfTrue,string valueIfFalse){
    string ret = valueIfFalse;
    if (conditon) {
        ret = valueIfTrue;
    }
    return ret;
}

list ParseClothingOrAttachmentLayersWorn(string wornFlags,list allNames){
    list layersWorn;
    integer length = llStringLength(wornFlags);
    integer i;
    for (; i < length; i += 1) {
        if (llGetSubString(wornFlags,i,i) == "1") {
            string layerName = llList2String(allNames,i);
            if (layerName) {
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

	link_message(integer sender,integer num,string str,key id) {
        if (num == -802) {
            NPosePath = str;
        }
        else  if (num == -237) {
            VictimKey = (key)str;
        }
        else  if (num == -238) {
            VictimsList = llCSV2List(str);
        }
        else  if (num == -8000) {
            list temp = llParseStringKeepNulls(str,[","],[]);
            string cmd = llToLower(llStringTrim(llList2String(temp,0),3));
            key target = (key)stringReplace(llStringTrim(llList2String(temp,1),3),"%VICTIM%",(string)VictimKey);
            list params = llDeleteSubList(temp,0,1);
            if (target) {
            }
            else  {
                target = VictimKey;
            }
            if (cmd == "showmenu") {
                showMenu(target,llList2String(params,0));
            }
        }
        else  if (num == -901) {
            if (id == MyUniqueId) {
                list params = llParseString2List(str,["|"],[]);
                string selection = llList2String(params,1);
                string path = llList2String(params,3);
                list pathParts = llParseString2List(path,[PATH_SEPARATOR],[]);
                key toucher = (key)llList2String(params,2);
                if (selection == MENU_BUTTON_BACK) {
                    selection = llList2String(pathParts,-2);
                    if (path == MENU_MAIN) {
                        llMessageLinked(-1,-800,NPosePath,toucher);
                        return;
                    }
                    else  if (selection == MENU_MAIN) {
                        showMenu(toucher,MENU_MAIN);
                        return;
                    }
                    else  {
                        pathParts = llDeleteSubList(pathParts,-2,-1);
                        path = llDumpList2String(pathParts,PATH_SEPARATOR);
                    }
                }
                if (selection == MENU_MAIN || selection == MENU_ATTACHMENTS || selection == MENU_CAPTURE || selection == MENU_RESTRICTIONS || selection == MENU_TIMER || selection == MENU_UNDRESS || selection == MENU_VICTIMS || ~llListFindList(RLV_RESTRICTIONS,[selection])) {
                    showMenu(toucher,selection);
                }
                else  {
                    if (path == MENU_MAIN) {
                        if (selection == MENU_BUTTON_UNSIT || selection == MENU_BUTTON_RELEASE) {
                            if (selection == MENU_BUTTON_UNSIT && isUnsitButtonAllowed(toucher)) {
                                llMessageLinked(-1,-8010,"unsit,%VICTIM%",NULL_KEY);
                                llSleep(1.0);
                            }
                            else  if (selection == MENU_BUTTON_RELEASE && isReleaseButtonAllowed(toucher)) {
                                llMessageLinked(-1,-8010,"release,%VICTIM%",NULL_KEY);
                                llSleep(1.0);
                            }
                            llMessageLinked(-1,-8000,"showMenu," + (string)toucher + "," + MENU_MAIN,NULL_KEY);
                        }
                    }
                    else  if (!llSubStringIndex(path,MENU_MAIN + PATH_SEPARATOR + MENU_RESTRICTIONS)) {
                        if (isRestrictionsMenuAllowed(toucher)) {
                            if (~llListFindList(ATTACHMENT_POINTS,[selection])) {
                                llMessageLinked(-1,-8010,"rlvCommand,%VICTIM%,@remattach:" + selection + "=force",NULL_KEY);
                                llSleep(0.5);
                                showMenu(toucher,MENU_ATTACHMENTS);
                            }
                            else  if (~llListFindList(CLOTHING_LAYERS,[selection])) {
                                llMessageLinked(-1,-8010,"rlvCommand,%VICTIM%,@remoutfit:" + selection + "=force",NULL_KEY);
                                llSleep(0.5);
                                showMenu(toucher,MENU_UNDRESS);
                            }
                            else  if (llGetSubString(selection,0,0) == "☐") {
                                llMessageLinked(-1,-8010,"rlvCommand,%VICTIM%,@" + llStringTrim(llDeleteSubString(selection,0,1),3) + "=n",NULL_KEY);
                                llSleep(0.5);
                                showMenu(toucher,llList2String(pathParts,-1));
                            }
                            else  if (llGetSubString(selection,0,0) == "☑") {
                                llMessageLinked(-1,-8010,"rlvCommand,%VICTIM%,@" + llStringTrim(llDeleteSubString(selection,0,1),3) + "=y",NULL_KEY);
                                llSleep(0.5);
                                showMenu(toucher,llList2String(pathParts,-1));
                            }
                        }
                    }
                    else  if (path == MENU_MAIN + PATH_SEPARATOR + MENU_CAPTURE) {
                        if (isCaptureMenuAllowed(toucher)) {
                            integer index = llListFindList(SensorList,[selection]);
                            if (~index) {
                                key avatarWorkingOn = llList2Key(SensorList,index + 1);
                                llMessageLinked(-1,-8010,"grab," + (string)avatarWorkingOn,NULL_KEY);
                            }
                        }
                        llMessageLinked(-1,-800,NPosePath,toucher);
                    }
                    else  if (path == MENU_MAIN + PATH_SEPARATOR + MENU_VICTIMS) {
                        if (isVictimMenuAllowed(toucher)) {
                            integer length = llGetListLength(VictimsList);
                            integer index;
                            for (; index < length; index += 3) {
                                key avatarWorkingOn = llList2Key(VictimsList,index);
                                if (llGetSubString(llKey2Name(avatarWorkingOn),0,15) == selection) {
                                    VictimKey = avatarWorkingOn;
                                    llMessageLinked(-1,-237,(string)VictimKey,"");
                                }
                            }
                        }
                        showMenu(toucher,MENU_MAIN);
                    }
                    else  if (path == MENU_MAIN + PATH_SEPARATOR + MENU_TIMER) {
                        if (isTimerMenuAllowed(toucher)) {
                            if (selection == "Reset") {
                                setVictimTimer(VictimKey,0);
                            }
                            else  if (llGetSubString(selection,0,0) == "-" || llGetSubString(selection,0,0) == "+") {
                                integer multiplier = 60;
                                string unit = llGetSubString(selection,-1,-1);
                                if (unit == "h") {
                                    multiplier = 3600;
                                }
                                else  if (unit == "d") {
                                    multiplier = 86400;
                                }
                                else  if (unit == "w") {
                                    multiplier = 604800;
                                }
                                addTimeToVictim(VictimKey,multiplier * (integer)llGetSubString(selection,0,-2));
                            }
                            showMenu(toucher,MENU_TIMER);
                        }
                    }
                }
            }
        }
        else  if (num == -240) {
            list optionsToSet = llParseStringKeepNulls(str,["~"],[]);
            integer length = llGetListLength(optionsToSet);
            integer n;
            for (; n < length; ++n) {
                list optionsItems = llParseString2List(llList2String(optionsToSet,n),["="],[]);
                string optionItem = llToLower(llStringTrim(llList2String(optionsItems,0),3));
                string optionSetting = llStringTrim(llList2String(optionsItems,1),3);
                if (optionItem == "rlv_grabrange") {
                    RLV_grabRange = (float)optionSetting;
                }
            }
        }
        else  if (num == 34334) {
            llSay(0,"Memory Used by " + llGetScriptName() + ": " + (string)llGetUsedMemory() + " of " + (string)llGetMemoryLimit() + ", Leaving " + (string)llGetFreeMemory() + " memory free.");
        }
        else  if (num == -8008) {
            if (str == "l") {
                debug(["VictimsList"] + VictimsList);
            }
            else  if (str == "o") {
                debug(["RLV_grabRange",RLV_grabRange]);
            }
        }
    }

	listen(integer channel,string name,key id,string message) {
        integer indexUsersList;
        string prompt;
        list buttons;
        if (~(indexUsersList = llListFindList(UsersList,[channel]))) {
            key menuTarget = llList2Key(UsersList,indexUsersList + 2);
            string menuName = llList2String(UsersList,indexUsersList + 3);
            removeFromUsersList(indexUsersList);
            integer restrictionsListIndex = llListFindList(RLV_RESTRICTIONS,[menuName]);
            if (menuName == MENU_RESTRICTIONS || ~restrictionsListIndex) {
                list activeRestrictions = llParseString2List(message,["/"],[]);
                integer index;
                integer length = llGetListLength(activeRestrictions);
                for (; index < length; index++) {
                    string restrictionWorkingOn = llList2String(activeRestrictions,index);
                    if (llSubStringIndex(restrictionWorkingOn,":") || llListFindList(IGNORED_RLV_RESTRICTIONS,[restrictionWorkingOn])) {
                        activeRestrictions = llDeleteSubList(activeRestrictions,index,index);
                        --index;
                        --length;
                    }
                }
                prompt = STRING_PROMPT_RESTRICTIONS_CAPTION + conditionalString(llGetListLength(activeRestrictions),llDumpList2String(activeRestrictions,", "),STRING_PROMPT_RESTRICTIONS_NONE);
                if (menuName == MENU_RESTRICTIONS) {
                    buttons = [MENU_UNDRESS,MENU_ATTACHMENTS];
                    length = llGetListLength(RLV_RESTRICTIONS);
                    for (index = 0; index < length; index += 2) {
                        buttons += llList2String(RLV_RESTRICTIONS,index);
                    }
                }
                else  {
                    prompt += STRING_NEW_LINE + STRING_NEW_LINE + "☑ ... set restriction active" + STRING_NEW_LINE + "☐ ... set restriction inactive" + STRING_NEW_LINE + "(Maybe not all retrictions can't be set inactive)";
                    list availibleRestrictions = llCSV2List(llList2String(RLV_RESTRICTIONS,restrictionsListIndex + 1));
                    length = llGetListLength(availibleRestrictions);
                    for (index = 0; index < length; index++) {
                        string restrictionWorkingOn = llList2String(availibleRestrictions,index);
                        if (llListFindList(activeRestrictions,[restrictionWorkingOn])) {
                            buttons += ["☑ " + restrictionWorkingOn];
                        }
                        else  {
                            buttons += ["☐ " + restrictionWorkingOn];
                        }
                    }
                }
            }
            else  if (menuName == MENU_ATTACHMENTS) {
                buttons == ParseClothingOrAttachmentLayersWorn(message,ATTACHMENT_POINTS);
                prompt = "The following attachment points are worn:\n" + llDumpList2String(buttons,", ") + "\n\nClick a button to try to detach this attachment\n" + "(Beware some might be locked and can't be removed)\n";
            }
            else  if (menuName == MENU_UNDRESS) {
                buttons = ParseClothingOrAttachmentLayersWorn(message,CLOTHING_LAYERS);
                prompt = "The following clothing layers are worn:\n" + llDumpList2String(buttons,", ") + "\n\nClick a button to try to detach this layer\n" + "(Beware some might be locked and can't be removed)\n";
            }
            displayMenu(menuTarget,menuName,prompt,buttons);
        }
    }

	sensor(integer num) {
        debug(["sensor",num]);
        SensorList = [];
        integer index;
        for (; index < num; index++) {
            if (!~getVictimIndex(llDetectedKey(index))) {
                SensorList += [llGetSubString(llDetectedName(index),0,15),llDetectedKey(index)];
            }
        }
        displayMenu(sensorUserKey,MENU_CAPTURE,"",llList2ListStrided(SensorList,0,-1,2));
    }


	no_sensor() {
        debug(["no_sensor"]);
        SensorList = [];
        displayMenu(sensorUserKey,MENU_CAPTURE,"",[]);
    }

	on_rez(integer start_param) {
        init();
    }

	changed(integer change) {
        if (change & 128) {
            llResetScript();
        }
    }

	timer() {
        integer length = llGetListLength(UsersList);
        integer index;
        integer currentTime = llGetUnixTime();
        for (; index < length; index += 5) {
            if (currentTime > llList2Integer(UsersList,index + 4)) {
                removeFromUsersList(index);
                index -= 5;
                length -= 5;
            }
        }
    }
}
