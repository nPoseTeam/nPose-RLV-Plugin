// LSL script generated: LSLScripts.nPose RLV+ Menu.lslp Tue Aug 16 10:25:54 Mitteleuropäische Sommerzeit 2016
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
// https://github.com/LeonaMorro/nPose-RLV-Plugin/wiki
// Report Bugs to:
// https://github.com/LeonaMorro/nPose-RLV-Plugin/issues
// or IM slmember1 Resident (Leona)


string STRING_NEW_LINE = "\n";
string MY_PLUGIN_NAME = "nPose_RLV+";

string STRING_PROMPT_VICTIM_CAPTION = "Selected Victim: ";
string STRING_PROMPT_VICTIM_NONE = "NONE";
string STRING_PROMPT_VICTIM_SELECT = "Select new active victim.";
string STRING_PROMPT_CAPTURE_CAPTION = "Choose someone to capture.";
string STRING_PROMPT_CAPTURE_NO_ONE_CAPTION = "There seems to be no one in range to cpature.";
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

list TIMER_BUTTONS1 = ["/*86400*/+1d","/*21600*/+6h","/*3600*/+1h","/*900*/+15m","/*60*/+1m"];
list TIMER_BUTTONS2 = ["/*-86400*/-1d","/*-21600*/-6h","/*-3600*/-1h","/*-900*/-15m","/*-60*/-1m","/*0*/Reset"];


list VictimsList;

list SensorUsersListUser;
list SensorUsersListMenuParams;

list SelectedVictimListUser;
list SelectedVictimListVictim;

list UsersList;

//Button comments marker
string MARKER_COMMENT_START = "/*";
string MARKER_COMMENT_END = "*/";

float RLV_grabRange = 10.0;
integer OptionUseDisplayNames;
//helper
// NO pragma inline
string joinNodes(list nodes){
    integer index;
    integer length = llGetListLength(nodes);
    list tempNodes;
    for (; (index < length); (index++)) {
        string currentNodeString = llList2String(nodes,index);
        if (currentNodeString) {
            (tempNodes += llParseStringKeepNulls(currentNodeString,[":"],[]));
        }
    }
    return llDumpList2String(tempNodes,":");
}

//helper
//no pragma inline
string buildParamSet1(string path,integer page,string prompt,list additionalButtons,list pluginParams){
    return llDumpList2String(([path,page,llDumpList2String(llParseStringKeepNulls(prompt,[","],[]),"‚"),llDumpList2String(additionalButtons,",")] + llList2List((pluginParams + ["","","",""]),0,3)),"|");
}

//no pragma inline
string getFirstComment(string text){
    integer start = llSubStringIndex(text,MARKER_COMMENT_START);
    if ((~start)) {
        integer end = llSubStringIndex(text,MARKER_COMMENT_END);
        if ((~end)) {
            if ((end > start)) {
                return llGetSubString(text,(start + llStringLength(MARKER_COMMENT_START)),(end - 1));
            }
        }
    }
    return "";
}

//no pragma inline
key getSelectedVictim(key user){
    integer index = llGetListLength(SelectedVictimListVictim);
    for (; index; (index--)) {
        if ((!(~llListFindList(VictimsList,[llList2Key(SelectedVictimListVictim,(index - 1))])))) {
            (SelectedVictimListUser = llDeleteSubList(SelectedVictimListUser,(index - 1),(index - 1)));
            (SelectedVictimListVictim = llDeleteSubList(SelectedVictimListVictim,(index - 1),(index - 1)));
        }
    }
    if (user) {
        (index = llListFindList(SelectedVictimListUser,[user]));
        if ((!(~index))) {
            (index = llListFindList(VictimsList,[((string)user)]));
            if ((~index)) {
                (index = setSelectedVictim(user,user));
            }
            else  if ((llGetListLength(VictimsList) >= 3)) {
                (index = setSelectedVictim(user,((key)llList2String(VictimsList,0))));
            }
            else  {
                return NULL_KEY;
            }
        }
        return llList2Key(SelectedVictimListVictim,index);
    }
    return NULL_KEY;
}

//no pragma inline
integer setSelectedVictim(key user,key victim){
    if (user) {
        if ((~llListFindList(VictimsList,[((string)victim)]))) {
            integer index = llListFindList(SelectedVictimListUser,[user]);
            if ((~index)) {
                (SelectedVictimListUser = llListReplaceList(SelectedVictimListUser,[user],index,index));
                (SelectedVictimListVictim = llListReplaceList(SelectedVictimListVictim,[victim],index,index));
                return index;
            }
            else  {
                (SelectedVictimListUser += user);
                (SelectedVictimListVictim += victim);
                return (llGetListLength(SelectedVictimListUser) - 1);
            }
        }
    }
    return -1;
}

//no pragma inline
string text2MenuText(string text){
    (text = llDumpList2String(llParseStringKeepNulls(text,["`"],[]),"‵"));
    (text = llDumpList2String(llParseStringKeepNulls(text,["|"],[]),"┃"));
    (text = llDumpList2String(llParseStringKeepNulls(text,["/"],[]),"⁄"));
    (text = llDumpList2String(llParseStringKeepNulls(text,[":"],[]),"꞉"));
    (text = llDumpList2String(llParseStringKeepNulls(text,[","],[]),"‚"));
    return text;
}

// NO pragma inline
string getVictimTimerString(key avatarUuid){
    string returnValue = "Timer: ";
    integer time;
    integer index = llListFindList(VictimsList,[((string)avatarUuid)]);
    if ((~index)) {
        (time = (llList2Integer(VictimsList,(index + 1)) - llGetUnixTime()));
        if ((time < 0)) {
            (time = 0);
        }
    }
    integer runningTimeS = time;
    if ((!runningTimeS)) {
        return ((returnValue + STRING_PROMPT_TIMER_ZERO) + STRING_NEW_LINE);
    }
    integer runningTimeM = (runningTimeS / 60);
    (runningTimeS = (runningTimeS % 60));
    integer runningTimeH = (runningTimeM / 60);
    (runningTimeM = (runningTimeM % 60));
    integer runningTimeD = (runningTimeH / 24);
    (runningTimeH = (runningTimeH % 24));
    return ((((((returnValue + conditionalString(runningTimeD,(((string)runningTimeD) + "d "),"")) + llGetSubString(("0" + ((string)runningTimeH)),-2,-1)) + ":") + llGetSubString(("0" + ((string)runningTimeM)),-2,-1)) + ":") + llGetSubString(("0" + ((string)runningTimeS)),-2,-1));
}

// NO pragma inline
string conditionalString(integer conditon,string valueIfTrue,string valueIfFalse){
    string ret = valueIfFalse;
    if (conditon) {
        (ret = valueIfTrue);
    }
    return ret;
}

// NO pragma inline
integer addToUsersList(key menuUser,string menuParams){
    integer index = (llListFindList(UsersList,[menuUser]) - 2);
    if ((~index)) {
        llListenRemove(llList2Integer(UsersList,(index + 1)));
        (UsersList = llDeleteSubList(UsersList,index,((index + 5) - 1)));
    }
    if ((!llGetListLength(UsersList))) {
        llSetTimerEvent(0.0);
    }
    integer channel = ((integer)(llFrand(1.0e9) + 1.0e9));
    (UsersList += [channel,llListen(channel,"",NULL_KEY,""),menuUser,menuParams,(llGetUnixTime() + 4)]);
    llSetTimerEvent(1.0);
    return channel;
}

default {

	link_message(integer sender,integer num,string str,key id) {
        if ((num == -8013)) {
            (VictimsList = llCSV2List(str));
        }
        else  if (((num == -830) || (num == -832))) {
            list params = llParseStringKeepNulls(str,["|"],[]);
            string pluginName = llList2String(params,5);
            if ((pluginName == llToLower(MY_PLUGIN_NAME))) {
                string path = llList2String(params,0);
                integer page = ((integer)llList2String(params,1));
                string prompt = llList2String(params,2);
                string buttons = llList2String(params,3);
                string pluginLocalPath = llList2String(params,4);
                string pluginMenuParams = llList2String(params,6);
                string pluginActionParams = llList2String(params,7);
                key selectedVictim = getSelectedVictim(id);
                if ((num == -830)) {
                    string pluginBasePath = llDumpList2String(llList2List(llParseStringKeepNulls(path,[":"],[]),0,((-llGetListLength(llParseString2List(pluginLocalPath,[":"],[]))) - 1)),":");
                    string pluginLocalPathPart0 = llDumpList2String(llList2List(llParseStringKeepNulls(pluginLocalPath,[":"],[]),0,0),":");
                    string pluginLocalPathPart1 = llDumpList2String(llList2List(llParseStringKeepNulls(pluginLocalPath,[":"],[]),1,1),":");
                    string pluginLocalPathPart2 = llDumpList2String(llList2List(llParseStringKeepNulls(pluginLocalPath,[":"],[]),2,2),":");
                    integer pipeActionThroughCore;
                    if ((pluginLocalPath == "")) {
                    }
                    else  if ((pluginLocalPath == MENU_BUTTON_UNSIT)) {
                        if (((selectedVictim != NULL_KEY) && (!(~llListFindList(VictimsList,[((string)id)]))))) {
                            if (selectedVictim) {
                                llMessageLinked(-1,-8010,("unsit," + ((string)selectedVictim)),NULL_KEY);
                                (pipeActionThroughCore = 1);
                            }
                        }
                        (path = pluginBasePath);
                    }
                    else  if ((pluginLocalPath == MENU_BUTTON_RELEASE)) {
                        if (((selectedVictim != NULL_KEY) && (!(~llListFindList(VictimsList,[((string)id)]))))) {
                            if (selectedVictim) {
                                llMessageLinked(-1,-8010,("release," + ((string)selectedVictim)),NULL_KEY);
                                (pipeActionThroughCore = 1);
                            }
                        }
                        (path = pluginBasePath);
                    }
                    else  if ((pluginLocalPathPart0 == MENU_CAPTURE)) {
                        if ((!((!(~llListFindList(VictimsList,[((string)id)]))) && (RLV_grabRange > 0)))) {
                            (path = pluginBasePath);
                        }
                        else  if (pluginLocalPathPart1) {
                            key avatarToCapture = ((key)getFirstComment(pluginLocalPathPart1));
                            if (avatarToCapture) {
                                llMessageLinked(-1,-8010,("grab," + ((string)avatarToCapture)),NULL_KEY);
                                (pipeActionThroughCore = 1);
                                llSleep(2.0);
                            }
                            (path = pluginBasePath);
                        }
                    }
                    else  if ((pluginLocalPathPart0 == MENU_RESTRICTIONS)) {
                        integer relayVersion;
                        integer _index16 = llListFindList(VictimsList,[((string)selectedVictim)]);
                        if ((~_index16)) {
                            (relayVersion = llList2Integer(VictimsList,(_index16 + 2)));
                        }
                        if ((!(((selectedVictim != NULL_KEY) && (!(~llListFindList(VictimsList,[((string)id)])))) && relayVersion))) {
                            (path = pluginBasePath);
                        }
                        else  if (pluginLocalPathPart2) {
                            if ((~llListFindList(ATTACHMENT_POINTS,[pluginLocalPathPart2]))) {
                                llMessageLinked(-1,-8010,(((("rlvCommand," + ((string)selectedVictim)) + ",@remattach:") + pluginLocalPathPart2) + "=force"),NULL_KEY);
                            }
                            else  if ((~llListFindList(CLOTHING_LAYERS,[pluginLocalPathPart2]))) {
                                llMessageLinked(-1,-8010,(((("rlvCommand," + ((string)selectedVictim)) + ",@remoutfit:") + pluginLocalPathPart2) + "=force"),NULL_KEY);
                            }
                            else  if ((llGetSubString(pluginLocalPathPart2,0,0) == "☐")) {
                                llMessageLinked(-1,-8010,(((("rlvCommand," + ((string)selectedVictim)) + ",@") + llStringTrim(llDeleteSubString(pluginLocalPathPart2,0,1),3)) + "=n"),NULL_KEY);
                            }
                            else  if ((llGetSubString(pluginLocalPathPart2,0,0) == "☑")) {
                                llMessageLinked(-1,-8010,(((("rlvCommand," + ((string)selectedVictim)) + ",@") + llStringTrim(llDeleteSubString(pluginLocalPathPart2,0,1),3)) + "=y"),NULL_KEY);
                            }
                            llSleep(2.0);
                            (path = llDumpList2String(llDeleteSubList(llParseStringKeepNulls(path,[":"],[]),-1,-1),":"));
                        }
                    }
                    else  if ((pluginLocalPathPart0 == MENU_VICTIMS)) {
                        if ((!((llGetListLength(VictimsList) > 3) || ((llGetListLength(VictimsList) == 3) && (selectedVictim == NULL_KEY))))) {
                            (path = pluginBasePath);
                        }
                        else  if (pluginLocalPathPart1) {
                            key avatarToSelect = ((key)getFirstComment(pluginLocalPathPart1));
                            setSelectedVictim(id,avatarToSelect);
                            (path = pluginBasePath);
                        }
                    }
                    else  if ((pluginLocalPathPart0 == MENU_TIMER)) {
                        integer _time23;
                        integer _index24 = llListFindList(VictimsList,[((string)selectedVictim)]);
                        if ((~_index24)) {
                            (_time23 = (llList2Integer(VictimsList,(_index24 + 1)) - llGetUnixTime()));
                            if ((_time23 < 0)) {
                                (_time23 = 0);
                            }
                        }
                        if ((!((selectedVictim != NULL_KEY) && ((!(~llListFindList(VictimsList,[((string)id)]))) || _time23)))) {
                            (path = pluginBasePath);
                        }
                        else  if (pluginLocalPathPart1) {
                            integer time = ((integer)getFirstComment(pluginLocalPathPart1));
                            if (((time > 0) || ((selectedVictim != NULL_KEY) && (!(~llListFindList(VictimsList,[((string)id)])))))) {
                                if ((!time)) {
                                    integer _index28 = llListFindList(VictimsList,[((string)selectedVictim)]);
                                    if ((~_index28)) {
                                        (VictimsList = llListReplaceList(VictimsList,[0],(_index28 + 1),(_index28 + 1)));
                                        llMessageLinked(-1,-8010,((("setTimer," + ((string)selectedVictim)) + ",") + "0"),NULL_KEY);
                                    }
                                }
                                else  {
                                    integer _index30 = llListFindList(VictimsList,[((string)selectedVictim)]);
                                    if ((~_index30)) {
                                        integer thisTime = llGetUnixTime();
                                        integer oldTime = llList2Integer(VictimsList,(_index30 + 1));
                                        if ((oldTime < thisTime)) {
                                            (oldTime = thisTime);
                                        }
                                        integer newTime = (oldTime + time);
                                        if ((newTime < (thisTime + 30))) {
                                            (newTime = (thisTime + 30));
                                        }
                                        integer _index3 = llListFindList(VictimsList,[((string)selectedVictim)]);
                                        if ((~_index3)) {
                                            (VictimsList = llListReplaceList(VictimsList,[newTime],(_index3 + 1),(_index3 + 1)));
                                            llMessageLinked(-1,-8010,((("setTimer," + ((string)selectedVictim)) + ",") + ((string)newTime)),NULL_KEY);
                                        }
                                    }
                                }
                            }
                            (path = joinNodes([pluginBasePath,MENU_TIMER]));
                        }
                    }
                    else  {
                        (path = pluginBasePath);
                    }
                    string paramSet1 = buildParamSet1(path,page,prompt,[buttons],[pluginLocalPath,pluginName,pluginMenuParams,pluginActionParams]);
                    if (pipeActionThroughCore) {
                        llMessageLinked(-1,-8016,paramSet1,id);
                    }
                    else  {
                        llMessageLinked(-1,-831,paramSet1,id);
                    }
                }
                else  if ((num == -832)) {
                    list buttonsList = llParseString2List(buttons,[","],[]);
                    string selection = llDumpList2String(llList2List(llParseStringKeepNulls(pluginLocalPath,[":"],[]),-1,-1),":");
                    string promptSelectedVictim = (STRING_PROMPT_VICTIM_CAPTION + conditionalString((selectedVictim != NULL_KEY),conditionalString(OptionUseDisplayNames,llGetDisplayName(selectedVictim),llKey2Name(selectedVictim)),STRING_PROMPT_VICTIM_NONE));
                    integer _relayVersion37;
                    integer _index38 = llListFindList(VictimsList,[((string)selectedVictim)]);
                    if ((~_index38)) {
                        (_relayVersion37 = llList2Integer(VictimsList,(_index38 + 2)));
                    }
                    string promptVictimMainInfo = conditionalString((selectedVictim != NULL_KEY),((((STRING_NEW_LINE + STRING_PROMPT_RELAY_CAPTION) + conditionalString(_relayVersion37,STRING_PROMPT_RELAY_DETECTED,STRING_PROMPT_RELAY_NOTDETECTED)) + STRING_NEW_LINE) + getVictimTimerString(selectedVictim)),"");
                    if ((pluginLocalPath == "")) {
                        (prompt = (promptSelectedVictim + promptVictimMainInfo));
                        if (((!(~llListFindList(VictimsList,[((string)id)]))) && (RLV_grabRange > 0))) {
                            (buttonsList += [MENU_CAPTURE]);
                        }
                        integer _relayVersion43;
                        integer _index44 = llListFindList(VictimsList,[((string)selectedVictim)]);
                        if ((~_index44)) {
                            (_relayVersion43 = llList2Integer(VictimsList,(_index44 + 2)));
                        }
                        if ((((selectedVictim != NULL_KEY) && (!(~llListFindList(VictimsList,[((string)id)])))) && _relayVersion43)) {
                            (buttonsList += [MENU_RESTRICTIONS]);
                        }
                        if (((selectedVictim != NULL_KEY) && (!(~llListFindList(VictimsList,[((string)id)]))))) {
                            (buttonsList += [MENU_BUTTON_RELEASE]);
                        }
                        if (((selectedVictim != NULL_KEY) && (!(~llListFindList(VictimsList,[((string)id)]))))) {
                            (buttonsList += [MENU_BUTTON_UNSIT]);
                        }
                        integer _time51;
                        integer _index52 = llListFindList(VictimsList,[((string)selectedVictim)]);
                        if ((~_index52)) {
                            (_time51 = (llList2Integer(VictimsList,(_index52 + 1)) - llGetUnixTime()));
                            if ((_time51 < 0)) {
                                (_time51 = 0);
                            }
                        }
                        if (((selectedVictim != NULL_KEY) && ((!(~llListFindList(VictimsList,[((string)id)]))) || _time51))) {
                            (buttonsList += [MENU_TIMER]);
                        }
                        if (((llGetListLength(VictimsList) > 3) || ((llGetListLength(VictimsList) == 3) && (selectedVictim == NULL_KEY)))) {
                            (buttonsList += [MENU_VICTIMS]);
                        }
                    }
                    else  if ((pluginLocalPath == MENU_CAPTURE)) {
                        if (RLV_grabRange) {
                            integer _index56 = llListFindList(SensorUsersListUser,[id]);
                            if ((~_index56)) {
                                (SensorUsersListUser = llDeleteSubList(SensorUsersListUser,_index56,_index56));
                                (SensorUsersListMenuParams = llDeleteSubList(SensorUsersListMenuParams,_index56,_index56));
                            }
                            (SensorUsersListUser += id);
                            (SensorUsersListMenuParams += str);
                            llSensor("",NULL_KEY,1,RLV_grabRange,3.14159265);
                            return;
                        }
                    }
                    else  if ((pluginLocalPath == MENU_RESTRICTIONS)) {
                        integer channel = addToUsersList(id,str);
                        llMessageLinked(-1,-8010,((("rlvCommand," + ((string)selectedVictim)) + ",@getstatus=") + ((string)channel)),NULL_KEY);
                        return;
                    }
                    else  if ((pluginLocalPath == joinNodes([MENU_RESTRICTIONS,MENU_UNDRESS]))) {
                        integer channel = addToUsersList(id,str);
                        llMessageLinked(-1,-8010,((("rlvCommand," + ((string)selectedVictim)) + ",@getoutfit=") + ((string)channel)),NULL_KEY);
                        return;
                    }
                    else  if ((pluginLocalPath == joinNodes([MENU_RESTRICTIONS,MENU_ATTACHMENTS]))) {
                        integer channel = addToUsersList(id,str);
                        llMessageLinked(-1,-8010,((("rlvCommand," + ((string)selectedVictim)) + ",@getattach=") + ((string)channel)),NULL_KEY);
                        return;
                    }
                    else  if (((llDumpList2String(llList2List(llParseStringKeepNulls(pluginLocalPath,[":"],[]),0,0),":") == MENU_RESTRICTIONS) && (~llListFindList(RLV_RESTRICTIONS,[selection])))) {
                        integer channel = addToUsersList(id,str);
                        llMessageLinked(-1,-8010,((("rlvCommand," + ((string)selectedVictim)) + ",@getstatus=") + ((string)channel)),NULL_KEY);
                        return;
                    }
                    else  if ((pluginLocalPath == MENU_TIMER)) {
                        (prompt += (STRING_NEW_LINE + getVictimTimerString(selectedVictim)));
                        (buttonsList += TIMER_BUTTONS1);
                        if (((selectedVictim != NULL_KEY) && (!(~llListFindList(VictimsList,[((string)id)]))))) {
                            (buttonsList += TIMER_BUTTONS2);
                        }
                        (prompt = (promptSelectedVictim + promptVictimMainInfo));
                    }
                    else  if ((pluginLocalPath == MENU_VICTIMS)) {
                        (prompt += ((promptSelectedVictim + STRING_NEW_LINE) + STRING_PROMPT_VICTIM_SELECT));
                        integer index;
                        integer length = llGetListLength(VictimsList);
                        for (; (index < length); (index += 3)) {
                            key avatarKey = ((key)llList2String(VictimsList,index));
                            string avatarName;
                            if (OptionUseDisplayNames) {
                                (avatarName = llGetDisplayName(avatarKey));
                            }
                            else  {
                                (avatarName = llKey2Name(avatarKey));
                            }
                            (avatarName = text2MenuText(avatarName));
                            if ((avatarKey == selectedVictim)) {
                                (avatarName = (("⚫" + avatarName) + "⚫"));
                            }
                            (buttonsList += (((MARKER_COMMENT_START + ((string)avatarKey)) + MARKER_COMMENT_END) + avatarName));
                        }
                    }
                    llMessageLinked(-1,-833,buildParamSet1(path,page,prompt,buttonsList,[pluginLocalPath,pluginName,pluginMenuParams,pluginActionParams]),id);
                }
            }
        }
        else  if ((num == -240)) {
            list optionsToSet = llParseStringKeepNulls(str,["~","|"],[]);
            integer length = llGetListLength(optionsToSet);
            integer index;
            for (; (index < length); (++index)) {
                list optionsItems = llParseString2List(llList2String(optionsToSet,index),["="],[]);
                string optionItem = llToLower(llStringTrim(llList2String(optionsItems,0),3));
                string optionString = llList2String(optionsItems,1);
                string optionSetting = llToLower(llStringTrim(optionString,3));
                integer optionSettingFlag = ((optionSetting == "on") || ((integer)optionSetting));
                if ((optionItem == "rlv_grabrange")) {
                    (RLV_grabRange = ((float)optionSetting));
                }
                if ((optionItem == "usedisplaynames")) {
                    (OptionUseDisplayNames = optionSettingFlag);
                }
            }
        }
        else  if ((num == 34334)) {
            llSay(0,(((((((("Memory Used by " + llGetScriptName()) + ": ") + ((string)llGetUsedMemory())) + " of ") + ((string)llGetMemoryLimit())) + ", Leaving ") + ((string)llGetFreeMemory())) + " memory free."));
        }
    }

	listen(integer channel,string name,key id,string message) {
        integer indexUsersList;
        string prompt;
        list buttons;
        if ((~(indexUsersList = llListFindList(UsersList,[channel])))) {
            key menuUser = llList2Key(UsersList,(indexUsersList + 2));
            list menuParams = llParseStringKeepNulls(llList2String(UsersList,(indexUsersList + 3)),["|"],[]);
            if ((~indexUsersList)) {
                llListenRemove(llList2Integer(UsersList,(indexUsersList + 1)));
                (UsersList = llDeleteSubList(UsersList,indexUsersList,((indexUsersList + 5) - 1)));
            }
            if ((!llGetListLength(UsersList))) {
                llSetTimerEvent(0.0);
            }
            string localPath = llList2String(menuParams,4);
            string selection = llDumpList2String(llList2List(llParseStringKeepNulls(localPath,[":"],[]),-1,-1),":");
            integer restrictionsListIndex = llListFindList(RLV_RESTRICTIONS,[selection]);
            if (((localPath == MENU_RESTRICTIONS) || (~restrictionsListIndex))) {
                list activeRestrictions = llParseString2List(message,["/"],[]);
                integer index;
                integer length = llGetListLength(activeRestrictions);
                for (; (index < length); (index++)) {
                    string restrictionWorkingOn = llList2String(activeRestrictions,index);
                    if (((~llSubStringIndex(restrictionWorkingOn,":")) || (~llListFindList(IGNORED_RLV_RESTRICTIONS,[restrictionWorkingOn])))) {
                        (activeRestrictions = llDeleteSubList(activeRestrictions,index,index));
                        (--index);
                        (--length);
                    }
                }
                key selectedVictim = getSelectedVictim(menuUser);
                (prompt = (((STRING_PROMPT_VICTIM_CAPTION + conditionalString((selectedVictim != NULL_KEY),conditionalString(OptionUseDisplayNames,llGetDisplayName(selectedVictim),llKey2Name(selectedVictim)),STRING_PROMPT_VICTIM_NONE)) + STRING_NEW_LINE) + STRING_NEW_LINE));
                (prompt += (STRING_PROMPT_RESTRICTIONS_CAPTION + conditionalString(llGetListLength(activeRestrictions),(STRING_NEW_LINE + llDumpList2String(activeRestrictions,", ")),STRING_PROMPT_RESTRICTIONS_NONE)));
                if ((localPath == MENU_RESTRICTIONS)) {
                    (buttons = [MENU_UNDRESS,MENU_ATTACHMENTS]);
                    (length = llGetListLength(RLV_RESTRICTIONS));
                    for ((index = 0); (index < length); (index += 2)) {
                        (buttons += llList2String(RLV_RESTRICTIONS,index));
                    }
                }
                else  {
                    (prompt += ((((((STRING_NEW_LINE + STRING_NEW_LINE) + "☑ ... set restriction active") + STRING_NEW_LINE) + "☐ ... set restriction inactive") + STRING_NEW_LINE) + "(Maybe not all retrictions can't be set inactive)"));
                    list availibleRestrictions = llCSV2List(llList2String(RLV_RESTRICTIONS,(restrictionsListIndex + 1)));
                    (length = llGetListLength(availibleRestrictions));
                    for ((index = 0); (index < length); (index++)) {
                        string restrictionWorkingOn = llList2String(availibleRestrictions,index);
                        if ((~llListFindList(activeRestrictions,[restrictionWorkingOn]))) {
                            (buttons += [("☑ " + restrictionWorkingOn)]);
                        }
                        else  {
                            (buttons += [("☐ " + restrictionWorkingOn)]);
                        }
                    }
                }
            }
            else  if ((localPath == joinNodes([MENU_RESTRICTIONS,MENU_ATTACHMENTS]))) {
                list allNames = ATTACHMENT_POINTS;
                list layersWorn;
                integer _length10 = llStringLength(message);
                integer i;
                for (; (i < _length10); (i += 1)) {
                    if ((llGetSubString(message,i,i) == "1")) {
                        string layerName = llList2String(allNames,i);
                        if (layerName) {
                            (layersWorn += [layerName]);
                        }
                    }
                }
                (buttons = layersWorn);
                (prompt = ((((((((STRING_NEW_LINE + "The following attachment points are worn:") + STRING_NEW_LINE) + llDumpList2String(buttons,", ")) + STRING_NEW_LINE) + STRING_NEW_LINE) + "Click a button to try to detach this attachment") + STRING_NEW_LINE) + "(Beware some might be locked and can't be removed)"));
            }
            else  if ((localPath == joinNodes([MENU_RESTRICTIONS,MENU_UNDRESS]))) {
                list _allNames13 = CLOTHING_LAYERS;
                list _layersWorn14;
                integer _length15 = llStringLength(message);
                integer _i16;
                for (; (_i16 < _length15); (_i16 += 1)) {
                    if ((llGetSubString(message,_i16,_i16) == "1")) {
                        string _layerName17 = llList2String(_allNames13,_i16);
                        if (_layerName17) {
                            (_layersWorn14 += [_layerName17]);
                        }
                    }
                }
                (buttons = _layersWorn14);
                (prompt = ((((((((STRING_NEW_LINE + "The following clothing layers are worn:") + STRING_NEW_LINE) + llDumpList2String(buttons,", ")) + STRING_NEW_LINE) + STRING_NEW_LINE) + "Click a button to try to detach this layer") + STRING_NEW_LINE) + "(Beware some might be locked and can't be removed)"));
            }
            llMessageLinked(-1,-833,buildParamSet1(llList2String(menuParams,0),0,prompt,buttons,llList2List(menuParams,4,-1)),menuUser);
        }
    }

	sensor(integer num) {
        list sensorList;
        integer index;
        for (; (index < num); (index++)) {
            key avatar = llDetectedKey(index);
            if ((!(~llListFindList(VictimsList,[((string)avatar)])))) {
                string prefix = ((MARKER_COMMENT_START + ((string)avatar)) + MARKER_COMMENT_END);
                if (OptionUseDisplayNames) {
                    (sensorList += (prefix + text2MenuText(llGetDisplayName(avatar))));
                }
                else  {
                    (sensorList += (prefix + text2MenuText(llKey2Name(avatar))));
                }
            }
        }
        integer length = llGetListLength(SensorUsersListUser);
        for ((index = 0); (index < length); (index++)) {
            list params = llParseStringKeepNulls(llList2String(SensorUsersListMenuParams,index),["|"],[]);
            llMessageLinked(-1,-833,buildParamSet1(llList2String(params,0),0,STRING_PROMPT_CAPTURE_CAPTION,sensorList,llList2List(params,4,-1)),llList2Key(SensorUsersListUser,index));
        }
        (SensorUsersListUser = []);
        (SensorUsersListMenuParams = []);
    }


	no_sensor() {
        integer length = llGetListLength(SensorUsersListUser);
        integer index;
        for (; (index < length); (index++)) {
            list params = llParseStringKeepNulls(llList2String(SensorUsersListMenuParams,index),["|"],[]);
            llMessageLinked(-1,-833,buildParamSet1(llList2String(params,0),0,STRING_PROMPT_CAPTURE_NO_ONE_CAPTION,[],llList2List(params,4,-1)),llList2Key(SensorUsersListUser,index));
        }
        (SensorUsersListUser = []);
        (SensorUsersListMenuParams = []);
    }

	timer() {
        integer length = llGetListLength(UsersList);
        integer index;
        integer currentTime = llGetUnixTime();
        for (; (index < length); (index += 5)) {
            if ((currentTime > llList2Integer(UsersList,(index + 4)))) {
                if ((~index)) {
                    llListenRemove(llList2Integer(UsersList,(index + 1)));
                    (UsersList = llDeleteSubList(UsersList,index,((index + 5) - 1)));
                }
                if ((!llGetListLength(UsersList))) {
                    llSetTimerEvent(0.0);
                }
                (index -= 5);
                (length -= 5);
            }
        }
    }

	on_rez(integer start_param) {
        llResetScript();
    }
}
