//This may be outdated

//LinkMessages
integer DOMENU                 = -800; // dialog control back to npose
integer USER_PERMISSION_UPDATE = -806; // to register a user defined permission
integer DIALOG                 = -900; // start dialog
integer DIALOG_RESPONSE        = -901; // eval dialog response

//integer RLV_MENU_NPOSE_PICK_SEAT_CHANGE_ACTIVE_VICTIM = -8009; //response from the nPose_pickSeat plugin
integer RLV_CORE_COMMAND             = -8010; //send commands to the RLV CORE
integer RLV_CHANGE_SELECTED_VICTIM   = -8012; //can be used to change the current victim. The new current victim has to be in the victims list
integer RLV_VICTIMS_LIST_UPDATE      = -8013; //for internal use
//integer RLV_CORE_PLUGIN_ACTION_RELAY = -8016; //for internal use
//integer RLV_CORE_PLUGIN_MENU_RELAY   = -8017; //for internal use

integer RLV_MENU_DUMP_DEBUG_STRING = -8008; //TODO: remove this
integer RLV_CORE_DUMP_DEBUG_STRING = -8018; //TODO: remove this

integer OPTIONS              = -240;
integer MEM_USAGE            = 34334;
integer SEAT_UPDATE          = 35353;

//nPose Menu Plugin
//integer PLUGIN_MENU_REGISTER=-810;
//integer PLUGIN_ACTION=-830;
//integer PLUGIN_ACTION_DONE=-831;
//integer PLUGIN_MENU=-832;
//integer PLUGIN_MENU_DONE=-833;

//NC Reader
integer NC_READER_REQUEST  = 224;
integer NC_READER_RESPONSE = 225;
string NC_READER_CONTENT_SEPARATOR="%&§";


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
