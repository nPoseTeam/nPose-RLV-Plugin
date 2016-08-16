$import LSLScripts.constantsRlvPlugin.lslm ();

debug(list message) {
	llOwnerSay(llGetScriptName() + "\n#>" + llDumpList2String(message, "\n#>"));
}

default {
	state_entry() {
		llListen(0, "", llGetOwner(), "");
		llListen(3, "", llGetOwner(), "");
	}

	link_message(integer sender_num, integer num, string str, key id) {
		if(num==RLV_CHANGE_SELECTED_VICTIM) {
			debug(["RLV_CHANGE_SELECTED_VICTIM", str]);
		}
		else if(num==RLV_VICTIMS_LIST_UPDATE) {
			debug(["RLV_VICTIMS_LIST_UPDATE", str]);
		}
		else if(num==USER_PERMISSION_UPDATE) {
			debug(["USER_PERMISSION_UPDATE", str]);
		}
		else if(num==DOMENU) {
			debug(["DOMENU", str, (string) id]);
		}
		else if(num==DIALOG) {
			debug(["DIALOG", str, (string) id]);
		}
		else if(num==RLV_CORE_COMMAND) {
			debug(["RLV_CORE_COMMAND", str]);
		}
		else if(num==OPTIONS) {
			debug(["OPTIONS", str]);
		}
		else if(num==DIALOG_RESPONSE) {
			debug(["DIALOG_RESPONSE", str, (string) id]);
		}
		else if(num==MEM_USAGE) {
			debug(["MEM_USAGE", str]);
		}
		else if(num==SEAT_UPDATE) {
			debug(["SEAT_UPDATE", str]);
		}
		else if(num==NC_READER_REQUEST) {
			debug(["NC_READER_REQUEST", str, (string) id]);
		}
		else if(num==NC_READER_RESPONSE) {
			debug(["NC_READER_RESPONSE", str, (string) id]);
		}
	}
	listen(integer channel, string name, key id, string message) {
		integer num;
		if(llGetSubString(message, 0, 0)=="m") {
			num=RLV_MENU_DUMP_DEBUG_STRING;
		}
		else if(llGetSubString(message, 0, 0)=="c") {
			num=RLV_CORE_DUMP_DEBUG_STRING;
		}
		if(num) {
			llMessageLinked(LINK_SET, num, llGetSubString(message, 1, -1), "");
		}
	}
}
