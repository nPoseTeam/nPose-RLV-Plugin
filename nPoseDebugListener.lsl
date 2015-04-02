// LSL script generated - patched Render.hs (0.1.6.2): RLV+.nPose-RLV-Plugin.nPoseDebugListener.lslp Thu Apr  2 22:55:29 Mitteleuropäische Sommerzeit 2015


debug(list message){
    llOwnerSay(llGetScriptName() + "\n#>" + llDumpList2String(message,"\n#>"));
}

default {

	link_message(integer sender_num,integer num,string str,key id) {
        if (num == 35353) {
            debug(["SEAT_UPDATE"] + llParseStringKeepNulls(str,["^"],[]));
        }
    }
}
