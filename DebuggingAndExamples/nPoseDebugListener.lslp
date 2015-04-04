integer SEAT_UPDATE=35353;

debug(list message) {
	llOwnerSay(llGetScriptName() + "\n#>" + llDumpList2String(message, "\n#>"));
}

default {
	link_message(integer sender_num, integer num, string str, key id) {
		if(num==SEAT_UPDATE) {
			debug(["SEAT_UPDATE"]+llParseStringKeepNulls(str, ["^"], []));
		}
	}
}
