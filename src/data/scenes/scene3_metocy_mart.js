// Scene 3 — Metocy Mart. Play as Xylo.
// "Hey guys, it's your boy Dulbers Frint!" is Ebain's line; everything else is a Claude DRAFT.

export const SCENE3 = [
  { who: 'narrator', line: 'East of the goblin village…' },
  { do: 'enterParty' },
  { do: 'showSign' },
  { who: 'xylo', mood: 'vision', line: 'There. I can feel it. The metocy is near.' },
  { who: 'skorn', mood: 'confused', line: 'Bro, it\'s a store. You feel a store?' },
  { who: 'lykor', mood: 'smug', line: '"For all yo metocy needs n shi folk." …Very professional.' },

  { do: 'dulbersAppears' },
  { who: 'dulbers', mood: 'grin', line: "Hey guys, it's your boy Dulbers Frint!" },
  { who: 'dulbers', mood: 'grin', line: "Welcome to Metocy Mart! Y'all looking for that good-good? Step inside, step inside!" },

  { do: 'enterShop' },
  { who: 'dulbers', line: 'Freshest metocy in Caelid. Little blue ovals. Hand-picked. By hand. My hand.' },
  { who: 'lykor', line: 'How much?' },
  { who: 'dulbers', mood: 'grin', line: "For y'all? First one's free." },
  { who: 'xylo', mood: 'unimpressed', line: 'Nothing is free. Except prophecy. And even that got a subscription now.' },
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

  { do: 'tripEnd' },
  { who: 'dulbers_demon', line: 'Ugh… fine… the REAL metocy… is past the mountain pass…' },
  { who: 'dulbers_demon', line: '…but nobody gets past the giant.' },
  { do: 'dulbersVanish' },
  { who: 'skorn', mood: 'confused', line: '…I still kinda see colors.' },
  { who: 'lykor', line: 'Mountain pass it is.' },
];
