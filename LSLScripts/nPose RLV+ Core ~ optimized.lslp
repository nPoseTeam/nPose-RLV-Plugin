integer ResumeVoid;
integer gd;
integer LslUserScript;
list gZ = ["*"];
integer gU = 60;
key IsSaveDue;
list gT;
list ga;
list System;
list gc;
list gf;
list edefaultcollision_start;
integer Pop;
integer ge;
list gg;
string LslLibrary = "@unsit=n|@sittp=n|@tploc=n|@tplure=n|@tplm=n|@acceptpermission=add|@editobj:%MYKEY%=add";
integer gV;

integer M(key llToLower)
{
    return llListFindList(edefaultcollision_start, (list)llToLower);
}

Y()
{
    integer loc_currentTime = llGetUnixTime();
    integer loc_length = edefaultcollision_start != [];
    integer loc_index;
    for (; loc_index < loc_length; loc_index = -~-~loc_index)
    {
        integer loc_timeout = llList2Integer(edefaultcollision_start, -~loc_index);
        if (loc_timeout & -(loc_timeout < loc_currentTime))
        {
            edefaultcollision_start = llDeleteSubList(edefaultcollision_start, loc_index, -~loc_index);
            loc_index = ~-~-loc_index;
            loc_length = ~-~-loc_length;
        }
    }
}

B(key llToLower)
{
    integer loc_index = M(llToLower);
    if (~loc_index)
    {
        edefaultcollision_start = llDeleteSubList(edefaultcollision_start, loc_index, -~loc_index);
    }
}

S(key llToLower)
{
    K(llToLower);
    if (gU)
    {
        edefaultcollision_start = edefaultcollision_start + llToLower + (llGetUnixTime() + gU);
    }
}

R(list llToLower)
{
    llOwnerSay(llGetScriptName() + "\n##########\n#>" + llDumpList2String(llToLower, "\n#>") + "\n##########");
}

string N(string llGetOwnerKey, string llToLower, string gb)
{
    return llDumpList2String(llParseStringKeepNulls(llGetOwnerKey, (list)llToLower, []), gb);
}

integer A(key llToLower)
{
    return llListFindList(gT, (list)llToLower);
}

integer F(key llToLower)
{
    return llListFindList(ga, (list)llToLower);
}

integer f(key llToLower)
{
    return llListFindList(System, (list)llToLower);
}

integer P(key llToLower)
{
    return llListFindList(gc, (list)llToLower);
}

integer G(key llToLower)
{
    return llListFindList(gf, (list)llToLower);
}

_()
{
    llMessageLinked(((integer)-1), ((integer)-8013), llList2CSV(gT), "");
    llMessageLinked(((integer)-1), 220, "UDPLIST|" + "victim" + "=" + (string)llList2ListStrided(gT, 0, ((integer)-1), 3), "");
}

d(key llToLower, integer llGetOwnerKey)
{
    K(llToLower);
    if (0 < llGetOwnerKey)
    {
        llGetOwnerKey = llGetOwnerKey + llGetUnixTime();
    }
    else if (llGetOwnerKey < 0)
    {
        llGetOwnerKey = 0;
    }
    gT = gT + llToLower + llGetOwnerKey + 0;
    _();
    E(llToLower, "!version" + "|" + LslLibrary, "");
    if (!gV)
    {
        llSetTimerEvent(((float)1));
        gV = 1;
    }
}

T(key llToLower)
{
    integer loc_isChanged;
    integer loc_index;
    while (~(loc_index = A(llToLower)))
    {
        gT = llDeleteSubList(gT, loc_index, ~-(3 + loc_index));
        loc_isChanged = 1;
    }
    if (loc_isChanged)
    {
        _();
        if (-(gT == []) & gV)
        {
            llSetTimerEvent(((float)0));
            gV = 0;
        }
    }
}

X(key llToLower)
{
    K(llToLower);
    System = System + llToLower;
}

e(key llToLower)
{
    integer loc_index;
    while (~(loc_index = f(llToLower)))
    {
        System = llDeleteSubList(System, loc_index, loc_index);
    }
}

D(key llToLower)
{
    K(llToLower);
    ga = ga + llToLower;
}

a(key llToLower)
{
    integer loc_index;
    while (~(loc_index = F(llToLower)))
    {
        ga = llDeleteSubList(ga, loc_index, loc_index);
    }
}

U(key llToLower)
{
    K(llToLower);
    gc = gc + llToLower + (60 + llGetUnixTime());
    while (6 < (gc != []))
    {
        gc = llList2List(gc, 2, ((integer)-1));
    }
}

Q(key llToLower)
{
    integer loc_index;
    while (~(loc_index = P(llToLower)))
    {
        gc = llDeleteSubList(gc, loc_index, -~loc_index);
    }
}

Z()
{
    integer loc_currentTime = llGetUnixTime();
    integer loc_length = gc != [];
    integer loc_index;
    for (; loc_index < loc_length; loc_index = -~-~loc_index)
    {
        integer loc_timeout = llList2Integer(gc, -~loc_index);
        if (loc_timeout < loc_currentTime)
        {
            gc = llDeleteSubList(gc, loc_index, -~loc_index);
            loc_index = ~-~-loc_index;
            loc_length = ~-~-loc_length;
        }
    }
}

I(key llToLower, integer llGetOwnerKey)
{
    K(llToLower);
    H();
    if (llGetOwnerKey < 0)
    {
        llGetOwnerKey = 0;
    }
    gf = gf + llToLower + llGetOwnerKey + 0;
    while (15 < (gf != []))
    {
        gf = llList2List(gf, 3, ((integer)-1));
    }
}

V(key llToLower)
{
    integer loc_index;
    while (~(loc_index = G(llToLower)))
    {
        gf = llDeleteSubList(gf, loc_index, ~-(3 + loc_index));
    }
}

H()
{
    integer loc_currentTime = llGetUnixTime();
    integer loc_length = gf != [];
    integer loc_index;
    for (; loc_index < loc_length; loc_index = 3 + loc_index)
    {
        integer loc_timeout = llList2Integer(gf, -~-~loc_index);
        if (loc_timeout & -(loc_timeout < loc_currentTime))
        {
            gf = llDeleteSubList(gf, loc_index, ~-(3 + loc_index));
            loc_index = ((integer)-3) + loc_index;
            loc_length = ((integer)-3) + loc_length;
        }
    }
}

K(key llToLower)
{
    T(llToLower);
    a(llToLower);
    e(llToLower);
    Q(llToLower);
    V(llToLower);
    B(llToLower);
}

E(key gb, string llToLower, string llGetOwnerKey)
{
    if (!(llToLower == ""))
    {
        if (gb)
        {
            llSay(((integer)-1812221819), b(llStringLength(llGetOwnerKey), llGetOwnerKey, (string)IsSaveDue) + "," + (string)gb + "," + N(llToLower, "%MYKEY%", (string)llGetKey()));
        }
    }
}

c(key llToLower, integer llGetOwnerKey)
{
    integer loc_index = A(llToLower);
    if (~loc_index)
    {
        gT = llListReplaceList(gT, (list)llGetOwnerKey, -~loc_index, -~loc_index);
        llMessageLinked(((integer)-1), ((integer)-8013), llList2CSV(gT), "");
    }
}

string b(integer llToLower, string llGetOwnerKey, string gb)
{
    string loc_ret = gb;
    if (llToLower)
    {
        loc_ret = llGetOwnerKey;
    }
    return loc_ret;
}

integer g(key llToLower)
{
    integer loc_relayVersion;
    integer loc_index = A(llToLower);
    if (~loc_index)
    {
        loc_relayVersion = llList2Integer(gT, -~-~loc_index);
    }
    return loc_relayVersion;
}

O(key llToLower, integer llGetOwnerKey)
{
    integer loc_index = A(llToLower);
    if (~loc_index)
    {
        gT = llListReplaceList(gT, (list)llGetOwnerKey, -~-~loc_index, -~-~loc_index);
        llMessageLinked(((integer)-1), ((integer)-8013), llList2CSV(gT), "");
    }
}

L(key llToLower)
{
    if (~A(llToLower))
    {
        D(llToLower);
    }
    E(llToLower, "!release", "");
}

J(key llToLower)
{
    L(llToLower);
    llSleep(1.5);
    llUnSit(llToLower);
}

C(key llToLower)
{
    if (~A(llToLower))
    {
        E(llToLower, LslLibrary, "");
    }
    else if (~F(llToLower))
    {
        d(llToLower, gd);
    }
    else if (!~f(llToLower))
    {
        U(llToLower);
        E(llToLower, "@sit:" + (string)llGetKey() + "=force", "");
    }
}

integer W(key llToLower)
{
    Y();
    if (!(llGetAgentSize(llToLower) == <((float)0), ((float)0), ((float)0)>))
    {
        if (Pop)
        {
            if (!(~A(llToLower) | ~F(llToLower) | ~f(llToLower) | ~P(llToLower) | ~G(llToLower) | ~M(llToLower)))
            {
                E(llToLower, "@sit:" + (string)llGetKey() + "=force", "");
                S(llToLower);
                return 1;
            }
        }
    }
    return 0;
}

default
{
    state_entry()
    {
        llListen(((integer)-1812221819), "", "", "");
        IsSaveDue = llGenerateKey();
    }

    link_message(integer llGetOwnerKey, integer llToLower, string gb, key llSay)
    {
        if (llToLower ^ ((integer)-8010))
            if (llToLower ^ 225)
                if (llToLower ^ 251)
                    if (llToLower ^ ((integer)-8016))
                        if (llToLower ^ ((integer)-8017))
                            if (llToLower ^ ((integer)-240))
                                if (llToLower ^ 34334)
                                {
                                    if (llToLower == ((integer)-8018))
                                    {
                                        if (gb == "l")
                                        {
                                            R("VictimsList" + gT + "####" + "FreeVictimsList" + ga + "####" + "DomList" + System + "####" + "GrabList" + gc + "####" + "RecaptureList" + gf + "####" + "TrapIgnoreList" + edefaultcollision_start);
                                        }
                                        else if (gb == "o")
                                        {
                                            R((list)"RLV_trapTimer" + ResumeVoid + "####" + "RLV_grabTimer" + gd + "####" + "RLV_collisionTrap" + LslUserScript + "####" + "RLV_enabledSeats" + gZ);
                                        }
                                    }
                                }
                                else
                                {
                                    llSay(0, "Memory Used by " + llGetScriptName() + ": " + (string)llGetUsedMemory() + " of " + (string)llGetMemoryLimit() + ", Leaving " + (string)llGetFreeMemory() + " memory free.");
                                }
                            else
                            {
                                list loc_optionsToSet = llParseStringKeepNulls(gb, (list)"~" + "|", []);
                                integer loc_length = loc_optionsToSet != [];
                                integer loc_index;
                                for (; loc_index < loc_length; ++loc_index)
                                {
                                    list loc_optionsItems = llParseString2List(llList2String(loc_optionsToSet, loc_index), (list)"=", []);
                                    string loc_optionItem = llToLower(llStringTrim(llList2String(loc_optionsItems, 0), 3));
                                    string loc_optionString = llList2String(loc_optionsItems, 1);
                                    string loc_optionSetting = llToLower(llStringTrim(loc_optionString, 3));
                                    integer loc_optionSettingFlag = !!(loc_optionSetting == "on" | (integer)loc_optionSetting);
                                    if (loc_optionItem == "rlv_grabtimer")
                                    {
                                        gd = (integer)loc_optionSetting;
                                    }
                                    else if (loc_optionItem == "rlv_traptimer")
                                    {
                                        ResumeVoid = (integer)loc_optionSetting;
                                    }
                                    else if (loc_optionItem == "rlv_enabledseats")
                                    {
                                        gZ = llParseString2List(loc_optionSetting, (list)"/" + "~", []);
                                    }
                                    else if (loc_optionItem == "rlv_collisiontrap")
                                    {
                                        LslUserScript = loc_optionSettingFlag;
                                    }
                                    else if (loc_optionItem == "rlv_cooldowntimer")
                                    {
                                        gU = (integer)loc_optionSetting;
                                    }
                                    else if (loc_optionItem == "rlv_traprange")
                                    {
                                        if ((float)loc_optionSetting == ((float)0))
                                        {
                                            llSensorRemove();
                                        }
                                        else
                                        {
                                            llSensorRepeat("", "", 1, (float)loc_optionSetting, ((float)4), 3);
                                        }
                                    }
                                }
                            }
                        else
                        {
                            llMessageLinked(((integer)-1), ((integer)-833), gb, llSay);
                        }
                    else
                    {
                        llMessageLinked(((integer)-1), ((integer)-831), gb, llSay);
                    }
                else
                {
                    H();
                    Z();
                    Y();
                    ge = 0;
                    Pop = 0;
                    gg = llParseStringKeepNulls(gb, (list)"^", []);
                    gb = "";
                    integer loc_slotsStride = (integer)llList2String(gg, 0);
                    integer loc_preambleLength = (integer)llList2String(gg, 1);
                    gg = llDeleteSubList(gg, 0, ~-loc_preambleLength);
                    integer loc_length = gg != [];
                    integer loc_index;
                    for (; loc_index < loc_length; loc_index = loc_index + loc_slotsStride)
                    {
                        key loc_avatarWorkingOn = (key)llList2String(gg, 8 + loc_index);
                        B(loc_avatarWorkingOn);
                        integer loc_seatNumber = -~(loc_index / loc_slotsStride);
                        integer loc_isRlvEnabledSeat = !!(~llListFindList(gZ, (list)"*") | ~llListFindList(gZ, (list)((string)loc_seatNumber)));
                        if (loc_avatarWorkingOn)
                        {
                            if (loc_isRlvEnabledSeat)
                            {
                                if (!~A(loc_avatarWorkingOn))
                                {
                                    if (~P(loc_avatarWorkingOn))
                                    {
                                        d(loc_avatarWorkingOn, gd);
                                    }
                                    else if (~G(loc_avatarWorkingOn))
                                    {
                                        d(loc_avatarWorkingOn, llList2Integer(gf, -~G(loc_avatarWorkingOn)));
                                    }
                                    else if (!~F(loc_avatarWorkingOn))
                                        if (~f(loc_avatarWorkingOn))
                                        {
                                            D(loc_avatarWorkingOn);
                                        }
                                        else
                                        {
                                            d(loc_avatarWorkingOn, ResumeVoid);
                                        }
                                }
                            }
                            else
                            {
                                if (~A(loc_avatarWorkingOn) | ~G(loc_avatarWorkingOn))
                                {
                                    E(loc_avatarWorkingOn, "!release", "");
                                }
                                X(loc_avatarWorkingOn);
                            }
                        }
                        else
                        {
                            if (loc_isRlvEnabledSeat)
                            {
                                ++Pop;
                            }
                            else
                            {
                                ++ge;
                            }
                        }
                    }
                    list loc_tempList;
                    loc_tempList = ga;
                    loc_length = loc_tempList != [];
                    loc_index = 0;
                    for (; loc_index < loc_length; loc_index = -~loc_index)
                    {
                        key loc_avatarWorkingOn = llList2Key(loc_tempList, loc_index);
                        if (!~llListFindList(gg, (list)((string)loc_avatarWorkingOn)))
                        {
                            S(loc_avatarWorkingOn);
                        }
                    }
                    loc_tempList = System;
                    loc_length = loc_tempList != [];
                    loc_index = 0;
                    for (; loc_index < loc_length; loc_index = -~loc_index)
                    {
                        key loc_avatarWorkingOn = llList2Key(loc_tempList, loc_index);
                        if (!~llListFindList(gg, (list)((string)loc_avatarWorkingOn)))
                        {
                            S(loc_avatarWorkingOn);
                        }
                    }
                    loc_tempList = gT;
                    loc_length = loc_tempList != [];
                    loc_index = 0;
                    for (; loc_index < loc_length; loc_index = 3 + loc_index)
                    {
                        key loc_avatarWorkingOn = llList2Key(loc_tempList, loc_index);
                        if (!~llListFindList(gg, (list)((string)loc_avatarWorkingOn)))
                        {
                            if (g(loc_avatarWorkingOn))
                            {
                                I(loc_avatarWorkingOn, llList2Integer(loc_tempList, -~loc_index) + -llGetUnixTime());
                            }
                            else
                            {
                                S(loc_avatarWorkingOn);
                            }
                        }
                    }
                }
            else
            {
                if (llSay == IsSaveDue)
                {
                    gb = (string)llList2List(llParseStringKeepNulls(gb, (list)"%&§", []), 3, ((integer)-1));
                    LslLibrary = N(gb, "/", "|");
                }
            }
        else
        {
            list loc_temp = llParseStringKeepNulls(gb, (list)",", []);
            string loc_cmd = llToLower(llStringTrim(llList2String(loc_temp, 0), 3));
            key loc_target = (key)llStringTrim(llList2String(loc_temp, 1), 3);
            list loc_params = llDeleteSubList(loc_temp, 0, 1);
            if (loc_target)
            {
                if (loc_cmd == "rlvcommand")
                {
                    E(loc_target, N(llList2String(loc_params, 0), "/", "|"), "");
                }
                else if (loc_cmd == "release")
                {
                    L(loc_target);
                }
                else if (loc_cmd == "unsit")
                {
                    J(loc_target);
                }
                else if (loc_cmd == "settimer")
                {
                    c(loc_target, (integer)llList2String(loc_params, 0));
                }
                else if (loc_cmd == "grab")
                {
                    C(loc_target);
                }
                else if (loc_cmd == "trap")
                {
                    W(loc_target);
                }
            }
            if (loc_cmd == "read")
            {
                llMessageLinked(((integer)-1), 224, llList2String(loc_params, 0), IsSaveDue);
            }
        }
    }

    listen(integer gb, string llGetOwnerKey, key llSay, string llToLower)
    {
        if (gb == ((integer)-1812221819))
        {
            list loc_messageParts = llParseStringKeepNulls(llToLower, (list)",", []);
            if ((key)llList2String(loc_messageParts, 1) == llGetKey())
            {
                string loc_cmd_name = llList2String(loc_messageParts, 0);
                string loc_command = llList2String(loc_messageParts, 2);
                string loc_reply = llList2String(loc_messageParts, 3);
                key loc_senderAvatarId = llGetOwnerKey(llSay);
                if (loc_command == "!version")
                {
                    O(loc_senderAvatarId, (integer)loc_reply);
                }
                else if (loc_command == "!release")
                {
                    if (loc_reply == "ok")
                    {
                        if (~A(loc_senderAvatarId))
                        {
                            D(loc_senderAvatarId);
                        }
                        Q(loc_senderAvatarId);
                        V(loc_senderAvatarId);
                    }
                }
                else if (loc_command == "ping")
                {
                    if (loc_cmd_name == loc_command & loc_reply == loc_command)
                    {
                        H();
                        integer loc_index = G(loc_senderAvatarId);
                        if (~loc_index)
                        {
                            if (Pop)
                            {
                                gf = llListReplaceList(gf, (list)(60 + llGetUnixTime()), -~-~loc_index, -~-~loc_index);
                                llSay(((integer)-1812221819), "ping" + "," + (string)loc_senderAvatarId + "," + "!pong");
                            }
                            else
                            {
                                V(loc_senderAvatarId);
                            }
                        }
                    }
                }
            }
        }
    }

    collision_start(integer llToLower)
    {
        if (LslUserScript)
        {
            W(llDetectedKey(0));
        }
    }

    sensor(integer llToLower)
    {
        integer loc_index;
        for (; loc_index < llToLower; ++loc_index)
        {
            if (W(llDetectedKey(loc_index)))
            {
                return;
            }
        }
    }

    timer()
    {
        integer loc_currentTime = llGetUnixTime();
        list loc_tempList = gT;
        integer loc_length = loc_tempList != [];
        integer loc_index;
        for (; loc_index < loc_length; loc_index = 3 + loc_index)
        {
            integer loc_time = llList2Integer(loc_tempList, -~loc_index);
            if (loc_time & -!(loc_currentTime < loc_time))
            {
                llMessageLinked(((integer)-1), ((integer)-8010), "release" + ("," + (string)llList2Key(loc_tempList, loc_index)), "00000000-0000-0000-0000-000000000000");
            }
        }
    }

    on_rez(integer llToLower)
    {
        llResetScript();
    }
}

