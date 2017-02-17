// LOOKUP_TABLE
// contains the command definition. Stride:
// [commandName, integer value for llSetLinkPrimitiveParamsFast, flag containsFaceNumber, parameterFormat]
// commandName: The name you wish to use
// integer value for llSetLinkPrimitiveParamsFast: the corresponding value. Use 0 if the command should not use llSetLinkPrimitiveParamsFast
// parameterFormat: a string containing a single letter for each parameter:
//     i:integer
//     f:float
//     s:string
//     k:key
//     v:vector
//     r:rotation
list LOOKUP_TABLE=[
	"TEXTURE", 0, TRUE, "is",
	"COLOR", 0, TRUE, "iv",
	"ALPHA", 0, TRUE, "if",
	"PRIM_MATERIAL", PRIM_MATERIAL, FALSE, "i",
	"PRIM_PHYSICS", PRIM_PHYSICS, FALSE, "i",
	"PRIM_TEMP_ON_REZ", PRIM_TEMP_ON_REZ, FALSE, "i",
	"PRIM_PHANTOM", PRIM_PHANTOM, FALSE, "i",
	"PRIM_POSITION", PRIM_POSITION, FALSE, "v",
	"PRIM_SIZE", PRIM_SIZE, FALSE, "v",
	"PRIM_ROTATION", PRIM_ROTATION, FALSE, "r",
//	"PRIM_TYPE", PRIM_TYPE, FALSE, "" //This command has several "Subcommands" with a different number of parameters
	"PRIM_TEXTURE", PRIM_TEXTURE, TRUE, "isvvf",
	"PRIM_COLOR", PRIM_COLOR, TRUE, "ivf",
	"PRIM_BUMP_SHINY", PRIM_BUMP_SHINY, TRUE, "iii",
	"PRIM_FULLBRIGHT", PRIM_FULLBRIGHT, TRUE, "ii",
	"PRIM_FLEXIBLE", PRIM_FLEXIBLE, FALSE, "iiffffv",
	"PRIM_TEXGEN", PRIM_TEXGEN, TRUE, "ii",
	"PRIM_POINT_LIGHT", PRIM_POINT_LIGHT, FALSE, "ivfff",
	"PRIM_GLOW", PRIM_GLOW, TRUE, "if",
	"PRIM_TEXT", PRIM_TEXT, FALSE, "svf",
	"PRIM_DESC", PRIM_DESC, FALSE, "s",
	"PRIM_ROT_LOCAL", PRIM_ROT_LOCAL, FALSE, "r",
	"PRIM_PHYSICS_SHAPE_TYPE", PRIM_PHYSICS_SHAPE_TYPE, FALSE, "i",
	"PRIM_OMEGA", PRIM_OMEGA, FALSE, "vff",
	"PRIM_POS_LOCAL", PRIM_POS_LOCAL, FALSE, "v",
	"PRIM_LINK_TARGET", PRIM_LINK_TARGET, FALSE, "i",
	"PRIM_SLICE", PRIM_SLICE, FALSE, "v",
	"PRIM_SPECULAR", PRIM_SPECULAR, TRUE, "isvvfvii",
	"PRIM_NORMAL", PRIM_NORMAL, TRUE, "isvvf",
	"PRIM_ALPHA_MODE", PRIM_ALPHA_MODE, TRUE, "iii",
	"PRIM_ALLOW_UNSIT", PRIM_ALLOW_UNSIT, FALSE, "i",
	"PRIM_SCRIPTED_SIT_ONLY", PRIM_SCRIPTED_SIT_ONLY, FALSE, "i",
	"PRIM_SIT_TARGET", PRIM_SIT_TARGET, FALSE, "ivr"
];

list SavedParams;
// this list stores all params that may be used in a prop
// Stride Format:
// [command, link, face, params]
// command: the command, see LOOKUP_TABLE
// link: the linkNumber (integer) or the linkDescription (string)
// face: the facenumber (only valid if the command has set the containsFaceNumber flag)
// params: a string that contains the params

integer PRIMEDIT=-8050;
integer ON_PROP_REZZED=-790;
integer CORERELAY=300;
integer MEMORY_USAGE=34334;

debug(list message){
	llOwnerSay((((llGetScriptName() + "\n##########\n#>") + llDumpList2String(message,"\n#>")) + "\n##########"));
}

saveCommands(list allCommands) {
	while(llGetListLength(allCommands)) {
		allCommands=saveAndRemoveFirstCommand(allCommands);
	}
}

list saveAndRemoveFirstCommand(list commandList) {
	string command=llList2String(commandList, 0);
	string link=llList2String(commandList, 1);
	list parameterList;
	
	integer index=llListFindList(LOOKUP_TABLE, [command]);
	if(!~index) {
		return[];
	}
	integer commandInteger=llList2Integer(LOOKUP_TABLE, index+1);
	integer faceUsedFlag=llList2Integer(LOOKUP_TABLE, index+2);
	string parameterTypes=llList2String(LOOKUP_TABLE, index+3);
	integer parameterIndex;
	integer numberOfParameters=llStringLength(parameterTypes);
	for(; parameterIndex<numberOfParameters; parameterIndex++) {
		string parameterType=llGetSubString(parameterTypes, parameterIndex, parameterIndex);
		string parameterString=llList2String(commandList, 2+parameterIndex);
		if(parameterType=="i") {
			parameterList+=(integer)parameterString;
		}
		else if(parameterType=="f") {
			parameterList+=(float)parameterString;
		}
		else if(parameterType=="s") {
			parameterList+=parameterString;
		}
		else if(parameterType=="k") {
			parameterList+=(key)parameterString;
		}
		else if(parameterType=="v") {
			parameterList+=(vector)parameterString;
		}
		else if(parameterType=="r") {
			parameterList+=(rotation)parameterString;
		}
	}
	saveCommand(commandInteger, faceUsedFlag, command, link, parameterList);
	commandList=llDeleteSubList(commandList, 0, 1+numberOfParameters);
	return commandList;
}


saveCommand(integer commandInteger, integer faceUsedFlag, string command, string link, list parameterList) {
		//store the stuff if props are within the scope, so that newly rezzed props can get their initial values
		list searchFor=[command, link];
		integer face;
		if(faceUsedFlag) {
			face=llList2Integer(parameterList, 0);
			searchFor+=face;
		}
		integer index=llListFindList(SavedParams, searchFor);
		if(~index) {
			SavedParams=llDeleteSubList(SavedParams, index, index+3);
		}
		SavedParams+=[command, link, face, llDumpList2String(parameterList, "~")];
	}

repeatCommands() {
	integer length=llGetListLength(SavedParams);
	integer index;
	string stringToSend;
	string stringToAppend;
	for(; index<length; index+=4) {
		stringToAppend=llDumpList2String([llList2String(SavedParams, index), llList2String(SavedParams, index+1), llList2String(SavedParams, index+3)], "~");
		if(getStringBytes(stringToSend + stringToAppend)<1023) {
			if(stringToSend) {
				stringToSend+="~";
			}
			stringToSend+=stringToAppend;
		}
		else {
			coreRelay(PRIMEDIT, stringToSend, NULL_KEY);
			stringToSend=stringToAppend;
		}
	}
	if(stringToSend!="") {
		coreRelay(PRIMEDIT, stringToSend, NULL_KEY);
	}
}

integer getStringBytes(string str) {
	return (3 * llSubStringIndex(llStringToBase64(str)+"=", "=")) >> 2;
}

coreRelay(integer num, string str, key id) {
	llMessageLinked(
		LINK_SET,
		CORERELAY,
		llDumpList2String([num, str, id], "|"),
		NULL_KEY
	);
}

default {
	link_message(integer sender_num, integer num, string str, key id) {
		if(num==PRIMEDIT) {
			saveCommands(llParseStringKeepNulls(str, ["~"], []));
		}
		else if(num==ON_PROP_REZZED) {
			repeatCommands();
		}
		else if(num==MEMORY_USAGE) {
			llSay(0,"Memory Used by " + llGetScriptName() + ": " + (string)llGetUsedMemory() + " of " + (string)llGetMemoryLimit()
				+ ", Leaving " + (string)llGetFreeMemory() + " memory free.");
		}
	}
	on_rez(integer param) {
		llResetScript();
	}
}
