#include "ChatCommand.as"

class ClassCommand : ChatCommand
{
	ClassCommand()
	{
		super("class", "Change your class");
		SetUsage("<name>");
	}

	bool canPlayerExecute(CPlayer@ player)
	{
		return (
			ChatCommand::canPlayerExecute(player) &&
			!ChatCommands::getManager().whitelistedClasses.empty()
		);
	}

	void Execute(string[] args, CPlayer@ player)
	{
		if (!isServer()) return;

		CBlob@ blob = player.getBlob();
		if (blob is null)
		{
			server_AddToChat(getTranslatedString("Your class cannot be changed while dead or spectating"), ConsoleColour::ERROR, player);
			return;
		}

		if (args.size() == 0)
		{
			string[] classes = ChatCommands::getManager().whitelistedClasses;
			server_AddToChat(getTranslatedString("Specify a class to swap to: " + join(classes, ", ")), ConsoleColour::ERROR, player);
			return;
		}

		string className = args[0];

		if (!isClassWhitelisted(className, player))
		{
			server_AddToChat(getTranslatedString("Class not found or cannot be swapped to"), ConsoleColour::ERROR, player);
			return;
		}

		if (blob.getName() == className)
		{
			server_AddToChat(getTranslatedString("You are already this class"), ConsoleColour::ERROR, player);
			return;
		}

		CBlob@ newBlob = server_CreateBlob(className, blob.getTeamNum(), blob.getPosition());
		if (newBlob is null)
		{
			server_AddToChat(getTranslatedString("Unable to change class"), ConsoleColour::ERROR, player);
			return;
		}

		newBlob.server_SetPlayer(player);
		blob.Tag("switch class");
		blob.server_SetPlayer(null);
		blob.server_Die();
	}
}

class TeamCommand : ChatCommand
{
	TeamCommand()
	{
		super("team", "Change your team");
		SetUsage("<team #>");
	}

	void Execute(string[] args, CPlayer@ player)
	{
		if (!isServer()) return;

		CBlob@ blob = player.getBlob();
		if (blob is null)
		{
			server_AddToChat(getTranslatedString("Team cannot be changed while dead or spectating"), ConsoleColour::ERROR, player);
			return;
		}

		if (args.size() == 0)
		{
			server_AddToChat(getTranslatedString("Specify a team number to change to"), ConsoleColour::ERROR, player);
			return;
		}

		int team = parseInt(args[0]);
		if (team == blob.getTeamNum())
		{
			server_AddToChat(getTranslatedString("You are already on this team"), ConsoleColour::ERROR, player);
			return;
		}

		blob.server_setTeamNum(team);
	}
}

class CoinsCommand : ChatCommand
{
	CoinsCommand()
	{
		super("coins", "Give yourself coins");
		AddAlias("money");
		SetUsage("[amount]");
	}

	void Execute(string[] args, CPlayer@ player)
	{
		if (isServer())
		{
			int coins = args.size() > 0 ? parseInt(args[0]) : player.getCoins() + 100;
			player.server_setCoins(coins);
		}

		if (player.isMyPlayer())
		{
			Sound::Play("snes_coin.ogg");
		}
	}
}

class HealCommand : ChatCommand
{
	HealCommand()
	{
		super("heal", "Heal yourself");
		AddAlias("health");
		SetUsage("[amount]");
	}

	void Execute(string[] args, CPlayer@ player)
	{
		CBlob@ blob = player.getBlob();
		if (blob is null)
		{
			if (isServer())
			{
				server_AddToChat(getTranslatedString("You cannot heal yourself while dead or spectating"), ConsoleColour::ERROR, player);
			}
			return;
		}

		//i hate this but it works
		float health;
		float healthClamped;

		if (args.size() > 0)
		{
			health = healthClamped = parseFloat(args[0]);

			if (blob.getHealth() * 2 + health < 0.5f)
			{
				healthClamped = 0.125f - blob.getHealth() * 2;
			}

			if (blob.getHealth() * 2 + health > blob.getInitialHealth() * 2)
			{
				healthClamped = (blob.getInitialHealth() - blob.getHealth()) * 2;
			}
		}
		else
		{
			health = blob.getInitialHealth() * 2;
			healthClamped = (blob.getInitialHealth() - blob.getHealth()) * 2;
		}

		if (isServer())
		{
			blob.server_Heal(healthClamped);
		}

		if (player.isMyPlayer())
		{
			if (healthClamped == 0)
			{
				if (health == 0)
				{
					client_AddToChat(getTranslatedString("Specify a valid amount to heal"), ConsoleColour::ERROR);
				}
				else if (health > 0)
				{
					client_AddToChat(getTranslatedString("You are already at full health"), ConsoleColour::ERROR);
				}
				else
				{
					client_AddToChat(getTranslatedString("You are already at the lowest health"), ConsoleColour::ERROR);
				}
			}
			else
			{
				CSprite@ sprite = blob.getSprite();
				if (sprite !is null)
				{
					if (health > 0)
					{
						sprite.PlaySound("Heart.ogg");
					}
					else
					{
						sprite.PlaySound("ArgShort.ogg", 1.0f, blob.getSexNum() == 0 ? 1.0f : 1.5f);
					}
				}
			}
		}
	}
}
