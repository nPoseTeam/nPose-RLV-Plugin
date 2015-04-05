// LSL script generated - patched Render.hs (0.1.6.2): LSLScripts.nPose RLV+ Core.lslp Sun Apr  5 10:57:22 Mitteleuropäische Sommerzeit 2015


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


string PLUGIN_NAME = "RLV_CORE";

string BACKBTN = "^";
string MENU_RLV_MAIN = "RLVMain";
string MENU_RLV_CAPTURE = "→Capture";
string MENU_RLV_RESTRICTIONS = "→Restrictions";
string MENU_RLV_VICTIMS = "→Victims";
string MENU_RLV_TIMER = "→Timer";
string BUTTON_RLV_RELEASE = "Release";
string BUTTON_RLV_UNSIT = "Unsit";

string RLV_COMMAND_RELEASE = "!release";
string RLV_COMMAND_VERSION = "!version";
string RLV_COMMAND_PING = "ping";
string RLV_COMMAND_PONG = "!pong";

list TIMER_BUTTONS1 = ["+1d","+6h","+1h","+15m","+1m"];
list TIMER_BUTTONS2 = ["-1d","-6h","-1h","-15m","-1m","Reset"];

string TIMER_NO_TIME = "--:--:--";
string PROMPT_VICTIM = "Selected Victim: ";
string PROMPT_CAPTURE = "Pick a victim to attempt capturing.";
string PROMPT_RELAY = "RLV Relay: ";
string PROMPT_RELAY_YES = "OK";
string PROMPT_RELAY_NO = "NOT RECOGNIZED";
string NEW_LINE = "\n";
string NO_VICTIM = "NONE";

string PATH_SEPARATOR = ":";

// --- global variables

// options
integer RLV_captureRange = 10;
integer RLV_trapTimer;
integer RLV_grabTimer;
list RLV_enabledSeats = ["*"];

key MyUniqueId;

string Path;
key NPosetoucherID;
string NPosePath;


key VictimKey = NULL_KEY;
//integer currentVictimIndex=-1; //contains the VictimsList-index of the current victim

list VictimsList;

list FreeVictimsList;

list GrabList;

list RecaptureList;

list SensorList;

integer FreeRlvEnabledSeats;
integer FreeNonRlvEnabledSeats;


// for RLV base restrictions and reading them from a notecard
string RlvBaseRestrictions = "@unsit=n|@sittp=n|@tploc=n|@tplure=n|@tplm=n|@acceptpermission=add|@editobj:%MYKEY%=add";
key NcQueryId;

//added for timer
integer TimerRunning;

string PLUGIN_NAME_RLV_RESTRICTIONS_MENU = "RLV_RESTRICTIONS_MENU";
integer RlvRestrictionsMenuAvailable;

// NO pragma inline
addToVictimsList(key avatarUuid,integer timerTime){
    if (timerTime > 0) {
        timerTime += llGetUnixTime();
    }
    else  if (timerTime < 0) {
        timerTime = 0;
    }
    removeFromVictimsList(avatarUuid);
    VictimsList += [avatarUuid,timerTime,0];
    llMessageLinked(-1,-8001,(string)avatarUuid,"");
    sendToRlvRelay(avatarUuid,RLV_COMMAND_VERSION + "|" + RlvBaseRestrictions,"");
    if (!TimerRunning) {
        llSetTimerEvent(1.0);
        TimerRunning = 1;
    }
}

// NO pragma inline
removeFromVictimsList(key avatarUuid){
    integer index;
    while (~(index = llListFindList(VictimsList,[avatarUuid]))) {
        VictimsList = llDeleteSubList(VictimsList,index,index + 3 - 1);
        llMessageLinked(-1,-8002,(string)avatarUuid,"");
    }
    if (VictimKey == avatarUuid) {
        changeCurrentVictim(NULL_KEY);
    }
    if (!llGetListLength(VictimsList) && TimerRunning) {
        llSetTimerEvent(0.0);
        TimerRunning = 0;
    }
}

// NO pragma inline
changeCurrentVictim(key newVictimKey){
    if (newVictimKey != VictimKey) {
        if (newVictimKey == NULL_KEY || ~llListFindList(VictimsList,[newVictimKey])) {
            VictimKey = newVictimKey;
            llMessageLinked(-1,-237,(string)VictimKey,"");
        }
    }
}

// NO pragma inline
recaptureListRemoveTimedOutEntrys(){
    integer currentTime = llGetUnixTime();
    integer length = llGetListLength(RecaptureList);
    integer index;
    for (; index < length; index += 3) {
        integer timeout = llList2Integer(RecaptureList,index + 2);
        if (timeout && timeout < currentTime) {
            RecaptureList = llDeleteSubList(RecaptureList,index,index + 3 - 1);
            index -= 3;
            length -= 3;
        }
    }
}

// NO pragma inline
showMenu(key targetKey,string prompt,list buttons,string menuPath){
    if (targetKey) {
        llMessageLinked(-1,-900,(string)targetKey + "|" + prompt + "\n" + menuPath + "\n" + "|" + "0" + "|" + llDumpList2String(buttons,"`") + "|" + llDumpList2String([BACKBTN],"`") + "|" + menuPath,MyUniqueId);
    }
}


// send rlv commands to the RLV relay, usable for common format (not ping)
// NO pragma inline
sendToRlvRelay(key victim,string rlvCommand,string identifier){
    if (rlvCommand) {
        if (victim) {
            string valueIfFalse = (string)MyUniqueId;
            string ret = valueIfFalse;
            if (llStringLength(identifier)) {
                ret = identifier;
            }
            string replace = (string)llGetKey();
            llSay(-1812221819,ret + "," + (string)victim + "," + llDumpList2String(llParseStringKeepNulls(rlvCommand,["%MYKEY%"],[]),replace));
        }
    }
}

// NO pragma inline
integer getVictimTimer(key avatarUuid){
    integer index = llListFindList(VictimsList,[avatarUuid]);
    if (~index) {
        integer time = llList2Integer(VictimsList,index + 1) - llGetUnixTime();
        if (time > 0) {
            return time;
        }
    }
    return 0;
}

// NO pragma inline
string getVictimTimerString(key avatarUuid){
    string returnValue = "Timer: ";
    integer runningTimeS = getVictimTimer(avatarUuid);
    if (!runningTimeS) {
        return returnValue + TIMER_NO_TIME + NEW_LINE;
    }
    integer runningTimeM = runningTimeS / 60;
    runningTimeS = runningTimeS % 60;
    integer runningTimeH = runningTimeM / 60;
    runningTimeM = runningTimeM % 60;
    integer runningTimeD = runningTimeH / 24;
    runningTimeH = runningTimeH % 24;
    string ret = "";
    if (runningTimeD) {
        ret = (string)runningTimeD + "d ";
    }
    return returnValue + ret + llGetSubString("0" + (string)runningTimeH,-2,-1) + ":" + llGetSubString("0" + (string)runningTimeM,-2,-1) + ":" + llGetSubString("0" + (string)runningTimeS,-2,-1);
}

// --- functions

debug(list message){
    llOwnerSay(llGetScriptName() + "\n##########\n#>" + llDumpList2String(message,"\n#>") + "\n##########");
}


showMainMenu(key targetKey){
    list buttons;
    integer numberOfVictims = llGetListLength(VictimsList) / 3;
    if (!~llListFindList(VictimsList,[targetKey])) {
        buttons += [MENU_RLV_CAPTURE];
        key avatarUuid = VictimKey;
        integer relayVersion;
        integer index = llListFindList(VictimsList,[avatarUuid]);
        if (~index) {
            relayVersion = llList2Integer(VictimsList,index + 2);
        }
        if (VictimKey != NULL_KEY && !~llListFindList(VictimsList,[targetKey]) && relayVersion && RlvRestrictionsMenuAvailable) {
            buttons += [MENU_RLV_RESTRICTIONS];
        }
        if (VictimKey) {
            buttons += [BUTTON_RLV_RELEASE,BUTTON_RLV_UNSIT];
        }
    }
    if (VictimKey != NULL_KEY && (!~llListFindList(VictimsList,[targetKey]) || getVictimTimer(VictimKey))) {
        buttons += [MENU_RLV_TIMER];
    }
    if (numberOfVictims) {
        buttons += [MENU_RLV_VICTIMS];
    }
    integer conditon = VictimKey != NULL_KEY;
    string valueIfTrue = llKey2Name(VictimKey);
    string valueIfFalse = NO_VICTIM;
    string ret = valueIfFalse;
    if (conditon) {
        ret = valueIfTrue;
    }
    string promt = PROMPT_VICTIM + ret + NEW_LINE;
    if (VictimKey) {
        key _avatarUuid10 = VictimKey;
        integer _relayVersion11;
        integer _index12 = llListFindList(VictimsList,[_avatarUuid10]);
        if (~_index12) {
            _relayVersion11 = llList2Integer(VictimsList,_index12 + 2);
        }
        integer _conditon15 = _relayVersion11;
        string _valueIfTrue16 = PROMPT_RELAY_YES;
        string _valueIfFalse17 = PROMPT_RELAY_NO;
        string _ret18 = _valueIfFalse17;
        if (_conditon15) {
            _ret18 = _valueIfTrue16;
        }
        promt += PROMPT_RELAY + _ret18 + NEW_LINE + getVictimTimerString(VictimKey);
    }
    showMenu(targetKey,promt,buttons,MENU_RLV_MAIN);
}

showTimerMenu(key targetKey){
    if (VictimKey != NULL_KEY && (!~llListFindList(VictimsList,[targetKey]) || getVictimTimer(VictimKey))) {
        list buttons = TIMER_BUTTONS1;
        if (!~llListFindList(VictimsList,[targetKey])) {
            buttons += TIMER_BUTTONS2;
        }
        integer conditon = VictimKey != NULL_KEY;
        string valueIfTrue = llKey2Name(VictimKey);
        string valueIfFalse = NO_VICTIM;
        string ret = valueIfFalse;
        if (conditon) {
            ret = valueIfTrue;
        }
        showMenu(targetKey,PROMPT_VICTIM + ret + NEW_LINE + getVictimTimerString(VictimKey),buttons,MENU_RLV_MAIN + PATH_SEPARATOR + MENU_RLV_TIMER);
    }
}

showVictimsMenu(key targetKey){
    list victimsButtons;
    integer length = llGetListLength(VictimsList);
    integer n;
    for (; n < length; n += 3) {
        victimsButtons += llGetSubString(llKey2Name(llList2Key(VictimsList,n)),0,15);
    }
    integer conditon = VictimKey != NULL_KEY;
    string valueIfTrue = llKey2Name(VictimKey);
    string valueIfFalse = NO_VICTIM;
    string ret = valueIfFalse;
    if (conditon) {
        ret = valueIfTrue;
    }
    showMenu(targetKey,PROMPT_VICTIM + ret + NEW_LINE + "Select new active victim.",victimsButtons,MENU_RLV_MAIN + PATH_SEPARATOR + MENU_RLV_VICTIMS);
}



// --- states

default {

	state_entry() {
        llListen(-1812221819,"",NULL_KEY,"");
        MyUniqueId = llGenerateKey();
        llMessageLinked(-1,-8049,PLUGIN_NAME,"");
        llMessageLinked(-1,-8048,PLUGIN_NAME_RLV_RESTRICTIONS_MENU,"");
    }


	link_message(integer sender,integer num,string str,key id) {
        if (num == -8048) {
            if (str == PLUGIN_NAME) {
                llMessageLinked(-1,-8049,PLUGIN_NAME,"");
            }
        }
        else  if (num == -8049) {
            if (str == PLUGIN_NAME_RLV_RESTRICTIONS_MENU) {
                RlvRestrictionsMenuAvailable = 1;
            }
        }
        else  if (num == -901) {
            if (id == MyUniqueId) {
                list params = llParseString2List(str,["|"],[]);
                string selection = llList2String(params,1);
                Path = llList2String(params,3);
                NPosetoucherID = (key)llList2String(params,2);
                list pathparts = llParseString2List(Path,[PATH_SEPARATOR],[]);
                key avatarUuid = NPosetoucherID;
                integer toucherIsVictim = ~llListFindList(VictimsList,[avatarUuid]);
                if (selection == BACKBTN) {
                    selection = llList2String(pathparts,-2);
                    if (Path == MENU_RLV_MAIN) {
                        llMessageLinked(-1,-800,NPosePath,NPosetoucherID);
                        return;
                    }
                    else  if (selection == MENU_RLV_MAIN) {
                        showMainMenu(NPosetoucherID);
                        return;
                    }
                    else  {
                        pathparts = llDeleteSubList(pathparts,-2,-1);
                        Path = llDumpList2String(pathparts,PATH_SEPARATOR);
                    }
                }
                if (Path == MENU_RLV_MAIN) {
                    if (selection == MENU_RLV_CAPTURE) {
                        if (!toucherIsVictim) {
                            llSensor("",NULL_KEY,1,RLV_captureRange,3.14159265);
                        }
                        else  {
                            showMainMenu(NPosetoucherID);
                        }
                    }
                    else  if (selection == MENU_RLV_RESTRICTIONS) {
                        llMessageLinked(-1,-8010,"showMenu," + (string)NPosetoucherID,"");
                    }
                    else  if (selection == BUTTON_RLV_RELEASE) {
                        if (!toucherIsVictim) {
                            key targetKey = VictimKey;
                            sendToRlvRelay(targetKey,RLV_COMMAND_RELEASE,"");
                            if (!~llListFindList(FreeVictimsList,[targetKey])) {
                                FreeVictimsList += targetKey;
                            }
                            removeFromVictimsList(targetKey);
                        }
                        showMainMenu(NPosetoucherID);
                    }
                    else  if (selection == BUTTON_RLV_UNSIT) {
                        if (!toucherIsVictim) {
                            key _targetKey4 = VictimKey;
                            sendToRlvRelay(_targetKey4,"@unsit=y","");
                            llSleep(0.75);
                            sendToRlvRelay(_targetKey4,"@unsit=force","");
                            llSleep(0.75);
                            sendToRlvRelay(_targetKey4,RLV_COMMAND_RELEASE,"");
                            if (!~llListFindList(FreeVictimsList,[_targetKey4])) {
                                FreeVictimsList += _targetKey4;
                            }
                            removeFromVictimsList(_targetKey4);
                        }
                        showMainMenu(NPosetoucherID);
                    }
                    else  if (selection == MENU_RLV_TIMER) {
                        showTimerMenu(NPosetoucherID);
                    }
                    else  if (selection == MENU_RLV_VICTIMS) {
                        showVictimsMenu(NPosetoucherID);
                    }
                    return;
                }
                else  if (Path == MENU_RLV_MAIN + PATH_SEPARATOR + MENU_RLV_CAPTURE) {
                    if (!toucherIsVictim) {
                        integer n = llListFindList(SensorList,[selection]);
                        if (~n) {
                            key avatarWorkingOn = llList2Key(SensorList,n + 1);
                            integer counter = llGetNumberOfPrims();
                            while (llGetAgentSize(llGetLinkKey(counter))) {
                                if (avatarWorkingOn == llGetLinkKey(counter)) {
                                    if (~llListFindList(VictimsList,[avatarWorkingOn])) {
                                        sendToRlvRelay(avatarWorkingOn,RlvBaseRestrictions,"");
                                        changeCurrentVictim(avatarWorkingOn);
                                        showMainMenu(NPosetoucherID);
                                        return;
                                    }
                                    else  if (~llListFindList(FreeVictimsList,[avatarWorkingOn])) {
                                        integer _index11;
                                        while (~(_index11 = llListFindList(FreeVictimsList,[avatarWorkingOn]))) {
                                            {
                                                FreeVictimsList = llDeleteSubList(FreeVictimsList,_index11,_index11 + 1 - 1);
                                            }
                                        }
                                        addToVictimsList(avatarWorkingOn,RLV_grabTimer);
                                        changeCurrentVictim(avatarWorkingOn);
                                        Path = "";
                                        llMessageLinked(-1,-800,NPosePath,NPosetoucherID);
                                        return;
                                    }
                                    else  {
                                        showMainMenu(NPosetoucherID);
                                        return;
                                    }
                                }
                                counter--;
                            }
                            if (!~llListFindList(GrabList,[avatarWorkingOn])) {
                                GrabList += [avatarWorkingOn,llGetUnixTime() + 60];
                                while (llGetListLength(GrabList) > 6) {
                                    {
                                        GrabList = llList2List(GrabList,2,-1);
                                    }
                                }
                            }
                            sendToRlvRelay(avatarWorkingOn,"@sit:" + (string)llGetKey() + "=force","");
                            Path = "";
                            llMessageLinked(-1,-800,NPosePath,NPosetoucherID);
                        }
                    }
                }
                else  if (Path == MENU_RLV_MAIN + PATH_SEPARATOR + MENU_RLV_TIMER) {
                    key _targetKey15 = NPosetoucherID;
                    if (VictimKey != NULL_KEY && (!~llListFindList(VictimsList,[_targetKey15]) || getVictimTimer(VictimKey))) {
                        if (selection == "Reset") {
                            key _avatarUuid17 = VictimKey;
                            integer _index18 = llListFindList(VictimsList,[_avatarUuid17]);
                            if (~_index18) {
                                VictimsList = llListReplaceList(VictimsList,[0],_index18 + 1,_index18 + 1);
                            }
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
                            key _avatarUuid20 = VictimKey;
                            integer _index21 = llListFindList(VictimsList,[_avatarUuid20]);
                            if (~_index21) {
                                integer thisTime = llGetUnixTime();
                                integer oldTime = llList2Integer(VictimsList,_index21 + 1);
                                if (oldTime < thisTime) {
                                    oldTime = thisTime;
                                }
                                integer newTime = oldTime + multiplier * (integer)llGetSubString(selection,0,-2);
                                if (newTime < thisTime + 30) {
                                    newTime = thisTime + 30;
                                }
                                VictimsList = llListReplaceList(VictimsList,[newTime],_index21 + 1,_index21 + 1);
                                if (!TimerRunning) {
                                    llSetTimerEvent(1.0);
                                    TimerRunning = 1;
                                }
                            }
                        }
                        showTimerMenu(NPosetoucherID);
                    }
                }
                else  if (Path == MENU_RLV_MAIN + PATH_SEPARATOR + MENU_RLV_VICTIMS) {
                    integer length = llGetListLength(VictimsList);
                    integer n;
                    for (; n < length; n += 3) {
                        key avatarWorkingOn = llList2Key(VictimsList,n);
                        if (llGetSubString(llKey2Name(avatarWorkingOn),0,15) == selection) {
                            changeCurrentVictim(avatarWorkingOn);
                        }
                    }
                    showMainMenu(NPosetoucherID);
                }
            }
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
                string menuName = llToLower(llStringTrim(llList2String(params,0),3));
                if (menuName == "" || menuName == "main") {
                    showMainMenu(target);
                }
                else  if (menuName == "victims") {
                    showVictimsMenu(target);
                }
                else  if (menuName == "capture") {
                    if (!~llListFindList(VictimsList,[target])) {
                        NPosetoucherID = target;
                        llSensor("",NULL_KEY,1,RLV_captureRange,3.14159265);
                    }
                }
                else  if (menuName == "timer") {
                    showTimerMenu(target);
                }
            }
            else  if (cmd == "rlvcommand") {
                sendToRlvRelay(target,llDumpList2String(llParseStringKeepNulls(llList2String(params,0),["/"],[]),"|"),"");
            }
            else  if (cmd == "release") {
                sendToRlvRelay(target,RLV_COMMAND_RELEASE,"");
                if (!~llListFindList(FreeVictimsList,[target])) {
                    FreeVictimsList += target;
                }
                removeFromVictimsList(target);
            }
            else  if (cmd == "unsit") {
                sendToRlvRelay(target,"@unsit=y","");
                llSleep(0.75);
                sendToRlvRelay(target,"@unsit=force","");
                llSleep(0.75);
                sendToRlvRelay(target,RLV_COMMAND_RELEASE,"");
                if (!~llListFindList(FreeVictimsList,[target])) {
                    FreeVictimsList += target;
                }
                removeFromVictimsList(target);
            }
            else  if (cmd == "addtime") {
                integer _index32 = llListFindList(VictimsList,[target]);
                if (~_index32) {
                    integer _thisTime33 = llGetUnixTime();
                    integer _oldTime34 = llList2Integer(VictimsList,_index32 + 1);
                    if (_oldTime34 < _thisTime33) {
                        _oldTime34 = _thisTime33;
                    }
                    integer _newTime35 = _oldTime34 + (integer)llList2String(params,0);
                    if (_newTime35 < _thisTime33 + 30) {
                        _newTime35 = _thisTime33 + 30;
                    }
                    VictimsList = llListReplaceList(VictimsList,[_newTime35],_index32 + 1,_index32 + 1);
                    if (!TimerRunning) {
                        llSetTimerEvent(1.0);
                        TimerRunning = 1;
                    }
                }
            }
            else  if (cmd == "resettime") {
                integer _index37 = llListFindList(VictimsList,[target]);
                if (~_index37) {
                    VictimsList = llListReplaceList(VictimsList,[0],_index37 + 1,_index37 + 1);
                }
            }
            else  if (cmd == "read") {
                string rlvRestrictionsNotecard = llList2String(params,0);
                if (llGetInventoryType(rlvRestrictionsNotecard) == 7) {
                    NcQueryId = llGetNotecardLine(rlvRestrictionsNotecard,0);
                }
                else  {
                    llWhisper(0,"Error: rlvRestrictions Notecard " + rlvRestrictionsNotecard + " not found");
                }
            }
            else  if (cmd == "setselectedvictim") {
                changeCurrentVictim(target);
            }
        }
        else  if (num == -802) {
            NPosePath = str;
        }
        else  if (num == 35353) {
            recaptureListRemoveTimedOutEntrys();
            integer currentTime = llGetUnixTime();
            integer _length39 = llGetListLength(GrabList);
            integer _index40;
            for (; _index40 < _length39; _index40 += 2) {
                integer timeout = llList2Integer(GrabList,_index40 + 1);
                if (timeout < currentTime) {
                    GrabList = llDeleteSubList(GrabList,_index40,_index40 + 2 - 1);
                    _index40 -= 2;
                    _length39 -= 2;
                }
            }
            FreeNonRlvEnabledSeats = 0;
            FreeRlvEnabledSeats = 0;
            list slotsList = llParseStringKeepNulls(str,["^"],[]);
            integer length = llGetListLength(slotsList);
            integer index;
            for (; index < length; index += 8) {
                key avatarWorkingOn = (key)llList2String(slotsList,index + 4);
                integer seatNumber = index / 8 + 1;
                integer isRlvEnabledSeat = ~llListFindList(RLV_enabledSeats,["*"]) || ~llListFindList(RLV_enabledSeats,[(string)seatNumber]);
                if (avatarWorkingOn) {
                    if (isRlvEnabledSeat) {
                        if (!~llListFindList(VictimsList,[avatarWorkingOn])) {
                            if (~llListFindList(GrabList,[avatarWorkingOn])) {
                                addToVictimsList(avatarWorkingOn,RLV_grabTimer);
                                changeCurrentVictim(avatarWorkingOn);
                            }
                            else  if (~llListFindList(RecaptureList,[avatarWorkingOn])) {
                                addToVictimsList(avatarWorkingOn,llList2Integer(RecaptureList,llListFindList(RecaptureList,[avatarWorkingOn]) + 1));
                                changeCurrentVictim(avatarWorkingOn);
                            }
                            else  if (~llListFindList(FreeVictimsList,[avatarWorkingOn])) {
                            }
                            else  {
                                addToVictimsList(avatarWorkingOn,RLV_trapTimer);
                                changeCurrentVictim(avatarWorkingOn);
                            }
                        }
                    }
                    else  {
                        if (~llListFindList(VictimsList,[avatarWorkingOn]) || ~llListFindList(RecaptureList,[avatarWorkingOn])) {
                            sendToRlvRelay(avatarWorkingOn,RLV_COMMAND_RELEASE,"");
                        }
                        removeFromVictimsList(avatarWorkingOn);
                        integer _index57;
                        while (~(_index57 = llListFindList(FreeVictimsList,[avatarWorkingOn]))) {
                            {
                                FreeVictimsList = llDeleteSubList(FreeVictimsList,_index57,_index57 + 1 - 1);
                            }
                        }
                    }
                }
                else  {
                    if (isRlvEnabledSeat) {
                        FreeRlvEnabledSeats++;
                    }
                    else  {
                        FreeNonRlvEnabledSeats++;
                    }
                }
                integer _index59;
                while (~(_index59 = llListFindList(GrabList,[avatarWorkingOn]))) {
                    {
                        GrabList = llDeleteSubList(GrabList,_index59,_index59 + 2 - 1);
                    }
                }
                integer _index61;
                while (~(_index61 = llListFindList(RecaptureList,[avatarWorkingOn]))) {
                    {
                        RecaptureList = llDeleteSubList(RecaptureList,_index61,_index61 + 3 - 1);
                    }
                }
            }
            length = llGetListLength(FreeVictimsList);
            index = 0;
            for (; index < length; index += 1) {
                key avatarWorkingOn = llList2Key(FreeVictimsList,index);
                if (!~llListFindList(slotsList,[(string)avatarWorkingOn])) {
                    integer _index64;
                    while (~(_index64 = llListFindList(FreeVictimsList,[avatarWorkingOn]))) {
                        {
                            FreeVictimsList = llDeleteSubList(FreeVictimsList,_index64,_index64 + 1 - 1);
                        }
                    }
                }
            }
            length = llGetListLength(VictimsList);
            index = 0;
            for (; index < length; index += 3) {
                key avatarWorkingOn = llList2Key(VictimsList,index);
                if (!~llListFindList(slotsList,[(string)avatarWorkingOn])) {
                    integer relayVersion;
                    integer _index68 = llListFindList(VictimsList,[avatarWorkingOn]);
                    if (~_index68) {
                        relayVersion = llList2Integer(VictimsList,_index68 + 2);
                    }
                    if (relayVersion) {
                        integer timerTime = llList2Integer(VictimsList,index + 1) - llGetUnixTime();
                        if (timerTime < 0) {
                            timerTime = 0;
                        }
                        recaptureListRemoveTimedOutEntrys();
                        integer _index70;
                        while (~(_index70 = llListFindList(RecaptureList,[avatarWorkingOn]))) {
                            {
                                {
                                    RecaptureList = llDeleteSubList(RecaptureList,_index70,_index70 + 3 - 1);
                                }
                            }
                        }
                        RecaptureList += [avatarWorkingOn,timerTime,0];
                        while (llGetListLength(RecaptureList) > 15) {
                            {
                                RecaptureList = llList2List(RecaptureList,3,-1);
                            }
                        }
                    }
                    removeFromVictimsList(avatarWorkingOn);
                    index -= 3;
                    length -= 3;
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
                if (optionItem == "rlv_capturerange") {
                    RLV_captureRange = (integer)optionSetting;
                }
                else  if (optionItem == "rlv_traptimer") {
                    RLV_trapTimer = (integer)optionSetting;
                }
                else  if (optionItem == "rlv_grabtimer") {
                    RLV_grabTimer = (integer)optionSetting;
                }
                else  if (optionItem == "rlv_enabledseats") {
                    RLV_enabledSeats = llParseString2List(optionSetting,["/"],[]);
                }
            }
        }
        else  if (num == 34334) {
            llSay(0,"Memory Used by " + llGetScriptName() + ": " + (string)llGetUsedMemory() + " of " + (string)llGetMemoryLimit() + ", Leaving " + (string)llGetFreeMemory() + " memory free.");
        }
        else  if (num == -8008) {
            debug(["VictimsList"] + VictimsList);
            debug(["FreeVictimsList"] + FreeVictimsList);
            debug(["GrabList"] + GrabList);
            debug(["RecaptureList"] + RecaptureList);
        }
    }


	changed(integer change) {
        if (change & 128) {
            llResetScript();
        }
        else  if (change & 1) {
            RlvRestrictionsMenuAvailable = 0;
            llMessageLinked(-1,-8048,PLUGIN_NAME_RLV_RESTRICTIONS_MENU,"");
        }
    }


	dataserver(key id,string data) {
        if (id == NcQueryId) {
            RlvBaseRestrictions = llDumpList2String(llParseStringKeepNulls(data,["/"],[]),"|");
        }
    }


	listen(integer channel,string name,key id,string message) {
        if (channel == -1812221819) {
            list messageParts = llParseStringKeepNulls(message,[","],[]);
            if ((key)llList2String(messageParts,1) == llGetKey()) {
                string cmd_name = llList2String(messageParts,0);
                string command = llList2String(messageParts,2);
                string reply = llList2String(messageParts,3);
                key senderAvatarId = llGetOwnerKey(id);
                if (command == RLV_COMMAND_VERSION) {
                    integer _index1 = llListFindList(VictimsList,[senderAvatarId]);
                    if (~_index1) {
                        VictimsList = llListReplaceList(VictimsList,[(integer)reply],_index1 + 2,_index1 + 2);
                    }
                }
                else  if (command == RLV_COMMAND_RELEASE) {
                    if (reply == "ok") {
                        if (~llListFindList(VictimsList,[senderAvatarId])) {
                            if (!~llListFindList(FreeVictimsList,[senderAvatarId])) {
                                FreeVictimsList += senderAvatarId;
                            }
                        }
                        removeFromVictimsList(senderAvatarId);
                        integer _index6;
                        while (~(_index6 = llListFindList(GrabList,[senderAvatarId]))) {
                            {
                                GrabList = llDeleteSubList(GrabList,_index6,_index6 + 2 - 1);
                            }
                        }
                        integer _index8;
                        while (~(_index8 = llListFindList(RecaptureList,[senderAvatarId]))) {
                            {
                                RecaptureList = llDeleteSubList(RecaptureList,_index8,_index8 + 3 - 1);
                            }
                        }
                    }
                }
                else  if (command == RLV_COMMAND_PING) {
                    if (cmd_name == command && reply == command) {
                        recaptureListRemoveTimedOutEntrys();
                        integer index = llListFindList(RecaptureList,[senderAvatarId]);
                        if (~index) {
                            if (FreeRlvEnabledSeats) {
                                RecaptureList = llListReplaceList(RecaptureList,[llGetUnixTime() + 60],index,index + 3 - 1);
                                llSay(-1812221819,RLV_COMMAND_PING + "," + (string)senderAvatarId + "," + RLV_COMMAND_PONG);
                            }
                            else  {
                                integer _index12;
                                while (~(_index12 = llListFindList(RecaptureList,[senderAvatarId]))) {
                                    {
                                        RecaptureList = llDeleteSubList(RecaptureList,_index12,_index12 + 3 - 1);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }


	timer() {
        integer currentTime = llGetUnixTime();
        integer length = llGetListLength(VictimsList);
        integer index;
        for (; index < length; index += 3) {
            integer time = llList2Integer(VictimsList,index + 1);
            if (time && time <= currentTime) {
                key avatarWorkingOn = llList2Key(VictimsList,index);
                sendToRlvRelay(avatarWorkingOn,RLV_COMMAND_RELEASE,"");
                removeFromVictimsList(avatarWorkingOn);
                if (!~llListFindList(FreeVictimsList,[avatarWorkingOn])) {
                    FreeVictimsList += avatarWorkingOn;
                }
            }
        }
    }


	sensor(integer num) {
        SensorList = [];
        integer n;
        for (n = 0; n < num; ++n) {
            SensorList += [llGetSubString(llDetectedName(n),0,15),llDetectedKey(n)];
        }
        showMenu(NPosetoucherID,PROMPT_CAPTURE,llList2ListStrided(SensorList,0,-1,2),MENU_RLV_MAIN + PATH_SEPARATOR + MENU_RLV_CAPTURE);
    }


	no_sensor() {
        SensorList = [];
        showMenu(NPosetoucherID,PROMPT_CAPTURE,[],MENU_RLV_MAIN + PATH_SEPARATOR + MENU_RLV_CAPTURE);
    }
}
