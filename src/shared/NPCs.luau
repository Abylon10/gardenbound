-- The townsfolk of Spawn Island: who they are and what they say. The
-- server builds and places them (server NPCs); talking to one ("Talk"
-- prompt, F key) shows these lines in order (client Dialog).

export type NPC = {
	displayName: string,
	title: string,
	color: Color3, -- accent color for the dialog box
	lines: { string },
}

local NPCs: { [string]: NPC } = {
	Louisa = {
		displayName = "Louisa",
		title = "Seed Shop",
		color = Color3.fromRGB(240, 130, 170),
		lines = {
			"Hi! I'm Louisa. Welcome to the Seed Shop! Press E at the counter to browse.",
			"Carrots are perfect for beginners. They're ready in just 20 seconds!",
			"Chillies take the longest to grow, but they sell for the most coins.",
			"Saplings go in your back garden. Birch grows fastest, Coconut gives the most wood.",
			"Tip: a Bee pet makes your crops grow faster. I love bees!",
		},
	},
	Diane = {
		displayName = "Diane",
		title = "Sell Shop",
		color = Color3.fromRGB(170, 60, 80),
		lines = {
			"Good day. I'm Diane, purveyor of the island's finest produce.",
			"Bring me your harvest and I'll pay a fair price. Every crop at once, no haggling.",
			"Chillies and cabbages fetch the best prices this season.",
			"A Butterfly pet charms my customers. They pay twenty percent more for your crops.",
			"Remember, darling: coins invested in better seeds grow faster than any crop.",
		},
	},
	Arthur = {
		displayName = "Arthur",
		title = "Blacksmith",
		color = Color3.fromRGB(200, 110, 50),
		lines = {
			"Arthur's the name, steel's the game. Welcome to the forge.",
			"Bring me copper and iron from the Abandoned Mine and I'll forge you a proper blade.",
			"Goblin fangs make a fine edge. Rough hide makes sturdy leather armor.",
			"Every piece can be tempered up to +10. Costs more each time, mind you.",
			"Shadow Essence from the mine's bats... that's what legends are forged from.",
		},
	},
	Gary = {
		displayName = "Gary",
		title = "Architect",
		color = Color3.fromRGB(70, 120, 210),
		lines = {
			"Oh! Hi, I'm Gary. Sorry, just finishing this sketch.",
			"I draw every blueprint here myself. House upgrades, benches, wells, you name it.",
			"Buy a blueprint, then build it at home with wood from your back garden.",
			"House Upgrade II adds a porch and four more garden tiles. Very efficient design.",
			"Measure twice, chop once. That's what I always say.",
		},
	},
	Kevin = {
		displayName = "Kevin",
		title = "Wilderness Scout",
		color = Color3.fromRGB(80, 150, 80),
		lines = {
			"Halt! Oh, just a farmer. I'm Kevin, scout of the Wilderness Gate.",
			"Through my spyglass I've spotted glowing eggs all over the Meadow.",
			"The further you go from the entrance, the rarer the eggs. Check behind rocks!",
			"Slimes are easy. Goblins hit harder, but they drop fangs and rough hide.",
		},
	},
	Josh = {
		displayName = "Josh",
		title = "Wilderness Scout",
		color = Color3.fromRGB(110, 140, 60),
		lines = {
			"Name's Josh. Kevin keeps watch, I keep the goblins off the bridge.",
			"Goblins sometimes carry rusty swords. Defeat enough and you might find one.",
			"Bring a Health Potion: two Slime Gel and a Wild Berry, brewed at your cauldron.",
			"Fell in the sea? Swim to a dock. The stairs take you back up the cliffs.",
		},
	},
	Alfred = {
		displayName = "Sir Alfred",
		title = "Portal Knight",
		color = Color3.fromRGB(70, 90, 170),
		lines = {
			"Halt, traveler. I am Sir Alfred, warden of the Dungeon Portal.",
			"Beyond this gate lies the Abandoned Mine. Slimes and bats lurk in the dark.",
			"Mine the copper and iron veins. Arthur's forge in the plaza turns them into gear.",
			"Should you fall in battle, you will wake safely at your home.",
		},
	},
	Susan = {
		displayName = "Dame Susan",
		title = "Portal Knight",
		color = Color3.fromRGB(170, 50, 60),
		lines = {
			"I am Dame Susan. Together, Alfred and I keep the mine's creatures from the islands.",
			"The bats are fast. Strike quickly and keep your health up.",
			"Rare bats carry Shadow Essence. The blacksmith prizes it above all.",
			"A Strength Potion before the Deep Cavern would serve you well.",
		},
	},
}

return NPCs
