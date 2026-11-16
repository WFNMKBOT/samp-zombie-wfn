#include <a_samp>
#include <FCNPC>

#define MAX_ZOMBIES     15
#define ZOMBIE_SPEED    FCNPC_MOVE_SPEED_SPRINT

#define COLOR_RED       0xFF3333FF
#define COLOR_GREEN     0x33FF33FF
#define COLOR_YELLOW    0xFFFF00FF
#define COLOR_WHITE     0xFFFFFFFF

new ZombieID[MAX_ZOMBIES];
new ZombieTimer;

new Float:ZombieSpawns[5][3] = {
    {235.1, 1835.5, 17.6},
    {188.6, 1920.4, 17.6},
    {268.2, 1884.1, 17.6},
    {135.4, 1850.2, 17.6},
    {215.0, 1810.0, 17.6}
};

main()
{
    print("\n-----------------------------------------");
    print("   ZOMBIE NPC SURVIVAL SIAP!             ");
    print("-----------------------------------------\n");
}

public OnGameModeInit()
{
    SetGameModeText("Zombie NPC Survival");
    UsePlayerPedAnims();
    SetWeather(9);
    SetWorldTime(0);

    AddPlayerClass(285, 213.4, 1871.2, 13.1, 0.0, 0, 0, 0, 0, 0, 0);
    AddPlayerClass(287, 213.4, 1871.2, 13.1, 0.0, 0, 0, 0, 0, 0, 0);

    CreateVehicle(470, 225.0, 1895.0, 17.6, 90.0, 0, 0, 60);

    for(new z = 0; z < MAX_ZOMBIES; z++)
    {
        new zname[24];
        format(zname, sizeof(zname), "Zombie_%d", z + 1);
        ZombieID[z] = FCNPC_Create(zname);

        new rand = random(sizeof(ZombieSpawns));
        FCNPC_Spawn(ZombieID[z], 162, ZombieSpawns[rand][0], ZombieSpawns[rand][1], ZombieSpawns[rand][2]);
        FCNPC_SetHealth(ZombieID[z], 100.0);
    }

    ZombieTimer = SetTimer("UpdateZombieAI", 600, true);
    return 1;
}

public OnGameModeExit()
{
    KillTimer(ZombieTimer);
    for(new z = 0; z < MAX_ZOMBIES; z++) {
        if(FCNPC_IsValid(ZombieID[z])) FCNPC_Destroy(ZombieID[z]);
    }
    return 1;
}

public OnPlayerConnect(playerid)
{
    if(IsPlayerNPC(playerid)) return 1;
    SendClientMessage(playerid, COLOR_YELLOW, "=== ZOMBIE NPC SURVIVAL ===");
    SendClientMessage(playerid, COLOR_WHITE, "Habisi gerombolan Zombie AI! Ketik /senjata untuk isi ulang peluru.");
    return 1;
}

public OnPlayerSpawn(playerid)
{
    if(IsPlayerNPC(playerid)) return 1;
    SetPlayerPos(playerid, 213.4, 1871.2, 13.1);
    SetPlayerHealth(playerid, 100.0);
    SetPlayerArmour(playerid, 100.0);
    GivePlayerWeapon(playerid, 24, 500);
    GivePlayerWeapon(playerid, 27, 200);
    GivePlayerWeapon(playerid, 31, 999);
    return 1;
}

forward UpdateZombieAI();
public UpdateZombieAI()
{
    for(new z = 0; z < MAX_ZOMBIES; z++)
    {
        new npcid = ZombieID[z];
        if(!FCNPC_IsValid(npcid) || FCNPC_IsDead(npcid)) continue;

        new Float:zx, Float:zy, Float:zz;
        FCNPC_GetPosition(npcid, zx, zy, zz);

        new target = INVALID_PLAYER_ID;
        new Float:minDist = 120.0;

        for(new i = 0; i < MAX_PLAYERS; i++)
        {
            if(!IsPlayerConnected(i) || IsPlayerNPC(i)) continue;
            if(GetPlayerState(i) == PLAYER_STATE_WASTED) continue;

            new Float:dist = GetPlayerDistanceFromPoint(i, zx, zy, zz);
            if(dist < minDist) {
                minDist = dist;
                target = i;
            }
        }

        if(target != INVALID_PLAYER_ID)
        {
            new Float:px, Float:py, Float:pz;
            GetPlayerPos(target, px, py, pz);

            if(minDist <= 1.6)
            {
                FCNPC_Stop(npcid);
                FCNPC_AimAt(npcid, px, py, pz, false);
                FCNPC_MeleeAttack(npcid, 500);

                new Float:hp;
                GetPlayerHealth(target, hp);
                SetPlayerHealth(target, hp - 12.0);
            }
            else
            {
                FCNPC_StopAttack(npcid);
                FCNPC_GoTo(npcid, px, py, pz, FCNPC_MOVE_TYPE_SPRINT, ZOMBIE_SPEED, FCNPC_MOVE_MODE_AUTO);
            }
        }
    }
    return 1;
}

public FCNPC_OnDeath(npcid, killerid, reason)
{
    if(killerid != INVALID_PLAYER_ID && !IsPlayerNPC(killerid)) {
        GivePlayerMoney(killerid, 100);
        GameTextForPlayer(killerid, "~g~+100$ ZOMBIE KILLED!", 1500, 3);
    }
    SetTimerEx("RespawnZombie", 5000, false, "i", npcid);
    return 1;
}

forward RespawnZombie(npcid);
public RespawnZombie(npcid)
{
    if(FCNPC_IsValid(npcid)) {
        new rand = random(sizeof(ZombieSpawns));
        FCNPC_Respawn(npcid);
        FCNPC_SetPosition(npcid, ZombieSpawns[rand][0], ZombieSpawns[rand][1], ZombieSpawns[rand][2]);
        FCNPC_SetHealth(npcid, 100.0);
    }
    return 1;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
    if(strcmp(cmdtext, "/senjata", true) == 0)
    {
        GivePlayerWeapon(playerid, 24, 500);
        GivePlayerWeapon(playerid, 27, 200);
        GivePlayerWeapon(playerid, 31, 999);
        SetPlayerHealth(playerid, 100.0);
        SetPlayerArmour(playerid, 100.0);
        SendClientMessage(playerid, COLOR_GREEN, "Senjata dan darah diisi ulang!");
        return 1;
    }
    return 0;
}
