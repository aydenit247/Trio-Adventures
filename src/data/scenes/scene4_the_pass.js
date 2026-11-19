// Scene 4 — The Mountain Pass: Metocin Mattias, then the Diddy Chud Giant.
// FOUNDATION ONLY: the beats and art are in place, the lines are empty slots (shown in orange in-game).
// "You had called?" is Ebain's line. Fill in the rest whenever you're ready.

export const SCENE4 = [
  { who: 'narrator', line: 'The mountain pass. Hot. Ashy. Rude.' },
  { do: 'enterParty' },
  { who: 'skorn', line: null, context: 'Skorn complains about the heat (maybe still seeing colors from the midtocy).' },
  { who: 'lykor', line: null, context: 'Lykor reacts to the volcanic pass.' },

  // Mattias shows up out of nowhere
  { do: 'mattiasAppears' },
  { who: 'mattias', line: 'You had called?' },
  { who: 'skorn', line: null, context: 'Skorn: nobody called him.' },
  { who: 'mattias', line: null, context: 'Mattias tells them to come find him — past the path the giant is inconveniently sleeping on.' },
  { do: 'mattiasVanish' },
  { who: 'xylo', line: null, context: 'Xylo reacts to Mattias vanishing.' },

  // The giant
  { do: 'toGiant' },
  { who: 'lykor', line: null, context: 'They see Diddy Chud Giant asleep across the path.' },
  { who: 'skorn', line: null, context: "Skorn's plan (probably a bad one)." },
  { do: 'giantWakes' },
  { who: 'giant', mood: 'angry', line: null, context: 'Diddy Chud Giant wakes up furious.' },
  { do: 'fightGiant' },
  { who: 'giant', line: null, context: 'After the fight — the giant gives up / moves out of the way.' },
];
