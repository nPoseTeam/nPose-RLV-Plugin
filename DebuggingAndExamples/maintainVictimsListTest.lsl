// LSL script generated - patched Render.hs (0.1.6.2): RLV+.nPose-RLV-Plugin.DebuggingAndExamples.maintainVictimsListTest.lslp Sat Apr  4 09:26:30 Mitteleuropäische Sommerzeit 2015


list victimsList;

default {

	link_message(integer sender_num,integer num,string str,key id) {
        if (num == -8001) {
            key avatarWorkingOn = (key)llList2String(llCSV2List(str),0);
            if (!~llListFindList(victimsList,[avatarWorkingOn])) {
                victimsList += avatarWorkingOn;
            }
        }
        else  if (num == -8002) {
            key avatarWorkingOn = (key)str;
            integer index = llListFindList(victimsList,[avatarWorkingOn]);
            if (~index) {
                victimsList = llDeleteSubList(victimsList,index,index);
            }
        }
    }

	touch_start(integer num_detected) {
        llWhisper(0,llGetScriptName() + "\n#>" + llDumpList2String(victimsList,"\n#>"));
    }
}
