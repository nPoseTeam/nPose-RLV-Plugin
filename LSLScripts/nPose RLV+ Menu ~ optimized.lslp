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

list gV = 
    [ "→Chat/IM"
    , "sendchat,chatshout,chatnormal,recvchat,recvemote,sendim,startim,recvim"
    , "→Inventory"
    , "showinv,viewnote,viewscript,viewtexture,edit,rez,unsharedwear,unsharedunwear"
    , "→Touch"
    , "fartouch,touchall,touchworld,touchattach"
    , "→World"
    , "shownames,showhovertextall,showworldmap,showminimap,showloc"
    , "→Debug/Env"
    , "setgroup,setdebug,setenv"
    ];
list gU = 
    [ "gloves"
    , "jacket"
    , "pants"
    , "shirt"
    , "shoes"
    , "skirt"
    , "socks"
    , "underpants"
    , "undershirt"
    , ""
    , ""
    , ""
    , ""
    , "alpha"
    , "tattoo"
    ];
list LslLibrary = 
    [ ""
    , "chest"
    , "skull"
    , "left shoulder"
    , "right shoulder"
    , "left hand"
    , "right hand"
    , "left foot"
    , "right foot"
    , "spine"
    , "pelvis"
    , "mouth"
    , "chin"
    , "left ear"
    , "right ear"
    , "left eyeball"
    , "right eyeball"
    , "nose"
    , "r upper arm"
    , "r forearm"
    , "l upper arm"
    , "l forearm"
    , "right hip"
    , "r upper leg"
    , "r lower leg"
    , "left hip"
    , "l upper leg"
    , "l lower leg"
    , "stomach"
    , "left pec"
    , "right pec"
    , ""
    , ""
    , ""
    , ""
    , ""
    , ""
    , ""
    , ""
    , "neck"
    , "root"
    ];
list gZ = 
    [ "/*86400*/+1d"
    , "/*21600*/+6h"
    , "/*3600*/+1h"
    , "/*900*/+15m"
    , "/*60*/+1m"
    ];
list Pop = 
    [ "/*-86400*/-1d"
    , "/*-21600*/-6h"
    , "/*-3600*/-1h"
    , "/*-900*/-15m"
    , "/*-60*/-1m"
    , "/*0*/Reset"
    ];
list gS;
list gT;
list ResumeVoid;
list IsSaveDue;
list System;
list gR;
float LslUserScript = 10;
integer ga = 1;

string J(string llToLower, integer llSay, integer llList2Key)
{
    return llDumpList2String(llDeleteSubList(llParseStringKeepNulls(llToLower, (list)":", []), llSay, llList2Key), ":");
}

string Q(string llToLower, integer llSay, integer llList2Key)
{
    return llDumpList2String(llList2List(llParseStringKeepNulls(llToLower, (list)":", []), llSay, llList2Key), ":");
}

string X(list llToLower)
{
    integer loc_index;
    integer loc_length = llToLower != [];
    list loc_tempNodes;
    for (; loc_index < loc_length; ++loc_index)
    {
        string loc_currentNodeString = llList2String(llToLower, loc_index);
        if (!(loc_currentNodeString == ""))
        {
            loc_tempNodes = loc_tempNodes + llParseStringKeepNulls(loc_currentNodeString, (list)":", []);
        }
    }
    return llDumpList2String(loc_tempNodes, ":");
}

string N(string llToLower, string llList2Key)
{
    return Q(llToLower, 0, ~(llParseString2List(llList2Key, (list)":", []) != []));
}

string F(string llToLower, integer llList2List, string llSay, list llList2Key, list llList2Integer)
{
    return llDumpList2String((list)llToLower + llList2List + llDumpList2String(llParseStringKeepNulls(llSay, (list)",", []), "‚") + llDumpList2String(llList2Key, ",") + llList2List(llList2Integer + "" + "" + "" + "", 0, 3), "|");
}

string U(string llToLower)
{
    integer loc_start = llSubStringIndex(llToLower, "/*");
    if (~loc_start)
    {
        integer loc_end = llSubStringIndex(llToLower, "*/");
        if (~loc_end)
        {
            if (loc_start < loc_end)
            {
                return llGetSubString(llToLower, -~-~loc_start, ~-loc_end);
            }
        }
    }
    return "";
}

key B(key llToLower)
{
    integer loc_index = System != [];
    for (; loc_index; --loc_index)
    {
        if (!~llListFindList(gS, (list)llList2Key(System, ~-loc_index)))
        {
            IsSaveDue = llDeleteSubList(IsSaveDue, ~-loc_index, ~-loc_index);
            System = llDeleteSubList(System, ~-loc_index, ~-loc_index);
        }
    }
    if (llToLower)
    {
        loc_index = G(llToLower);
        if (!~loc_index)
        {
            loc_index = _(llToLower);
            if (~loc_index)
            {
                loc_index = Y(llToLower, llToLower);
            }
            else if ((gS != []) < 3)
            {
                return "00000000-0000-0000-0000-000000000000";
            }
            else
            {
                loc_index = Y(llToLower, (key)llList2String(gS, 0));
            }
        }
        return llList2Key(System, loc_index);
    }
    return "00000000-0000-0000-0000-000000000000";
}

integer Y(key llToLower, key llList2Key)
{
    if (llToLower)
    {
        if (~_(llList2Key))
        {
            integer loc_index = G(llToLower);
            if (~loc_index)
            {
                IsSaveDue = llListReplaceList(IsSaveDue, (list)llToLower, loc_index, loc_index);
                System = llListReplaceList(System, (list)llList2Key, loc_index, loc_index);
                return loc_index;
            }
            else
            {
                IsSaveDue = IsSaveDue + llToLower;
                System = System + llList2Key;
                return ~-(IsSaveDue != []);
            }
        }
    }
    return ((integer)-1);
}

string R(key llToLower)
{
    return "Selected Victim: " + M(!(llToLower == "00000000-0000-0000-0000-000000000000"), M(ga, llGetDisplayName(llToLower), llKey2Name(llToLower)), "NONE");
}

string A(string llToLower)
{
    llToLower = llDumpList2String(llParseStringKeepNulls(llToLower, (list)"`", []), "‵");
    llToLower = llDumpList2String(llParseStringKeepNulls(llToLower, (list)"|", []), "┃");
    llToLower = llDumpList2String(llParseStringKeepNulls(llToLower, (list)"/", []), "⁄");
    llToLower = llDumpList2String(llParseStringKeepNulls(llToLower, (list)":", []), "꞉");
    llToLower = llDumpList2String(llParseStringKeepNulls(llToLower, (list)",", []), "‚");
    return llToLower;
}

integer G(key llToLower)
{
    return llListFindList(IsSaveDue, (list)llToLower);
}

integer _(key llToLower)
{
    return llListFindList(gS, (list)((string)llToLower));
}

integer b(key llToLower)
{
    integer loc_relayVersion;
    integer loc_index = _(llToLower);
    if (~loc_index)
    {
        loc_relayVersion = llList2Integer(gS, -~-~loc_index);
    }
    return loc_relayVersion;
}

integer D(key llToLower)
{
    integer loc_time;
    integer loc_index = _(llToLower);
    if (~loc_index)
    {
        loc_time = llList2Integer(gS, -~loc_index) + -llGetUnixTime();
        if (loc_time < 0)
        {
            loc_time = 0;
        }
    }
    return loc_time;
}

C(key llToLower, integer llList2Key)
{
    integer loc_index = _(llToLower);
    if (~loc_index)
    {
        integer loc_thisTime = llGetUnixTime();
        integer loc_oldTime = llList2Integer(gS, -~loc_index);
        if (loc_oldTime < loc_thisTime)
        {
            loc_oldTime = loc_thisTime;
        }
        integer loc_newTime = loc_oldTime + llList2Key;
        if (loc_newTime < 30 + loc_thisTime)
        {
            loc_newTime = 30 + loc_thisTime;
        }
        Z(llToLower, loc_newTime);
    }
}

Z(key llToLower, integer llList2Key)
{
    integer loc_index = _(llToLower);
    if (~loc_index)
    {
        gS = llListReplaceList(gS, (list)llList2Key, -~loc_index, -~loc_index);
        llMessageLinked(((integer)-1), ((integer)-8010), "setTimer," + (string)llToLower + "," + (string)llList2Key, "00000000-0000-0000-0000-000000000000");
    }
}

string O(key llToLower)
{
    integer loc_runningTimeS = D(llToLower);
    if (!loc_runningTimeS)
    {
        return "Timer: " + "--:--:--" + "\n";
    }
    integer loc_runningTimeM = loc_runningTimeS / 60;
    loc_runningTimeS = loc_runningTimeS % 60;
    integer loc_runningTimeH = loc_runningTimeM / 60;
    loc_runningTimeM = loc_runningTimeM % 60;
    integer loc_runningTimeD = loc_runningTimeH / 24;
    loc_runningTimeH = loc_runningTimeH % 24;
    return "Timer: " + M(loc_runningTimeD, (string)loc_runningTimeD + "d ", "") + llGetSubString("0" + (string)loc_runningTimeH, ((integer)-2), ((integer)-1)) + ":" + llGetSubString("0" + (string)loc_runningTimeM, ((integer)-2), ((integer)-1)) + ":" + llGetSubString("0" + (string)loc_runningTimeS, ((integer)-2), ((integer)-1));
}

string M(integer llToLower, string llList2Key, string llSay)
{
    string loc_ret = llSay;
    if (llToLower)
    {
        loc_ret = llList2Key;
    }
    return loc_ret;
}

E(integer llToLower)
{
    if (~llToLower)
    {
        llListenRemove(llList2Integer(gR, -~llToLower));
        gR = llDeleteSubList(gR, llToLower, ~-(5 + llToLower));
    }
    if (gR == [])
    {
        llSetTimerEvent(((float)0));
    }
}

integer L(key llToLower, string llList2Key)
{
    integer loc_index = ~-~-llListFindList(gR, (list)llToLower);
    E(loc_index);
    integer loc_channel = (integer)(((float)1000000000) + llFrand(((float)1000000000)));
    gR = gR + 
        [ loc_channel
        , llListen(loc_channel, "", "", "")
        , llToLower
        , llList2Key
        , 4 + llGetUnixTime()
        ];
    llSetTimerEvent(((float)1));
    return loc_channel;
}

V(key llList2Key, string llToLower)
{
    integer loc_index = llListFindList(gT, (list)llList2Key);
    if (~loc_index)
    {
        gT = llDeleteSubList(gT, loc_index, loc_index);
        ResumeVoid = llDeleteSubList(ResumeVoid, loc_index, loc_index);
    }
    gT = gT + llList2Key;
    ResumeVoid = ResumeVoid + llToLower;
}

integer I(key llToLower, key llList2Key)
{
    return !(~_(llToLower) | !(0 < LslUserScript));
}

integer a(key llToLower, key llList2Key)
{
    return !!(-!(llList2Key == "00000000-0000-0000-0000-000000000000" | ~_(llToLower)) & b(llList2Key));
}

integer T(key llToLower, key llList2Key)
{
    return !(llList2Key == "00000000-0000-0000-0000-000000000000" | ~_(llToLower));
}

integer H(key llToLower, key llList2Key)
{
    return !(llList2Key == "00000000-0000-0000-0000-000000000000" | ~_(llToLower));
}

integer S(key llToLower, key llList2Key)
{
    return !(llList2Key == "00000000-0000-0000-0000-000000000000" | ~_(llToLower) & -!D(llList2Key));
}

integer K(key llToLower, key llList2Key)
{
    return !(llList2Key == "00000000-0000-0000-0000-000000000000" | ~_(llToLower));
}

integer P(key llToLower, key llList2Key)
{
    return !!(3 < (gS != []) | gS != [] == 3 & llList2Key == "00000000-0000-0000-0000-000000000000");
}

list W(string llToLower, list llList2Key)
{
    list loc_layersWorn;
    integer loc_length = llStringLength(llToLower);
    integer loc_i;
    for (; loc_i < loc_length; loc_i = -~loc_i)
    {
        if (llGetSubString(llToLower, loc_i, loc_i) == "1")
        {
            string loc_layerName = llList2String(llList2Key, loc_i);
            if (!(loc_layerName == ""))
            {
                loc_layersWorn = loc_layersWorn + loc_layerName;
            }
        }
    }
    return loc_layersWorn;
}

default
{
    link_message(integer llList2Key, integer llToLower, string llSay, key llList2List)
    {
        if (llToLower ^ ((integer)-8013))
            if (llToLower == ((integer)-830) | llToLower == ((integer)-832))
            {
                list loc_params = llParseStringKeepNulls(llSay, (list)"|", []);
                string loc_pluginName = llList2String(loc_params, 5);
                if (loc_pluginName == "npose_rlv+")
                {
                    string loc_path = llList2String(loc_params, 0);
                    integer loc_page = (integer)llList2String(loc_params, 1);
                    string loc_prompt = llList2String(loc_params, 2);
                    string loc_buttons = llList2String(loc_params, 3);
                    string loc_pluginLocalPath = llList2String(loc_params, 4);
                    string loc_pluginMenuParams = llList2String(loc_params, 6);
                    string loc_pluginActionParams = llList2String(loc_params, 7);
                    key loc_selectedVictim = B(llList2List);
                    if (llToLower ^ ((integer)-830))
                    {
                        if (llToLower == ((integer)-832))
                        {
                            list loc_buttonsList = llParseString2List(loc_buttons, (list)",", []);
                            string loc_selection = Q(loc_pluginLocalPath, ((integer)-1), ((integer)-1));
                            string loc_promptSelectedVictim = R(loc_selectedVictim);
                            string loc_promptVictimMainInfo = M(!(loc_selectedVictim == "00000000-0000-0000-0000-000000000000"), "\n" + "RLV Relay: " + M(b(loc_selectedVictim), "OK", "NOT RECOGNIZED") + "\n" + O(loc_selectedVictim), "");
                            if (loc_pluginLocalPath == "")
                            {
                                loc_prompt = loc_promptSelectedVictim + loc_promptVictimMainInfo;
                                if (I(llList2List, loc_selectedVictim))
                                {
                                    loc_buttonsList = loc_buttonsList + "→Capture";
                                }
                                if (a(llList2List, loc_selectedVictim))
                                {
                                    loc_buttonsList = loc_buttonsList + "→Restrictions";
                                }
                                if (T(llList2List, loc_selectedVictim))
                                {
                                    loc_buttonsList = loc_buttonsList + "Release";
                                }
                                if (H(llList2List, loc_selectedVictim))
                                {
                                    loc_buttonsList = loc_buttonsList + "Unsit";
                                }
                                if (S(llList2List, loc_selectedVictim))
                                {
                                    loc_buttonsList = loc_buttonsList + "→Timer";
                                }
                                if (P(llList2List, loc_selectedVictim))
                                {
                                    loc_buttonsList = loc_buttonsList + "→Victims";
                                }
                            }
                            else if (loc_pluginLocalPath == "→Capture")
                            {
                                if (!(LslUserScript == ((float)0)))
                                {
                                    V(llList2List, llSay);
                                    llSensor("", "", 1, LslUserScript, ((float)4));
                                    return;
                                }
                            }
                            else if (loc_pluginLocalPath == "→Restrictions")
                            {
                                integer loc_channel = L(llList2List, llSay);
                                llMessageLinked(((integer)-1), ((integer)-8010), "rlvCommand," + (string)loc_selectedVictim + ",@getstatus=" + (string)loc_channel, "00000000-0000-0000-0000-000000000000");
                                return;
                            }
                            else if (loc_pluginLocalPath == X((list)"→Restrictions" + "→Undress"))
                            {
                                integer loc_channel = L(llList2List, llSay);
                                llMessageLinked(((integer)-1), ((integer)-8010), "rlvCommand," + (string)loc_selectedVictim + ",@getoutfit=" + (string)loc_channel, "00000000-0000-0000-0000-000000000000");
                                return;
                            }
                            else if (loc_pluginLocalPath == X((list)"→Restrictions" + "→Attachments"))
                            {
                                integer loc_channel = L(llList2List, llSay);
                                llMessageLinked(((integer)-1), ((integer)-8010), "rlvCommand," + (string)loc_selectedVictim + ",@getattach=" + (string)loc_channel, "00000000-0000-0000-0000-000000000000");
                                return;
                            }
                            else if (-(Q(loc_pluginLocalPath, 0, 0) == "→Restrictions") & ~llListFindList(gV, (list)loc_selection))
                            {
                                integer loc_channel = L(llList2List, llSay);
                                llMessageLinked(((integer)-1), ((integer)-8010), "rlvCommand," + (string)loc_selectedVictim + ",@getstatus=" + (string)loc_channel, "00000000-0000-0000-0000-000000000000");
                                return;
                            }
                            else if (loc_pluginLocalPath == "→Timer")
                            {
                                loc_prompt = loc_prompt + ("\n" + O(loc_selectedVictim));
                                loc_buttonsList = loc_buttonsList + gZ;
                                if (K(llList2List, loc_selectedVictim))
                                {
                                    loc_buttonsList = loc_buttonsList + Pop;
                                }
                                loc_prompt = loc_promptSelectedVictim + loc_promptVictimMainInfo;
                            }
                            else if (loc_pluginLocalPath == "→Victims")
                            {
                                loc_prompt = loc_prompt + (loc_promptSelectedVictim + "\n" + "Select new active victim.");
                                integer loc_index;
                                integer loc_length = gS != [];
                                for (; loc_index < loc_length; loc_index = 3 + loc_index)
                                {
                                    key loc_avatarKey = (key)llList2String(gS, loc_index);
                                    string loc_avatarName;
                                    if (ga)
                                    {
                                        loc_avatarName = llGetDisplayName(loc_avatarKey);
                                    }
                                    else
                                    {
                                        loc_avatarName = llKey2Name(loc_avatarKey);
                                    }
                                    loc_avatarName = A(loc_avatarName);
                                    if (loc_avatarKey == loc_selectedVictim)
                                    {
                                        loc_avatarName = "⚫" + loc_avatarName + "⚫";
                                    }
                                    loc_buttonsList = loc_buttonsList + ("/*" + (string)loc_avatarKey + "*/" + loc_avatarName);
                                }
                            }
                            llMessageLinked(((integer)-1), ((integer)-833), F(loc_path, loc_page, loc_prompt, loc_buttonsList, (list)loc_pluginLocalPath + loc_pluginName + loc_pluginMenuParams + loc_pluginActionParams), llList2List);
                        }
                    }
                    else
                    {
                        string loc_pluginBasePath = N(loc_path, loc_pluginLocalPath);
                        string loc_pluginLocalPathPart0 = Q(loc_pluginLocalPath, 0, 0);
                        string loc_pluginLocalPathPart1 = Q(loc_pluginLocalPath, 1, 1);
                        string loc_pluginLocalPathPart2 = Q(loc_pluginLocalPath, 2, 2);
                        integer loc_pipeActionThroughCore;
                        if (!(loc_pluginLocalPath == ""))
                            if (loc_pluginLocalPath == "Unsit")
                            {
                                if (H(llList2List, loc_selectedVictim))
                                {
                                    if (loc_selectedVictim)
                                    {
                                        llMessageLinked(((integer)-1), ((integer)-8010), "unsit," + (string)loc_selectedVictim, "00000000-0000-0000-0000-000000000000");
                                        loc_pipeActionThroughCore = 1;
                                    }
                                }
                                loc_path = loc_pluginBasePath;
                            }
                            else if (loc_pluginLocalPath == "Release")
                            {
                                if (T(llList2List, loc_selectedVictim))
                                {
                                    if (loc_selectedVictim)
                                    {
                                        llMessageLinked(((integer)-1), ((integer)-8010), "release," + (string)loc_selectedVictim, "00000000-0000-0000-0000-000000000000");
                                        loc_pipeActionThroughCore = 1;
                                    }
                                }
                                loc_path = loc_pluginBasePath;
                            }
                            else if (loc_pluginLocalPathPart0 == "→Capture")
                            {
                                if (I(llList2List, loc_selectedVictim))
                                {
                                    if (!(loc_pluginLocalPathPart1 == ""))
                                    {
                                        key loc_avatarToCapture = (key)U(loc_pluginLocalPathPart1);
                                        if (loc_avatarToCapture)
                                        {
                                            llMessageLinked(((integer)-1), ((integer)-8010), "grab," + (string)loc_avatarToCapture, "00000000-0000-0000-0000-000000000000");
                                            loc_pipeActionThroughCore = 1;
                                            llSleep(((float)2));
                                        }
                                        loc_path = loc_pluginBasePath;
                                    }
                                }
                                else
                                {
                                    loc_path = loc_pluginBasePath;
                                }
                            }
                            else if (loc_pluginLocalPathPart0 == "→Restrictions")
                            {
                                if (a(llList2List, loc_selectedVictim))
                                {
                                    if (!(loc_pluginLocalPathPart2 == ""))
                                    {
                                        if (~llListFindList(LslLibrary, (list)loc_pluginLocalPathPart2))
                                        {
                                            llMessageLinked(((integer)-1), ((integer)-8010), "rlvCommand," + (string)loc_selectedVictim + ",@remattach:" + loc_pluginLocalPathPart2 + "=force", "00000000-0000-0000-0000-000000000000");
                                        }
                                        else if (~llListFindList(gU, (list)loc_pluginLocalPathPart2))
                                        {
                                            llMessageLinked(((integer)-1), ((integer)-8010), "rlvCommand," + (string)loc_selectedVictim + ",@remoutfit:" + loc_pluginLocalPathPart2 + "=force", "00000000-0000-0000-0000-000000000000");
                                        }
                                        else if (llGetSubString(loc_pluginLocalPathPart2, 0, 0) == "☐")
                                        {
                                            llMessageLinked(((integer)-1), ((integer)-8010), "rlvCommand," + (string)loc_selectedVictim + ",@" + llStringTrim(llDeleteSubString(loc_pluginLocalPathPart2, 0, 1), 3) + "=n", "00000000-0000-0000-0000-000000000000");
                                        }
                                        else if (llGetSubString(loc_pluginLocalPathPart2, 0, 0) == "☑")
                                        {
                                            llMessageLinked(((integer)-1), ((integer)-8010), "rlvCommand," + (string)loc_selectedVictim + ",@" + llStringTrim(llDeleteSubString(loc_pluginLocalPathPart2, 0, 1), 3) + "=y", "00000000-0000-0000-0000-000000000000");
                                        }
                                        llSleep(((float)2));
                                        loc_path = J(loc_path, ((integer)-1), ((integer)-1));
                                    }
                                }
                                else
                                {
                                    loc_path = loc_pluginBasePath;
                                }
                            }
                            else if (loc_pluginLocalPathPart0 == "→Victims")
                            {
                                if (P(llList2List, loc_selectedVictim))
                                {
                                    if (!(loc_pluginLocalPathPart1 == ""))
                                    {
                                        key loc_avatarToSelect = (key)U(loc_pluginLocalPathPart1);
                                        Y(llList2List, loc_avatarToSelect);
                                        loc_path = loc_pluginBasePath;
                                    }
                                }
                                else
                                {
                                    loc_path = loc_pluginBasePath;
                                }
                            }
                            else if (loc_pluginLocalPathPart0 == "→Timer")
                            {
                                if (S(llList2List, loc_selectedVictim))
                                {
                                    if (!(loc_pluginLocalPathPart1 == ""))
                                    {
                                        integer loc_time = (integer)U(loc_pluginLocalPathPart1);
                                        if (0 < loc_time | K(llList2List, loc_selectedVictim))
                                        {
                                            if (loc_time)
                                            {
                                                C(loc_selectedVictim, loc_time);
                                            }
                                            else
                                            {
                                                Z(loc_selectedVictim, 0);
                                            }
                                        }
                                        loc_path = X((list)loc_pluginBasePath + "→Timer");
                                    }
                                }
                                else
                                {
                                    loc_path = loc_pluginBasePath;
                                }
                            }
                            else
                            {
                                loc_path = loc_pluginBasePath;
                            }
                        string loc_paramSet1 = F(loc_path, loc_page, loc_prompt, (list)loc_buttons, (list)loc_pluginLocalPath + loc_pluginName + loc_pluginMenuParams + loc_pluginActionParams);
                        if (loc_pipeActionThroughCore)
                        {
                            llMessageLinked(((integer)-1), ((integer)-8016), loc_paramSet1, llList2List);
                        }
                        else
                        {
                            llMessageLinked(((integer)-1), ((integer)-831), loc_paramSet1, llList2List);
                        }
                    }
                }
            }
            else if (llToLower ^ ((integer)-240))
            {
                if (llToLower == 34334)
                {
                    llSay(0, "Memory Used by " + llGetScriptName() + ": " + (string)llGetUsedMemory() + " of " + (string)llGetMemoryLimit() + ", Leaving " + (string)llGetFreeMemory() + " memory free.");
                }
            }
            else
            {
                list loc_optionsToSet = llParseStringKeepNulls(llSay, (list)"~" + "|", []);
                integer loc_length = loc_optionsToSet != [];
                integer loc_index;
                for (; loc_index < loc_length; ++loc_index)
                {
                    list loc_optionsItems = llParseString2List(llList2String(loc_optionsToSet, loc_index), (list)"=", []);
                    string loc_optionItem = llToLower(llStringTrim(llList2String(loc_optionsItems, 0), 3));
                    string loc_optionString = llList2String(loc_optionsItems, 1);
                    string loc_optionSetting = llToLower(llStringTrim(loc_optionString, 3));
                    integer loc_optionSettingFlag = !!(loc_optionSetting == "on" | (integer)loc_optionSetting);
                    if (loc_optionItem == "rlv_grabrange")
                    {
                        LslUserScript = (float)loc_optionSetting;
                    }
                    if (loc_optionItem == "usedisplaynames")
                    {
                        ga = loc_optionSettingFlag;
                    }
                }
            }
        else
        {
            gS = llCSV2List(llSay);
        }
    }

    listen(integer llSay, string llList2Key, key llList2List, string llToLower)
    {
        integer loc_indexUsersList;
        string loc_prompt;
        list loc_buttons;
        if (~(loc_indexUsersList = llListFindList(gR, (list)llSay)))
        {
            key loc_menuUser = llList2Key(gR, -~-~loc_indexUsersList);
            list loc_menuParams = llParseStringKeepNulls(llList2String(gR, 3 + loc_indexUsersList), (list)"|", []);
            E(loc_indexUsersList);
            string loc_localPath = llList2String(loc_menuParams, 4);
            string loc_selection = Q(loc_localPath, ((integer)-1), ((integer)-1));
            integer loc_restrictionsListIndex = llListFindList(gV, (list)loc_selection);
            if (loc_localPath == "→Restrictions" | ~loc_restrictionsListIndex)
            {
                list loc_activeRestrictions = llParseString2List(llToLower, (list)"/", []);
                integer loc_index;
                integer loc_length = loc_activeRestrictions != [];
                for (; loc_index < loc_length; ++loc_index)
                {
                    string loc_restrictionWorkingOn = llList2String(loc_activeRestrictions, loc_index);
                    if (~llSubStringIndex(loc_restrictionWorkingOn, ":") | ~llListFindList((list)"acceptpermission" + "detach", (list)loc_restrictionWorkingOn))
                    {
                        loc_activeRestrictions = llDeleteSubList(loc_activeRestrictions, loc_index, loc_index);
                        --loc_index;
                        --loc_length;
                    }
                }
                loc_prompt = R(B(loc_menuUser)) + "\n" + "\n";
                loc_prompt = loc_prompt + ("Active restrictions are: " + M(loc_activeRestrictions != [], "\n" + llDumpList2String(loc_activeRestrictions, ", "), "NONE. Victim may be FREE."));
                if (loc_localPath == "→Restrictions")
                {
                    loc_buttons = (list)"→Undress" + "→Attachments";
                    loc_length = gV != [];
                    for (loc_index = 0; loc_index < loc_length; loc_index = -~-~loc_index)
                    {
                        loc_buttons = loc_buttons + llList2String(gV, loc_index);
                    }
                }
                else
                {
                    loc_prompt = loc_prompt + ("\n" + "\n" + "☑ ... set restriction active" + "\n" + "☐ ... set restriction inactive" + "\n" + "(Maybe not all retrictions can't be set inactive)");
                    list loc_availibleRestrictions = llCSV2List(llList2String(gV, -~loc_restrictionsListIndex));
                    loc_length = loc_availibleRestrictions != [];
                    for (loc_index = 0; loc_index < loc_length; ++loc_index)
                    {
                        string loc_restrictionWorkingOn = llList2String(loc_availibleRestrictions, loc_index);
                        if (~llListFindList(loc_activeRestrictions, (list)loc_restrictionWorkingOn))
                        {
                            loc_buttons = loc_buttons + ("☑ " + loc_restrictionWorkingOn);
                        }
                        else
                        {
                            loc_buttons = loc_buttons + ("☐ " + loc_restrictionWorkingOn);
                        }
                    }
                }
            }
            else if (loc_localPath == X((list)"→Restrictions" + "→Attachments"))
            {
                loc_buttons = W(llToLower, LslLibrary);
                loc_prompt = "\n" + "The following attachment points are worn:" + "\n" + llDumpList2String(loc_buttons, ", ") + "\n" + "\n" + "Click a button to try to detach this attachment" + "\n" + "(Beware some might be locked and can't be removed)";
            }
            else if (loc_localPath == X((list)"→Restrictions" + "→Undress"))
            {
                loc_buttons = W(llToLower, gU);
                loc_prompt = "\n" + "The following clothing layers are worn:" + "\n" + llDumpList2String(loc_buttons, ", ") + "\n" + "\n" + "Click a button to try to detach this layer" + "\n" + "(Beware some might be locked and can't be removed)";
            }
            llMessageLinked(((integer)-1), ((integer)-833), F(llList2String(loc_menuParams, 0), 0, loc_prompt, loc_buttons, llList2List(loc_menuParams, 4, ((integer)-1))), loc_menuUser);
        }
    }

    sensor(integer llToLower)
    {
        list loc_sensorList;
        integer loc_index;
        for (; loc_index < llToLower; ++loc_index)
        {
            key loc_avatar = llDetectedKey(loc_index);
            if (!~_(loc_avatar))
            {
                string loc_prefix = "/*" + (string)loc_avatar + "*/";
                if (ga)
                {
                    loc_sensorList = loc_sensorList + (loc_prefix + A(llGetDisplayName(loc_avatar)));
                }
                else
                {
                    loc_sensorList = loc_sensorList + (loc_prefix + A(llKey2Name(loc_avatar)));
                }
            }
        }
        integer loc_length = gT != [];
        for (loc_index = 0; loc_index < loc_length; ++loc_index)
        {
            list loc_params = llParseStringKeepNulls(llList2String(ResumeVoid, loc_index), (list)"|", []);
            llMessageLinked(((integer)-1), ((integer)-833), F(llList2String(loc_params, 0), 0, "Choose someone to capture.", loc_sensorList, llList2List(loc_params, 4, ((integer)-1))), llList2Key(gT, loc_index));
        }
        gT = [];
        ResumeVoid = [];
    }

    no_sensor()
    {
        integer loc_length = gT != [];
        integer loc_index;
        for (; loc_index < loc_length; ++loc_index)
        {
            list loc_params = llParseStringKeepNulls(llList2String(ResumeVoid, loc_index), (list)"|", []);
            llMessageLinked(((integer)-1), ((integer)-833), F(llList2String(loc_params, 0), 0, "There seems to be no one in range to cpature.", [], llList2List(loc_params, 4, ((integer)-1))), llList2Key(gT, loc_index));
        }
        gT = [];
        ResumeVoid = [];
    }

    timer()
    {
        integer loc_length = gR != [];
        integer loc_index;
        integer loc_currentTime = llGetUnixTime();
        for (; loc_index < loc_length; loc_index = 5 + loc_index)
        {
            if (llList2Integer(gR, 4 + loc_index) < loc_currentTime)
            {
                E(loc_index);
                loc_index = ((integer)-5) + loc_index;
                loc_length = ((integer)-5) + loc_length;
            }
        }
    }

    on_rez(integer llToLower)
    {
        llResetScript();
    }
}

