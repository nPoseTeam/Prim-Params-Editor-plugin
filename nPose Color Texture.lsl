// linkMessageFormat:
// num=-8050
// str=command~scope~link~parameters[~command~....]
// key=whatever
// command: see LOOKUP_TABLE
// scope:
//     "" (empty) or "main": the command should not be relayed to props. It only affects the main nPose object
//     "*" or "all": the command will be relayed to props and also affects the main nPose object
//     "?" or "props": the command will be relayed to props but does not affects the main nPose obejct
// link: the linkNumber or the linkDescription
// parameters: a list of parameters (specific to the command) separated by "~"

list SavedParams;
// this list stores all params that may be used in a prop
// Stride Format:
// [command, link, face, params]
// command: the command, see LOOKUP_TABLE
// link: the linkNumber (integer) or the linkDescription (string)
// face: the facenumber (only valid if the command has set the containsFaceNumber flag)
// params: a string that contains the params



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


integer SET_PRIMITIVE_PARAMS=-8050;
integer OLD_TEXTURE_CHANGER=-22452987;
integer ON_PROP_REZZED=-790;
integer CORERELAY=300;
integer MEMORY_USAGE=34334;

list LinkNumberList; //2-strided list [linkDescription, linkNumber]


debug(list message){
	llOwnerSay((((llGetScriptName() + "\n##########\n#>") + llDumpList2String(message,"\n#>")) + "\n##########"));
}

executeCommands(list allCommands) {
	LinkNumberList=getLinkNumberList();
	while(llGetListLength(allCommands)) {
		allCommands=executeAndRemoveFirstCommand(allCommands);
	}
}

list executeAndRemoveFirstCommand(list commandList) {
	string command=llList2String(commandList, 0);
	string scope=llList2String(commandList, 1);
	string link=llList2String(commandList, 2);
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
		string parameterString=llList2String(commandList, 3+parameterIndex);
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
	executeCommand(commandInteger, faceUsedFlag, command, scope, link, parameterList);
	commandList=llDeleteSubList(commandList, 0, 2+numberOfParameters);
	return commandList;
}

executeCommand(integer commandInteger, integer faceUsedFlag, string command, string scope, string link, list parameterList) {
	integer skipLocal;
	integer skipRemote;
	if(scope=="" || scope=="main") {
		skipRemote=TRUE;
	}
	else if(scope=="?" || scope=="props") {
		skipLocal=TRUE;
	}

	//resolve the linkNumbers
	list linkNumbers;
	if(!skipLocal) {
		if((string)((integer)link)!=link) {
			//it is a string
			linkNumbers=getLinkNumbersFromLinkNumberList(LinkNumberList, link);
		}
		else {
			linkNumbers+=link;
		}
		//execute the command locally
		integer linkNumbersIndex;
		integer linkNumbersLenght=llGetListLength(linkNumbers);
		for(; linkNumbersIndex<linkNumbersLenght; linkNumbersIndex++) {
			integer linkNumber=(integer)llList2String(linkNumbers, linkNumbersIndex);
			if(commandInteger>0) {
				llSetLinkPrimitiveParamsFast(linkNumber, [commandInteger]+parameterList);
			}
			else if(command=="TEXTURE") {
				llSetLinkTexture(linkNumber, llList2String(parameterList, 1), llList2Integer(parameterList, 0));
			}
			else if(command=="COLOR") {
				llSetLinkColor(linkNumber, llList2Vector(parameterList, 1), llList2Integer(parameterList, 0));
			}
			else if(command=="ALPHA") {
				llSetLinkAlpha(linkNumber, llList2Float(parameterList, 1), llList2Integer(parameterList, 0));
			}
		}
	}

	//relay the command to props if the scope include them (remove the scope string to be sure that the props don't send them again)
	if(!skipRemote) {
		coreRelay(SET_PRIMITIVE_PARAMS, llDumpList2String([command, "", link]+parameterList, "~"), NULL_KEY);
		//store the stuff if props are within the scope, so that newly rezzed props can get their initial values
		list searchFor=[command, link];
		integer face;
		if(faceUsedFlag) {
			face==llList2Integer(parameterList, 0);
			searchFor+=face;
		}
		integer index=llListFindList(SavedParams, searchFor);
		if(~index) {
			SavedParams=llDeleteSubList(SavedParams, index, index+3);
		}
		SavedParams+=[command, link, face, llDumpList2String(parameterList, "~")];
	}
}

repeatCommands() {
	integer length=llGetListLength(SavedParams);
	integer index;
	string stringToSend;
	string stringToAppend;
	for(; index<length; index+=4) {
		stringToAppend=llDumpList2String([llList2String(SavedParams, index), "", llList2String(SavedParams, index+1), llList2String(SavedParams, index+3)], "~");
		if(getStringBytes(stringToSend + stringToAppend)<1023) {
			if(stringToSend) {
				stringToSend+="~";
			}
			stringToSend+=stringToAppend;
		}
		else {
			coreRelay(SET_PRIMITIVE_PARAMS, stringToSend, NULL_KEY);
			stringToSend=stringToAppend;
		}
	}
	if(stringToSend!="") {
		coreRelay(SET_PRIMITIVE_PARAMS, stringToSend, NULL_KEY);
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

list getLinkNumberList() {
	//returns a 2-strided list [linkDescription, linkNumbers (separated by ~]
	//only links with a description will be returned
	//link descriptions must not be an integer
	
	list tempList;
	list retList;
	integer count=llGetObjectPrimCount(llGetKey());
	if(!count) {
		count=llGetNumberOfPrims();
	}
	if(count<=1) {
		string description=llList2String(llGetPrimitiveParams([PRIM_DESC]), 0);
		if(description!="(No Description)" && description!="") {
			tempList+=[description, 0];
		}
	}
	else {
		integer index=1;
		for(; index<=count; index++) {
			string description=llList2String(llGetLinkPrimitiveParams(index, [PRIM_DESC]), 0);
			if(description!="(No Description)" && description!="") {
				tempList+=[description, index];
			}
		}
	}
	integer indexTempList;
	integer lengthTempList=llGetListLength(tempList);
	for(; indexTempList<lengthTempList; indexTempList+=2) {
		list descriptionParts=llParseString2List(llList2String(tempList, indexTempList), ["~"], []);
		integer linkNumber=llList2Integer(tempList, indexTempList+1);
		integer indexDescription;
		integer lenghtDescription=llGetListLength(descriptionParts);
		for(; indexDescription<lenghtDescription; indexDescription++) {
			string description=llList2String(descriptionParts, indexDescription);
			if((string)((integer)description)!=description) {
				integer indexRetList=llListFindList(retList, [description]);
				list linkNumbers;
				if(~indexRetList) {
					linkNumbers=llParseString2List(llList2String(retList, indexRetList+1), ["~"], []);
					retList=llDeleteSubList(retList, indexRetList, indexRetList+1);
				}
				integer indexLinkNumbers=llListFindList(linkNumbers, [linkNumber]);
				if(!~indexLinkNumbers) {
					linkNumbers+=[linkNumber];
				}
				retList+=[description, llDumpList2String(linkNumbers, "~")];
			}
		}
	}
	return retList;
}

list getLinkNumbersFromLinkNumberList(list linkNumberList, string linkDesc) {
	//linkNumberList: a 2-strided list [linkDescription, linkNumbers(separated by ~)]
	integer index=llListFindList(linkNumberList, [linkDesc]);
	if(~index) {
		return llParseString2List(llList2String(linkNumberList, index+1), ["~"], []);
	}
	return [];
}

default {
	link_message(integer sender_num, integer num, string str, key id) {
		if(num==SET_PRIMITIVE_PARAMS) {
			executeCommands(llParseStringKeepNulls(str, ["~"], []));
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