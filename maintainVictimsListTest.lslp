integer RLV_VICTIM_ADDED=-8001;
integer RLV_VICTIM_REMOVED=-8002;

list victimsList;

default {
	link_message(integer sender_num, integer num, string str, key id) {
		if(num==RLV_VICTIM_ADDED) {
			key avatarWorkingOn=(key)llList2String(llCSV2List(str), 0);
			if(!~llListFindList(victimsList, [avatarWorkingOn])) {
				victimsList+=avatarWorkingOn;
			}
		}
		else if(num==RLV_VICTIM_REMOVED) {
			key avatarWorkingOn=(key)str;
			integer index=llListFindList(victimsList, [avatarWorkingOn]);
			if(~index) {
				victimsList=llDeleteSubList(victimsList, index, index);
			}
		}
	}
	touch_start(integer num_detected) {
		llWhisper(0, llGetScriptName() + "\n#>" + llDumpList2String(victimsList, "\n#>"));
	}
}
