// Scene 1 — "The Map" (camp, night). Play as Skorn.
//
// HOW TO EDIT VOICELINES:
//   Change the text in quotes. `line: null` = empty slot (shows the context in orange in-game).
//   mood: 'angry' / 'shocked' picks that portrait expression if the image exists.
//   thought: true shows the line as inner monologue (italic, in parentheses).
//   Lines marked  // DRAFT  were written by Claude in Ebain's style — keep, edit or replace.
//
// `do:` steps trigger animations in IntroScene (hooks), they aren't dialogue.

export const SCENE1 = [
  { who: 'narrator', line: 'Caelid. Night. The night before the greatest quest of their lives.' },
  { who: 'narrator', line: 'The quest for the metocy.' },

  // Beat 1 — camp, everyone settling in
  { who: 'lykor', line: 'Dat metocy gon be gah tomorrow, on the absolute.' },
  { who: 'xylo',  line: 'On my Dragon Mama it is.' },
  { who: 'skorn', line: "Man, it's about cold as a motherfucker. We could get the fire going, though." },

  // Beat 2 — the warning
  { do: 'showBagLabel' },
  { who: 'lykor', line: "Aight bet. But don't touch my bag, though." },
  { who: 'skorn', line: 'Why would I touch yo bag, mud?' }, // DRAFT

  // Beat 3 — Skorn looks for something to burn (later: free-roam camp interactions go here)
  { do: 'showFireLabel' },
  { who: 'skorn', thought: true, line: "Alright, where the fuck is some fire starter? I'm tryna get this bitch going." },
  { who: 'skorn', thought: true, line: 'Man, fuck this jit Lykor. He probably got some gas fire starter in his bag.' },

  // Beat 4 — the bag
  { do: 'skornGrabsMap' },
  { who: 'narrator', line: 'Skorn got: Important-Looking Paper.' },
  { who: 'narrator', line: 'It reads: "M̷Ꭺ̵Ꮲ̶ ̸Ƭ̷Ө̴ ̵Ƭ̶Ң̸Ɛ̷ ̴M̵Ɛ̶Ƭ̸Ө̷C̴Ɏ̵" (Skorn cannot read)' },
  { who: 'skorn', thought: true, line: 'Bunch of squiggly ass lines. Yeah, that\'s fire starter.' }, // DRAFT

  // Beat 5 — into the fire
  { do: 'burnMap' },
  { who: 'lykor', line: 'Damn, you started that up quick. Good shit, dude.' },
  { who: 'skorn', line: "Yeah, I just used the paper that was in your bag. I don't know why you said I couldn't use your bag." },
  { who: 'lykor', line: 'Say you swear to the absolute.' },
  { who: 'skorn', line: 'What? What are you talking about, mud?' },

  // Beat 6 — the realization
  { who: 'lykor', mood: 'shocked', line: 'BRO. THAT WAS THE MAP TO THE METOCY. THE ONLY MAP.' }, // DRAFT
  { who: 'xylo',  mood: 'shocked', line: "On my Dragon Mama... I seen this in a vision. I just ain't think it'd be this dumb." }, // DRAFT
  { who: 'skorn', mood: 'angry', line: 'Then why the fuck you leave it in a bag?! Bags is for fire starter!' }, // DRAFT
  { who: 'lykor', mood: 'angry', line: 'Bags is for MAPS, Skorn!' }, // DRAFT
  { who: 'skorn', line: 'Not no more.' }, // DRAFT

  // Beat 7 — new plan
  { who: 'xylo',  line: 'Chill. Them goblins up north know every road in Caelid. We just ask them.' }, // DRAFT
  { who: 'lykor', line: 'Bet. We leave at sunrise. And nobody touch NOTHING.' }, // DRAFT
  { do: 'morning' },
  { who: 'narrator', line: 'The next morning…' },
  { who: 'lykor', line: "Aight, new rule: Skorn don't hold nothing. I'm leading." }, // DRAFT
  { who: 'skorn', line: "Bet. I'ma hold a grudge then." }, // DRAFT
];
