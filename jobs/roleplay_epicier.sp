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

#define __LAST_REV__ 		"v:0.1.0"

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

//#define DEBUG

public Plugin myinfo = {
	name = "Jobs: EPICIER", author = "KoSSoLaX",
	description = "RolePlay - Jobs: Epicier",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

Handle g_hCigarette[65], g_hEVENT;
int g_cBeam;

// ----------------------------------------------------------------------------
public void OnPluginStart() {
	RegServerCmd("rp_item_cig", 		Cmd_ItemCigarette,		"RP-ITEM",	FCVAR_UNREGISTERED);	
	RegServerCmd("rp_item_sanandreas",	Cmd_ItemSanAndreas,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_needforspeed",Cmd_ItemNeedForSpeed,	"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_lessive",		Cmd_ItemLessive,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_cafe",		Cmd_ItemCafe,			"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_crayons",		Cmd_ItemCrayons,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_map",			Cmd_ItemMaps,			"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_ruban",		Cmd_ItemRuban,			"RP-ITEM",	FCVAR_UNREGISTERED);
	
	g_hEVENT =  FindConVar("rp_event");
	
	for (int i = 1; i <= MaxClients; i++)
		if( IsValidClient(i) )
			OnClientPostAdminCheck(i);
}
public void OnMapStart() {
	g_cBeam = PrecacheModel("materials/sprites/laserbeam.vmt", true);
}
public void OnClientPostAdminCheck(int client) {
	#if defined DEBUG
	PrintToServer("OnClientPostAdminCheck");
	#endif
	
	if( rp_GetClientBool(client, b_Crayon) )
		rp_HookEvent(client, RP_PrePlayerTalk, fwdTalkCrayon);
	
	rp_HookEvent(client, RP_OnPlayerUse, fwdUse);
}
public Action fwdUse(int client) {
	char tmp[32];
	rp_GetZoneData(rp_GetPlayerZone(client), zone_type_type, tmp, sizeof(tmp));
	
	if( StrEqual(tmp, "metro") ) {
		DisplayMetroMenu(client);
	}
}

void DisplayMetroMenu(int client) {
	#if defined DEBUG
	PrintToServer("DisplayMetroMenu");
	#endif
	
	if( !rp_IsTutorialOver(client) )
		return;
	
	Handle menu = CreateMenu(eventMetroMenu);
	SetMenuTitle(menu, "== Station de métro: ==");
	
	if( GetConVarInt(g_hEVENT) == 1 )
		AddMenuItem(menu, "metro_event", "Métro: Station événementiel");
	
	AddMenuItem(menu, "metro_paix", 	"Métro: Station de la paix");
	AddMenuItem(menu, "metro_zoning", 	"Métro: Station Place Station");
	AddMenuItem(menu, "metro_inno", 	"Métro: Station de l'innovation");
	AddMenuItem(menu, "metro_pigalle", 	"Métro: Station pigalle");
	
	AddMenuItem(menu, "metro_nucleair", "Métro: Station PVP - Nucléaire");
	AddMenuItem(menu, "metro_tour", 	"Métro: Station PVP - Toit tour");
	
	SetMenuPagination(menu, MENU_NO_PAGINATION);
	SetMenuExitBackButton(menu, false);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 30);
}

public int eventMetroMenu(Handle menu, MenuAction action, int client, int param2) {
	#if defined DEBUG
	PrintToServer("eventMetroMenu");
	#endif
	if( action == MenuAction_Select ) {
		char options[64], tmp[64];
		GetMenuItem(menu, param2, options, sizeof(options));
		rp_GetZoneData(rp_GetPlayerZone(client), zone_type_type, tmp, sizeof(tmp));
		
		if( !StrEqual(tmp, "metro", false) ) {
			return;
		}
		if( StrEqual(options, "metro_event") && GetConVarInt(g_hEVENT) == 0 ) {
			return;
		}
		
		int Max, i, hours, min, iLocation[150];
		
		for( i=0; i<150; i++ ) {
			rp_GetLocationData(i, location_type_base, tmp, sizeof(tmp));
			
			if( StrEqual(tmp, options, false) ) {
				iLocation[Max++] = i;
			}
		}
		i = iLocation[Math_GetRandomInt(0, (Max-1))];
		float pos[3];
		
		pos[0] = float(rp_GetLocationInt(i, location_type_origin_x));
		pos[1] = float(rp_GetLocationInt(i, location_type_origin_y));
		pos[2] = float(rp_GetLocationInt(i, location_type_origin_z))+8.0;
		
		rp_GetTime(hours, min);
		min = 5 - (min % 5);
		
		rp_GetZoneData(rp_GetZoneFromPoint(pos), zone_type_name, tmp, sizeof(tmp));
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Restez assis à l'intérieur du métro, le prochain départ pour %s est dans %d seconde(s).", tmp, min );
		rp_SetClientInt(client, i_TeleportTo, i);
		CreateTimer(float(min) + Math_GetRandomFloat(0.01, 0.8), metroTeleport, client);
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
}
public Action metroTeleport(Handle timer, any client) {
	
	char tmp[32];
	rp_GetZoneData(rp_GetPlayerZone(client), zone_type_type, tmp, sizeof(tmp));
	int tp = rp_GetClientInt(client, i_TeleportTo);
	rp_SetClientInt(client, i_TeleportTo, 0);
	
	if( tp == 0 )
		return Plugin_Handled;
	if( !StrEqual(tmp, "metro", false) )
		return Plugin_Handled;
	
	bool paid = false;
	
	rp_GetLocationData(tp, location_type_base, tmp, sizeof(tmp));
	
	if( StrEqual(tmp, "metro_event") ) {
		if( rp_GetClientBool(client, b_IsMuteEvent) == true ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} En raison de votre mauvais comportement, il vous est temporairement interdit de participer à un event.");
			return Plugin_Handled;
		}
		paid = true;
	}
	if( !paid && rp_GetClientJobID(client) == 31 ) {
		paid = true;
	}
	if( !paid && rp_GetClientItem(client, 42) > 0 ) {
		paid = true;
		rp_ClientGiveItem(client, 42, -1);
	}
	if( !paid && rp_GetClientItem(client, 42, true) > 0) { 		
		paid = true;
		rp_ClientGiveItem(client, 42, -1, true);
	}
	if( !paid && (rp_GetClientInt(client, i_Money)+rp_GetClientInt(client, i_Bank)) >= 100 ) {
		rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) - 100);
		rp_SetJobCapital(31, rp_GetJobCapital(31) + 100);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Le métro vous a couté 100$. Pensez à acheter des tickets à un épicier pour obtenir une réduction.");
		paid = true;
	}
	
	if( paid  ) {
		float pos[3], vel[3];
		pos[0] = float(rp_GetLocationInt(tp, location_type_origin_x));
		pos[1] = float(rp_GetLocationInt(tp, location_type_origin_y));
		pos[2] = float(rp_GetLocationInt(tp, location_type_origin_z))+8.0;
		
		vel[0] = Math_GetRandomFloat(-300.0, 300.0);
		vel[1] = Math_GetRandomFloat(-300.0, 300.0);
		vel[2] = 100.0;
						
		TeleportEntity(client, pos, NULL_VECTOR, vel);
		FakeClientCommandEx(client, "sm_stuck");
	}
	
	
	return Plugin_Continue;
}
// ----------------------------------------------------------------------------
public Action Cmd_ItemCigarette(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemCigarette");
	#endif
	
	char Arg1[32];
	GetCmdArg(1, Arg1, 31);
	int client = GetCmdArgInt(2);
	
	
	if( StrEqual(Arg1, "deg") ) {		
		rp_SetClientInt(client, i_LastAgression, GetTime());
		float origin[3];
		GetClientAbsOrigin(client, origin);
		origin[2] -= 1.0;
		rp_Effect_Push(origin, 500.0, 1000.0, client);
	}
	else if( StrEqual(Arg1, "flame") ) {
		UningiteEntity(client);
		for(float i=0.1; i<=30.0; i+= 0.50) {
			CreateTimer(i, Task_UningiteEntity, client);
		}
	}
	else if( StrEqual(Arg1, "light") ) {
		rp_HookEvent(client, RP_PrePlayerPhysic, fwdCigGravity, 30.0);
	}
	else if( StrEqual(Arg1, "choco") ) {
		// Ne fait absolument rien.
	}
	else { // WHAT IS THAT KIND OF SORCELERY?
		rp_HookEvent(client, RP_PrePlayerPhysic, fwdCigSpeed, 30.0);
	}
	
	ServerCommand("sm_effect_particles %d shacks_exhaust 30 forward", client);
	
	if( g_hCigarette[client] )
		delete g_hCigarette[client];
	
	g_hCigarette[client] = CreateTimer( 30.0, ItemStopCig, client);
	rp_SetClientBool(client, b_Smoking, true);
	
	return Plugin_Handled;
}
public Action Task_UningiteEntity(Handle timer, any client) {
	#if defined DEBUG
	PrintToServer("Task_UningiteEntity");
	#endif
	UningiteEntity(client);
}
public Action ItemStopCig(Handle timer, any client) {
	#if defined DEBUG
	PrintToServer("ItemStopCig");
	#endif
	
	rp_SetClientBool(client, b_Smoking, false);
}
public Action fwdCigSpeed(int client, float& speed, float& gravity) {
	#if defined DEBUG
	PrintToServer("fwdCigSpeed");
	#endif
	speed += 0.15;
	
	return Plugin_Changed;
}
public Action fwdCigGravity(int client, float& speed, float& gravity) {
	#if defined DEBUG
	PrintToServer("fwdCigGravity");
	#endif
	gravity -= 0.15;
	
	return Plugin_Changed;
}
// ----------------------------------------------------------------------------
public Action Cmd_ItemRuban(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemRuban");
	#endif

	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);
	rp_ClientGiveItem(client, item_id);
	
	Handle dp;
	CreateDataTimer(0.25, Cmd_ItemRuban_Task, dp);
	WritePackCell(dp, client);
	WritePackCell(dp, item_id);
	
	
	return Plugin_Handled;
}
public Action Cmd_ItemRuban_Task(Handle timer, any dp) {
	ResetPack(dp);
	int client = ReadPackCell(dp);
	int item_id = ReadPackCell(dp);
	
	char tmp[32];
	Handle menu = CreateMenu(MenuRubanWho);
	SetMenuTitle(menu, "Sur qui mettre le ruban ?");
	Format(tmp, 31, "%i_target", item_id);
	AddMenuItem(menu, tmp, "Ce que je vise");
	Format(tmp, 31, "%i_client", item_id);
	AddMenuItem(menu, tmp, "Moi");
	DisplayMenu(menu, client, 60);
	
	CloseHandle(dp);
	return Plugin_Handled;
}
public int MenuRubanWho(Handle menu, MenuAction action, int client, int param2) {
	if( action == MenuAction_Select ) {
		int target;
		char options[64], data[2][32];
		GetMenuItem(menu, param2, options, 63);
		ExplodeString(options, "_", data, sizeof(data), sizeof(data[]));
		if(StrEqual(data[1],"client")){
			target = client;
		}
		else{
			target = GetClientAimTarget(client, false);
			if( target == 0 || !IsValidEdict(target) || !IsValidEntity(target) ) {
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre cible n'est pas valide.");
				return;
			}
			char classname[64];
			GetEdictClassname(target, classname, sizeof(classname));

			if( StrContains("chicken|player|weapon|prop_physics|", classname) == -1 ){
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre cible n'est pas valide.");
				return;
			}

			if( !rp_IsEntitiesNear(client, target) ){
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre cible est trop loin.");
				return;
			}
		}
		char tmp[64];
		Handle menucolor = CreateMenu(MenuRubanColor);
		SetMenuTitle(menucolor, "De quelle couleur ?");
		Format(tmp,63,"%s_%i_%i_%i_%i_%i", data[0], target, 255, 0  , 0  , 200);
		AddMenuItem(menucolor, tmp, "Rouge");
		Format(tmp,63,"%s_%i_%i_%i_%i_%i", data[0], target, 0  , 255, 0  , 200);
		AddMenuItem(menucolor, tmp, "Vert");
		Format(tmp,63,"%s_%i_%i_%i_%i_%i", data[0], target, 0  , 0  , 255, 200);
		AddMenuItem(menucolor, tmp, "Bleu");
		Format(tmp,63,"%s_%i_%i_%i_%i_%i", data[0], target, 255, 255, 255, 200);
		AddMenuItem(menucolor, tmp, "Blanc");
		Format(tmp,63,"%s_%i_%i_%i_%i_%i", data[0], target, 122, 122, 0  , 200);
		AddMenuItem(menucolor, tmp, "Jaune");
		Format(tmp,63,"%s_%i_%i_%i_%i_%i", data[0], target, 253, 108, 158, 200);
		AddMenuItem(menucolor, tmp, "Rose");
		DisplayMenu(menucolor, client, 20);
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
}
public int MenuRubanColor(Handle menu, MenuAction action, int client, int param2) {
	if( action == MenuAction_Select ) {
		char options[64], data[6][32];
		int color[4];
		GetMenuItem(menu, param2, options, 63);
		ExplodeString(options, "_", data, sizeof(data), sizeof(data[]));
		int item_id = StringToInt(data[0]);
		int target = StringToInt(data[1]);
		color[0] = StringToInt(data[2]);
		color[1] = StringToInt(data[3]);
		color[2] = StringToInt(data[4]);
		color[3] = StringToInt(data[5]);
		if( target == 0 || !IsValidEdict(target) || !IsValidEntity(target) ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre cible a disparue.");
			return;
		}
		if(rp_GetClientItem(client, item_id)==0){
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous n'avez plus l'item ruban.");
			return;
		}
		else{
			rp_ClientGiveItem(client, item_id, -1);
		}

		TE_SetupBeamFollow(target, g_cBeam, 0, 180.0, 4.0, 0.1, 5, color);
		TE_SendToAll();
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
}
// ----------------------------------------------------------------------------
public Action Cmd_ItemSanAndreas(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemSanAndreas");
	#endif
	
	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);
	int wepid = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	char classname[64];
	
	if( !IsValidEntity(wepid) ) {
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	
	GetEdictClassname(wepid, classname, sizeof(classname));
		
	if( StrContains(classname, "weapon_bayonet") == 0 || StrContains(classname, "weapon_knife") == 0 ) {
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
		
	int ammo = Weapon_GetPrimaryClip(wepid);
	if( ammo >= 5000 ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous aviez déjà 5000 balles.");
		return Plugin_Handled;
	}
	ammo += 1000;
	if( ammo > 5000 )
		ammo = 5000;
	Weapon_SetPrimaryClip(wepid, ammo);
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre arme a maintenant %i balles", ammo);
	
	SDKHook(wepid, SDKHook_Reload, OnWeaponReload);
	return Plugin_Handled;
}
public Action OnWeaponReload(int wepid) {
	static float cache[65];
	
	int ammo = Weapon_GetPrimaryClip(wepid);
	if( ammo >= 150 ) {
		int client = Weapon_GetOwner(wepid);
		
		if( cache[client] < GetGameTime() ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre arme a un San Andreas, il vous reste %d balles dans votre chargeur.", ammo);
			cache[client] = GetGameTime() + 1.0;
		}
		
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Cmd_ItemNeedForSpeed(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemNeedForSpeed");
	#endif
	
	int client = GetCmdArgInt(1);
	
	rp_HookEvent(client, RP_PrePlayerPhysic, fwdCigSpeed, 60.0);
	rp_HookEvent(client, RP_PrePlayerPhysic, fwdCigSpeed, 10.0);
	
}
public Action Cmd_ItemLessive(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemLessive");
	#endif
	
	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);
	
	if( rp_IsInPVP(client) ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Cet objet est interdit en PvP.");
		return Plugin_Handled;
	}
	
	SDKHooks_TakeDamage(client, client, client, 5000.0);
	rp_ClientDamage(client, 5000, client);
	
	rp_ClientRespawn(client);
	return Plugin_Handled;
}
public Action Cmd_ItemCafe(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemCafe");
	#endif
	
	int client = GetCmdArgInt(1);
	
	rp_HookEvent(client, RP_PrePlayerPhysic, fwdCigSpeed, 10.0);
	rp_HookEvent(client, RP_PrePlayerPhysic, fwdCigSpeed, 10.0);
	
	rp_IncrementSuccess(client, success_list_cafeine);
}
public Action Cmd_ItemCrayons(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemCrayons");
	#endif
	
	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);
	
	bool crayon = rp_GetClientBool(client, b_Crayon);
	
	if( crayon ) {
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	
	rp_IncrementSuccess(client, success_list_rainbow);
	rp_HookEvent(client, RP_PrePlayerTalk,	fwdTalkCrayon);	
	rp_HookEvent(client, RP_OnAssurance,	fwdAssurance);
	
	rp_SetClientBool(client, b_Crayon, true);
	return Plugin_Handled;
}
public Action fwdAssurance(int client, int& amount) {
	if( rp_GetClientBool(client, b_Crayon) )
		amount += 900;
}
public Action fwdTalkCrayon(int client, char[] szSayText, int length, bool local) {
	
	char tmp[64];
	int hours, minutes;
	rp_GetTime(hours, minutes);
	
	IntToString( GetClientHealth(client), tmp, sizeof(tmp));
	ReplaceString(szSayText, length, "{hp}", tmp);
	
	IntToString( rp_GetClientInt(client, i_Kevlar), tmp, sizeof(tmp));
	ReplaceString(szSayText, length, "{ap}", tmp);
	
	IntToString( hours, tmp, sizeof(tmp));
	ReplaceString(szSayText, length, "{heure}", tmp);

	if(hours != 23)
		IntToString( hours+1, tmp, sizeof(tmp));
	else
		tmp="0";

	ReplaceString(szSayText, length, "{h+1}", tmp);

	IntToString( minutes, tmp, sizeof(tmp));
	ReplaceString(szSayText, length, "{minute}", tmp);
	
	rp_GetDate(tmp, length);
	ReplaceString(szSayText, length, "{date}", tmp);
	GetClientName(client, tmp, sizeof(tmp));							ReplaceString(szSayText, length, "{me}", tmp);
	
	int target = GetClientTarget(client);
	if( IsValidClient(target) ) {
		GetClientName(target, tmp, sizeof(tmp));
		ReplaceString(szSayText, length, "{target}", tmp);
	}
	else {
		ReplaceString(szSayText, length, "{target}", "Personne");
	}
	
	rp_GetZoneData(rp_GetPlayerZone( rp_IsValidDoor(target) ? target : client ), zone_type_name, tmp, sizeof(tmp));
	ReplaceString(szSayText, length, "{door}", tmp);
	
	rp_GetJobData(rp_GetClientInt(client, i_Job), job_type_name, tmp, sizeof(tmp));
	ReplaceString(szSayText, length, "{job}", tmp);
	
	rp_GetJobData(rp_GetClientInt(client, i_Group), job_type_name, tmp, sizeof(tmp));
	ReplaceString(szSayText, length, "{gang}", tmp);
	
	rp_GetZoneData(rp_GetPlayerZone( client ), zone_type_name, tmp, sizeof(tmp));
	ReplaceString(szSayText, length, "{zone}", tmp);
	
	
	ReplaceString(szSayText, length, "[TSX-RP]", "");	
	ReplaceString(szSayText, length, "{white}", "{default}");
	
	return Plugin_Changed;
}

public Action Cmd_ItemMaps(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemMaps");
	#endif
	
	int client = GetCmdArgInt(1);
	rp_SetClientBool(client, b_Map, true);
	rp_HookEvent(client, RP_OnAssurance,	fwdAssurance2);
}
public Action fwdAssurance2(int client, int& amount) {
		amount += 1000;
}
// ----------------------------------------------------------------------------
void UningiteEntity(int entity) {
	
	int ent = GetEntPropEnt(entity, Prop_Data, "m_hEffectEntity");
	if( IsValidEdict(ent) )
		SetEntPropFloat(ent, Prop_Data, "m_flLifetime", 0.0); 
}
