# The readable books in the Deloye library (Ebain 11/25: "a book UI with an actual decent amount of lore in it"; the
# narrator reads every page aloud, cloned voice files keyed by the page text: reword a page = regenerate it). Ebain picked these six from a draft list and OK'd the text ("Go ahead"); every word is still # DRAFT, he
# can rewrite any of it. Pages are BBCode ([b] [i]). BookUI shows two pages side by side.
# Lore they rest on (Ebain 11/25): the land is Chudmoor. Dulbmeethus is a god from the start and made metocy; he gave
# Metocin Mattias the metocy spells and made him its wielder in this reality (keeps it from the unworthy); they've been
# smoking buddies for ~500 years. Death is a really nice, personable guy who is also the Grim Reaper; he only shows up
# for the dead, has taken metocy with Dulbmeethus. Deloye is just some guy who ended up in the library and is forced by
# John and John's orb to write about the universe forever; some see him as a god and all-knowing prophet. The trio meet
# Dulbmeethus in game 2 and get a mission from him (book 1 hints at it). Mattias's library card is due in 2067 (a joke).
extends RefCounted

const BOOKS := {
	"prophecy_three": {
		"title": "The Prophecy of the Three",
		"pages": [
			"This prophecy was written in the library by the one who writes, on a night when the orb glowed and John said \"write.\"\n\nIt has been copied 4,000 times. Every copy is slightly worse. This is copy 4,001.\n\nHear it, reader. Or don't. It happens either way.",
			"Three shall walk north from a fire that would not light.\n\nOne shall be purple and loud, and he shall burn the only map, and he shall say it was on purpose.\n\nOne shall be fair of face and fairer of hair, and the goblins shall sing his name, and he shall mog the unmoggable.\n\nOne shall be red and scaled and he shall have read this book already. He shall say \"I knew it.\" He did not know it.",
			"They shall seek the little blue oval. They shall be offered a lesser one, and one of them shall pocket it anyway.\n\nA giant shall sleep across the road, and the road shall wait for him to say two words.\n\nAt the top of the mountain, an old wizard shall ask them a question. Their answer shall decide how the first chapter ends. There is no wrong answer. There are several bad ones.",
			"And when the smoke clears, the three shall hear a voice from inside it. The voice shall ask if they can hear it. They shall say yes. It shall not believe them, and it shall ask again.\n\nThe voice shall have a task. The task shall be simple. It shall not stay simple.\n\nThey shall be lost. They shall be found. They shall be lost again, worse, somewhere with no goblins at all.",
			"The rest of this page is blank.\n\nNot because the future is unwritten. Because the one who writes ran out of ink, and John said the orb would get him more \"soon.\"\n\n[i](A note in the margin, in different handwriting:)[/i] it's been 300 years john",
		],
	},
	"on_metocy": {
		"title": "Deloye Lore, Vol. 3,112: On Metocy",
		"pages": [
			"Metocy is the most sacred substance in Chudmoor. It is small, blue and oval. It fits in the palm of a goblin, which is to say it is very small.\n\nIt was not found. It was not grown. It was made, in the smoke, by Dulbmeethus, before there was anyone around to ask him why.\n\nThose who take it are said to see further, think deeper and, in most cases, sit down for a while.",
			"[b]How to know true metocy:[/b]\n\n1. It is blue. Not teal. Not \"kind of blue in this light.\" Blue.\n\n2. It is oval. A round one is a mint. Do not argue with the mint.\n\n3. It is never moist. True metocy is never moist. If it is moist, put it down and wash your hands.\n\n4. If it is orange, it is very, very old. It still works. It is just not as good. The blue one is way better.",
			"[b]On midtocy:[/b] a fake. It looks close enough to fool an orc. It is sold, mostly, by people who introduce themselves on camera. Those who take it see colors that are not there and hear a song that is not playing. It wears off. Usually.\n\n[b]On fentocy:[/b] do not. Not even as a joke. Especially not to a demon.",
			"When Dulbmeethus made metocy, he knew someone in this reality had to hold it. Not own it. Hold it.\n\nHe chose a wizard. He gave the wizard the metocy spells: the words that call it, keep it and know it. The wizard has wielded it ever since, for almost 500 years, and keeps it from the unworthy.\n\nNobody knows exactly what makes someone unworthy. The wizard says you can tell. The wizard says \"you just know, folk.\"",
			"If you are reading this because you want metocy: it is at the top of the mountain, in the wizard's crib.\n\nIf you are reading this because you already took some: hello. You've been on this page for 40 minutes.",
		],
	},
	"dulbmeethus": {
		"title": "The Book of Dulbmeethus, Chapter 1",
		"pages": [
			"In the beginning there was smoke.\n\nNot from a fire. There was no fire yet. Just smoke, everywhere, forever, minding its own business.\n\nThen a voice came from inside it, and the voice said: \"Y'all could hear me doe?\"\n\nThere was nobody to hear him. So he said it louder.",
			"That was Dulbmeethus. He was a god from the start. He did not climb to it, earn it or win it in a bet. He was simply there first, and being there first, he decided things.\n\nHe decided there should be ground, so people would have somewhere to sit. He decided there should be people, so somebody could hear him. He decided the goblins should have jobs. That one did not work out.",
			"Then, alone in the smoke, Dulbmeethus made his greatest work: a tiny blue oval. He called it metocy.\n\nHe took the first one himself. Witnesses (there were none) say he was quiet for a very long time, and then he said, \"Aight.\"\n\nHe knew it was too powerful to leave lying around, so he gave it to a wizard who could be trusted to hold it. The wizard's name was Mattias.",
			"Mattias and Dulbmeethus have been taking metocy together for almost 500 years. They talk about everything. They talk about nothing. Mostly they sit.\n\nOnce, a third guest joined them. He was tall, wore a hood and carried a scythe, and he was the politest person either of them had ever met. He brought snacks. He asked how their day was and listened to the answer.\n\nIt was Death. He was off work.",
			"Dulbmeethus does not show himself often. When he does, it is usually from the smoke, and usually in the middle of something.\n\nThe prophets say that one day he will call on three unlikely heroes for a task only they can do.\n\nThe prophets also say he will have to ask them twice if they can hear him.\n\n[i]End of Chapter 1. Chapter 2 is checked out.[/i]",
		],
	},
	"library_card": {
		"title": "Mattias's Library Card",
		"pages": [
			"[b]DELOYE LORE LIBRARY[/b]\n[b]Member card[/b]\n\nName: Metocin Mattias\nMember since: \"a while\"\nAddress: the crib (top of the mountain, you'll know it)\n\nChecked out: Deloye Lore, Volumes 1 to 40,000\nDue back: [b]2067[/b]\nStatus: still reading",
			"[b]Late fees owed:[/b] 14,208 gold, 3 beezy, \"one (1) Chipotle Bowl, burrito style\"\n\n[b]Notes from the librarian[/b] (there is no librarian):\n\n• Patron returned Volume 9 signed. Nobody knows who signed it.\n\n• Patron was asked to stop teleporting into the Restricted Section. Patron said \"bet\" and did it again.\n\n• Patron fell asleep in the SAVED SEAT for 11 years.",
			"[i]The back of the card, in Mattias's handwriting:[/i]\n\nThings to ask Dulbmeethus next time:\n1. Why the goblins don't have jobs\n2. Is Deloye ok\n3. Who is John\n\nThings to bring:\n• metocy (obviously)\n• snacks for Death, he always brings some and I feel bad\n\nReminder: Deloye Lore Vol. 10,000 is just the word \"rock.\" Do NOT tell Xylo, let him find out himself.",
		],
	},
	"the_giant": {
		"title": "Deloye Lore, Vol. 6,700: The Giant",
		"pages": [
			"There is one road north through the lava pass, and across it sleeps the Diddy Chud Giant.\n\nNobody remembers him lying down. The oldest goblins say he was already asleep when their grandparents were unemployed. The road was built around him, then the road gave up and just went up to him and stopped.",
			"He is not evil. He is not guarding anything. He is simply very large and very tired, and he picked a bad spot.\n\n[b]Things that have been tried to move him:[/b]\n\n• asking nicely (he snored louder)\n• a goblin army (they sat down next to him and also fell asleep)\n• a song (he liked it)\n• a slap (do not)",
			"The Giant is said to wake for only a few things: being hit very hard, the smell of midtocy, a good enough question about Deloye Lore, or a relative.\n\nHe is, distantly, related to Chief Bogdrinker. Neither of them likes to talk about it. At family gatherings, the Chief sits on the far side of the giant, which is about a mile away.",
			"When he does wake, he always says the same two words, slowly, as if he has been saving them:\n\n[b]\"Aight. Bet.\"[/b]\n\nScholars have argued for centuries about what he means. Some say it is a warning. Some say it is a greeting. Most agree he says it right before something hits you.",
			"Behind the place where he sleeps, there is a gorge, and the gorge leads up to the mountain, and the mountain leads to the wizard.\n\nSo every hero who has ever reached the metocy has had to deal with the Giant first. Some fought him. Some tiptoed. One read him lore until he gave up.\n\nHe does not hold it against any of them. He just goes back to sleep.",
		],
	},
	"prophecy_death": {
		"title": "The Prophecy of Death",
		"pages": [
			"Everyone in Chudmoor is afraid of Death. This is a misunderstanding.\n\nDeath is the nicest person you will ever meet. He remembers your birthday. He asks about your family and remembers their names. He has never once been late.\n\nHe is also the Grim Reaper. Both things are true.",
			"Death is not hunting anyone. He does not want your soul, your gold or your metocy. He only shows up when someone has died, so that nobody has to go wherever they go next alone.\n\nHe says the first thing he tells everyone is \"Hey. You're good. Take your time.\"\n\nThe second thing is usually directions.",
			"In his time off, Death has taken metocy with Dulbmeethus and the wizard Mattias. He was a great guest. He brought snacks and cleaned up after.\n\nMattias still fears him a little. Not because Death is scary, but because one day Death will show up for Mattias on the job, and Mattias will have to admit he never returned his library books.",
			"[b]The prophecy:[/b]\n\n[i]When three walk where the living should not, a tall friend in a hood shall walk beside them. He shall not be there for them. Not yet. He shall just be really nice about it.[/i]\n\n[i]He shall help them more than he is supposed to. He shall get in trouble for it. He shall say it was worth it.[/i]",
			"[b]If you meet Death, the old books advise:[/b]\n\n• Be polite. He always is.\n• Do not try to fight him. Nobody has won. He is very apologetic about it.\n• If he offers you a snack, take it.\n• If he says \"take your time,\" you are probably fine. If he says \"you good?\", check yourself.\n\n[i]Written by the one who writes, at John's request. Death read the first draft and said it was \"really kind,\" which made the writer feel weird for a week.[/i]",
		],
	},
}
