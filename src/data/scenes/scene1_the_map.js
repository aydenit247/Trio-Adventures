// Scene 1 — "The Map" (camp, night). Play as Skorn.
//
// HOW TO FILL IN VOICELINES:
//   Replace `line: null` with your line in quotes, e.g.  line: 'SKORN COLD.',
//   Leave it null and the game shows the context in orange so you know it's still missing.
//   Optional: add mood: 'angry' / 'shocked' to use that portrait expression.
//
// `do:` steps trigger animations in IntroScene (hooks), they aren't dialogue.

export const SCENE1 = [
  { who: 'narrator', line: 'Caelid. Night. The night before the greatest quest of their lives.' },
  { who: 'narrator', line: 'The quest for the metocy.' },

  // Beat 1 — camp, everyone settling in
  { who: 'lykor', line: null, context: 'Lykor is hyped about tomorrow\'s quest for the metocy.' },
  { who: 'xylo',  line: null, context: 'Xylo says something ominous/mysterious about tomorrow.' },
  { who: 'skorn', line: null, context: 'Skorn is cold and wants a fire.' },

  // Beat 2 — the warning
  { do: 'showBagLabel' },
  { who: 'lykor', line: null, context: 'Lykor warns everyone not to touch his bag — the map is in it.' },
  { who: 'skorn', line: null, context: 'Skorn\'s suspicious reply.' },

  // Beat 3 — Skorn checks the fire (later: free-roam camp interactions go here)
  { do: 'showFireLabel' },
  { who: 'skorn', line: null, context: 'Skorn looks at the campfire. It has nothing to burn.' },

  // Beat 4 — the bag
  { do: 'skornGrabsMap' },
  { who: 'narrator', line: 'Skorn got: Important-Looking Paper.' },
  { who: 'skorn', line: null, context: 'Skorn finds the map in Lykor\'s bag. He can\'t read.' },

  // Beat 5 — into the fire
  { do: 'burnMap' },
  { who: 'lykor', line: null, context: 'Lykor says the fire looks great and asks what Skorn used.' },
  { who: 'skorn', line: null, context: 'Skorn tells him.' },

  // Beat 6 — the realization
  { who: 'lykor', mood: 'shocked', line: null, context: 'Lykor freaks out — that was the only map.' },
  { who: 'xylo',  line: null, context: 'Xylo: a "the prophecy is fulfilled"-type line.' },
  { who: 'skorn', mood: 'angry', line: null, context: 'Skorn defends himself.' },

  // Beat 7 — new plan
  { who: 'xylo',  line: null, context: 'Xylo mentions the goblin village to the north — they might know the way.' },
  { do: 'morning' },
  { who: 'narrator', line: 'The next morning…' },
  { who: 'lykor', line: null, context: 'Lykor takes the lead. New rule about Skorn holding things.' },
  { who: 'skorn', line: null, context: 'Skorn\'s response.' },
];
