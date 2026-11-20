// Scene 3 — Metocy Mart. Play as Xylo.
// "Hey guys, it's your boy Dulbers Frint!" is Ebain's line; everything else is a Claude DRAFT.

export const SCENE3 = [
  { who: 'narrator', line: 'East of the goblin village…' },
  { do: 'enterParty' },
  {
    if: 'goblinAllies', // only if the goblins came along (Scene 2, "Sneak out")
    steps: [
      { who: 'goblin', line: 'Ooooh. A STORE.' },
      { who: 'chief', line: 'Bogdrinker has heard of this place. Very legit.' },
      { who: 'skorn', mood: 'angry', line: "Y'all OD as hell for following us still." }, // Ebain
      { who: 'goblins', line: 'On some field trip shiiiiii.' }, // Ebain
    ],
  },
  { do: 'showSign' },
  { who: 'xylo', mood: 'vision', line: 'There. I can feel it. The metocy is near.' },
  { ifNot: 'skornKing', steps: [{ who: 'skorn', mood: 'confused', line: 'Bro, it\'s a store. You feel a store?' }] },
  { if: 'skornKing', steps: [{ who: 'lykor', line: "It's weird without Skorn. …Peaceful, but weird." }] },
  { who: 'lykor', mood: 'smug', line: '"For all yo metocy needs n shi folk." …Very professional.' },

  { do: 'dulbersAppears' },
  { who: 'dulbers', mood: 'grin', line: "Hey guys, it's your boy Dulbers Frint!" },
  { who: 'dulbers', mood: 'grin', line: "Y'all could pull up before the Diddy Chud Giant smells you?" }, // Ebain
  {
    if: 'foreheadLoser', // lost the chugging contest in Scene 2
    steps: [
      { who: 'dulbers', mood: 'grin', line: '…"Loser"? Says so right on your forehead, my boy.' },
      { who: 'lykor', mood: 'angry', line: "Don't." },
    ],
  },
  {
    if: 'lykorDethroned', // Skorn took the goblins' worship in Scene 2
    steps: [
      { who: 'skorn', mood: 'smug', line: 'Make way. Purple god of the goblins, coming through. No big deal.' }, // Ebain
      { who: 'lykor', mood: 'angry', line: 'You was a god for five minutes, bro. Pipe down.' }, // Ebain
    ],
  },

  { do: 'enterShop' },
  { do: 'showPill' },
  { who: 'dulbers', line: "Finest metocy in Caelid. This shit'll have u geekin, folk. Hand-made." }, // Ebain
  {
    if: 'skornKing', // Skorn was left behind as the goblins' Purple King
    steps: [
      { do: 'skornBurstsIn' },
      { who: 'skorn', mood: 'angry', line: 'THEY HAD KICKED ME OUT.' }, // Ebain
      { who: 'lykor', mood: 'shocked', line: 'Already??' },
      { who: 'skorn', mood: 'angry', line: 'I drank too much beezy and cracked on too many goblin biddies. They got pissed.' }, // Ebain
      { who: 'xylo', mood: 'unimpressed', line: '…Goblin biddies.' },
      { who: 'skorn', mood: 'smug', line: "Don't judge me." },
    ],
  },
  { who: 'lykor', line: 'Aight, so what the word? What we owe ya for some metocy, mud?' }, // Ebain
  { who: 'dulbers', mood: 'grin', line: "For y'all? First one's free." },
  { who: 'lykor', mood: 'smug', line: 'On some type shit.' }, // Ebain
  { who: 'skorn', mood: 'smug', line: 'Free?? Say less.' },
  { do: 'takeIt' },
  { who: 'narrator', line: 'The trio takes the metocy.' },
  { who: 'lykor', line: "…I don't feel nothing." },
  { who: 'skorn', line: 'Me neith—' },

  { do: 'tripStart' },
  { who: 'skorn', mood: 'tweaking', line: 'Yo. YO. Why the floor breathing?' },
  { who: 'lykor', mood: 'tweaking', line: "My hair is talking to me. It says I'm doing great. I KNEW it." },
  { who: 'xylo', mood: 'tweaking', line: 'On my Dragon Mama… I can see sounds. The sounds are purple.' },
  { who: 'skorn', mood: 'tweaking', line: "This ain't godlike. I don't feel insight. I feel like a dumbass. More than usual." },
  { who: 'xylo', mood: 'tweaking', line: 'The metocy gives profound insight. This gives… profound disarray.' },
  { who: 'lykor', mood: 'angry', line: 'Dulbers. What did you give us.' },
  { do: 'revealMidtocy' },
  { who: 'dulbers', mood: 'grin', line: "Heh… yeah so that's actually midtocy. Off-brand. Similar vibes." },
  { who: 'skorn', mood: 'angry', line: 'YOU LACED US WITH MIDTOCY?!' },
  { who: 'dulbers', mood: 'grin', line: '…And now that you know…' },

  { do: 'transform' },
  { who: 'dulbers_demon', line: "NOBODY LEAVES METOCY MART. NO REFUNDS. NO EXCHANGES." },
  { who: 'skorn', mood: 'tweaking', line: "Bro turned into a demon and I'm still tripping. Is this real??" },
  { who: 'xylo', mood: 'tweaking', line: 'Real enough to fight.' },
  { do: 'fightDulbers' },
  { if: 'goblinAllies', steps: [{ who: 'chief', line: 'Goblins: one. Demon: zero.' }] },

  { do: 'tripEnd' },
  { who: 'dulbers_demon', line: 'Ugh… fine… the REAL metocy… is past the mountain pass…' },
  { who: 'dulbers_demon', line: '…but nobody gets past the giant.' },
  { do: 'dulbersVanish' },
  { who: 'skorn', mood: 'confused', line: '…I still kinda see colors.' },
  { who: 'lykor', line: 'Mountain pass it is.' },
];
