// LSL script generated - patched Render.hs (0.1.6.2): LSLScripts.nPose RLV+ Menu.lslp Sat Apr 25 09:19:52 Mitteleuropäische Sommerzeit 2015
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


string STRING_NEW_LINE = "\n";
string PATH_SEPARATOR = ":";
string MENU_BUTTON_BACK = "^";

string STRING_PROMPT_VICTIM_CAPTION = "Selected Victim: ";
string STRING_PROMPT_VICTIM_NONE = "NONE";
string STRING_PROMPT_VICTIM_SELECT = "Select new active victim.";
string STRING_PROMPT_CAPTURE_CAPTION = "Choose someone to capture.";
string STRING_PROMPT_RESTRICTIONS_CAPTION = "Active restrictions are: ";
string STRING_PROMPT_RESTRICTIONS_NONE = "NONE. Victim may be FREE.";
string STRING_PROMPT_RELAY_CAPTION = "RLV Relay: ";
string STRING_PROMPT_RELAY_DETECTED = "OK";
string STRING_PROMPT_RELAY_NOTDETECTED = "NOT RECOGNIZED";
string STRING_PROMPT_TIMER_ZERO = "--:--:--";
string MENU_CAPTURE = "→Capture";
string MENU_RESTRICTIONS = "→Restrictions";
string MENU_UNDRESS = "→Undress";
string MENU_ATTACHMENTS = "→Attachments";
string MENU_VICTIMS = "→Victims";
string MENU_TIMER = "→Timer";
string MENU_BUTTON_RELEASE = "Release";
string MENU_BUTTON_UNSIT = "Unsit";

list RLV_RESTRICTIONS = ["→Chat/IM","sendchat,chatshout,chatnormal,recvchat,recvemote,sendim,startim,recvim","→Inventory","showinv,viewnote,viewscript,viewtexture,edit,rez,unsharedwear,unsharedunwear","→Touch","fartouch,touchall,touchworld,touchattach","→World","shownames,showhovertextall,showworldmap,showminimap,showloc","→Debug/Env","setgroup,setdebug,setenv"];

list IGNORED_RLV_RESTRICTIONS = ["acceptpermission","detach"];

list CLOTHING_LAYERS = ["gloves","jacket","pants","shirt","shoes","skirt","socks","underpants","undershirt","","","","","alpha","tattoo"];

list ATTACHMENT_POINTS = ["","chest","skull","left shoulder","right shoulder","left hand","right hand","left foot","right foot","spine","pelvis","mouth","chin","left ear","right ear","left eyeball","right eyeball","nose","r upper arm","r forearm","l upper arm","l forearm","right hip","r upper leg","r lower leg","left hip","l upper leg","l lower leg","stomach","left pec","right pec","","","","","","","","","neck","root"];

list TIMER_BUTTONS1 = ["+1d","+6h","+1h","+15m","+1m"];
list TIMER_BUTTONS2 = ["-1d","-6h","-1h","-15m","-1m","Reset"];
list CARD_NAMES = ["DEFAULT","SET","BTN","SEQ"];


key MyUniqueId;

integer rlvResponseChannel;
integer rlvResponseHandle;

key VictimKey = NULL_KEY;

list VictimsList;

list SensorList;

list SensorUsersList;

list UsersList;

float RLV_grabRange = 10.0;


// NO pragma inline
debug(list message){
    llOwnerSay(llGetScriptName() + "\n##########\n#>" + llDumpList2String(message,"\n#>") + "\n##########");
}

// NO pragma inline
integer getVictimRelayVersion(key avatarUuid){
    integer relayVersion;
    integer index = llListFindList(VictimsList,[(string)avatarUuid]);
    if (~index) {
        relayVersion = llList2Integer(VictimsList,index + 2);
    }
    return relayVersion;
}

// NO pragma inline
integer getVictimTimer(key avatarUuid){
    integer time;
    integer index = llListFindList(VictimsList,[(string)avatarUuid]);
    if (~index) {
        time = llList2Integer(VictimsList,index + 1) - llGetUnixTime();
        if (time < 0) {
            time = 0;
        }
    }
    return time;
}

// NO pragma inline
setVictimTimer(key avatarUuid,integer time){
    integer index = llListFindList(VictimsList,[(string)avatarUuid]);
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

// NO pragma inline
string conditionalString(integer conditon,string valueIfTrue,string valueIfFalse){
    string ret = valueIfFalse;
    if (conditon) {
        ret = valueIfTrue;
    }
    return ret;
}

// NO pragma inline
removeFromUsersList(integer index){
    if (~index) {
        llListenRemove(llList2Integer(UsersList,index + 1));
        UsersList = llDeleteSubList(UsersList,index,index + 6 - 1);
    }
    if (!llGetListLength(UsersList)) {
        llSetTimerEvent(0.0);
    }
}

// NO pragma inline
integer addToUsersList(key menuTarget,string basePath,string localPath){
    integer index = llListFindList(UsersList,[menuTarget,basePath,localPath]) - 2;
    removeFromUsersList(index);
    integer channel = (integer)(llFrand(1.0e9) + 1.0e9);
    UsersList += [channel,llListen(channel,"",NULL_KEY,""),menuTarget,basePath,localPath,llGetUnixTime() + 4];
    llSetTimerEvent(1.0);
    return channel;
}

// NO pragma inline
init(){
    MyUniqueId = llGenerateKey();
    llListenRemove(rlvResponseHandle);
    rlvResponseChannel = (integer)(llFrand(-1.0e9) - 1.0e9);
    rlvResponseHandle = llListen(rlvResponseChannel,"",NULL_KEY,"");
    SensorUsersList = [];
    UsersList = [];
}

// NO pragma inline
showMenu(key menuTarget,string basePath,string localPath){
    string menuName = llList2String(llParseStringKeepNulls(localPath,[PATH_SEPARATOR],[]),-1);
    if (menuName == MENU_CAPTURE) {
        if (RLV_grabRange) {
            integer index = llListFindList(SensorUsersList,[menuTarget]);
            if (~index) {
                SensorUsersList = llDeleteSubList(SensorUsersList,index,index + 2 - 1);
            }
            SensorUsersList += [menuTarget,basePath,localPath];
            llSensor("",NULL_KEY,1,RLV_grabRange,3.14159265);
        }
        else  {
            displayMenu(menuTarget,basePath,localPath,"",[]);
        }
    }
    else  if (menuName == MENU_RESTRICTIONS) {
        integer channel = addToUsersList(menuTarget,basePath,localPath);
        llMessageLinked(-1,-8010,"rlvCommand,%VICTIM%,@getstatus=" + (string)channel,NULL_KEY);
    }
    else  if (menuName == MENU_UNDRESS) {
        integer channel = addToUsersList(menuTarget,basePath,localPath);
        llMessageLinked(-1,-8010,"rlvCommand,%VICTIM%,@getoutfit=" + (string)channel,NULL_KEY);
    }
    else  if (menuName == MENU_ATTACHMENTS) {
        integer channel = addToUsersList(menuTarget,basePath,localPath);
        llMessageLinked(-1,-8010,"rlvCommand,%VICTIM%,@getattach=" + (string)channel,NULL_KEY);
    }
    else  if (~llListFindList(RLV_RESTRICTIONS,[menuName])) {
        integer channel = addToUsersList(menuTarget,basePath,localPath);
        llMessageLinked(-1,-8010,"rlvCommand,%VICTIM%,@getstatus=" + (string)channel,NULL_KEY);
    }
    else  {
        displayMenu(menuTarget,basePath,localPath,"",[]);
    }
}

// NO pragma inline
displayMenu(key menuTarget,string basePath,string localPath,string additionalPrompt,list additionalButtons){
    list buttons;
    string prompt = STRING_PROMPT_VICTIM_CAPTION + conditionalString(VictimKey != NULL_KEY,llKey2Name(VictimKey),STRING_PROMPT_VICTIM_NONE);
    string menuName = llList2String(llParseStringKeepNulls(localPath,[PATH_SEPARATOR],[]),-1);
    if (menuName == MENU_VICTIMS) {
        if (llGetListLength(VictimsList) > 3 || (llGetListLength(VictimsList) == 3 && VictimKey == NULL_KEY)) {
            integer length = llGetListLength(VictimsList);
            integer n;
            for (; n < length; n += 3) {
                buttons += llGetSubString(llKey2Name(llList2Key(VictimsList,n)),0,15);
            }
            renderMenu(menuTarget,basePath,localPath,prompt + STRING_NEW_LINE + STRING_PROMPT_VICTIM_SELECT,buttons);
        }
    }
    else  if (menuName == MENU_CAPTURE) {
        if (!~llListFindList(VictimsList,[(string)menuTarget]) && RLV_grabRange > 0) {
            renderMenu(menuTarget,basePath,localPath,STRING_PROMPT_CAPTURE_CAPTION,additionalButtons);
        }
    }
    else  if (menuName == MENU_TIMER) {
        if (VictimKey != NULL_KEY && (!~llListFindList(VictimsList,[(string)menuTarget]) || getVictimTimer(VictimKey))) {
            buttons = TIMER_BUTTONS1;
            if (!~llListFindList(VictimsList,[(string)menuTarget])) {
                buttons += TIMER_BUTTONS2;
            }
            renderMenu(menuTarget,basePath,localPath,prompt + STRING_NEW_LINE + getVictimTimerString(VictimKey),buttons);
        }
    }
    else  if (menuName == MENU_RESTRICTIONS || menuName == MENU_UNDRESS || menuName == MENU_ATTACHMENTS || ~llListFindList(RLV_RESTRICTIONS,[menuName])) {
        if (VictimKey != NULL_KEY && !~llListFindList(VictimsList,[(string)menuTarget]) && getVictimRelayVersion(VictimKey)) {
            renderMenu(menuTarget,basePath,localPath,prompt + STRING_NEW_LINE + additionalPrompt,additionalButtons);
        }
    }
    if (menuName == "") {
        if (!~llListFindList(VictimsList,[(string)menuTarget]) && RLV_grabRange > 0) {
            buttons += [MENU_CAPTURE];
        }
        if (VictimKey != NULL_KEY && !~llListFindList(VictimsList,[(string)menuTarget]) && getVictimRelayVersion(VictimKey)) {
            buttons += [MENU_RESTRICTIONS];
        }
        if (VictimKey != NULL_KEY && !~llListFindList(VictimsList,[(string)menuTarget])) {
            buttons += [MENU_BUTTON_RELEASE];
        }
        if (VictimKey != NULL_KEY && !~llListFindList(VictimsList,[(string)menuTarget])) {
            buttons += [MENU_BUTTON_UNSIT];
        }
        if (VictimKey != NULL_KEY && (!~llListFindList(VictimsList,[(string)menuTarget]) || getVictimTimer(VictimKey))) {
            buttons += [MENU_TIMER];
        }
        if (llGetListLength(VictimsList) > 3 || (llGetListLength(VictimsList) == 3 && VictimKey == NULL_KEY)) {
            buttons += [MENU_VICTIMS];
        }
        if (VictimKey) {
            prompt += STRING_NEW_LINE + STRING_PROMPT_RELAY_CAPTION + conditionalString(getVictimRelayVersion(VictimKey),STRING_PROMPT_RELAY_DETECTED,STRING_PROMPT_RELAY_NOTDETECTED) + STRING_NEW_LINE + getVictimTimerString(VictimKey);
        }
        renderMenu(menuTarget,basePath,localPath,prompt,buttons);
    }
}

// NO pragma inline
renderMenu(key targetKey,string basePath,string localPath,string prompt,list buttons){
    if (targetKey) {
        llMessageLinked(-1,-900,(string)targetKey + "|" + prompt + STRING_NEW_LINE + STRING_NEW_LINE + basePath + localPath + STRING_NEW_LINE + "|0|" + llDumpList2String(buttons,"`") + "|" + conditionalString(basePath != "" || localPath != "",MENU_BUTTON_BACK,"") + "|" + basePath + "," + localPath,MyUniqueId);
    }
}

// NO pragma inline
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
        if (num == -237) {
            VictimKey = (key)str;
        }
        else  if (num == -238) {
            VictimsList = llCSV2List(str);
        }
        else  if (num == -8000) {
            list temp = llParseStringKeepNulls(str,[","],[]);
            string cmd = llToLower(llStringTrim(llList2String(temp,0),3));
            string replace = (string)VictimKey;
            key target = (key)llDumpList2String(llParseStringKeepNulls(llStringTrim(llList2String(temp,1),3),["%VICTIM%"],[]),replace);
            list params = llDeleteSubList(temp,0,1);
            if (target) {
            }
            else  {
                target = VictimKey;
            }
            if (cmd == "showmenu") {
                list pathParts = llParseStringKeepNulls(llList2String(params,0),[PATH_SEPARATOR],[]);
                if (~llListFindList(CARD_NAMES,[llList2String(pathParts,0)])) {
                    pathParts = "Main" + llDeleteSubList(pathParts,0,0);
                }
                integer _index4 = llSubStringIndex(llList2String(pathParts,-1),"{");
                if (~_index4) {
                    pathParts = llDeleteSubList(pathParts,-1,-1) + llDeleteSubString(llList2String(pathParts,-1),_index4,-1);
                }
                showMenu(target,llDumpList2String(pathParts,PATH_SEPARATOR),llList2String(params,1));
            }
        }
        else  if (num == -901) {
            if (id == MyUniqueId) {
                list params = llParseString2List(str,["|"],[]);
                string selection = llList2String(params,1);
                key toucher = (key)llList2String(params,2);
                list tempPath = llParseStringKeepNulls(llList2String(params,3),[","],[]);
                string basePath = llList2String(tempPath,0);
                string localPath = llList2String(tempPath,1);
                list localPathParts = llParseStringKeepNulls(localPath,[PATH_SEPARATOR],[]);
                if (selection == MENU_BUTTON_BACK) {
                    if (localPath == "") {
                        basePath = llDumpList2String(llDeleteSubList(llParseStringKeepNulls(basePath,[PATH_SEPARATOR],[]),-1,-1),PATH_SEPARATOR);
                        if (basePath) {
                            llMessageLinked(-1,-800,basePath,toucher);
                        }
                    }
                    else  {
                        showMenu(toucher,basePath,llDumpList2String(llDeleteSubList(localPathParts,-1,-1),PATH_SEPARATOR));
                    }
                }
                else  if (selection == "" || selection == MENU_ATTACHMENTS || selection == MENU_CAPTURE || selection == MENU_RESTRICTIONS || selection == MENU_TIMER || selection == MENU_UNDRESS || selection == MENU_VICTIMS || ~llListFindList(RLV_RESTRICTIONS,[selection])) {
                    showMenu(toucher,basePath,localPath + PATH_SEPARATOR + selection);
                }
                else  {
                    if (localPath == "") {
                        if (selection == MENU_BUTTON_UNSIT || selection == MENU_BUTTON_RELEASE) {
                            if (selection == MENU_BUTTON_UNSIT && VictimKey != NULL_KEY && !~llListFindList(VictimsList,[(string)toucher])) {
                                llMessageLinked(-1,-8010,"unsit,%VICTIM%",NULL_KEY);
                                llSleep(1.0);
                            }
                            else  if (selection == MENU_BUTTON_RELEASE && VictimKey != NULL_KEY && !~llListFindList(VictimsList,[(string)toucher])) {
                                llMessageLinked(-1,-8010,"release,%VICTIM%",NULL_KEY);
                                llSleep(1.0);
                            }
                            llMessageLinked(-1,-8000,"showMenu," + (string)toucher + "," + basePath + "," + localPath,NULL_KEY);
                        }
                    }
                    else  if (!llSubStringIndex(localPath,PATH_SEPARATOR + MENU_RESTRICTIONS)) {
                        if (VictimKey != NULL_KEY && !~llListFindList(VictimsList,[(string)toucher]) && getVictimRelayVersion(VictimKey)) {
                            if (~llListFindList(ATTACHMENT_POINTS,[selection])) {
                                llMessageLinked(-1,-8010,"rlvCommand,%VICTIM%,@remattach:" + selection + "=force",NULL_KEY);
                                llSleep(0.5);
                                showMenu(toucher,basePath,localPath);
                            }
                            else  if (~llListFindList(CLOTHING_LAYERS,[selection])) {
                                llMessageLinked(-1,-8010,"rlvCommand,%VICTIM%,@remoutfit:" + selection + "=force",NULL_KEY);
                                llSleep(0.5);
                                showMenu(toucher,basePath,localPath);
                            }
                            else  if (llGetSubString(selection,0,0) == "☐") {
                                llMessageLinked(-1,-8010,"rlvCommand,%VICTIM%,@" + llStringTrim(llDeleteSubString(selection,0,1),3) + "=n",NULL_KEY);
                                llSleep(0.5);
                                showMenu(toucher,basePath,localPath);
                            }
                            else  if (llGetSubString(selection,0,0) == "☑") {
                                llMessageLinked(-1,-8010,"rlvCommand,%VICTIM%,@" + llStringTrim(llDeleteSubString(selection,0,1),3) + "=y",NULL_KEY);
                                llSleep(0.5);
                                showMenu(toucher,basePath,localPath);
                            }
                        }
                    }
                    else  if (localPath == PATH_SEPARATOR + MENU_CAPTURE) {
                        if (!~llListFindList(VictimsList,[(string)toucher]) && RLV_grabRange > 0) {
                            integer index = llListFindList(SensorList,[selection]);
                            if (~index) {
                                key avatarWorkingOn = llList2Key(SensorList,index + 1);
                                llMessageLinked(-1,-8010,"grab," + (string)avatarWorkingOn,NULL_KEY);
                                if (toucher == avatarWorkingOn) {
                                    llSleep(2.0);
                                }
                            }
                            llMessageLinked(-1,-800,llDumpList2String(llDeleteSubList(llParseStringKeepNulls(basePath,[PATH_SEPARATOR],[]),-1,-1),PATH_SEPARATOR),toucher);
                        }
                    }
                    else  if (localPath == PATH_SEPARATOR + MENU_VICTIMS) {
                        if (llGetListLength(VictimsList) > 3 || (llGetListLength(VictimsList) == 3 && VictimKey == NULL_KEY)) {
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
                        showMenu(toucher,basePath,localPath);
                    }
                    else  if (localPath == PATH_SEPARATOR + MENU_TIMER) {
                        if (VictimKey != NULL_KEY && (!~llListFindList(VictimsList,[(string)toucher]) || getVictimTimer(VictimKey))) {
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
                                key avatarUuid = VictimKey;
                                integer _index19 = llListFindList(VictimsList,[(string)avatarUuid]);
                                if (~_index19) {
                                    integer thisTime = llGetUnixTime();
                                    integer oldTime = llList2Integer(VictimsList,_index19 + 1);
                                    if (oldTime < thisTime) {
                                        oldTime = thisTime;
                                    }
                                    integer newTime = oldTime + multiplier * (integer)llGetSubString(selection,0,-2);
                                    if (newTime < thisTime + 30) {
                                        newTime = thisTime + 30;
                                    }
                                    setVictimTimer(avatarUuid,newTime);
                                }
                            }
                            showMenu(toucher,basePath,localPath);
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
                debug(["VictimsList"] + VictimsList + ["####","SensorList"] + SensorList + ["####","UsersList"] + UsersList);
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
            string basePath = llList2String(UsersList,indexUsersList + 3);
            string localPath = llList2String(UsersList,indexUsersList + 4);
            removeFromUsersList(indexUsersList);
            string menuName = llList2String(llParseStringKeepNulls(localPath,[PATH_SEPARATOR],[]),-1);
            integer restrictionsListIndex = llListFindList(RLV_RESTRICTIONS,[menuName]);
            if (menuName == MENU_RESTRICTIONS || ~restrictionsListIndex) {
                list activeRestrictions = llParseString2List(message,["/"],[]);
                integer index;
                integer length = llGetListLength(activeRestrictions);
                for (; index < length; index++) {
                    string restrictionWorkingOn = llList2String(activeRestrictions,index);
                    if (~llSubStringIndex(restrictionWorkingOn,":") || ~llListFindList(IGNORED_RLV_RESTRICTIONS,[restrictionWorkingOn])) {
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
                        if (~llListFindList(activeRestrictions,[restrictionWorkingOn])) {
                            buttons += ["☑ " + restrictionWorkingOn];
                        }
                        else  {
                            buttons += ["☐ " + restrictionWorkingOn];
                        }
                    }
                }
            }
            else  if (menuName == MENU_ATTACHMENTS) {
                buttons = ParseClothingOrAttachmentLayersWorn(message,ATTACHMENT_POINTS);
                prompt = "The following attachment points are worn:\n" + llDumpList2String(buttons,", ") + "\n\nClick a button to try to detach this attachment\n" + "(Beware some might be locked and can't be removed)";
            }
            else  if (menuName == MENU_UNDRESS) {
                buttons = ParseClothingOrAttachmentLayersWorn(message,CLOTHING_LAYERS);
                prompt = "The following clothing layers are worn:\n" + llDumpList2String(buttons,", ") + "\n\nClick a button to try to detach this layer\n" + "(Beware some might be locked and can't be removed)";
            }
            displayMenu(menuTarget,basePath,localPath,prompt,buttons);
        }
    }

	sensor(integer num) {
        SensorList = [];
        integer index;
        for (; index < num; index++) {
            key avatarUuid = llDetectedKey(index);
            if (!~llListFindList(VictimsList,[(string)avatarUuid])) {
                SensorList += [llGetSubString(llDetectedName(index),0,15),llDetectedKey(index)];
            }
        }
        integer length = llGetListLength(SensorUsersList);
        for (index = 0; index < length; index += 3) {
            displayMenu(llList2Key(SensorUsersList,index),llList2Key(SensorUsersList,index + 1),llList2Key(SensorUsersList,index + 2),"",llList2ListStrided(SensorList,0,-1,2));
        }
        SensorUsersList = [];
    }


	no_sensor() {
        SensorList = [];
        integer length = llGetListLength(SensorUsersList);
        integer index;
        for (; index < length; index += 3) {
            displayMenu(llList2Key(SensorUsersList,index),llList2Key(SensorUsersList,index + 1),llList2Key(SensorUsersList,index + 2),"",[]);
        }
        SensorUsersList = [];
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
        for (; index < length; index += 6) {
            if (currentTime > llList2Integer(UsersList,index + 5)) {
                removeFromUsersList(index);
                index -= 6;
                length -= 6;
            }
        }
    }
}
