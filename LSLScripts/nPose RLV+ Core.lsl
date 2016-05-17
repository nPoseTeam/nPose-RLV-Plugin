// LSL script generated: LSLScripts.nPose RLV+ Core.lslp Tue May 17 16:31:04 Mitteleuropäische Sommerzeit 2016

string NC_READER_CONTENT_SEPARATOR = "%&§";
string RLV_RELAY_API_COMMAND_RELEASE = "!release";
string RLV_RELAY_API_COMMAND_VERSION = "!version";
string RLV_RELAY_API_COMMAND_PING = "ping";
string RLV_RELAY_API_COMMAND_PONG = "!pong";
string USER_PERMISSION_TYPE_LIST = "list";
string USER_PERMISSION_VICTIM = "victim";

// options
integer RLV_trapTimer;
integer RLV_grabTimer;
integer RLV_collisionTrap;
list RLV_enabledSeats = ["*"];
integer RLV_cooldownTimer = 60;

//other
key MyUniqueId;

key VictimKey = NULL_KEY;

//lists
//a sitting avatar is either in the VictimsList or in the FreeVictimsList or in the DomList

list VictimsList;

list FreeVictimsList;

list DomList;

list GrabList;

list RecaptureList;

list TrapIgnoreList;

integer FreeRlvEnabledSeats;
integer FreeNonRlvEnabledSeats;

list SlotList;

// for RLV base restrictions and reading them from a notecard
string RlvBaseRestrictions = "@unsit=n|@sittp=n|@tploc=n|@tplure=n|@tplm=n|@acceptpermission=add|@editobj:%MYKEY%=add";

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
    for (; (index < length); (index += 2)) {
        integer timeout = llList2Integer(TrapIgnoreList,(index + 1));
        if ((timeout && (timeout < currentTime))) {
            (TrapIgnoreList = llDeleteSubList(TrapIgnoreList,index,((index + 2) - 1)));
            (index -= 2);
            (length -= 2);
        }
    }
}

removeFromTrapIgnoreList(key avatarUuid){
    integer index = getTrapIgnoreIndex(avatarUuid);
    if ((~index)) {
        (TrapIgnoreList = llDeleteSubList(TrapIgnoreList,index,((index + 2) - 1)));
    }
}

addToTrapIgnoreList(key avatarUuid){
    removeFromAllLists(avatarUuid);
    if (RLV_cooldownTimer) {
        (TrapIgnoreList += [avatarUuid,(llGetUnixTime() + RLV_cooldownTimer)]);
    }
}


// NO pragma inline
debug(list message){
    llOwnerSay((((llGetScriptName() + "\n##########\n#>") + llDumpList2String(message,"\n#>")) + "\n##########"));
}

// NO pragma inline
addToVictimsList(key avatarUuid,integer timerTime){
    removeFromAllLists(avatarUuid);
    if ((timerTime > 0)) {
        (timerTime += llGetUnixTime());
    }
    else  if ((timerTime < 0)) {
        (timerTime = 0);
    }
    (VictimsList += [avatarUuid,timerTime,0]);
    llMessageLinked(-1,-8013,llList2CSV(VictimsList),"");
    llMessageLinked(-1,-806,llList2CSV([USER_PERMISSION_VICTIM,USER_PERMISSION_TYPE_LIST,llDumpList2String(llList2ListStrided(VictimsList,0,-1,3),"|")]),"");
    sendToRlvRelay(avatarUuid,((RLV_RELAY_API_COMMAND_VERSION + "|") + RlvBaseRestrictions),"");
    if ((!TimerRunning)) {
        llSetTimerEvent(1.0);
        (TimerRunning = 1);
    }
}

// NO pragma inline
removeFromVictimsList(key avatarUuid){
    integer isChanged;
    integer index;
    while ((~(index = llListFindList(VictimsList,[avatarUuid])))) {
        (VictimsList = llDeleteSubList(VictimsList,index,((index + 3) - 1)));
        (isChanged = 1);
    }
    if (isChanged) {
        llMessageLinked(-1,-8013,llList2CSV(VictimsList),"");
        llMessageLinked(-1,-806,llList2CSV([USER_PERMISSION_VICTIM,USER_PERMISSION_TYPE_LIST,llDumpList2String(llList2ListStrided(VictimsList,0,-1,3),"|")]),"");
        if ((VictimKey == avatarUuid)) {
            changeCurrentVictim(NULL_KEY);
        }
        if (((!llGetListLength(VictimsList)) && TimerRunning)) {
            llSetTimerEvent(0.0);
            (TimerRunning = 0);
        }
    }
}

// NO pragma inline
changeCurrentVictim(key newVictimKey){
    if ((newVictimKey != VictimKey)) {
        if (((newVictimKey == NULL_KEY) || (~llListFindList(VictimsList,[newVictimKey])))) {
            (VictimKey = newVictimKey);
            llMessageLinked(-1,-8012,((string)VictimKey),"");
        }
    }
}

// NO pragma inline
removeFromDomList(key avatarUuid){
    integer index;
    while ((~(index = llListFindList(DomList,[avatarUuid])))) {
        (DomList = llDeleteSubList(DomList,index,((index + 1) - 1)));
    }
}

// NO pragma inline
addToFreeVictimsList(key avatarUuid){
    removeFromAllLists(avatarUuid);
    (FreeVictimsList += avatarUuid);
}

// NO pragma inline
removeFromFreeVictimsList(key avatarUuid){
    integer index;
    while ((~(index = llListFindList(FreeVictimsList,[avatarUuid])))) {
        (FreeVictimsList = llDeleteSubList(FreeVictimsList,index,((index + 1) - 1)));
    }
}

// NO pragma inline
recaptureListRemoveTimedOutEntrys(){
    integer currentTime = llGetUnixTime();
    integer length = llGetListLength(RecaptureList);
    integer index;
    for (; (index < length); (index += 3)) {
        integer timeout = llList2Integer(RecaptureList,(index + 2));
        if ((timeout && (timeout < currentTime))) {
            (RecaptureList = llDeleteSubList(RecaptureList,index,((index + 3) - 1)));
            (index -= 3);
            (length -= 3);
        }
    }
}

// NO pragma inline
removeFromAllLists(key avatarUuid){
    removeFromVictimsList(avatarUuid);
    removeFromFreeVictimsList(avatarUuid);
    removeFromDomList(avatarUuid);
    integer index;
    while ((~(index = llListFindList(GrabList,[avatarUuid])))) {
        {
            (GrabList = llDeleteSubList(GrabList,index,((index + 2) - 1)));
        }
    }
    integer _index2;
    while ((~(_index2 = llListFindList(RecaptureList,[avatarUuid])))) {
        {
            (RecaptureList = llDeleteSubList(RecaptureList,_index2,((_index2 + 3) - 1)));
        }
    }
    removeFromTrapIgnoreList(avatarUuid);
}

// send rlv commands to the RLV relay, usable for common format (not ping)
// NO pragma inline
sendToRlvRelay(key victim,string rlvCommand,string identifier){
    if (rlvCommand) {
        if (victim) {
            string valueIfFalse = ((string)MyUniqueId);
            string ret = valueIfFalse;
            if (llStringLength(identifier)) {
                (ret = identifier);
            }
            string replace = ((string)llGetKey());
            llSay(-1812221819,((((ret + ",") + ((string)victim)) + ",") + llDumpList2String(llParseStringKeepNulls(rlvCommand,["%MYKEY%"],[]),replace)));
        }
    }
}


setVictimTimer(key avatarUuid,integer time){
    integer index = llListFindList(VictimsList,[avatarUuid]);
    if ((~index)) {
        (VictimsList = llListReplaceList(VictimsList,[time],(index + 1),(index + 1)));
        llMessageLinked(-1,-8013,llList2CSV(VictimsList),"");
    }
}

grabAvatar(key targetKey){
    if ((~llListFindList(VictimsList,[targetKey]))) {
        sendToRlvRelay(targetKey,RlvBaseRestrictions,"");
        changeCurrentVictim(targetKey);
    }
    else  if ((~llListFindList(FreeVictimsList,[targetKey]))) {
        addToVictimsList(targetKey,RLV_grabTimer);
        changeCurrentVictim(targetKey);
    }
    else  if ((~llListFindList(DomList,[targetKey]))) {
    }
    else  {
        removeFromAllLists(targetKey);
        (GrabList += [targetKey,(llGetUnixTime() + 60)]);
        while ((llGetListLength(GrabList) > 6)) {
            {
                (GrabList = llList2List(GrabList,2,-1));
            }
        }
        sendToRlvRelay(targetKey,(("@sit:" + ((string)llGetKey())) + "=force"),"");
    }
}

integer trapAvatar(key targetKey){
    trapIgnoreListRemoveTimedOutValues();
    if (llGetAgentSize(targetKey)) {
        if (FreeRlvEnabledSeats) {
            if (((((((!(~llListFindList(VictimsList,[targetKey]))) && (!(~llListFindList(FreeVictimsList,[targetKey])))) && (!(~llListFindList(DomList,[targetKey])))) && (!(~llListFindList(GrabList,[targetKey])))) && (!(~llListFindList(RecaptureList,[targetKey])))) && (!(~getTrapIgnoreIndex(targetKey))))) {
                sendToRlvRelay(targetKey,(("@sit:" + ((string)llGetKey())) + "=force"),"");
                addToTrapIgnoreList(targetKey);
                return 1;
            }
        }
    }
    return 0;
}


default {

	state_entry() {
        llListen(-1812221819,"",NULL_KEY,"");
        (MyUniqueId = llGenerateKey());
    }


	link_message(integer sender,integer num,string str,key id) {
        if ((num == -8012)) {
            changeCurrentVictim(((key)str));
        }
        else  if ((num == -8010)) {
            list temp = llParseStringKeepNulls(str,[","],[]);
            string cmd = llToLower(llStringTrim(llList2String(temp,0),3));
            string replace = ((string)VictimKey);
            key target = ((key)llDumpList2String(llParseStringKeepNulls(llStringTrim(llList2String(temp,1),3),["%VICTIM%"],[]),replace));
            list params = llDeleteSubList(temp,0,1);
            if (target) {
            }
            else  {
                (target = VictimKey);
            }
            if ((cmd == "rlvcommand")) {
                sendToRlvRelay(target,llDumpList2String(llParseStringKeepNulls(llList2String(params,0),["/"],[]),"|"),"");
            }
            else  if ((cmd == "release")) {
                if ((~llListFindList(VictimsList,[target]))) {
                    addToFreeVictimsList(target);
                }
                sendToRlvRelay(target,RLV_RELAY_API_COMMAND_RELEASE,"");
            }
            else  if ((cmd == "unsit")) {
                if ((~llListFindList(VictimsList,[target]))) {
                    addToFreeVictimsList(target);
                }
                sendToRlvRelay(target,RLV_RELAY_API_COMMAND_RELEASE,"");
                llSleep(1.5);
                llUnSit(target);
            }
            else  if ((cmd == "settimer")) {
                setVictimTimer(target,((integer)llList2String(params,0)));
            }
            else  if ((cmd == "grab")) {
                grabAvatar(target);
            }
            else  if ((cmd == "trap")) {
                trapAvatar(target);
            }
            else  if ((cmd == "read")) {
                llMessageLinked(-1,224,llList2String(params,0),MyUniqueId);
            }
        }
        else  if ((num == 225)) {
            if ((id == MyUniqueId)) {
                (str = llDumpList2String(llList2List(llParseStringKeepNulls(str,[NC_READER_CONTENT_SEPARATOR],[]),3,-1),""));
                (RlvBaseRestrictions = llDumpList2String(llParseStringKeepNulls(str,["/"],[]),"|"));
            }
        }
        else  if ((num == 35353)) {
            recaptureListRemoveTimedOutEntrys();
            integer currentTime = llGetUnixTime();
            integer _length9 = llGetListLength(GrabList);
            integer _index10;
            for (; (_index10 < _length9); (_index10 += 2)) {
                integer timeout = llList2Integer(GrabList,(_index10 + 1));
                if ((timeout < currentTime)) {
                    (GrabList = llDeleteSubList(GrabList,_index10,((_index10 + 2) - 1)));
                    (_index10 -= 2);
                    (_length9 -= 2);
                }
            }
            trapIgnoreListRemoveTimedOutValues();
            (FreeNonRlvEnabledSeats = 0);
            (FreeRlvEnabledSeats = 0);
            (SlotList = llParseStringKeepNulls(str,["^"],[]));
            integer length = llGetListLength(SlotList);
            integer index;
            for (; (index < length); (index += 8)) {
                key avatarWorkingOn = ((key)llList2String(SlotList,(index + 4)));
                removeFromTrapIgnoreList(avatarWorkingOn);
                integer seatNumber = ((index / 8) + 1);
                integer isRlvEnabledSeat = ((~llListFindList(RLV_enabledSeats,["*"])) || (~llListFindList(RLV_enabledSeats,[((string)seatNumber)])));
                if (avatarWorkingOn) {
                    if (isRlvEnabledSeat) {
                        if ((!(~llListFindList(VictimsList,[avatarWorkingOn])))) {
                            if ((~llListFindList(GrabList,[avatarWorkingOn]))) {
                                addToVictimsList(avatarWorkingOn,RLV_grabTimer);
                                changeCurrentVictim(avatarWorkingOn);
                            }
                            else  if ((~llListFindList(RecaptureList,[avatarWorkingOn]))) {
                                addToVictimsList(avatarWorkingOn,llList2Integer(RecaptureList,(llListFindList(RecaptureList,[avatarWorkingOn]) + 1)));
                                changeCurrentVictim(avatarWorkingOn);
                            }
                            else  if ((~llListFindList(FreeVictimsList,[avatarWorkingOn]))) {
                            }
                            else  if ((~llListFindList(DomList,[avatarWorkingOn]))) {
                                addToFreeVictimsList(avatarWorkingOn);
                            }
                            else  {
                                addToVictimsList(avatarWorkingOn,RLV_trapTimer);
                                changeCurrentVictim(avatarWorkingOn);
                            }
                        }
                    }
                    else  {
                        if (((~llListFindList(VictimsList,[avatarWorkingOn])) || (~llListFindList(RecaptureList,[avatarWorkingOn])))) {
                            sendToRlvRelay(avatarWorkingOn,RLV_RELAY_API_COMMAND_RELEASE,"");
                        }
                        removeFromAllLists(avatarWorkingOn);
                        (DomList += [avatarWorkingOn]);
                    }
                }
                else  {
                    if (isRlvEnabledSeat) {
                        (FreeRlvEnabledSeats++);
                    }
                    else  {
                        (FreeNonRlvEnabledSeats++);
                    }
                }
            }
            list tempList;
            (tempList = FreeVictimsList);
            (length = llGetListLength(tempList));
            (index = 0);
            for (; (index < length); (index += 1)) {
                key avatarWorkingOn = llList2Key(tempList,index);
                if ((!(~llListFindList(SlotList,[((string)avatarWorkingOn)])))) {
                    addToTrapIgnoreList(avatarWorkingOn);
                }
            }
            (tempList = DomList);
            (length = llGetListLength(tempList));
            (index = 0);
            for (; (index < length); (index += 1)) {
                key avatarWorkingOn = llList2Key(tempList,index);
                if ((!(~llListFindList(SlotList,[((string)avatarWorkingOn)])))) {
                    addToTrapIgnoreList(avatarWorkingOn);
                }
            }
            (tempList = VictimsList);
            (length = llGetListLength(tempList));
            (index = 0);
            for (; (index < length); (index += 3)) {
                key avatarWorkingOn = llList2Key(tempList,index);
                if ((!(~llListFindList(SlotList,[((string)avatarWorkingOn)])))) {
                    integer relayVersion;
                    integer _index34 = llListFindList(VictimsList,[avatarWorkingOn]);
                    if ((~_index34)) {
                        (relayVersion = llList2Integer(VictimsList,(_index34 + 2)));
                    }
                    if (relayVersion) {
                        integer timerTime = (llList2Integer(tempList,(index + 1)) - llGetUnixTime());
                        removeFromAllLists(avatarWorkingOn);
                        recaptureListRemoveTimedOutEntrys();
                        if ((timerTime < 0)) {
                            (timerTime = 0);
                        }
                        (RecaptureList += [avatarWorkingOn,timerTime,0]);
                        while ((llGetListLength(RecaptureList) > 15)) {
                            {
                                (RecaptureList = llList2List(RecaptureList,3,-1));
                            }
                        }
                    }
                    else  {
                        addToTrapIgnoreList(avatarWorkingOn);
                    }
                }
            }
        }
        else  if ((num == -240)) {
            list optionsToSet = llParseStringKeepNulls(str,["~"],[]);
            integer length = llGetListLength(optionsToSet);
            integer index;
            for (; (index < length); (index++)) {
                list optionsItems = llParseString2List(llList2String(optionsToSet,index),["="],[]);
                string optionItem = llToLower(llStringTrim(llList2String(optionsItems,0),3));
                string optionSetting = llStringTrim(llList2String(optionsItems,1),3);
                if ((optionItem == "rlv_grabtimer")) {
                    (RLV_grabTimer = ((integer)optionSetting));
                }
                else  if ((optionItem == "rlv_traptimer")) {
                    (RLV_trapTimer = ((integer)optionSetting));
                }
                else  if ((optionItem == "rlv_traprange")) {
                    if (((float)optionSetting)) {
                        llSensorRepeat("",NULL_KEY,1,((float)optionSetting),3.14159265,3);
                    }
                    else  {
                        llSensorRemove();
                    }
                }
                else  if ((optionItem == "rlv_enabledseats")) {
                    (RLV_enabledSeats = llParseString2List(optionSetting,["/"],[]));
                }
                else  if ((optionItem == "rlv_collisiontrap")) {
                    (RLV_collisionTrap = ((integer)optionSetting));
                }
                else  if ((optionItem == "rlv_cooldowntimer")) {
                    (RLV_cooldownTimer = ((integer)optionSetting));
                }
            }
        }
        else  if ((num == 34334)) {
            llSay(0,(((((((("Memory Used by " + llGetScriptName()) + ": ") + ((string)llGetUsedMemory())) + " of ") + ((string)llGetMemoryLimit())) + ", Leaving ") + ((string)llGetFreeMemory())) + " memory free."));
        }
        else  if ((num == -8018)) {
            if ((str == "l")) {
                debug((((((((((((["VictimsList"] + VictimsList) + ["####","FreeVictimsList"]) + FreeVictimsList) + ["####","DomList"]) + DomList) + ["####","GrabList"]) + GrabList) + ["####","RecaptureList"]) + RecaptureList) + ["####","TrapIgnoreList"]) + TrapIgnoreList));
            }
            else  if ((str == "o")) {
                debug((["RLV_trapTimer",RLV_trapTimer,"####","RLV_grabTimer",RLV_grabTimer,"####","RLV_collisionTrap",RLV_collisionTrap,"####","RLV_enabledSeats"] + RLV_enabledSeats));
            }
        }
    }


	changed(integer change) {
        if ((change & 128)) {
            llResetScript();
        }
    }


	listen(integer channel,string name,key id,string message) {
        if ((channel == -1812221819)) {
            list messageParts = llParseStringKeepNulls(message,[","],[]);
            if ((((key)llList2String(messageParts,1)) == llGetKey())) {
                string cmd_name = llList2String(messageParts,0);
                string command = llList2String(messageParts,2);
                string reply = llList2String(messageParts,3);
                key senderAvatarId = llGetOwnerKey(id);
                if ((command == RLV_RELAY_API_COMMAND_VERSION)) {
                    integer _index1 = llListFindList(VictimsList,[senderAvatarId]);
                    if ((~_index1)) {
                        (VictimsList = llListReplaceList(VictimsList,[((integer)reply)],(_index1 + 2),(_index1 + 2)));
                        llMessageLinked(-1,-8013,llList2CSV(VictimsList),"");
                    }
                }
                else  if ((command == RLV_RELAY_API_COMMAND_RELEASE)) {
                    if ((reply == "ok")) {
                        if ((~llListFindList(VictimsList,[senderAvatarId]))) {
                            addToFreeVictimsList(senderAvatarId);
                        }
                        integer _index5;
                        while ((~(_index5 = llListFindList(GrabList,[senderAvatarId])))) {
                            {
                                (GrabList = llDeleteSubList(GrabList,_index5,((_index5 + 2) - 1)));
                            }
                        }
                        integer _index7;
                        while ((~(_index7 = llListFindList(RecaptureList,[senderAvatarId])))) {
                            {
                                (RecaptureList = llDeleteSubList(RecaptureList,_index7,((_index7 + 3) - 1)));
                            }
                        }
                    }
                }
                else  if ((command == RLV_RELAY_API_COMMAND_PING)) {
                    if (((cmd_name == command) && (reply == command))) {
                        recaptureListRemoveTimedOutEntrys();
                        integer index = llListFindList(RecaptureList,[senderAvatarId]);
                        if ((~index)) {
                            if (FreeRlvEnabledSeats) {
                                (RecaptureList = llListReplaceList(RecaptureList,[(llGetUnixTime() + 60)],(index + 2),(index + 2)));
                                llSay(-1812221819,((((RLV_RELAY_API_COMMAND_PING + ",") + ((string)senderAvatarId)) + ",") + RLV_RELAY_API_COMMAND_PONG));
                            }
                            else  {
                                integer _index11;
                                while ((~(_index11 = llListFindList(RecaptureList,[senderAvatarId])))) {
                                    {
                                        (RecaptureList = llDeleteSubList(RecaptureList,_index11,((_index11 + 3) - 1)));
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

	
	collision_start(integer num_detected) {
        key avatarWorkingOn = llDetectedKey(0);
        if (RLV_collisionTrap) {
            trapAvatar(llDetectedKey(0));
        }
    }

	
	sensor(integer num_detected) {
        integer index;
        for (; (index < num_detected); (index++)) {
            if (trapAvatar(llDetectedKey(index))) {
                return;
            }
        }
    }


	timer() {
        integer currentTime = llGetUnixTime();
        list tempList = VictimsList;
        integer length = llGetListLength(tempList);
        integer index;
        for (; (index < length); (index += 3)) {
            integer time = llList2Integer(tempList,(index + 1));
            if ((time && (time <= currentTime))) {
                key targetKey = llList2Key(tempList,index);
                if ((~llListFindList(VictimsList,[targetKey]))) {
                    addToFreeVictimsList(targetKey);
                }
                sendToRlvRelay(targetKey,RLV_RELAY_API_COMMAND_RELEASE,"");
            }
        }
    }
}
