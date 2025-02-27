/*
 * Cette oeuvre, création, site ou texte est sous licence Creative Commons Attribution
 * - Pas d’Utilisation Commerciale
 * - Partage dans les Mêmes Conditions 4.0 International. 
 * Pour accéder à une copie de cette licence, merci de vous rendre à l'adresse suivante
 * http://creativecommons.org/licenses/by-nc-sa/4.0/ .
 *
 * Merci de respecter le travail fourni par le ou les auteurs 
 * https://www.ts-x.eu/ - kossolax@ts-x.eu
 */
#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <colors_csgo>	// https://forums.alliedmods.net/showthread.php?p=2205447#post2205447
#include <smlib>		// https://github.com/bcserv/smlib
#include <emitsoundany> // https://forums.alliedmods.net/showthread.php?t=237045

#define __LAST_REV__ 		"v:0.1.0"

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

//#define DEBUG
#define MODEL_GRAVE "models/props/de_inferno/church_ornament_01.mdl"

public Plugin myinfo = {
	name = "Jobs: Immo", author = "KoSSoLaX",
	description = "RolePlay - Jobs: Immobilier",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

int g_cBeam, g_cGlow;

int g_PropsAppartItemId,g_PropsOutdoorItemId;
char g_PropsAppart[][][128] = {
	{ "Bureau",					"models/props_office/desk_01.mdl"},
	{ "Télévision",				"models/props_interiors/tv.mdl"},
	{ "Machine a laver",		"models/props_c17/furniturewashingmachine001a.mdl"},
	{ "Armoire",				"models/props_c17/FurnitureDresser001a.mdl"},
	{ "Chaise",					"models/props_interiors/chair_office2.mdl"},
	{ "Canapé",					"models/props_interiors/couch.mdl"},
	{ "Table basse",			"models/props_interiors/coffee_table_rectangular.mdl"},
	{ "Pile de palettes",		"models/props/cs_assault/box_stack1.mdl"},
	{ "Bar",					"models/props/cs_militia/bar01.mdl"},
	{ "Lit",					"models/props/de_house/bed_rustic.mdl"},
	{ "Etagère télévision",		"models/props_interiors/tv_cabinet.mdl"}
};
char g_PropsOutdoor[][][128] = {
	{ "Cube",					"models/props/DeadlyDesire/blocks/32x32.mdl"},
	{ "Palette",				"models/props_industrial/pallet_stack_96.mdl"},
	{ "Mur de fortification",	"models/props_fortifications/concrete_block001_128_reference.mdl"},
	{ "Distributeur de boisson","models/props/cs_office/vending_machine.mdl"},
	{ "Bateau",					"models/props_urban/boat002.mdl"},
	{ "Cabine de toilettes",	"models/props_urban/outhouse002.mdl"},
	{ "Conduit en béton",		"models/props_pipes/concrete_pipe001b.mdl"},
	{ "Petite Benne",			"models/props_junk/trashdumpster02a.mdl"},
	{ "Table de picnic",		"models/props_interiors/table_picnic.mdl"},
	{ "Etagère industrielle",   "models/props_industrial/warehouse_shelf001.mdl"},
	{ "Barricade de carton",    "models/props/cs_assault/box_stack1.mdl"},
	{ "Planche en bois",		"models/props/de_vertigo/construction_wood_2x4_01.mdl"}
};
// ----------------------------------------------------------------------------
public void OnPluginStart() {
	RegServerCmd("rp_give_appart_door",		Cmd_ItemGiveAppart,				"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_appart_bonus",	Cmd_ItemGiveBonus,				"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_appart_keys",		Cmd_ItemGiveAppartDouble,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_appart_serrure",		Cmd_ItemAppartSerrure,		"RP-ITEM",	FCVAR_UNREGISTERED);
	
	RegServerCmd("rp_item_prop_appart",		Cmd_ItemPropAppart,			"RP-ITEM",  FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_prop_outdoor",	Cmd_ItemPropOutdoor,		"RP-ITEM",  FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_proptraps",	Cmd_ItemPropTrap,		"RP-ITEM",  FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_graves",		Cmd_ItemGrave,			"RP-ITEM", 	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_lampe", 		Cmd_ItemLampe,			"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_jumelle", 	Cmd_ItemLampe,			"RP-ITEM",	FCVAR_UNREGISTERED);
	
	for (int i = 1; i <= MaxClients; i++) 
		if( IsValidClient(i) )
			OnClientPostAdminCheck(i);
}
public void OnMapStart() {
	g_cBeam = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	g_cGlow = PrecacheModel("materials/sprites/glow01.vmt", true);
	PrecacheModel(MODEL_GRAVE, true);
}
public void OnClientPostAdminCheck(int client) {
	#if defined DEBUG
	PrintToServer("OnClientPostAdminCheck");
	#endif
	rp_HookEvent(client, RP_OnPlayerCommand, fwdCommand);
}
// ----------------------------------------------------------------------------
public Action fwdCommand(int client, char[] command, char[] arg) {
	#if defined DEBUG
	PrintToServer("fwdCommand");
	#endif
	if( StrEqual(command, "infocoloc") ) {
		return Cmd_InfoColoc(client);
	}
	return Plugin_Continue;
}

public Action Cmd_ItemGiveAppart(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemGiveAppart");
	#endif
	char arg1[12], arg2[12];
	
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	int client = StringToInt(arg1);
	int appart = StringToInt(arg2);
	
	if( !rp_GetClientKeyAppartement(client, appart) ) { // TODO: Check si y a pas déjà un proprio... 
		
		for (int i = 0; i < view_as<int>(appart_bonus_max); i++)
			rp_SetAppartementInt(appart, view_as<type_appart_bonus>(i), 0);
		
		rp_SetClientInt(client, i_AppartCount, rp_GetClientInt(client, i_AppartCount) + 1);
		rp_SetClientKeyAppartement(client, appart, true);
		rp_SetAppartementInt(appart, appart_proprio, client);
		
		if( appart < 10 )
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous êtes maintenant le propriétaire du garage n°%d", appart);
		else
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous êtes maintenant le propriétaire de l'appartement n°%d", appart);
	}
}
public Action Cmd_ItemAppartSerrure(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemAppartSerrure");
	#endif

	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);
	int appartID = rp_GetPlayerZoneAppart(client);
	Handle dp;
	CreateDataTimer(0.25 , Task_ItemAppartSerrure, dp, TIMER_DATA_HNDL_CLOSE);
	WritePackCell(dp, client);
	WritePackCell(dp, item_id);
	WritePackCell(dp, appartID);
	return Plugin_Handled;
}
public Action Task_ItemAppartSerrure(Handle timer, Handle dp) {
	#if defined DEBUG
	PrintToServer("Task_ItemAppartSerrure");
	#endif
	ResetPack(dp);
	int client = ReadPackCell(dp);
	int item_id = ReadPackCell(dp);
	int appartID = ReadPackCell(dp);

	if( appartID == -1 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez être dans votre appartement.");
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	if( rp_GetAppartementInt(appartID, appart_proprio) != client ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous n'êtes pas le propriétaire de cet appartement.");
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	Handle menu = CreateMenu(MenuSerrureVirer);
	SetMenuTitle(menu, "Qui faut-il virer de l'appartement ?");
	char tmp[32], tmp2[32];
	for(int i=1; i<MAXPLAYERS; i++){
		if( !IsValidClient(i) )
			continue;
		
		if(rp_GetClientKeyAppartement(i, appartID) && i!=client){
			Format(tmp, 31, "%i_%i_%i", item_id, appartID, i);
			Format(tmp2, 31, "%N", i);
			AddMenuItem(menu,tmp,tmp2);
		}
	}
	DisplayMenu(menu, client, 60);
	return Plugin_Handled;
}
public int MenuSerrureVirer(Handle menu, MenuAction action, int client, int param2) {
	if( action == MenuAction_Select ) {
		char options[64], data[3][32];
		GetMenuItem(menu, param2, options, 63);
		ExplodeString(options, "_", data, sizeof(data), sizeof(data[]));
		int item_id = StringToInt(data[0]);
		int appartID = StringToInt(data[1]);
		int target = StringToInt(data[2]);

		if(rp_GetClientKeyAppartement(target, appartID)){
			rp_SetClientInt(target, i_AppartCount, rp_GetClientInt(target, i_AppartCount) - 1);
			rp_SetClientKeyAppartement(target, appartID, false);
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Les clefs de l'appartement ont été retirées à %N.", target);
		}
		else{
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Le joueur n'a pas les clefs de l'appartement.");
			ITEM_CANCEL(client, item_id);
		}
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
}
public Action Cmd_ItemGiveAppartDouble(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemGiveAppartDouble");
	#endif
	
	int client = GetCmdArgInt(1);
	int itemID = GetCmdArgInt(args);
	int target = GetClientAimTarget(client);
	
	if( !IsValidClient(target) ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez viser un joueur.");
		ITEM_CANCEL(client, itemID);
		return Plugin_Handled;
	}
	
	int appartID = rp_GetPlayerZoneAppart(client);
	if( appartID == -1 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez être dans votre appartement.");
		ITEM_CANCEL(client, itemID);
		return Plugin_Handled;
	}
	if( !rp_GetClientKeyAppartement(client, appartID) ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous n'êtes pas propriétaire de cet appartement.");
		ITEM_CANCEL(client, itemID);
		return Plugin_Handled;
	}
	if( rp_GetClientKeyAppartement(target, appartID ) ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} %N{default} a déjà les clés de cet appartement.", target);
		ITEM_CANCEL(client, itemID);
		return Plugin_Handled;
	}
	
	rp_SetClientInt(target, i_AppartCount, rp_GetClientInt(target, i_AppartCount) + 1);
	rp_SetClientKeyAppartement(target, appartID, true);
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} %N{default} a maintenant les clés de l'appartement %d.", target, appartID);
	
	return Plugin_Handled;
}
public Action Cmd_ItemGiveBonus(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemGiveBonus");
	#endif
	
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	int client = GetCmdArgInt(2);
	int itemID = GetCmdArgInt(args);
	
	int appartID = rp_GetPlayerZoneAppart(client);
	if( appartID == -1 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez être dans votre appartement.");
		ITEM_CANCEL(client, itemID);
		return Plugin_Handled;
	}
	if( !rp_GetClientKeyAppartement(client, appartID) ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous n'êtes pas propriétaire de cet appartement.");
		ITEM_CANCEL(client, itemID);
		return Plugin_Handled;
	}
	
	int bonus, mnt = 1;
	// BO BO BONUS
	
	if( StrEqual(arg1, "heal") )
		bonus = appart_bonus_heal;
	else if( StrEqual(arg1, "armor") )
		bonus = appart_bonus_armor;
	else if( StrEqual(arg1, "energy") )
		bonus = appart_bonus_energy;
	else if( StrEqual(arg1, "garage") )
		bonus = appart_bonus_garage;
	else if( StrEqual(arg1, "vitality") )
		bonus = appart_bonus_vitality;
	else if( StrEqual(arg1, "coffre") )
		bonus = appart_bonus_coffre;
	else if( StrEqual(arg1, "bronze") ) {
		bonus = appart_bonus_paye;
		mnt = 50;
	}
	else if( StrEqual(arg1, "argent") ) {
		bonus = appart_bonus_paye;
		mnt = 75;
	}
	else if( StrEqual(arg1, "or") ) {
		bonus = appart_bonus_paye;
		mnt = 100;
	}
	else if( StrEqual(arg1, "platine") ) {
		bonus = appart_bonus_paye;
		mnt = 150;
	}
	else if( StrEqual(arg1, "all") ) {
		for(int i=0; i<view_as<int>(appart_bonus_paye); i++) {
			rp_SetAppartementInt(appartID, view_as<type_appart_bonus>(i), 1);
		}
		rp_SetAppartementInt(appartID, appart_bonus_paye, 150);
		return Plugin_Handled;
	}
	else {
		ITEM_CANCEL(client, itemID);
		return Plugin_Handled;	
	}
	
	if( rp_GetAppartementInt(appartID, view_as<type_appart_bonus>(bonus)) >= mnt ) {
		ITEM_CANCEL(client, itemID);
		return Plugin_Handled;
	}
	rp_SetAppartementInt(appartID, view_as<type_appart_bonus>(bonus), mnt);
	
	return Plugin_Handled;	
}
// ----------------------------------------------------------------------------
public Action Cmd_ItemPropAppart(int args){
	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);
	rp_ClientGiveItem(client,item_id);
	g_PropsAppartItemId = item_id;
	int zone = rp_GetPlayerZone(client);
	int appart = rp_GetPlayerZoneAppart(client);
	if(appart == -1){
		if(rp_GetZoneInt(zone, zone_type_type) != rp_GetClientJobID(client)){
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez être dans votre planque ou dans votre appartment.");
			return Plugin_Handled;
		}
	}
	CreateTimer(0.25, task_ItemPropAppart, client);
	return Plugin_Handled;
}
public Action task_ItemPropAppart(Handle timer, any client) {
	Handle menu = CreateMenu(MenuPropAppart);
	SetMenuTitle(menu, "Quel props voulez vous spawn");
	for(int i=0; i<sizeof(g_PropsAppart); i++){
		AddMenuItem(menu, g_PropsAppart[i][1], g_PropsAppart[i][0]);
	}
	DisplayMenu(menu, client, 60);
	return Plugin_Handled;
}
public int MenuPropAppart(Handle menu, MenuAction action, int client, int param2) {
	if( action == MenuAction_Select ) {
		char model[128];
		GetMenuItem(menu, param2, model, 127);
		int item_id = g_PropsAppartItemId;
		int zone = rp_GetPlayerZone(client);
		int appart = rp_GetPlayerZoneAppart(client);
		if(appart == -1){
			if(rp_GetZoneInt(zone, zone_type_type) != rp_GetClientJobID(client)){
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez être dans votre planque ou dans votre appartment.");
				return;
			}
		}
		int ent = CreateEntityByName("prop_physics_override"); 
		if( !IsModelPrecached(model) ) {
			PrecacheModel(model);
		}
		
		DispatchKeyValue(ent, "physdamagescale", "0.0");
		DispatchKeyValue(ent, "model", model);
		DispatchSpawn(ent);
		SetEntityModel(ent, model);
		
		float min[3], max[3], position[3], ang_eye[3], ang_ent[3], normal[3];
		float distance = 50.0;
		
		GetEntPropVector( ent, Prop_Send, "m_vecMins", min );
		GetEntPropVector( ent, Prop_Send, "m_vecMaxs", max );
		
		distance += SquareRoot( (max[0] - min[0]) * (max[0] - min[0]) + (max[1] - min[1]) * (max[1] - min[1]) ) * 0.5;
		
		GetClientFrontLocationData( client, position, ang_eye, distance );
		normal[0] = 0.0;
		normal[1] = 0.0;
		normal[2] = 1.0;
		
		NegateVector( normal );
		GetVectorAngles( normal, ang_ent );
		
		float volume = (max[0]-min[0]) * (max[1]-min[1]) * (max[2]-min[2]);
		int heal = RoundToCeil(volume/500.0)+10;
		position[2] += max[2];
		Handle trace = TR_TraceHullEx(position, position, min, max, MASK_SOLID);
		if( TR_DidHit(trace) ) {
			delete trace;
			
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Il n'y a pas assez de place.");
			AcceptEntityInput(ent, "Kill");
			return;
		}
		delete trace;
		
		SetEntProp( ent, Prop_Data, "m_takedamage", 2);
		SetEntProp( ent, Prop_Data, "m_iHealth", heal);
		
		SetEntityMoveType(ent, MOVETYPE_VPHYSICS); 
		TeleportEntity(ent, position, ang_ent, NULL_VECTOR);
		AcceptEntityInput(ent, "DisableMotion");
		rp_ScheduleEntityInput(ent, 0.6, "EnableMotion");
		
		ServerCommand("sm_effect_fading %i 0.5", ent);
		
		rp_SetBuildingData(ent, BD_owner, client);
		rp_SetBuildingData(ent, BD_item_id, item_id);
		rp_Effect_BeamBox(client, ent, NULL_VECTOR, 0, 64, 255);
		
		HookSingleEntityOutput(ent, "OnBreak", PropBuilt_break);
		rp_ClientGiveItem(client,item_id,-1);
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
}
public Action Cmd_ItemPropOutdoor(int args){
	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);
	rp_ClientGiveItem(client,item_id);
	g_PropsOutdoorItemId = item_id;
	int zone = rp_GetPlayerZone(client);
	int zoneBIT = rp_GetZoneBit(zone);

	if( rp_GetZoneInt(zone, zone_type_type) == 1 || zoneBIT & BITZONE_PEACEFULL || zoneBIT & BITZONE_BLOCKBUILD ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Cet objet est interdit où vous êtes.");
		return Plugin_Handled;
	}
	CreateTimer(0.25, task_ItemPropOutdoor, client);
	return Plugin_Handled;
}

public Action task_ItemPropOutdoor(Handle timer, any client){
	Handle menu = CreateMenu(MenuPropOutdoor);
	SetMenuTitle(menu, "Quel props voulez vous spawn");
	for(int i=0; i<sizeof(g_PropsOutdoor); i++){
		AddMenuItem(menu, g_PropsOutdoor[i][1], g_PropsOutdoor[i][0]);
	}
	DisplayMenu(menu, client, 60);
	return Plugin_Handled;
}
public int MenuPropOutdoor(Handle menu, MenuAction action, int client, int param2) {
	if( action == MenuAction_Select ) {
		char model[128];
		GetMenuItem(menu, param2, model, 127);
		int item_id = g_PropsOutdoorItemId;
		int zone = rp_GetPlayerZone(client);
		int zoneBIT = rp_GetZoneBit(zone);

		int ent = CreateEntityByName("prop_physics_override"); 
		if( !IsModelPrecached(model) ) {
			PrecacheModel(model);
		}
		if( rp_GetZoneInt(zone, zone_type_type) == 1 || zoneBIT & BITZONE_PEACEFULL || zoneBIT & BITZONE_BLOCKBUILD ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Cet objet est interdit où vous êtes.");
			return;
		}
		DispatchKeyValue(ent, "physdamagescale", "0.0");
		DispatchKeyValue(ent, "model", model);
		DispatchSpawn(ent);
		SetEntityModel(ent, model);
		
		float min[3], max[3], position[3], ang_eye[3], ang_ent[3], normal[3];
		float distance = 50.0;
		
		GetEntPropVector( ent, Prop_Send, "m_vecMins", min );
		GetEntPropVector( ent, Prop_Send, "m_vecMaxs", max );
		
		distance += SquareRoot( (max[0] - min[0]) * (max[0] - min[0]) + (max[1] - min[1]) * (max[1] - min[1]) ) * 0.5;
		
		GetClientFrontLocationData( client, position, ang_eye, distance );
		normal[0] = 0.0;
		normal[1] = 0.0;
		normal[2] = 1.0;
		
		NegateVector( normal );
		GetVectorAngles( normal, ang_ent );
		
		float volume = (max[0]-min[0]) * (max[1]-min[1]) * (max[2]-min[2]);
		int heal = RoundToCeil(volume/250.0)+10;
		position[2] += max[2];
		Handle trace = TR_TraceHullEx(position, position, min, max, MASK_SOLID);
		if( TR_DidHit(trace) ) {
			delete trace;
			
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Il n'y a pas assez de place.");
			AcceptEntityInput(ent, "Kill");
			return;
		}
		delete trace;
		
		SetEntProp( ent, Prop_Data, "m_takedamage", 2);
		SetEntProp( ent, Prop_Data, "m_iHealth", heal);
		
		SetEntityMoveType(ent, MOVETYPE_VPHYSICS); 
		TeleportEntity(ent, position, ang_ent, NULL_VECTOR);
		AcceptEntityInput(ent, "DisableMotion");
		rp_ScheduleEntityInput(ent, 0.6, "EnableMotion");
		
		ServerCommand("sm_effect_fading %i 0.5", ent);
		
		rp_SetBuildingData(ent, BD_owner, client);
		rp_SetBuildingData(ent, BD_item_id, item_id);
		rp_Effect_BeamBox(client, ent, NULL_VECTOR, 0, 64, 255);
		
		HookSingleEntityOutput(ent, "OnBreak", PropBuilt_break);
		rp_ClientGiveItem(client,item_id,-1);
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
}
public void PropBuilt_break(const char[] output, int caller, int activator, float delay) {
	#if defined DEBUG
	PrintToServer("PropBuilt_break");
	#endif
	
	int client = rp_GetBuildingData(caller, BD_owner);
	rp_SetBuildingData(caller, BD_owner, 0);

	if( client == activator ) {
		rp_IncrementSuccess(client, success_list_ikea_fail);
	}
}
// ----------------------------------------------------------------------------
public Action Cmd_ItemPropTrap(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemPropTrap");
	#endif
	int client = GetCmdArgInt(1);
	int target = GetClientAimTarget(client, false);
	
	int item_id = GetCmdArgInt(args);
	if( target == 0 || !IsValidEdict(target) || !IsValidEntity(target) || !rp_IsMoveAble(target) ) {
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	
	if( rp_GetBuildingData(target, BD_owner) != client ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Ce props ne vous appartient pas.");
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	
	if( rp_GetBuildingData(target, BD_Trapped) ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Ce props est déjà piégé.");
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	
	rp_SetClientInt(client, i_LastAgression, GetTime());
	float vecTarget[3];
	Entity_GetAbsOrigin(target, vecTarget);
	TE_SetupBeamRingPoint(vecTarget, 1.0, 150.0, g_cBeam, g_cGlow, 0, 15, 0.5, 50.0, 0.0, {50, 100, 255, 50}, 10, 0);
	TE_SendToAll();
	
	rp_SetBuildingData(target, BD_Trapped, 1);
	SDKHook(target, SDKHook_OnTakeDamage, PropsDamage);
	SDKHook(target, SDKHook_Touch,		PropsTouched);
	return Plugin_Handled;
}
public void PropsTouched(int touched, int toucher) {
	#if defined DEBUG
	PrintToServer("PropsTouched");
	#endif
	if( IsValidClient(toucher) && toucher != rp_GetBuildingData(touched, BD_owner) ) {
		rp_Effect_PropExplode(touched);
		rp_SetClientInt(rp_GetBuildingData(touched, BD_owner), i_LastAgression, GetTime());
	}
}
public Action PropsDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) {
	#if defined DEBUG
	PrintToServer("PropsDamage");
	#endif
	if( attacker == inflictor && IsValidClient(attacker) ) {
		int wep_id = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		char sWeapon[32];
		
		GetEdictClassname(wep_id, sWeapon, sizeof(sWeapon));
		if( StrContains(sWeapon, "weapon_knife") == 0 || StrContains(sWeapon, "weapon_bayonet") == 0 ) {
			rp_Effect_PropExplode(victim);
		}
	}
}
// ----------------------------------------------------------------------------
public Action Cmd_ItemGrave(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemGrave");
	#endif
	int client = GetCmdArgInt(1);
	
	if( BuildingTomb(client) == 0 ) {
		char arg_last[12];
		GetCmdArg(args, arg_last, 11);
		int item_id = StringToInt(arg_last);
		
		ITEM_CANCEL(client, item_id);
	}
	
	return Plugin_Handled;
}
int BuildingTomb(int client) {
	#if defined DEBUG
	PrintToServer("BuildingTomb");
	#endif
	
	if( !rp_IsBuildingAllowed(client) )
		return 0;	
	
	char classname[64], tmp[64];
	Format(classname, sizeof(classname), "rp_grave_%i", client);
	
	float vecOrigin[3], vecAngles[3];
	GetClientAbsOrigin(client, vecOrigin);
	GetClientEyeAngles(client, vecAngles);
	
	for(int i=1; i<=2048; i++) {
		if( !IsValidEdict(i) )
			continue;
		if( !IsValidEntity(i) )
			continue;
		
		GetEdictClassname(i, tmp, sizeof(tmp));
		
		if( StrEqual(classname, tmp) ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez déjà une tombe de placée.");
			return 0;
		}
	}
	
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Construction en cours...");
	
	EmitSoundToAllAny("player/ammo_pack_use.wav", client, _, _, _, 0.66);
	
	int ent = CreateEntityByName("prop_physics");
	
	DispatchKeyValue(ent, "classname", classname);
	DispatchKeyValue(ent, "model", MODEL_GRAVE);
	DispatchKeyValue(ent, "solid", "0");
	DispatchSpawn(ent);
	ActivateEntity(ent);
	
	SetEntityModel(ent, MODEL_GRAVE);
	
	SetEntProp( ent, Prop_Data, "m_iHealth", 1000);
	SetEntProp( ent, Prop_Data, "m_takedamage", 0);
	
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	
	
	vecAngles[0] = vecAngles[2] = 0.0;
	TeleportEntity(ent, vecOrigin, vecAngles, NULL_VECTOR);
	
	ServerCommand("sm_effect_fading \"%i\" \"3.0\" \"0\"", ent);
	
	SetEntityMoveType(client, MOVETYPE_NONE);
	SetEntityMoveType(ent, MOVETYPE_NONE);
	
	CreateTimer(3.0, BuildingTomb_post, ent);
	rp_SetBuildingData(ent, BD_owner, client);
	
	rp_SetClientBool(client, b_HasGrave, true);
	rp_SetClientBool(client, b_SpawnToGrave, true);
	return 1;
}
public Action BuildingTomb_post(Handle timer, any entity) {
	#if defined DEBUG
	PrintToServer("BuildingTomb_post");
	#endif
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	SetEntityMoveType(client, MOVETYPE_WALK);
	
	rp_Effect_BeamBox(client, entity, NULL_VECTOR, 0, 255, 100);
	SetEntProp(entity, Prop_Data, "m_takedamage", 2);
	
	HookSingleEntityOutput(entity, "OnBreak", BuildingTomb_break);
	return Plugin_Handled;
}
public void BuildingTomb_break(const char[] output, int caller, int activator, float delay) {
	#if defined DEBUG
	PrintToServer("BuildingTomb_break");
	#endif
	
	int owner = GetEntPropEnt(caller, Prop_Send, "m_hOwnerEntity");
	if( IsValidClient(owner) ) {
		CPrintToChat(owner, "{lightblue}[TSX-RP]{default} Votre tombe a été détruite.");
		rp_SetClientBool(owner, b_HasGrave, false);
	}
}
public Action Cmd_ItemLampe(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemLampe");
	#endif
	char arg1[32];
	GetCmdArg(0, arg1, sizeof(arg1));
	
	int client = GetCmdArgInt(1);
	
	if( StrContains(arg1, "jumelle") != -1 ) {
		rp_SetClientBool(client, b_Jumelle, true);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous pouvez maintenant utiliser vos jumelles (touche H).");
		rp_HookEvent(client, RP_OnAssurance,	fwdAssurance2);
}
	}
	else if( StrContains(arg1, "lampe") != -1 ) {
		rp_SetClientBool(client, b_LampePoche, true);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous pouvez maintenant utiliser votre visions nocturne (touche H).");
		rp_HookEvent(client, RP_OnAssurance,	fwdAssurance);
}
	}
	
	
	return Plugin_Handled;
}
public Action fwdAssurance(int client, int& amount) {
		amount += 250;
}
public Action fwdAssurance2(int client, int& amount) {
		amount += 300;
}
// ----------------------------------------------------------------------------
void GetClientFrontLocationData( int client, float position[3], float angles[3], float distance = 50.0 ) {
	
	float _origin[3], _angles[3], direction[3];
	GetClientAbsOrigin( client, _origin );
	GetClientEyeAngles( client, _angles );
	
	
	GetAngleVectors( _angles, direction, NULL_VECTOR, NULL_VECTOR );
	
	position[0] = _origin[0] + direction[0] * distance;
	position[1] = _origin[1] + direction[1] * distance;
	position[2] = _origin[2];
	
	angles[0] = 0.0;
	angles[1] = _angles[1];
	angles[2] = 0.0;
}

public Action Cmd_InfoColoc(int client){
	#if defined DEBUG
	PrintToServer("Cmd_InfoColoc");
	#endif
	if(rp_GetClientInt(client, i_AppartCount) == 0){
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous n'avez pas d'appartement.");
		return Plugin_Handled;
	}
	char tmp[128];
	char tmp2[64];
	int proprio;
	Handle menu = CreateMenu(MenuNothing);
	SetMenuTitle(menu, "Information sur vos appartements");
	for (int i = 1; i <= 48; i++) {
		if( rp_GetClientKeyAppartement(client, i) ) {

			if(i<10)
				Format(tmp,127,"--- Garage %i ---",i);
			else
				Format(tmp,127,"--- Appartement %i ---",i);

			AddMenuItem(menu, tmp, tmp,	ITEMDRAW_DISABLED);

			tmp = "  Bonus :";
			if(rp_GetAppartementInt(i, appart_bonus_energy) == 1)
				StrCat(tmp, 127, " energie");
			if(rp_GetAppartementInt(i, appart_bonus_heal) == 1)
				StrCat(tmp, 127, ", regen");
			if(rp_GetAppartementInt(i, appart_bonus_armor) == 1)
				StrCat(tmp, 127, ", kevlar");
			if(rp_GetAppartementInt(i, appart_bonus_garage) == 1)
				StrCat(tmp, 127, ", garage");
			if(rp_GetAppartementInt(i, appart_bonus_vitality) == 1)
				StrCat(tmp, 127, ", vitalité");
			if(rp_GetAppartementInt(i, appart_bonus_coffre) == 1)
				StrCat(tmp, 127, ", coffre");
			if(rp_GetAppartementInt(i, appart_bonus_paye) >= 50){
				Format(tmp2, 63, ", Paye * %i%%", rp_GetAppartementInt(i, appart_bonus_paye));
				StrCat(tmp, 127, tmp2);
			}
			AddMenuItem(menu, tmp, tmp,	ITEMDRAW_DISABLED);

			proprio = rp_GetAppartementInt(i, appart_proprio);
			Format(tmp,127,"  Proprio: %N", proprio);
			AddMenuItem(menu, tmp, tmp,	ITEMDRAW_DISABLED);

			for(int j=1; j<MAXPLAYERS; j++){
				if( !IsValidClient(j) )
					continue;
				if(rp_GetClientKeyAppartement(j, i) && j != proprio){
					Format(tmp,127,"  %N",j);
					AddMenuItem(menu, tmp, tmp,	ITEMDRAW_DISABLED);
				}
			}
		}
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 60);
	return Plugin_Handled;
}

public int MenuNothing(Handle menu, MenuAction action, int client, int param2) {
	#if defined DEBUG
	PrintToServer("MenuNothing");
	#endif
	if( action == MenuAction_Select ) {
		if( menu != INVALID_HANDLE )
			CloseHandle(menu);
	}
	else if( action == MenuAction_End ) {
		if( menu != INVALID_HANDLE )
			CloseHandle(menu);
	}
}
