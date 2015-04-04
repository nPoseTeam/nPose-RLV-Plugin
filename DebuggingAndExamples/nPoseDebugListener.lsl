// LSL script generated - patched Render.hs (0.1.6.2): RLV+.nPose-RLV-Plugin.DebuggingAndExamples.nPoseDebugListener.lslp Sat Apr  4 09:26:30 Mitteleuropäische Sommerzeit 2015


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
