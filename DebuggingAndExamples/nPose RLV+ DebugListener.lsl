// LSL script generated - patched Render.hs (0.1.6.2): DebuggingAndExamples.nPose RLV+ DebugListener.lslp Wed Apr 22 13:04:42 Mitteleuropäische Sommerzeit 2015


debug(list message){
    llOwnerSay(llGetScriptName() + "\n#>" + llDumpList2String(message,"\n#>"));
}

default {

	state_entry() {
        llListen(0,"",llGetOwner(),"");
    }


	link_message(integer sender_num,integer num,string str,key id) {
        if (num == -237) {
            debug(["CHANGE_SELECTED_VICTIM",str]);
        }
        else  if (num == -238) {
            debug(["UPDATE_VICTIMS_LIST",str]);
        }
        else  if (num == -800) {
            debug(["DOMENU",str,(string)id]);
        }
        else  if (num == -900) {
            debug(["DIALOG",str,(string)id]);
        }
        else  if (num == -8000) {
            debug(["RLV_MENU_COMMAND",str]);
        }
        else  if (num == -8010) {
            debug(["RLV_CORE_COMMAND",str]);
        }
        else  if (num == -240) {
            debug(["OPTIONS",str]);
        }
        else  if (num == -901) {
            debug(["DIALOG_RESPONSE",str,(string)id]);
        }
        else  if (num == 34334) {
            debug(["MEM_USAGE",str]);
        }
        else  if (num == 35353) {
            debug(["SEAT_UPDATE",str]);
        }
    }

	listen(integer channel,string name,key id,string message) {
        integer num;
        if (llGetSubString(message,0,0) == "m") {
            num = -8008;
        }
        else  if (llGetSubString(message,0,0) == "c") {
            num = -8018;
        }
        if (num) {
            llMessageLinked(-1,num,llGetSubString(message,1,-1),"");
        }
    }
}
