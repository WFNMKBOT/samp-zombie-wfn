//======================= Inventory system copied ==============================
//===========================[INCLUDES START]===================================
#include <a_samp>
#define FIXES_ServerVarMsg 0
#include <fixes>
#include <sscanf2>
#include <SII>
#include <mxini>
#include <FCNPC>
#include <streamer>
#include <foreach>
#include <colandreas>
//============================[INCLUDES END]====================================
//===========================[DEFINES START]====================================
#undef  MAX_PLAYERS
#define MAX_PLAYERS                                                     50
//============================== [RRGGBB] ======================================
#define cwhite															"{EEFFFF}"
#define cligreen                                                        "{44CC22}"
#define cred                                                            "{FF1111}"
#define dred                                                            "{490B0B}"
#define cgreen                                                          "{05E200}"
#define cblue                                                           "{00B9FF}"
#define cjam                                                            "{E67EF8}"
#define corange                                                         "{FF9600}"
#define cgrey                                                           "{CCCCCC}"
#define cgold                                                           "{FFBB00}"
#define cplat                                                           "{A8A8A8}"
#define cyellow            								    		    "{FFFF00}"
#define cpurple                                                         "{6E00FF}"
#define cpblue                                                          "{A3CAD9}"
#define cband                                                           "{8080FF}"
//============================== [Colors] ======================================
#define red                                                           	0xFF0000FF
#define white                                                           0xFFFFFFFF
#define orange                                                          0xFFA000FF
#define purple                                                          0x6E00FFFF
#define green                                                           0x00FF0AFF
#define gold                                                            0xFFC800FF
#define plat                                                            0xAAAAAAFF
//============================== [Server config] ===============================
#define function%0(%1)     												forward%0(%1); public%0(%1)
#define HUMAN                                                           1
#define ZOMBIE                                                          2
#define PRESSED(%0)  													(((newkeys & (%0)) == (%0)) && ((oldkeys & (%0)) != (%0)))
#define HOLDING(%0)														((newkeys & (%0)) == (%0))
#define RELEASED(%0) 													(((newkeys & (%0)) != (%0)) && ((oldkeys & (%0)) == (%0)))
#define SendFMessage(%0,%1,%2,%3) 										do{new _str[150]; format(_str,150,%2,%3); SendClientMessage(%0,%1,_str);}while(FALSE)
#define SendFMessageToAll(%1,%2,%3) 									do{new _str[190]; format(_str,150,%2,%3); SendClientMessageToAll(%1,_str);}while(FALSE)
#define PlayAudioStream(%0,%1,%2)                               		PlayAudioStreamForPlayer(%0,%1); SetTimerEx("UnloadMusic",%2*1000,false,"i",%0)
#undef  MAX_VEHICLES
#define MAX_VEHICLES                                                    200
#define MAX_ITEMS 														20
#define MAX_ITEM_STACK 													99
#define MAX_ITEM_NAME 													24
#define isEven(%0) 														(!((%0) & 0b1))
#define isOdd(%0) 														!isEven((%0))
#define DSL 															DIALOG_STYLE_LIST
#define DSI 															DIALOG_STYLE_INPUT
#define DSM 															DIALOG_STYLE_MSGBOX
#define DSP 															DIALOG_STYLE_PASSWORD
#define DSTH                                                            DIALOG_STYLE_TABLIST_HEADERS
#define GRENADE_SPEED 													40.0
#define GRENADE_OBJECT 													342
#define MAX_PLAYER_GRENADES 											1
#define MAX_GRENADES 													(MAX_PLAYERS * MAX_PLAYER_GRENADES)

//============================== [FCNPC config] ===============================
#define FCNPC_MOVE_TYPE_AUTO      										(-1)
#define FCNPC_MOVE_TYPE_WALK      										(0)
#define FCNPC_MOVE_TYPE_RUN       										(1)
#define FCNPC_MOVE_TYPE_SPRINT    										(2)
#define FCNPC_MOVE_TYPE_DRIVE     										(3)

#define FCNPC_MOVE_SPEED_AUTO     										(-1.0)
#define FCNPC_MOVE_SPEED_WALK     										(0.1552086)
#define FCNPC_MOVE_SPEED_RUN      										(0.56444)
#define FCNPC_MOVE_SPEED_SPRINT   										(0.926784)

#define FCNPC_MAX_NODES           										(64)
#define FCNPC_INVALID_MOVEPATH_ID 										(-1)
#define FCNPC_INVALID_RECORD_ID   										(-1)
//============================== [FCNPC config] ================================

#define MAX_NPCS                                                         1000
#define MAX_ZOMBIES                                                      35 // Sesuaikan dengan maxnpc di server.cfg

main(){}

new IsDead[MAX_PLAYERS];
new CanBeStingered[MAX_PLAYERS];
new ZombieSkins[] = {75,77,78,79,134,135,137,160,162,212,213,230};

new ZombieID[MAX_ZOMBIES];
new NPCTargetID[MAX_NPCS];
new NPCRank[MAX_NPCS];
new NPCPerk[MAX_NPCS];
new NPCIsBiting[MAX_NPCS];
new NPCCanScream[MAX_NPCS];
new Text3D:NPCLabel[MAX_NPCS];

// Fungsi mencari posisi spawn valid di seluruh map / sekitar pemain aktif
stock GetDynamicZombieSpawnPos(&Float:outX, &Float:outY, &Float:outZ)
{
	new activePlayers[MAX_PLAYERS], count = 0;
	foreach(new i : Player)
	{
		if(!IsPlayerNPC(i) && IsDead[i] == 0 && GetPlayerInterior(i) == 0 && GetPlayerVirtualWorld(i) == 0)
		{
			activePlayers[count++] = i;
		}
	}

	if(count > 0)
	{
		// Pilih salah satu pemain aktif secara acak, lalu spawn zombie di radius 35 - 95 meter darinya
		new target = activePlayers[random(count)];
		new Float:px, Float:py, Float:pz;
		GetPlayerPos(target, px, py, pz);

		new Float:angle = float(random(360));
		new Float:dist = 35.0 + float(random(60));
		outX = px + (dist * floatsin(-angle, degrees));
		outY = py + (dist * floatcos(-angle, degrees));
	}
	else
	{
		// Jika belum ada pemain, sebar acak di seluruh map San Andreas
		outX = float(-2800 + random(5600));
		outY = float(-2800 + random(5600));
	}

	CA_FindZ_For2DCoord(outX, outY, outZ);
	if(outZ < 0.5) outZ = 3.0; // Hindari spawn di dasar laut dalam
	outZ += 1.0;
	return 1;
}

stock IsAnyPlayerNearPos(Float:x, Float:y, Float:z, Float:range)
{
	foreach(new i : Player)
	{
		if(!IsPlayerNPC(i) && IsDead[i] == 0 && GetPlayerInterior(i) == 0)
		{
			if(IsPlayerInRangeOfPoint(i, range, x, y, z)) return 1;
		}
	}
	return 0;
}

public OnPlayerDeath(playerid,killerid,reason)
{
	if(IsPlayerNPC(playerid)) return 0;
	IsDead[playerid] = 1;
	return 1;
}

public OnPlayerSpawn(playerid)
{
	if(IsPlayerNPC(playerid)) return 1;
	CanBeStingered[playerid] = 1;
	IsDead[playerid] = 0;
	GivePlayerWeapon(playerid, 24, 5000); // Desert Eagle
	GivePlayerWeapon(playerid, 31, 5000); // M4 untuk bertahan hidup
	return 1;
}

public OnGameModeInit()
{
	CA_Init();
	SetTimer("CheckPositions", 250, true);
	SetTimer("RelocateFarZombies", 4000, true); // Cek zombie yang terlalu jauh setiap 4 detik
	SetTimer("MoveNPCToRandomPos", 1500, false);
	CreateVehicle(411, 0, 0, 10, 0, 0, 0, -1, 0);

	for(new i = 0; i < MAX_ZOMBIES; i++)
	{
		new string[32];
		format(string, sizeof string, "ZOMBIE_%i", i);
		ZombieID[i] = FCNPC_Create(string);
		if(ZombieID[i] == INVALID_PLAYER_ID) continue;

		NPCTargetID[ZombieID[i]] = -1;
		NPCIsBiting[ZombieID[i]] = 0;

		new rand = random(17);
		if(rand <= 4) rand = 1;
		else if(rand <= 7) rand = 5;
		else if(rand <= 10) rand = 10;
		else if(rand <= 12) rand = 15;
		else if(rand <= 14) rand = 20;
		else if(rand == 15) rand = 25;
		else rand = 30;
		NPCRank[ZombieID[i]] = rand;

		new skin = ZombieSkins[random(sizeof ZombieSkins)];
		FCNPC_SetSkin(ZombieID[i], skin);
		FCNPC_SetHealth(ZombieID[i], 100);

		new Float:sx, Float:sy, Float:sz;
		GetDynamicZombieSpawnPos(sx, sy, sz);
		FCNPC_Spawn(ZombieID[i], skin, sx, sy, sz);
	}
	return 1;
}

public FCNPC_OnSpawn(npcid)
{
	new rand = random(sizeof ZombieSkins);
	FCNPC_SetSkin(npcid, ZombieSkins[rand]);
	FCNPC_SetSpeed(npcid, 1);
	NPCCanScream[npcid] = 1;

	rand = random(17);
	if(rand <= 4) rand = 1;
	else if(rand <= 7) rand = 5;
	else if(rand <= 10) rand = 10;
	else if(rand <= 12) rand = 15;
	else if(rand <= 14) rand = 20;
	else if(rand == 15) rand = 25;
	else rand = 30;
	NPCRank[npcid] = rand;

	if(NPCRank[npcid] == 1) NPCPerk[npcid] = 1;
	else if(NPCRank[npcid] == 5)
	{
		rand = random(2);
		NPCPerk[npcid] = (rand == 0) ? 4 : 2;
	}
	else if(NPCRank[npcid] == 10)
	{
		rand = random(3);
		if(rand == 0) NPCPerk[npcid] = 4;
		else if(rand == 1) NPCPerk[npcid] = 2;
		else NPCPerk[npcid] = 9;
	}
	else if(NPCRank[npcid] == 15)
	{
		rand = random(4);
		if(rand == 0) NPCPerk[npcid] = 4;
		else if(rand == 1) NPCPerk[npcid] = 2;
		else if(rand == 2) NPCPerk[npcid] = 9;
		else NPCPerk[npcid] = 11;
	}
	else if(NPCRank[npcid] == 20)
	{
		rand = random(4);
		if(rand == 0) NPCPerk[npcid] = 11;
		else if(rand == 1) NPCPerk[npcid] = 19;
		else if(rand == 2) NPCPerk[npcid] = 20;
		else NPCPerk[npcid] = 14;
	}
	else if(NPCRank[npcid] == 25 || NPCRank[npcid] == 30)
	{
		rand = random(6);
		if(rand == 0) NPCPerk[npcid] = 11;
		else if(rand == 1) NPCPerk[npcid] = 19;
		else if(rand == 2) NPCPerk[npcid] = 20;
		else if(rand == 3) NPCPerk[npcid] = 14;
		else if(rand == 4) NPCPerk[npcid] = 22;
		else NPCPerk[npcid] = 24;
	}

	NPCTargetID[npcid] = -1;
	NPCIsBiting[npcid] = 0;

	new health = 100;
	if(NPCRank[npcid] == 5) health = 125;
	else if(NPCRank[npcid] == 10) health = 150;
	else if(NPCRank[npcid] == 15) health = 175;
	else if(NPCRank[npcid] == 20) health = 200;
	else if(NPCRank[npcid] == 25) health = 225;
	else if(NPCRank[npcid] >= 30) health = 250;
	FCNPC_SetHealth(npcid, health);

	new string[128];
	format(string, sizeof string, ""cpurple"Rank: %i | Perk: %i\n"cred"HEALTH: %i", NPCRank[npcid], NPCPerk[npcid], health);
	if(IsValidDynamic3DTextLabel(NPCLabel[npcid])) DestroyDynamic3DTextLabel(NPCLabel[npcid]);
	NPCLabel[npcid] = CreateDynamic3DTextLabel(string, white, 0, 0, 0.5, 15, npcid, INVALID_VEHICLE_ID, 1, -1, -1, -1, STREAMER_3D_TEXT_LABEL_SD, -1, 0);
	return 1;
}

public FCNPC_OnRespawn(npcid)
{
	new Float:sx, Float:sy, Float:sz;
	GetDynamicZombieSpawnPos(sx, sy, sz);
	FCNPC_SetPosition(npcid, sx, sy, sz);
	return 1;
}

// Memindahkan zombie yang tertinggal jauh (>140m) agar selalu ada zombie di seluruh map tempat pemain berada
function RelocateFarZombies()
{
	new activeCount = 0;
	foreach(new p : Player)
	{
		if(!IsPlayerNPC(p) && IsDead[p] == 0 && GetPlayerInterior(p) == 0) activeCount++;
	}
	if(activeCount == 0) return 1;

	new Float:zx, Float:zy, Float:zz;
	foreach(new b : NPC)
	{
		if(FCNPC_IsDead(b)) continue;
		if(NPCTargetID[b] != -1) continue;

		FCNPC_GetPosition(b, zx, zy, zz);
		if(!IsAnyPlayerNearPos(zx, zy, zz, 140.0))
		{
			new Float:sx, Float:sy, Float:sz;
			GetDynamicZombieSpawnPos(sx, sy, sz);
			FCNPC_Stop(b);
			FCNPC_SetPosition(b, sx, sy, sz);
		}
	}
	return 1;
}

public OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ)
{
	new Float:x, Float:y, Float:z;
	GetPlayerPos(playerid, x, y, z);
	foreach(new i : NPC)
	{
		if(IsPlayerInRangeOfPoint(i, 100.0, x, y, z))
		{
			if(NPCTargetID[i] != -1) continue;
			new Float:Speed = 0.85;
			if(NPCRank[i] == 5) Speed = 0.95;
			else if(NPCRank[i] == 10) Speed = 1.05;
			else if(NPCRank[i] == 15) Speed = 1.15;
			else if(NPCRank[i] == 20) Speed = 1.2;
			else if(NPCRank[i] == 25) Speed = 1.25;
			else if(NPCRank[i] >= 30) Speed = 1.3;
			FCNPC_GoTo(i, x, y, z+1, MOVE_TYPE_SPRINT, Speed);
			NPCTargetID[i] = playerid;
		}
	}
	return 1;
}

public FCNPC_OnUpdate(npcid)
{
	new Float:x, Float:y, Float:z, Float:Mz;
	FCNPC_GetPosition(npcid, x, y, z);
	CA_FindZ_For2DCoord(x, y, Mz);
	if(floatabs(z - (Mz + 1.0)) > 2.5) // Koreksi ketinggian hanya jika melayang atau tenggelam
	{
		FCNPC_SetPosition(npcid, x, y, Mz + 1.0);
	}
	new Float:hp = FCNPC_GetHealth(npcid);
	new string[129];
	format(string, sizeof string, ""cpurple"Rank: %i | Perk: %i\n"cgrey"HEALTH: "cred"%i", NPCRank[npcid], NPCPerk[npcid], floatround(hp, floatround_round));
	UpdateDynamic3DTextLabelText(NPCLabel[npcid], white, string);
	return 1;
}

public FCNPC_OnDeath(npcid, killerid, weaponid)
{
	SetTimerEx("RespawnBot", 3000, false, "i", npcid);
	NPCTargetID[npcid] = -1;
	NPCIsBiting[npcid] = 0;
	FCNPC_Stop(npcid);
	return 1;
}

public FCNPC_OnReachDestination(npcid)
{
	return 1;
}

public FCNPC_OnTakeDamage(npcid, damagerid, weaponid, bodypart, Float:health_loss)
{
	if(NPCIsBiting[npcid] == 1) return 1;
	if(NPCTargetID[npcid] != -1) return 1;
	new Float:x, Float:y, Float:z;
	GetPlayerPos(damagerid, x, y, z);
	if(IsPlayerInRangeOfPoint(damagerid, 80.0, x, y, z))
	{
		new Float:Speed = 0.85;
		if(NPCRank[npcid] == 5) Speed = 0.95;
		else if(NPCRank[npcid] == 10) Speed = 1.05;
		else if(NPCRank[npcid] == 15) Speed = 1.15;
		else if(NPCRank[npcid] == 20) Speed = 1.2;
		else if(NPCRank[npcid] == 25) Speed = 1.25;
		else if(NPCRank[npcid] >= 30) Speed = 1.3;
		FCNPC_GoTo(npcid, x, y, z+1, MOVE_TYPE_SPRINT, Speed);
		NPCTargetID[npcid] = damagerid;
	}
	return 1;
}

//=======================================FUNCTIONS Start================================
function CheckPositions()
{
	new Float:x, Float:y, Float:z, Float:a, Float:hp;
	foreach(new b : NPC)
	{
		if(FCNPC_IsDead(b)) continue;
		new Float:Speed = 0.85, BiteTime = 1200;
		if(NPCRank[b] == 5) { Speed = 0.95; BiteTime = 1100; }
		else if(NPCRank[b] == 10) { Speed = 1.05; BiteTime = 1000; }
		else if(NPCRank[b] == 15) { Speed = 1.15; BiteTime = 900; }
		else if(NPCRank[b] == 20) { Speed = 1.2; BiteTime = 800; }
		else if(NPCRank[b] == 25) { Speed = 1.25; BiteTime = 750; }
		else if(NPCRank[b] >= 30) { Speed = 1.3; BiteTime = 650; }

		FCNPC_GetPosition(b, x, y, z);
		if(NPCTargetID[b] == -1)
		{
			new id = -1;
			foreach(new i : Player)
			{
				if(IsPlayerNPC(i) || IsDead[i] == 1) continue;
				if(IsPlayerInRangeOfPoint(i, 45.0, x, y, z)) // Jarak deteksi zombie diperluas menjadi 45 meter
				{
					id = i;
					break;
				}
			}
			if(id != -1)
			{
				NPCTargetID[b] = id;
				GetPlayerPos(id, x, y, z);
				FCNPC_GoTo(b, x, y, z+1, MOVE_TYPE_SPRINT, Speed);
				FCNPC_ApplyAnimation(b, "Muscular", "MuscleSprint", 4.1, 1, 1, 1, 1, 1);
			}
		}
		else
		{
			if(!IsPlayerConnected(NPCTargetID[b]) || IsDead[NPCTargetID[b]] == 1)
			{
				FCNPC_Stop(b);
				FCNPC_ApplyAnimation(b, "CARRY", "crry_prtial", 4.0, 0, 0, 0, 0, 0);
				NPCTargetID[b] = -1;
				continue;
			}
			GetPlayerPos(NPCTargetID[b], x, y, z);
			if(NPCPerk[b] != 9 && NPCPerk[b] != 20)
			{
				if(IsPlayerInRangeOfPoint(b, 0.8, x, y, z))
				{
					if(IsPlayerInRangeOfPoint(b, 0.6, x, y, z)) FCNPC_Stop(b);
					if(NPCIsBiting[b] == 0)
					{
						BiteHuman(NPCTargetID[b], b, BiteTime);
						NPCIsBiting[b] = 1;
					}
				}
			}
			else
			{
				if(NPCCanScream[b] == 1)
				{
					FCNPC_ApplyAnimation(b, "RIOT", "RIOT_shout", 3, 0, 1, 1, 0, 1000);
					if(NPCPerk[b] == 9)
					{
						FCNPC_Stop(b);
						NPCCanScream[b] = 0;
						SetTimerEx("ResetScream", 2700, false, "i", b);
						foreach(new i : Player)
						{
							if(IsPlayerInRangeOfPoint(b, 10, x, y, z))
							{
								GetPlayerPos(b, x, y, z);
								if(IsPlayerFacingPlayer(b, i, 70))
								{
									GetPlayerHealth(i, hp);
									SetPlayerHealth(i, hp - 5);
									GetPlayerVelocity(i, x, y, z);
									GetPlayerFacingAngle(b, a);
									x += (0.5 * floatsin(-a, degrees));
									y += (0.5 * floatcos(-a, degrees));
									ApplyAnimation(i, "PED", "KO_skid_front", 2.0, 0, 0, 0, 0, 0, 1);
									SetPlayerVelocity(i, x*0.9, y*0.9, z+0.1);
								}
							}
						}
					}
					else if(NPCPerk[b] == 20 && IsPlayerInRangeOfPoint(b, 16, x, y, z))
					{
						FCNPC_Stop(b);
						SetTimerEx("ResetScream", 3500, false, "i", b);
						NPCCanScream[b] = 0;
						foreach(new i : Player)
						{
							GetPlayerPos(b, x, y, z);
							if(IsPlayerFacingPlayer(b, i, 70))
							{
								if(!IsPlayerInAnyVehicle(i))
								{
									GetPlayerHealth(i, hp);
									SetPlayerHealth(i, hp - 7);
									GetPlayerVelocity(i, x, y, z);
									GetPlayerFacingAngle(b, a);
									x += (0.5 * floatsin(-a, degrees));
									y += (0.5 * floatcos(-a, degrees));
									ApplyAnimation(i, "PED", "KO_skid_front", 2.0, 0, 0, 0, 0, 0, 1);
									SetPlayerVelocity(i, x*1.1, y*1.1, z+0.14);
								}
								else
								{
									GetPlayerHealth(i, hp);
									SetPlayerHealth(i, hp - 7);
									SetVehicleAngularVelocity(GetPlayerVehicleID(i), 0, 0, 0.3);
								}
							}
						}
					}
				}
			}

			if(IsPlayerInRangeOfPoint(b, 70.0, x, y, z))
			{
				FCNPC_GoTo(b, x, y, z+1, MOVE_TYPE_SPRINT, Speed);
				FCNPC_ApplyAnimation(b, "Muscular", "MuscleSprint", 4.1, 1, 1, 1, 1, 1);
			}
			else
			{
				NPCTargetID[b] = -1;
				FCNPC_Stop(b);
				FCNPC_ApplyAnimation(b, "CARRY", "crry_prtial", 4.0, 0, 0, 0, 0, 0);
			}
		}
	}
	return 1;
}

function MoveNPCToRandomPos()
{
	new Float:x, Float:y, Float:z;
	foreach(new b : NPC)
	{
		if(FCNPC_IsDead(b)) continue;
		if(NPCTargetID[b] != -1) continue;
		if(random(3) != 0) continue;
		FCNPC_GetPosition(b, x, y, z);
		new Float:RandX = x + random(20) - random(20);
		new Float:RandY = y + random(20) - random(20);
		new Float:RandZ;
		CA_FindZ_For2DCoord(RandX, RandY, RandZ);
		FCNPC_GoTo(b, RandX, RandY, RandZ+1, MOVE_TYPE_WALK, 0.2);
	}
	SetTimer("MoveNPCToRandomPos", 1000 + random(3000), false);
	return 1;
}

function RespawnBot(npcid)
{
	FCNPC_Respawn(npcid);
	return 1;
}

function ResetScream(npcid)
{
	NPCCanScream[npcid] = 1;
	return 1;
}

function BiteHuman(playerid, npcid, BiteTime)
{
	new Float:hp, Float:x, Float:y, Float:z;
	if(FCNPC_IsDead(npcid) || IsDead[playerid] == 1) return NPCIsBiting[npcid] = 0;
	FCNPC_GetPosition(npcid, x, y, z);
	if(IsPlayerInRangeOfPoint(playerid, 1.3, x, y, z))
	{
		ApplyAnimation(playerid, "PED", "DAM_armR_frmFT", 2, 0, 1, 1, 0, 0, 1);
		PlayNearSound(playerid, 1136);
		ApplyAnimation(npcid, "WAYFARER", "WF_FWD", 4, 0, 0, 0, 0, 0, 1);
		if(NPCPerk[npcid] == 11 && CanBeStingered[playerid] == 1)
		{
			CanBeStingered[playerid] = 0;
			ApplyAnimation(playerid, "PED", "DAM_Stomach_frmFT", 0.5, 0, 0, 0, 0, 0, 1);
			SetTimerEx("StingerPhase1", 500, false, "i", playerid);
			SetTimerEx("StingerPhase2", 1000, false, "i", playerid);
			SetTimerEx("CanBeStingeredTime", 12000, false, "i", playerid);
		}
		GetPlayerHealth(playerid, hp);
		if(NPCPerk[npcid] == 2 || NPCPerk[npcid] == 19) SetPlayerHealth(playerid, hp - 5);
		else SetPlayerHealth(playerid, hp - 3);

		hp = FCNPC_GetHealth(npcid);
		new MaxHealth = 125;
		if(NPCRank[npcid] >= 5) MaxHealth = 150;
		if(NPCRank[npcid] >= 10) MaxHealth = 200;
		if(NPCRank[npcid] >= 15) MaxHealth = 225;
		if(NPCRank[npcid] >= 20) MaxHealth = 250;

		if(NPCPerk[npcid] == 4 || NPCPerk[npcid] == 19) FCNPC_SetHealth(npcid, (hp >= MaxHealth-5) ? float(MaxHealth) : hp+5);
		else if(NPCPerk[npcid] == 22) FCNPC_SetHealth(npcid, (hp >= MaxHealth-8) ? float(MaxHealth) : hp+8);
		else FCNPC_SetHealth(npcid, (hp >= MaxHealth-3) ? float(MaxHealth) : hp+3);

		SetTimerEx("BiteHuman", BiteTime, false, "iii", playerid, npcid, BiteTime);
	}
	else NPCIsBiting[npcid] = 0;
	return 1;
}

function StingerPhase1(playerid)
{
	ApplyAnimation(playerid, "PED", "DAM_LegL_frmFT", 5, 0, 0, 0, 0, 0, 1);
	return 1;
}

function StingerPhase2(playerid)
{
	ApplyAnimation(playerid, "PED", "DAM_stomach_frmRT", 5, 0, 0, 0, 0, 0, 1);
	return 1;
}

function CanBeStingeredTime(playerid)
{
	CanBeStingered[playerid] = 1;
	return 1;
}

//=======================================STOCKS START==================================
stock PlayNearSound(playerid, soundid)
{
	new Float:p[3];
	GetPlayerPos(playerid, p[0], p[1], p[2]);
	for(new i; i < MAX_PLAYERS; i++)
	{
		if(IsPlayerInRangeOfPoint(i, 7.0, p[0], p[1], p[2]))
			PlayerPlaySound(i, soundid, p[0], p[1], p[2]);
	}
	return 1;
}

stock IsPlayerFacingPlayer(playerid, targetid, Float:dOffset)
{
	new Float:pX, Float:pY, Float:pZ, Float:pA, Float:X, Float:Y, Float:Z, Float:ang;
	if(!IsPlayerConnected(playerid) || !IsPlayerConnected(targetid)) return 0;
	GetPlayerPos(targetid, pX, pY, pZ);
	GetPlayerPos(playerid, X, Y, Z);
	GetPlayerFacingAngle(playerid, pA);

	if(Y > pY) ang = (-acos((X - pX) / floatsqroot((X - pX)*(X - pX) + (Y - pY)*(Y - pY))) - 90.0);
	else if(Y < pY && X < pX) ang = (acos((X - pX) / floatsqroot((X - pX)*(X - pX) + (Y - pY)*(Y - pY))) - 450.0);
	else if(Y < pY) ang = (acos((X - pX) / floatsqroot((X - pX)*(X - pX) + (Y - pY)*(Y - pY))) - 90.0);

	if(AngleInRangeOfAngle(-ang, pA, dOffset)) return true;
	return false;
}

stock AngleInRangeOfAngle(Float:a1, Float:a2, Float:range)
{
	a1 -= a2;
	if((a1 < range) && (a1 > -range)) return true;
	return false;
}
