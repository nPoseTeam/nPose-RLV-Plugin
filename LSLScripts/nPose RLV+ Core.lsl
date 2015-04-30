// LSL script generated - patched Render.hs (0.1.6.2): LSLScripts.nPose RLV+ Core.lslp Sun Apr 26 15:10:11 Mitteleuropäische Sommerzeit 2015

string RLV_RELAY_API_COMMAND_RELEASE = "!release";
string RLV_RELAY_API_COMMAND_VERSION = "!version";
string RLV_RELAY_API_COMMAND_PING = "ping";
string RLV_RELAY_API_COMMAND_PONG = "!pong";

// options
integer RLV_trapTimer;
integer RLV_grabTimer;
list RLV_enabledSeats = ["*"];

key MyUniqueId;

key VictimKey = NULL_KEY;
//integer currentVictimIndex=-1; //contains the VictimsList-index of the current victim

//a sitting avatar is either in the VvictimsList or in the FreeVictimsList or in the DomList

list VictimsList;

list FreeVictimsList;

list DomList;

list GrabList;

list RecaptureList;

list TrapIgnoreList;

integer FreeRlvEnabledSeats;
integer FreeNonRlvEnabledSeats;


// for RLV base restrictions and reading them from a notecard
string RlvBaseRestrictions = "@unsit=n|@sittp=n|@tploc=n|@tplure=n|@tplm=n|@acceptpermission=add|@editobj:%MYKEY%=add";
key NcQueryId;

//added for timer
integer TimerRunning;

// --- functions
integer getTrapIgnoreIndex(key avatarUuid){
    return llListFindList(TrapIgnoreList,[avatarUuid]);
}

trapIgnoreListRemoveTimedOutValues(){
    integer currentTime = llGetUnixTime();
    integer length = llGetListLength(TrapIgnoreList);
    integer index;
    for (; index < length; index += 2) {
        integer timeout = llList2Integer(TrapIgnoreList,index + 1);
        if (timeout && timeout < currentTime) {
            TrapIgnoreList = llDeleteSubList(TrapIgnoreList,index,index + 2 - 1);
            index -= 2;
            length -= 2;
        }
    }
}

removeFromTrapIgnoreList(key avatarUuid){
    integer index = getTrapIgnoreIndex(avatarUuid);
    if (~index) {
        TrapIgnoreList = llDeleteSubList(TrapIgnoreList,index,index + 2 - 1);
    }
}

addToTrapIgnoreList(key avatarUuid){
    TrapIgnoreList += [avatarUuid,llGetUnixTime() + 60];
}


// NO pragma inline
debug(list message){
    llOwnerSay(llGetScriptName() + "\n##########\n#>" + llDumpList2String(message,"\n#>") + "\n##########");
}

// NO pragma inline
addToVictimsList(key avatarUuid,integer timerTime){
    removeFromVictimsList(avatarUuid);
    removeFromFreeVictimsList(avatarUuid);
    removeFromDomList(avatarUuid);
    if (timerTime > 0) {
        timerTime += llGetUnixTime();
    }
    else  if (timerTime < 0) {
        timerTime = 0;
    }
    VictimsList += [avatarUuid,timerTime,0];
    llMessageLinked(-1,-238,llList2CSV(VictimsList),"");
    sendToRlvRelay(avatarUuid,RLV_RELAY_API_COMMAND_VERSION + "|" + RlvBaseRestrictions,"");
    if (!TimerRunning) {
        llSetTimerEvent(1.0);
        TimerRunning = 1;
    }
}

// NO pragma inline
removeFromVictimsList(key avatarUuid){
    integer isChanged;
    integer index;
    while (~(index = llListFindList(VictimsList,[avatarUuid]))) {
        VictimsList = llDeleteSubList(VictimsList,index,index + 3 - 1);
        isChanged = 1;
    }
    if (isChanged) {
        llMessageLinked(-1,-238,llList2CSV(VictimsList),"");
        if (VictimKey == avatarUuid) {
            changeCurrentVictim(NULL_KEY);
        }
        if (!llGetListLength(VictimsList) && TimerRunning) {
            llSetTimerEvent(0.0);
            TimerRunning = 0;
        }
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
removeFromDomList(key avatarUuid){
    integer index;
    while (~(index = llListFindList(DomList,[avatarUuid]))) {
        DomList = llDeleteSubList(DomList,index,index + 1 - 1);
    }
}

// NO pragma inline
addToFreeVictimsList(key avatarUuid){
    removeFromVictimsList(avatarUuid);
    removeFromFreeVictimsList(avatarUuid);
    removeFromDomList(avatarUuid);
    FreeVictimsList += avatarUuid;
}

// NO pragma inline
removeFromFreeVictimsList(key avatarUuid){
    integer index;
    while (~(index = llListFindList(FreeVictimsList,[avatarUuid]))) {
        FreeVictimsList = llDeleteSubList(FreeVictimsList,index,index + 1 - 1);
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


setVictimTimer(key avatarUuid,integer time){
    integer index = llListFindList(VictimsList,[avatarUuid]);
    if (~index) {
        VictimsList = llListReplaceList(VictimsList,[time],index + 1,index + 1);
        llMessageLinked(-1,-238,llList2CSV(VictimsList),"");
    }
}

grabAvatar(key targetKey){
    if (~llListFindList(VictimsList,[targetKey])) {
        sendToRlvRelay(targetKey,RlvBaseRestrictions,"");
        changeCurrentVictim(targetKey);
    }
    else  if (~llListFindList(FreeVictimsList,[targetKey])) {
        addToVictimsList(targetKey,RLV_grabTimer);
        changeCurrentVictim(targetKey);
    }
    else  if (~llListFindList(DomList,[targetKey])) {
    }
    else  {
        if (!~llListFindList(GrabList,[targetKey])) {
            GrabList += [targetKey,llGetUnixTime() + 60];
            while (llGetListLength(GrabList) > 6) {
                {
                    GrabList = llList2List(GrabList,2,-1);
                }
            }
        }
        sendToRlvRelay(targetKey,"@sit:" + (string)llGetKey() + "=force","");
    }
}


default {

	state_entry() {
        llListen(-1812221819,"",NULL_KEY,"");
        MyUniqueId = llGenerateKey();
    }


	link_message(integer sender,integer num,string str,key id) {
        if (num == -237) {
            changeCurrentVictim((key)str);
        }
        else  if (num == -8010) {
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
            if (cmd == "rlvcommand") {
                sendToRlvRelay(target,llDumpList2String(llParseStringKeepNulls(llList2String(params,0),["/"],[]),"|"),"");
            }
            else  if (cmd == "release") {
                addToFreeVictimsList(target);
                removeFromVictimsList(target);
                sendToRlvRelay(target,RLV_RELAY_API_COMMAND_RELEASE,"");
            }
            else  if (cmd == "unsit") {
                removeFromVictimsList(target);
                addToFreeVictimsList(target);
                sendToRlvRelay(target,"@unsit=y","");
                llSleep(0.75);
                sendToRlvRelay(target,"@unsit=force","");
                llSleep(0.75);
                sendToRlvRelay(target,RLV_RELAY_API_COMMAND_RELEASE,"");
            }
            else  if (cmd == "settimer") {
                setVictimTimer(target,(integer)llList2String(params,0));
            }
            else  if (cmd == "grab") {
                grabAvatar(target);
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
        }
        else  if (num == 35353) {
            recaptureListRemoveTimedOutEntrys();
            integer currentTime = llGetUnixTime();
            integer _length7 = llGetListLength(GrabList);
            integer _index8;
            for (; _index8 < _length7; _index8 += 2) {
                integer timeout = llList2Integer(GrabList,_index8 + 1);
                if (timeout < currentTime) {
                    GrabList = llDeleteSubList(GrabList,_index8,_index8 + 2 - 1);
                    _index8 -= 2;
                    _length7 -= 2;
                }
            }
            trapIgnoreListRemoveTimedOutValues();
            FreeNonRlvEnabledSeats = 0;
            FreeRlvEnabledSeats = 0;
            list slotsList = llParseStringKeepNulls(str,["^"],[]);
            integer length = llGetListLength(slotsList);
            integer index;
            for (; index < length; index += 8) {
                key avatarWorkingOn = (key)llList2String(slotsList,index + 4);
                removeFromTrapIgnoreList(avatarWorkingOn);
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
                            else  if (~llListFindList(DomList,[avatarWorkingOn])) {
                                addToFreeVictimsList(avatarWorkingOn);
                            }
                            else  {
                                addToVictimsList(avatarWorkingOn,RLV_trapTimer);
                                changeCurrentVictim(avatarWorkingOn);
                            }
                        }
                    }
                    else  {
                        if (~llListFindList(VictimsList,[avatarWorkingOn]) || ~llListFindList(RecaptureList,[avatarWorkingOn])) {
                            sendToRlvRelay(avatarWorkingOn,RLV_RELAY_API_COMMAND_RELEASE,"");
                        }
                        removeFromVictimsList(avatarWorkingOn);
                        removeFromFreeVictimsList(avatarWorkingOn);
                        removeFromDomList(avatarWorkingOn);
                        DomList += [avatarWorkingOn];
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
                integer _index28;
                while (~(_index28 = llListFindList(GrabList,[avatarWorkingOn]))) {
                    {
                        GrabList = llDeleteSubList(GrabList,_index28,_index28 + 2 - 1);
                    }
                }
                integer _index30;
                while (~(_index30 = llListFindList(RecaptureList,[avatarWorkingOn]))) {
                    {
                        RecaptureList = llDeleteSubList(RecaptureList,_index30,_index30 + 3 - 1);
                    }
                }
            }
            length = llGetListLength(FreeVictimsList);
            index = 0;
            for (; index < length; index += 1) {
                key avatarWorkingOn = llList2Key(FreeVictimsList,index);
                if (!~llListFindList(slotsList,[(string)avatarWorkingOn])) {
                    removeFromFreeVictimsList(avatarWorkingOn);
                    addToTrapIgnoreList(avatarWorkingOn);
                }
            }
            length = llGetListLength(DomList);
            index = 0;
            for (; index < length; index += 1) {
                key avatarWorkingOn = llList2Key(DomList,index);
                if (!~llListFindList(slotsList,[(string)avatarWorkingOn])) {
                    removeFromDomList(avatarWorkingOn);
                    addToTrapIgnoreList(avatarWorkingOn);
                }
            }
            length = llGetListLength(VictimsList);
            index = 0;
            for (; index < length; index += 3) {
                key avatarWorkingOn = llList2Key(VictimsList,index);
                if (!~llListFindList(slotsList,[(string)avatarWorkingOn])) {
                    integer relayVersion;
                    integer _index36 = llListFindList(VictimsList,[avatarWorkingOn]);
                    if (~_index36) {
                        relayVersion = llList2Integer(VictimsList,_index36 + 2);
                    }
                    if (relayVersion) {
                        integer timerTime = llList2Integer(VictimsList,index + 1) - llGetUnixTime();
                        if (timerTime < 0) {
                            timerTime = 0;
                        }
                        recaptureListRemoveTimedOutEntrys();
                        integer _index38;
                        while (~(_index38 = llListFindList(RecaptureList,[avatarWorkingOn]))) {
                            {
                                {
                                    RecaptureList = llDeleteSubList(RecaptureList,_index38,_index38 + 3 - 1);
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
                    else  {
                        addToTrapIgnoreList(avatarWorkingOn);
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
            integer index;
            for (; index < length; index++) {
                list optionsItems = llParseString2List(llList2String(optionsToSet,index),["="],[]);
                string optionItem = llToLower(llStringTrim(llList2String(optionsItems,0),3));
                string optionSetting = llStringTrim(llList2String(optionsItems,1),3);
                if (optionItem == "rlv_grabtimer") {
                    RLV_grabTimer = (integer)optionSetting;
                }
                else  if (optionItem == "rlv_traptimer") {
                    RLV_trapTimer = (integer)optionSetting;
                }
                else  if (optionItem == "rlv_traprange") {
                    if ((float)optionSetting) {
                        llSensorRepeat("",NULL_KEY,1,(float)optionSetting,3.14159265,3);
                    }
                    else  {
                        llSensorRemove();
                    }
                }
                else  if (optionItem == "rlv_enabledseats") {
                    RLV_enabledSeats = llParseString2List(optionSetting,["/"],[]);
                }
            }
        }
        else  if (num == 34334) {
            llSay(0,"Memory Used by " + llGetScriptName() + ": " + (string)llGetUsedMemory() + " of " + (string)llGetMemoryLimit() + ", Leaving " + (string)llGetFreeMemory() + " memory free.");
        }
        else  if (num == -8018) {
            if (str == "l") {
                debug(["VictimsList"] + VictimsList + ["####","FreeVictimsList"] + FreeVictimsList + ["####","DomList"] + DomList + ["####","GrabList"] + GrabList + ["####","RecaptureList"] + RecaptureList + ["####","TrapIgnoreList"] + TrapIgnoreList);
            }
            else  if (str == "o") {
                debug(["RLV_trapTimer",RLV_trapTimer,"####","RLV_grabTimer",RLV_grabTimer,"####","RLV_enabledSeats"] + RLV_enabledSeats);
            }
        }
    }


	changed(integer change) {
        if (change & 128) {
            llResetScript();
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
                if (command == RLV_RELAY_API_COMMAND_VERSION) {
                    integer _index1 = llListFindList(VictimsList,[senderAvatarId]);
                    if (~_index1) {
                        VictimsList = llListReplaceList(VictimsList,[(integer)reply],_index1 + 2,_index1 + 2);
                        llMessageLinked(-1,-238,llList2CSV(VictimsList),"");
                    }
                }
                else  if (command == RLV_RELAY_API_COMMAND_RELEASE) {
                    if (reply == "ok") {
                        addToFreeVictimsList(senderAvatarId);
                        integer _index3;
                        while (~(_index3 = llListFindList(GrabList,[senderAvatarId]))) {
                            {
                                GrabList = llDeleteSubList(GrabList,_index3,_index3 + 2 - 1);
                            }
                        }
                        integer _index5;
                        while (~(_index5 = llListFindList(RecaptureList,[senderAvatarId]))) {
                            {
                                RecaptureList = llDeleteSubList(RecaptureList,_index5,_index5 + 3 - 1);
                            }
                        }
                    }
                }
                else  if (command == RLV_RELAY_API_COMMAND_PING) {
                    if (cmd_name == command && reply == command) {
                        recaptureListRemoveTimedOutEntrys();
                        integer index = llListFindList(RecaptureList,[senderAvatarId]);
                        if (~index) {
                            if (FreeRlvEnabledSeats) {
                                RecaptureList = llListReplaceList(RecaptureList,[llGetUnixTime() + 60],index + 2,index + 2);
                                llSay(-1812221819,RLV_RELAY_API_COMMAND_PING + "," + (string)senderAvatarId + "," + RLV_RELAY_API_COMMAND_PONG);
                            }
                            else  {
                                integer _index9;
                                while (~(_index9 = llListFindList(RecaptureList,[senderAvatarId]))) {
                                    {
                                        RecaptureList = llDeleteSubList(RecaptureList,_index9,_index9 + 3 - 1);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

	
	sensor(integer num_detected) {
        if (FreeRlvEnabledSeats) {
            trapIgnoreListRemoveTimedOutValues();
            integer index;
            for (; index < num_detected; index++) {
                key avatarWorkingOn = llDetectedKey(index);
                if (!~llListFindList(VictimsList,[avatarWorkingOn]) && !~llListFindList(FreeVictimsList,[avatarWorkingOn]) && !~llListFindList(DomList,[avatarWorkingOn]) && !~llListFindList(GrabList,[avatarWorkingOn]) && !~llListFindList(RecaptureList,[avatarWorkingOn]) && !~getTrapIgnoreIndex(avatarWorkingOn)) {
                    sendToRlvRelay(avatarWorkingOn,"@sit:" + (string)llGetKey() + "=force","");
                    addToTrapIgnoreList(avatarWorkingOn);
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
                sendToRlvRelay(avatarWorkingOn,RLV_RELAY_API_COMMAND_RELEASE,"");
                addToFreeVictimsList(avatarWorkingOn);
            }
        }
    }
}
