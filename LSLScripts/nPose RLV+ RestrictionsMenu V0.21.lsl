// LSL script generated - patched Render.hs (0.1.6.2): RLV+.nPose-RLV-Plugin.LSLScripts.nPose RLV+ RestrictionsMenu V0.21.lslp Sat Apr  4 09:26:30 Mitteleuropäische Sommerzeit 2015
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

// linkMessage Numbers from -8000 to -8050 are assigned to the RLV+ Plugins
// linkMessage Numbers from -8000 to -8009 are assigned to the RLV+ Core Plugin
// linkMessage Numbers from -8010 to -8019 are assigned to the RLV+ RestrictionsMenu Plugin
// linkMessage Numbers from -8020 to -8047 are reserved for later use
// linkMessage Numbers from -8048 to -8049 are assigned to universal purposes

string PLUGIN_NAME = "RLV_RESTRICTIONS_MENU";

string BACKBTN = "^";
string MENU_RLV_RESTRICTIONS_MAIN = "RLVRestrictions";
string MENU_RLV_UNDRESS = "→Undress";
string MENU_RLV_ATTACHMENTS = "→Attachments";

// the following rlv restrictions can be controlled with this plugin
list RLV_RESTRICTIONS = ["→Chat/IM","sendchat,chatshout,chatnormal,recvchat,recvemote,sendim,startim,recvim","→Inventory","showinv,viewnote,viewscript,viewtexture,edit,rez,unsharedwear,unsharedunwear","→Touch","fartouch,touchall,touchworld,touchattach","→World","shownames,showhovertextall,showworldmap,showminimap,showloc","→Debug/Env","setgroup,setdebug,setenv"];

list IGNORED_RLV_RESTRICTIONS = ["acceptpermission","detach"];

list CLOTHING_LAYERS = ["gloves","jacket","pants","shirt","shoes","skirt","socks","underpants","undershirt","","","","","alpha","tattoo"];

list ATTACHMENT_POINTS = ["","chest","skull","left shoulder","right shoulder","left hand","right hand","left foot","right foot","spine","pelvis","mouth","chin","left ear","right ear","left eyeball","right eyeball","nose","r upper arm","r forearm","l upper arm","l forearm","right hip","r upper leg","r lower leg","left hip","l upper leg","l lower leg","stomach","left pec","right pec","","","","","","","","","neck","root"];

string PROMPT_VICTIM = "Selected Victim: ";
string PROMPT_RESTRICTIONS = "Active restrictions are: ";
string NO_RESTRICTIONS = "NONE. Victim may be FREE.";
string NEW_LINE = "\n";
string NO_VICTIM = "NONE";

string PATH_SEPARATOR = ":";

// --- global variables

// options

// random channel for RLV responses
integer RlvReplyChannel;
integer RlvReplyChannelClothing;
integer RlvReplyChannelAttachment;
//handles
integer RlvReplyListenHandle;

key MyUniqueId;

string Path;
key NPosetoucherID;

key VictimKey;


string StringReplace(string str,string search,string replace){
    return llDumpList2String(llParseStringKeepNulls(str,[search],[]),replace);
}

ShowMenu(key targetKey,string prompt,list buttons,string menuPath){
    if (targetKey) {
        llMessageLinked(-1,-900,(string)targetKey + "|" + prompt + "\n" + menuPath + "\n" + "|" + "0" + "|" + llDumpList2String(buttons,"`") + "|" + llDumpList2String([BACKBTN],"`") + "|" + menuPath,MyUniqueId);
    }
}

// send rlv commands to the RLV relay, usable for common format (not ping)
SendToRlvRelay(key victim,string rlvCommand,string identifier){
    if (!llStringLength(identifier)) {
        identifier = (string)MyUniqueId;
    }
    if (rlvCommand) {
        if (victim) {
            llSay(-1812221819,identifier + "," + (string)victim + "," + StringReplace(rlvCommand,"%MYKEY%",(string)llGetKey()));
        }
    }
}

QueryRlvGetStatus(){
    llListenRemove(RlvReplyListenHandle);
    RlvReplyChannel = 10000 + (integer)llFrand(30000);
    RlvReplyListenHandle = llListen(RlvReplyChannel,"",NULL_KEY,"");
    SendToRlvRelay(VictimKey,"@getstatus=" + (string)RlvReplyChannel,"");
}

QueryWornClothes(){
    llListenRemove(RlvReplyListenHandle);
    RlvReplyChannelClothing = 10000 + (integer)llFrand(30000);
    RlvReplyListenHandle = llListen(RlvReplyChannelClothing,"",NULL_KEY,"");
    SendToRlvRelay(VictimKey,"@getoutfit=" + (string)RlvReplyChannelClothing,"");
}

QueryWornAttachments(){
    llListenRemove(RlvReplyListenHandle);
    RlvReplyChannelAttachment = 10000 + (integer)llFrand(30000);
    RlvReplyListenHandle = llListen(RlvReplyChannelAttachment,"",NULL_KEY,"");
    SendToRlvRelay(VictimKey,"@getattach=" + (string)RlvReplyChannelAttachment,"");
}


list ParseClothingOrAttachmentLayersWorn(string message,list names){
    integer length = llStringLength(message);
    list layersWorn = [];
    integer i;
    for (i = 0; i < length; i += 1) {
        string isWorn = llGetSubString(message,i,i);
        if (isWorn == "1") {
            string layerName = llList2String(names,i);
            if (layerName != "") {
                layersWorn += [layerName];
            }
        }
    }
    return layersWorn;
}

string getSelectedVictimPromt(){
    if (VictimKey) {
        return PROMPT_VICTIM + llKey2Name(VictimKey) + NEW_LINE;
    }
    else  {
        return PROMPT_VICTIM + NO_VICTIM + NEW_LINE;
    }
}

// --- states

default {

	state_entry() {
        MyUniqueId = llGenerateKey();
        llMessageLinked(-1,-8049,PLUGIN_NAME,"");
    }


	link_message(integer sender,integer num,string str,key id) {
        if (num == -8048) {
            if (str == PLUGIN_NAME) {
                llMessageLinked(-1,-8049,PLUGIN_NAME,"");
            }
        }
        else  if (num == -237) {
            VictimKey = (key)str;
        }
        else  if (num == -901) {
            if (id == MyUniqueId) {
                list params = llParseString2List(str,["|"],[]);
                string selection = llList2String(params,1);
                Path = llList2String(params,3);
                NPosetoucherID = (key)llList2String(params,2);
                list pathparts = llParseString2List(Path,[PATH_SEPARATOR],[]);
                if (selection == BACKBTN) {
                    selection = llList2String(pathparts,-2);
                    if (Path == MENU_RLV_RESTRICTIONS_MAIN) {
                        llMessageLinked(-1,-8000,"showMenu," + (string)NPosetoucherID,"");
                        return;
                    }
                    else  if (selection == MENU_RLV_RESTRICTIONS_MAIN) {
                        Path = MENU_RLV_RESTRICTIONS_MAIN;
                        QueryRlvGetStatus();
                        return;
                    }
                    else  {
                        pathparts = llDeleteSubList(pathparts,-2,-1);
                        Path = llDumpList2String(pathparts,PATH_SEPARATOR);
                    }
                }
                if (Path == MENU_RLV_RESTRICTIONS_MAIN) {
                    if (selection == MENU_RLV_UNDRESS) {
                        Path += PATH_SEPARATOR + selection;
                        QueryWornClothes();
                    }
                    else  if (selection == MENU_RLV_ATTACHMENTS) {
                        Path += PATH_SEPARATOR + selection;
                        QueryWornAttachments();
                    }
                    else  if (~llListFindList(RLV_RESTRICTIONS,[selection])) {
                        Path += PATH_SEPARATOR + selection;
                        QueryRlvGetStatus();
                    }
                    return;
                }
                else  if (Path == MENU_RLV_RESTRICTIONS_MAIN + PATH_SEPARATOR + MENU_RLV_UNDRESS) {
                    if (~llListFindList(CLOTHING_LAYERS,[selection])) {
                        SendToRlvRelay(VictimKey,"@remoutfit:" + selection + "=force","");
                        llSleep(0.5);
                        QueryWornClothes();
                    }
                }
                else  if (Path == MENU_RLV_RESTRICTIONS_MAIN + PATH_SEPARATOR + MENU_RLV_ATTACHMENTS) {
                    if (~llListFindList(ATTACHMENT_POINTS,[selection])) {
                        SendToRlvRelay(VictimKey,"@remattach:" + selection + "=force","");
                        llSleep(0.5);
                        QueryWornAttachments();
                    }
                }
                else  {
                    if (llGetSubString(selection,0,0) == "☐") {
                        SendToRlvRelay(VictimKey,"@" + llDeleteSubString(selection,0,1) + "=n","");
                        QueryRlvGetStatus();
                    }
                    else  if (llGetSubString(selection,0,0) == "☑") {
                        SendToRlvRelay(VictimKey,"@" + llDeleteSubString(selection,0,1) + "=y","");
                        QueryRlvGetStatus();
                    }
                    else  {
                    }
                }
            }
        }
        else  if (num == -8010) {
            list temp = llParseStringKeepNulls(str,[","],[]);
            string cmd = llToLower(llStringTrim(llList2String(temp,0),3));
            key target = (key)StringReplace(llStringTrim(llList2String(temp,1),3),"%VICTIM%",(string)VictimKey);
            list params = llDeleteSubList(temp,0,1);
            if (target) {
            }
            else  {
                target = VictimKey;
            }
            if (cmd == "showmenu") {
                Path = MENU_RLV_RESTRICTIONS_MAIN;
                NPosetoucherID = target;
                QueryRlvGetStatus();
            }
        }
        else  if (num == 34334) {
            llSay(0,"Memory Used by " + llGetScriptName() + ": " + (string)llGetUsedMemory() + " of " + (string)llGetMemoryLimit() + ", Leaving " + (string)llGetFreeMemory() + " memory free.");
        }
    }


	changed(integer change) {
        if (change & 128) {
            llResetScript();
        }
    }


	listen(integer channel,string name,key id,string message) {
        if (channel == RlvReplyChannel) {
            llListenRemove(RlvReplyListenHandle);
            list activeRestrictions = llParseString2List(message,["/"],[]);
            list usedRestrictions = [];
            integer length = llGetListLength(activeRestrictions);
            integer index;
            for (; index < length; index++) {
                string restrictionName = llList2String(activeRestrictions,index);
                if (~llSubStringIndex(restrictionName,":")) {
                }
                else  if (~llListFindList(IGNORED_RLV_RESTRICTIONS,[restrictionName])) {
                }
                else  {
                    usedRestrictions += [restrictionName];
                }
            }
            string prompt = getSelectedVictimPromt() + PROMPT_RESTRICTIONS;
            if (usedRestrictions) {
                prompt += llDumpList2String(usedRestrictions,", ");
            }
            else  {
                prompt += NO_RESTRICTIONS;
            }
            list buttons;
            if (Path == MENU_RLV_RESTRICTIONS_MAIN) {
                buttons = [MENU_RLV_UNDRESS,MENU_RLV_ATTACHMENTS];
                length = llGetListLength(RLV_RESTRICTIONS);
                for (index = 0; index < length; index += 2) {
                    buttons += [llList2String(RLV_RESTRICTIONS,index)];
                }
            }
            else  {
                prompt += NEW_LINE + NEW_LINE + "☑ ... set restriction active" + NEW_LINE + "☐ ... set restriction inactive" + NEW_LINE + "(Maybe not all retrictions can't be set inactive)";
                list pathparts = llParseString2List(Path,[PATH_SEPARATOR],[]);
                string restrictionGroup = llList2String(pathparts,-1);
                integer restrictionIndex = llListFindList(RLV_RESTRICTIONS,[restrictionGroup]);
                if (~restrictionIndex) {
                    list restrictions = llCSV2List(llList2String(RLV_RESTRICTIONS,restrictionIndex + 1));
                    length = llGetListLength(restrictions);
                    for (index = 0; index < length; index++) {
                        string restrictionName = llList2String(restrictions,index);
                        if (~llListFindList(usedRestrictions,[restrictionName])) {
                            buttons += ["☑ " + restrictionName];
                        }
                        else  {
                            buttons += ["☐ " + restrictionName];
                        }
                    }
                }
            }
            ShowMenu(NPosetoucherID,prompt,buttons,Path);
        }
        else  if (channel == RlvReplyChannelClothing) {
            llListenRemove(RlvReplyListenHandle);
            list clothingLayersWorn = ParseClothingOrAttachmentLayersWorn(message,CLOTHING_LAYERS);
            string title = "The following clothing layers are worn:\n" + llDumpList2String(clothingLayersWorn,", ") + "\n\nClick a button to try to detach this layer\n" + "(Beware some might be locked and can't be removed)\n";
            ShowMenu(NPosetoucherID,title,clothingLayersWorn,Path);
        }
        else  if (channel == RlvReplyChannelAttachment) {
            llListenRemove(RlvReplyListenHandle);
            list attachmentPointsWorn = ParseClothingOrAttachmentLayersWorn(message,ATTACHMENT_POINTS);
            string title = "The following attachment points are worn:\n" + llDumpList2String(attachmentPointsWorn,", ") + "\n\nClick a button to try to detach this attachment\n" + "(Beware some might be locked and can't be removed)\n";
            ShowMenu(NPosetoucherID,title,attachmentPointsWorn,Path);
        }
    }


	timer() {
    }
}
