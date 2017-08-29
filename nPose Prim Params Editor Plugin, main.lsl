// linkMessageFormat:
// num=-8050
// str=command~link~parameters[~command~....]
// key=whatever
// command: see LOOKUP_TABLE
// link: the linkDescription (or the linkNumber)
// parameters: a list of parameters (specific to the command) separated by "~"

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
	"REL_POS_LOCAL", 0, FALSE, "vvv",
	"REL_SIZE", 0, FALSE, "vvv",
	"OFFSET_POSITION", 0, FALSE, "vv",
	"OFFSET_REL_POSITION", 0, FALSE, "vvvv",
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


integer PLUGIN_COMMAND_REGISTER=310;
string PLUGIN_COMMAND_NAME="PRIMEDIT";
integer PRIMEDIT=-8050;
integer MEMORY_USAGE=34334;

list LinkNumberList; //2-strided list [linkDescription, linkNumber]


debug(list message){
	llOwnerSay((((llGetScriptName() + "\n##########\n#>") + llDumpList2String(message,"\n#>")) + "\n##########"));
}

vector vectorScale(vector reference, vector current, vector target) {
	if(reference.x!=0.0 && reference.y!=0.0 && reference.z!=0.0) {
		//only use a scale factor if the reference is set / avoid division by zero
		target=<
			target.x * current.x / reference.x,
			target.y * current.y / reference.y,
			target.z * current.z / reference.z
		>;
	}
	return target;
}

vector vectorMin(vector value1, vector value2) {
	return <floatMin(value1.x, value2.x), floatMin(value1.y, value2.y), floatMin(value1.z, value2.z)>;
}

float floatMin(float value1, float value2) {
	if(value1<value2) {
		return value1;
	}
	return value2;
}


executeCommands(list allCommands) {
	LinkNumberList=getLinkNumberList();
	while(llGetListLength(allCommands)) {
		allCommands=executeAndRemoveFirstCommand(allCommands);
	}
}

list executeAndRemoveFirstCommand(list commandList) {
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
	executeCommand(commandInteger, faceUsedFlag, command, link, parameterList);
	commandList=llDeleteSubList(commandList, 0, 1+numberOfParameters);
	return commandList;
}

executeCommand(integer commandInteger, integer faceUsedFlag, string command, string link, list parameterList) {
	//resolve the linkNumbers
	list linkNumbers;
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
		else if(command=="REL_POS_LOCAL" || command=="REL_SIZE") {
			vector reference=llList2Vector(parameterList, 0);
			vector current=llList2Vector(parameterList, 1);
			vector target=llList2Vector(parameterList, 2);
			
			target=vectorMin(vectorScale(reference, current, target), <64.0, 64.0, 64.0>);
			if(command=="REL_POS_LOCAL") {
				llSetLinkPrimitiveParamsFast(linkNumber, [PRIM_POS_LOCAL, target]);
			}
			else if(command=="REL_SIZE") {
				llSetLinkPrimitiveParamsFast(linkNumber, [PRIM_SIZE, target]);
			}
		}
		else if(command=="OFFSET_POSITION") {
			llSetLinkPrimitiveParamsFast(linkNumber, [PRIM_POSITION, llList2Vector(parameterList, 0) + llList2Vector(parameterList, 1)]);
		}
		else if(command=="OFFSET_REL_POSITION") {
			vector offset=llList2Vector(parameterList, 0);
			vector reference=llList2Vector(parameterList, 1);
			vector current=llList2Vector(parameterList, 2);
			vector target=llList2Vector(parameterList, 3);
			llSetLinkPrimitiveParamsFast(linkNumber, [PRIM_POSITION, offset + vectorScale(reference, current, target)]);
		}
	}
}


list getLinkNumberList() {
	//returns a 2-strided list [linkDescription, linkNumbers (separated by ~]
	//only links with a description will be returned
	//link descriptions must not be an integer
	
	list tempList;
	list retList;
	integer count=llGetObjectPrimCount(llGetKey());
	integer numberOfPrims=llGetNumberOfPrims();
	integer index=count>1 || numberOfPrims>1;
	if(!count) {
		count=numberOfPrims;
	}
	for(; index<=count; index++) {
		string description=llList2String(llGetLinkPrimitiveParams(index, [PRIM_DESC]), 0);
		if(description!="(No Description)" && description!="") {
			tempList+=[description, index];
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
	state_entry() {
		llSleep(1.0); //Wait for other scripts
		llMessageLinked(LINK_SET, PLUGIN_COMMAND_REGISTER, llDumpList2String([PLUGIN_COMMAND_NAME, PRIMEDIT, 1], "|"), NULL_KEY); 
	}
	link_message(integer sender_num, integer num, string str, key id) {
		if(num==PRIMEDIT) {
			executeCommands(llParseStringKeepNulls(str, ["~"], []));
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