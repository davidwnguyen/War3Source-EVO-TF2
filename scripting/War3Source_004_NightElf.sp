#include <war3source>

#assert GGAMEMODE == MODE_WAR3SOURCE
#assert GGAMETYPE_JAILBREAK == JAILBREAK_OFF

#define RACE_ID_NUMBER 4
#define RACE_LONGNAME "Night Elf"
#define RACE_SHORTNAME "nightelf"

/**
* File: War3Source_NightElf.sp
* Description: The Night Elf race for War3Source.
* Author(s): Anthony Iacono
*/

public W3ONLY(){} //unload this?

int thisRaceID;

bool bIsEntangled[MAXPLAYERSCUSTOM];

Handle EntangleCooldownCvar; // cooldown

//Handle hWeaponDrop;


int SKILL_EVADE, SKILL_THORNS, SKILL_TRUESHOT, ULT_ENTANGLE; //, SKILL_SHADOWMELD;

//float Shadowmeld[7]={0.0,0.80,0.70,0.60,0.50,0.50,0.50};

float EvadeChance[]={0.10,0.11,0.12,0.13,0.14};
float ThornsReturnDamage[]={0.20,0.22,0.25,0.27,0.3};
float TrueshotDamagePercent[]={0.20,0.22,0.25,0.27,0.3};
float EntangleDistance[]={2000.0,2500.0,3000.0,3500.0,4000.0};
float EntangleDuration[]={5.0, 5.25, 5.5, 5.75, 6.0};

char entangleSound[]="war3source/entanglingrootsdecay1.mp3";
//char entangleSound[256]; //="war3source/entanglingrootsdecay1.mp3";

// Effects
//int TeleBeam,
int BeamSprite,HaloSprite;

//char RaceShortName[]="nightelf";

// Methodmap inherits W3player methodmap from war3source.inc
methodmap ThisRacePlayer < W3player
{
	// constructor
	public ThisRacePlayer(int playerindex) //constructor
	{
		if(!ValidPlayer(playerindex)) return view_as<ThisRacePlayer>(0);
		return view_as<ThisRacePlayer>(playerindex); //make sure you do validity check on players
	}
	property bool IsEntangled
	{
		public get() { return bIsEntangled[this.index]; }
		public set( bool value ) { bIsEntangled[this.index] =  value; }
	}
}

public Plugin:myinfo =
{
	name = "Race - Night Elf",
	author = "PimpinJuice & El Diablo",
	description = "The Night Elf race for War3Source.",
	version = "1.0.0.0",
	url = "http://pimpinjuice.net/"
};

bool HooksLoaded = false;
public void Load_Hooks()
{
	if(HooksLoaded) return;
	HooksLoaded = true;

	W3Hook(W3Hook_OnW3TakeDmgBulletPre, OnW3TakeDmgBulletPre);
	W3Hook(W3Hook_OnWar3EventPostHurt, OnWar3EventPostHurt);
	W3Hook(W3Hook_OnW3TakeDmgAll, OnW3TakeDmgAll);
	W3Hook(W3Hook_OnUltimateCommand, OnUltimateCommand);
	//W3Hook(W3Hook_OnAbilityCommand, OnAbilityCommand);
	W3Hook(W3Hook_OnWar3EventSpawn, OnWar3EventSpawn);
}
public void UnLoad_Hooks()
{
	if(!HooksLoaded) return;
	HooksLoaded = false;

	W3Unhook(W3Hook_OnW3TakeDmgBulletPre, OnW3TakeDmgBulletPre);
	W3Unhook(W3Hook_OnWar3EventPostHurt, OnWar3EventPostHurt);
	W3Unhook(W3Hook_OnW3TakeDmgAll, OnW3TakeDmgAll);
	W3Unhook(W3Hook_OnUltimateCommand, OnUltimateCommand);
	//W3Unhook(W3Hook_OnAbilityCommand, OnAbilityCommand);
	W3Unhook(W3Hook_OnWar3EventSpawn, OnWar3EventSpawn);
}
bool RaceDisabled=true;
public OnWar3RaceEnabled(newrace)
{
	if(newrace==thisRaceID)
	{
		Load_Hooks();

		RaceDisabled=false;
	}
}
public OnWar3RaceDisabled(oldrace)
{
	if(oldrace==thisRaceID)
	{
		RaceDisabled=true;

		UnLoad_Hooks();
	}
}
//	if(RaceDisabled)
//		return;


public OnPluginStart()
{
	EntangleCooldownCvar=CreateConVar("war3_nightelf_entangle_cooldown","20","Cooldown timer.");

	//LoadTranslations("w3s.race.nightelf.phrases");
}
public OnAllPluginsLoaded()
{
	War3_RaceOnPluginStart("nightelf");
}

public OnPluginEnd()
{
	if(LibraryExists("RaceClass"))
		War3_RaceOnPluginEnd("nightelf");
}

public OnMapStart()
{
	UnLoad_Hooks();

	strcopy(entangleSound,sizeof(entangleSound),"war3source/entanglingrootsdecay1.mp3");
	//TeleBeam=PrecacheModel("materials/sprites/tp_beam001.vmt");

	BeamSprite=War3_PrecacheBeamSprite();
	HaloSprite=War3_PrecacheHaloSprite();

	PrecacheSound(entangleSound);
}

public OnAddSound(sound_priority)
{
	if(sound_priority==PRIORITY_MEDIUM)
	{
		War3_AddSound(entangleSound);
	}
}

/* ***************************  OnWar3LoadRaceOrItemOrdered2 *************************************/

public OnWar3LoadRaceOrItemOrdered2(num,reloadrace_id,String:shortname[])
{
	if(num==RACE_ID_NUMBER||(reloadrace_id>0&&StrEqual(RACE_SHORTNAME,shortname,false)))
	{
		thisRaceID=War3_CreateNewRace(RACE_LONGNAME,RACE_SHORTNAME,reloadrace_id,"Evasion, roots, damage.");
		SKILL_EVADE=War3_AddRaceSkill(thisRaceID,"Evasion","Up to 14 percent chance of evading a shot",false,4);
		SKILL_THORNS=War3_AddRaceSkill(thisRaceID,"Thorns Aura","You deal up to 30% percent of damage recieved to your attacker. ",false,4);
		SKILL_TRUESHOT=War3_AddRaceSkill(thisRaceID,"Trueshot Aura","Your attacks deal up to 30% percent more damage",false,4);
		ULT_ENTANGLE=War3_AddRaceSkill(thisRaceID,"Entangling Roots","Bind enemies to the ground,\nrendering them immobile for up to 6 seconds. Up to 4000HU range.\nHas 2 second casting time.",true,4);
		War3_CreateRaceEnd(thisRaceID);
	}
}

/* ***************************  OnRaceChanged *************************************/

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace==thisRaceID)
	{
		InitPassiveSkills(client);
	}
	else //if(newrace==oldrace)
	{
		RemovePassiveSkills(client);
	}
}
/* ****************************** InitPassiveSkills ************************** */
public InitPassiveSkills(client)
{
}
/* ****************************** RemovePassiveSkills ************************** */
public RemovePassiveSkills(client)
{
	ThisRacePlayer player = ThisRacePlayer(client);
	player.setbuff(fInvisibilitySkill,thisRaceID,1.0);
}


public DropWeapon(client,weapon)
{
//	float angle[3];
//	GetClientEyeAngles(client,angle);
//	float dir[3];
//	GetAngleVectors(angle,dir,NULL_VECTOR,NULL_VECTOR);
//	ScaleVector(dir,20.0);
//	SDKCall(hWeaponDrop,client,weapon,NULL_VECTOR,dir);
}


int ClientTracer;

public bool AimTargetFilter( int entity, int mask)
{
	return !(entity==ClientTracer);
}

public bool ImmunityCheck( int client, int target, int SkillID)
{
	ThisRacePlayer iTarget = ThisRacePlayer(target);
	if(iTarget.IsEntangled)
	{
		return false;
	}
	else if(iTarget.immunity(Immunity_Ultimates))
	{
		//War3_NotifyPlayerImmuneFromSkill(client, target, SkillID);
		iTarget.immunefromskill(client, SkillID);
		return false;
	}
	return true;
}

public void OnUltimateCommand(int client, int race, bool pressed, bool bypass)
{
	if(RaceDisabled)
		return;

	ThisRacePlayer player = ThisRacePlayer(client);

	if(race==thisRaceID && player.alive && pressed)
	{
		int skill_level= player.getskilllevel(race,ULT_ENTANGLE);
		// Spys should be visible to use this ultimate
#if GGAMETYPE == GGAME_TF2
			if(!Spying(player.index))
			{
#endif
				if(!Silenced(player.index)&& player.skillnotcooldown(thisRaceID,ULT_ENTANGLE,true))
				{

					float distance=EntangleDistance[skill_level];
					int target; // easy support for both

					target=War3_GetTargetInViewCone(client,distance,false,23.0,ImmunityCheck,ULT_ENTANGLE);

					ThisRacePlayer iTarget = ThisRacePlayer(target);

					if(iTarget.alive)
					{
#if GGAMETYPE == GGAME_TF2
						if(!Spying(iTarget.index))
						{
#endif
							//War3_CastSpell(client, target, SpellEffectsLight, SPELLCOLOR_YELLOW, thisRaceID, ULT_ENTANGLE, 3.0);
							player.castspell(iTarget.index, SpellEffectsLight, SPELLCOLOR_YELLOW, ULT_ENTANGLE, 2.0);

							//War3_CooldownMGR(client,15.0,thisRaceID,ULT_ENTANGLE,false,true);
							player.setcooldown(15.0,thisRaceID,ULT_ENTANGLE,false,true);

#if GGAMETYPE == GGAME_TF2
						}
#endif
					}
					else
					{
						W3MsgNoTargetFound(player.index,distance);
					}
				}
#if GGAMETYPE == GGAME_TF2
			}
			else
			{
				PrintHintText(player.index,"You must not be disguised/cloaked!");
			}
#endif
	}
}

public Action StopEntangle(Handle timer,any client)
{
	ThisRacePlayer player = ThisRacePlayer(client);
	player.IsEntangled=false;
	player.setbuff(bNoMoveMode,thisRaceID,false);
	return Plugin_Stop;
}

public void OnWar3EventSpawn (int client)
{
	if(RaceDisabled)
		return;

	ThisRacePlayer player = ThisRacePlayer(client);

	if(player && player.IsEntangled)
	{
		player.IsEntangled=false;
		player.setbuff(bNoMoveMode,thisRaceID,false);
	}
}


int damagestackcritmatch=-1;

public Action OnW3TakeDmgBulletPre(int victim, int attacker, float damage, int damagecustom)
{
	if(RaceDisabled)
		return Plugin_Continue;

	ThisRacePlayer iVictim = ThisRacePlayer(victim);
	ThisRacePlayer iAttacker = ThisRacePlayer(attacker);

	if(ValidPlayer(attacker,true) && ValidPlayer(victim,true))
	{
		if(GetClientTeam(victim)==GetClientTeam(attacker))
		{
			return Plugin_Continue;
		}
	}
	if(IsValidEntity(victim)&&ValidPlayer(attacker,false))
	{
		//evade
		//if they are not this race thats fine, later check for race
		if(ValidPlayer(victim,true))
		{
			if(iVictim.raceid==thisRaceID &&
			!(W3GetDamageType()!=262208 //grenade
			||W3GetDamageType()!=2359360 //rocket
			||W3GetDamageType()!=16777218 //pyro flare
			||W3GetDamageType()!=2490432 //sticky
			||W3GetDamageType()!=2097216 //melee explosive demoman cabor?
			))
			{
				int skill_level_evasion=iVictim.getskilllevel(thisRaceID,SKILL_EVADE);
				float resistance = W3GetBuffStackedFloat(attacker, fAbilityResistance);

				if(!iVictim.hexed && GetRandomFloat(0.0,1.0)<=EvadeChance[skill_level_evasion]*resistance)
				{
					if(!iAttacker.immunity(Immunity_Skills))
					{
						iVictim.flashscreen(RGBA_COLOR_BLUE);

						War3_DamageModPercent(0.0); //NO DAMAMGE

						W3MsgEvaded(iVictim.index,iAttacker.index);
						#if GGAMETYPE == GGAME_TF2
						float pos[3];
						GetClientEyePosition(iVictim.index, pos);
						pos[2] += 4.0;
						War3_TF_ParticleToClient(0, "miss_text", pos); //to the attacker at the enemy pos
						#endif
					}
					else
					{
						iVictim.immunefromskill(iAttacker.index, SKILL_EVADE);
					}
				}
			}
		}
		// Trueshot Aura
		if(iAttacker.raceid==thisRaceID)
		{
			//PrintToServer("NE !!!");
			float chance_mod=W3ChanceModifier(iAttacker.index);
			float chance=1.00*chance_mod;
			int skill_level_trueshot=iAttacker.getskilllevel(thisRaceID,SKILL_TRUESHOT);
			if(GetRandomFloat(0.0,1.0)<=chance && !iAttacker.hexed)
			{
				if(ValidPlayer(victim,true))
				{				
					if(!iVictim.immunity(Immunity_Skills))
					{
						float resistance = W3GetBuffStackedFloat(victim, fAbilityResistance);
						//PrintToServer("trig %f",TrueshotDamagePercent[skill_level_trueshot]);
						damagestackcritmatch=W3GetDamageStack();
						War3_DamageModPercent(TrueshotDamagePercent[skill_level_trueshot]*resistance+1.0);
						iVictim.flashscreen(RGBA_COLOR_RED);
					}
					else
					{
						iAttacker.immunefromskill(iVictim.index, SKILL_TRUESHOT);
					}
				}
				else
				{
					damagestackcritmatch=W3GetDamageStack();
					War3_DamageModPercent(TrueshotDamagePercent[skill_level_trueshot]+1.0);
					iVictim.flashscreen(RGBA_COLOR_RED);
				}
			}
		}
	}
	return Plugin_Stop;
}

//need event for weapon string
public Action OnWar3EventPostHurt(int victim, int attacker, float dmgamount, char weapon[32], bool isWarcraft, const float damageForce[3], const float damagePosition[3])
{
	if(RaceDisabled)
		return Plugin_Continue;

	ThisRacePlayer iVictim = ThisRacePlayer(victim);
	ThisRacePlayer iAttacker = ThisRacePlayer(attacker);

	// Trigger Ultimate on bots 5% chance
	if(iVictim.index>0&&iAttacker.index>0&&iVictim.index!=iAttacker.index)
	{
		if(iAttacker.raceid==thisRaceID)
		{
			if(damagestackcritmatch==W3GetDamageStack())
			{
				damagestackcritmatch=-1;
				iVictim.flashscreen(RGBA_COLOR_RED);
			}
		}
	}
	return Plugin_Continue;
}

//public OnWar3EventPostHurt(victim,attacker,damage){
public Action OnW3TakeDmgAll(int victim,int attacker, float damage)
{
	if(RaceDisabled)
		return Plugin_Continue;

	ThisRacePlayer iVictim = ThisRacePlayer(victim);
	ThisRacePlayer iAttacker = ThisRacePlayer(attacker);

	if(W3GetDamageIsBullet()
	&&iVictim.alive
	&&iAttacker.alive
	&&iVictim.team!=iAttacker.team)
	{

		if(iVictim.raceid==thisRaceID)
		{
			int skill_level=iVictim.getskilllevel(thisRaceID,SKILL_THORNS);
			if(!iVictim.hexed)
			{
				if(!iAttacker.immunity(Immunity_Skills) && W3Chance(W3ChanceModifier(iAttacker.index)) ) //added chance modifier to fix double proc issue - Dagothur 1/7/2014
				{
					int damage_i=RoundToFloor(damage*ThornsReturnDamage[skill_level]);
					if(damage_i>0)
					{
						if(damage_i>10) damage_i=10; // lets not be too unfair ;]

						if(War3_DealDamage(iAttacker.index,damage_i,iVictim.index,_,"thorns",_,W3DMGTYPE_PHYSICAL))
						{
							War3_EffectReturnDamage(iVictim.index, iAttacker.index, damage_i, SKILL_THORNS);
						}
					}
				}
				else
				{
					iAttacker.immunefromskill(victim, SKILL_THORNS);
				}
			}
		}
	}
	return Plugin_Continue;
}
/*
public void OnAbilityCommand(int client, int ability, bool pressed, bool bypass)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
	{
		new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_SHADOWMELD);
		if(skill_level>0)
		{
			// fInvisiblityItem and not Skill so that it won't stack with cloak
			War3_SetBuff(client,fInvisibilityItem,thisRaceID,Shadowmeld[skill_level]);
		}
	}
	else if(War3_GetRace(client)==thisRaceID && ability==0 && !pressed && IsPlayerAlive(client))
	{
		War3_SetBuff(client,fInvisibilityItem,thisRaceID,1.0);
	}
}*/

public OnWar3EventDeath(victim,attacker)
{
	if(RaceDisabled)
		return;

	ThisRacePlayer iVictim = ThisRacePlayer(victim);

	if(iVictim.raceid==thisRaceID)
	{
		iVictim.setbuff(fInvisibilityItem,thisRaceID,1.0);
	}
}


//====================================================================================
//						OnWar3CastingFinished
//====================================================================================
public OnWar3CastingFinished(client, target, W3SpellEffects:spelleffect, String:SpellColor[], raceid, skillid)
{
	ThisRacePlayer player = ThisRacePlayer(client);
	ThisRacePlayer iTarget = ThisRacePlayer(target);

	//DP("casting finished");
	if(player.alive && iTarget.alive && raceid==thisRaceID)
	{
		if(skillid == ULT_ENTANGLE)
		{
			int skill_level=player.getskilllevel(raceid,ULT_ENTANGLE);
			if(!iTarget.immunity(Immunity_Ultimates))
			{
				float our_pos[3];
				GetClientAbsOrigin(player.index,our_pos);

				bIsEntangled[target]=true;

				iTarget.setbuff(bNoMoveMode,thisRaceID,true,client);
				float entangle_time=EntangleDuration[skill_level] * W3GetBuffStackedFloat(target, fAbilityResistance);
				CreateTimer(entangle_time,StopEntangle,target);
				float effect_vec[3];
				GetClientAbsOrigin(target,effect_vec);
				effect_vec[2]+=15.0;
				TE_SetupBeamRingPoint(effect_vec,45.0,44.0,BeamSprite,HaloSprite,0,15,entangle_time,5.0,0.0,{0,255,0,255},10,0);
				TE_SendToAll();
				effect_vec[2]+=15.0;
				TE_SetupBeamRingPoint(effect_vec,45.0,44.0,BeamSprite,HaloSprite,0,15,entangle_time,5.0,0.0,{0,255,0,255},10,0);
				TE_SendToAll();
				effect_vec[2]+=15.0;
				TE_SetupBeamRingPoint(effect_vec,45.0,44.0,BeamSprite,HaloSprite,0,15,entangle_time,5.0,0.0,{0,255,0,255},10,0);
				TE_SendToAll();
				our_pos[2]+=25.0;
				TE_SetupBeamPoints(our_pos,effect_vec,BeamSprite,HaloSprite,0,50,4.0,6.0,25.0,0,12.0,{80,255,90,255},40);
				TE_SendToAll();
				War3_EmitSoundToAll(entangleSound,iTarget.index);
				War3_EmitSoundToAll(entangleSound,iTarget.index);

				char targetname[32];
				GetClientName(iTarget.index,targetname,32);
				char sclientname[32];
				GetClientName(player.index,sclientname,32);

				char sCTeam[32], sTTeam[32];
				GetTeamColor(player.index,STRING(sCTeam));
				GetTeamColor(iTarget.index,STRING(sTTeam));
				War3_ChatMessage(0,"%s%s {default}was entangled by %s%s",sTTeam,targetname,sCTeam,sclientname);

				W3MsgEntangle(iTarget.index,player.index);
			}
			player.setcooldown(GetConVarFloat(EntangleCooldownCvar),thisRaceID,ULT_ENTANGLE,_,_);
		}
	}
}


//====================================================================================
//						OnWar3CancelSpell_Post
//====================================================================================
public OnWar3CancelSpell_Post(client, raceid, skillid, target)
{
	ThisRacePlayer player = ThisRacePlayer(client);
	if(player.alive && raceid==thisRaceID)
	{
		if(skillid == ULT_ENTANGLE)
		{
			player.setcooldown(20.0,thisRaceID,ULT_ENTANGLE,false,true);
		}
	}
}
