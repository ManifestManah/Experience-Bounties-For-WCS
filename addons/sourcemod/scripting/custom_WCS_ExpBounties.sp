// List of Includes
#include <sourcemod>
#include <clientprefs>
#include <multicolors>

// The code formatting rules we wish to follow
#pragma semicolon 1;
#pragma newdecls required;


// The retrievable information about the plugin itself 
public Plugin myinfo =
{
	name		= "[CS:GO] Experience Bounty",
	author		= "Manifest @Road To Glory",
	description	= "Players can collect experience bounties by killing enemies.",
	version		= "V. 1.0.0 [Beta]",
	url			= ""
};


// Config Convars
Handle cvar_MinimumKillsForBounty;
Handle cvar_BountyBaseExperience;
Handle cvar_BountyBonusExperience;
Handle cvar_BountyMaximumExperience;

// Integers
int KillStreak[MAXPLAYERS + 1] = {1};

// Cookie Variables
bool option_bounty_announcemessage[MAXPLAYERS + 1] = {true,...};
Handle cookie_bounty_announcemessage = INVALID_HANDLE;


// This happens when the plugin is loaded
public void OnPluginStart()
{
	// Hooks the events that we intend to use in our plugin
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);

	// Our list of Convars
	cvar_MinimumKillsForBounty = CreateConVar("Mani_MinimumKillsForBounty", "5", "The minimum amount of players a player must kill in a row to have an experience bounty put on his head - [Default = 5]");
	cvar_BountyBaseExperience = CreateConVar("Mani_BountyBaseExperience", "100", "The base amount of experience that a bounty starts at - [Default = 100 | Disable = 0]");
	cvar_BountyBonusExperience = CreateConVar("Mani_BountyBonusExperience", "25", "The amount of bonus experience to add to the bounty for each additional kill that surpasses the Mani_MinimumKillsForBounty amount - [Default = 25 | Disable = 0]");
	cvar_BountyMaximumExperience = CreateConVar("Mani_BountyMaximumExperience", "250", "The maximum amount of experience a bounty can ever reach, a bounty cannot exceed this value - [Default = 250 | Disable = 0] ");

	// Cookie Stuff
	cookie_bounty_announcemessage = RegClientCookie("Bounty Messages On/Off 1", "bountm1337", CookieAccess_Private);
	SetCookieMenuItem(CookieMenuHandler_bounty_announcemessage, cookie_bounty_announcemessage, "Bounty Messages");

	// Automatically generates a config file that contains our variables
	AutoExecConfig(true, "custom_WCS_ExpBounties");

	// Loads the multi-language translation file
	LoadTranslations("custom_WCS_ExpBounties.phrases");
}


public void OnClientDisconnect(int client)
{
	// Changes the player's kill streak to 0
	KillStreak[client] = 0;
}


// This happens every time a player spawns
public void Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	// Obtains the victim and attacker's userids and store them within the respective variables: client and attacker
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	// If Both the client and the attacker meets our criteria of client validation then execute this section
	if(IsValidClient(client) && IsValidClient(attacker))
	{
		// If the attacker is not the same person as the victim, then execute this section
		if(attacker != client)
		{
			// If the attacker is dead when he kills someone e.g. with a molotov then this should not count towards his kill count
			if(IsPlayerAlive(attacker))
			{
				// Adds a kill to the killstreak of the player that killed the opponent
				KillStreak[attacker] += 1;
			}

			// Obtains the value of our attackers kill streak and store the value inside of KillStreakAttackerCheck
			int KillStreakAttackerCheck = KillStreak[attacker];

			// Obtains the value of our attackers kill streak and store the value inside of KillStreakAttackerCheck
			int KillStreakVictimCheck = KillStreak[client];

			// Creates an integer variable matching our cvar_MinimumKillsForBounty convar's value
			int MinimumKillsForBounty = GetConVarInt(cvar_MinimumKillsForBounty);

			// If the attacker has killed more than 3 people in a row without dying or the map changing then execute this section
			if(KillStreakAttackerCheck >= MinimumKillsForBounty)
			{
				// Creates an integer variable matching our cvar_BountyBaseExperience convar's value
				int BountyBaseExperience = GetConVarInt(cvar_BountyBaseExperience);

				// Creates an integer variable matching our cvar_BountyBonusExperience convar's value
				int BountyBonusExperience = GetConVarInt(cvar_BountyBonusExperience);

				// Creates an integer variable matching our cvar_BountyMaximumExperience convar's value
				int BountyMaximumExperience = GetConVarInt(cvar_BountyMaximumExperience);

				// Finds out how many additional kills the player has acquired
				int KillDifference = KillStreakAttackerCheck - MinimumKillsForBounty;
				
				// Multiplies the bonus experience value by the amount of additional kills beyond the minimum amount of kills
				int BountyTotalExperience = BountyBaseExperience + (BountyBonusExperience * KillDifference);

				// If the maximum amount of experience is not set to 0 then execute this section
				if (BountyMaximumExperience != 0)
				{
					// If the total experience bounty exceeds the maximum amount of experience a player's bounty is allowed to become, then execute this section
					if(BountyTotalExperience > BountyMaximumExperience)
					{
						// Changes the total experience to the maximum experience allowed to be acquired from a bounty
						BountyTotalExperience = BountyMaximumExperience;
					}
				}

				// Loops through all the players online
				for(int i = 1 ;i <= MaxClients; i++)
				{
					// If the client meets our criteria of validation then execute this section
					if (IsValidClient(i))
					{
						// If the player is not a bot then execute this section
						if (!IsFakeClient(i))
						{
							// If the player has the bounty announcement messages enabled then execute this section
							if (option_bounty_announcemessage[i])
							{
								// Creates a variable to store the player's name within
								char AttackerName[64];

								// Obtains the attacker's name and store it within AttackerName
								GetClientName(attacker, AttackerName, 64);

								// Prints a message to the chat announcing the bounty
								CPrintToChat(i, "%t", "Experience Bounty Announcement Promised", AttackerName, KillStreakAttackerCheck, BountyTotalExperience);
							}
						}
					}
				}
			}

			// If the victim has killed more than 3 people in a row without dying or the map changing then execute this section
			if(KillStreakVictimCheck >= MinimumKillsForBounty)
			{
				// Creates an integer variable matching our cvar_BountyBaseExperience convar's value
				int BountyBaseExperience = GetConVarInt(cvar_BountyBaseExperience);

				// Creates an integer variable matching our cvar_BountyBonusExperience convar's value
				int BountyBonusExperience = GetConVarInt(cvar_BountyBonusExperience);

				// Creates an integer variable matching our cvar_BountyMaximumExperience convar's value
				int BountyMaximumExperience = GetConVarInt(cvar_BountyMaximumExperience);

				// Finds out how many additional kills the player has acquired
				int KillDifference = KillStreakVictimCheck - MinimumKillsForBounty;
				
				// Multiplies the bonus experience value by the amount of additional kills beyond the minimum amount of kills
				int BountyTotalExperience = BountyBaseExperience + (BountyBonusExperience * KillDifference);


				// If the maximum amount of experience is not set to 0 then execute this section
				if (BountyMaximumExperience != 0)
				{
					// If the total experience bounty exceeds the maximum amount of experience a player's bounty is allowed to become, then execute this section
					if(BountyTotalExperience > BountyMaximumExperience)
					{
						// Changes the total experience to the maximum experience allowed to be acquired from a bounty
						BountyTotalExperience = BountyMaximumExperience;
					}
				}

				// We create a variable named attackerid which we need as Source-Python commands uses userid's instead of indexes
				int attackerid = GetEventInt(event, "attacker");

				// Creates a variable named ServerCommandMessage which we'll store our message data within
				char ServerCommandMessage[128];

				// Formats a message and store it within our ServerCommandMessage variable
				FormatEx(ServerCommandMessage, sizeof(ServerCommandMessage), "wcs_givexp %i %i", attackerid, BountyTotalExperience);

				// Executes our GiveLevel server command on the player, to award them with levels
				ServerCommand(ServerCommandMessage);

				// Loops through all the players online
				for(int i = 1 ;i <= MaxClients; i++)
				{
					// If the client meets our criteria of validation then execute this section
					if (IsValidClient(i))
					{
						// If the player is not a bot then execute this section
						if (!IsFakeClient(i))
						{
							// If the player has the bounty announcement messages enabled then execute this section
							if (option_bounty_announcemessage[i])
							{
								// Creates a variable to store the victim's name within
								char ClientName[64];

								// Creates a variable to store the attacker's name within
								char AttackerName[64];

								// Obtains the client's name and store it within AttackerName
								GetClientName(client, ClientName, 64);

								// Obtains the attacker's name and store it within AttackerName
								GetClientName(attacker, AttackerName, 64);

								// Prints a message to the chat announcing the bounty
								CPrintToChat(i, "%t", "Experience Bounty Announcement Collected", AttackerName, ClientName, BountyTotalExperience);
							}
						}
					}
				}
			}
		}
		// Changes the kill streak of the player that died to 0 
		KillStreak[client] = 0;
	}
}


// We call upon this true and false statement whenever we wish to validate our player
bool IsValidClient(int client)
{
	if (!(1 <= client <= MaxClients) || !IsClientConnected(client) || !IsClientInGame(client) || IsClientSourceTV(client) || IsClientReplay(client))
	{
		return false;
	}

	return true;
}


// Cookie stuff below
public void OnClientCookiesCached(int client)
{
	option_bounty_announcemessage[client] = GetCookiebounty_announcemessage(client);
}


bool GetCookiebounty_announcemessage(int client)
{
	char buffer[10];

	GetClientCookie(client, cookie_bounty_announcemessage, buffer, sizeof(buffer));
	
	return !StrEqual(buffer, "Off");
}


public void CookieMenuHandler_bounty_announcemessage(int client, CookieMenuAction action, any bounty_announcemessage, char[] buffer, int maxlen)
{	
	if (action == CookieMenuAction_DisplayOption)
	{
		char status[16];
		if (option_bounty_announcemessage[client])
		{
			Format(status, sizeof(status), "%s", "[ON]", client);
		}
		else
		{
			Format(status, sizeof(status), "%s", "[OFF]", client);
		}
		
		Format(buffer, maxlen, "EXP Bounty Messages: %s", status);
	}
	else
	{
		option_bounty_announcemessage[client] = !option_bounty_announcemessage[client];
		
		if (option_bounty_announcemessage[client])
		{
			SetClientCookie(client, cookie_bounty_announcemessage, "On");
			CPrintToChat(client, "%t", "Bounty Messages Enabled");
		}
		else
		{
			SetClientCookie(client, cookie_bounty_announcemessage, "Off");
			CPrintToChat(client, "%t", "Bounty Messages Disabled");
		}
		
		ShowCookieMenu(client);
	}
}