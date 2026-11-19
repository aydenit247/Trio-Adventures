// Scene 2 — Goblin Village. Play as Lykor.
// Every line here is a Claude DRAFT in Ebain's style — keep, edit or replace any of them.
// Format notes are at the top of scene1_the_map.js.

const OUTRO = [
  { who: 'chief', line: 'Go then, Shiny One. Seek the metocy. They sell it at the Metocy Mart, east of here.' },
  { who: 'xylo', mood: 'unimpressed', line: 'They… sell it?' },
  { who: 'chief', line: 'For all yo metocy needs.' },
  { do: 'goblinsCry' },
  { who: 'goblins', line: '*sobbing* BYE SHINY ONE!! COME BACK HARDER!!' },
  { who: 'xylo', mood: 'smug', line: "On my Dragon Mama, I'm leading from here. Lykor too famous now." },
  { do: 'leave' },
];

export const SCENE2 = [
  { who: 'narrator', line: 'Later that morning…' },
  { do: 'enterParty' },
  { who: 'skorn', mood: 'angry', line: "Man, I can't believe this jit got the lead now." },
  { who: 'lykor', mood: 'smug', line: "Map-burners don't get a vote, Skorn." },
  { who: 'xylo', mood: 'vision', line: 'On my Dragon Mama… we are being watched. By many small, crusty eyes.' },

  { do: 'goblinsAppear' },
  { who: 'goblin', line: '…' },
  { who: 'goblin', line: 'Yo… YO. Look at his HAIR.' },
  { who: 'goblins', line: 'THE SHINY ONE!!' },
  { do: 'goblinsKneel' },
  { who: 'lykor', mood: 'flattered', line: 'Oh word? …Oh, WORD?' },
  { who: 'skorn', mood: 'angry', line: "Hell nah. Why they ain't bowing to ME? I'm the one with armor." },
  { who: 'xylo', mood: 'unimpressed', line: 'Prophecies be weird like that.' },

  { do: 'chiefAppears' },
  { who: 'chief', line: 'For a thousand years we have waited for the Shiny One. Golden hair. Pointy ears. Smells like expensive conditioner.' },
  { who: 'lykor', mood: 'smug', line: 'I mean… it IS the expensive kind.' },
  { who: 'chief', line: 'Come, Shiny One. Your throne awaits.' },

  { do: 'toThrone' },
  { who: 'narrator', line: 'The goblins seat Lykor on a throne made of spoons, bones, and one (1) wagon wheel.' },
  { do: 'crown' },
  { who: 'lykor', mood: 'flattered', line: "Bring me grapes. Peel 'em. Actually don't peel 'em, I'm not a monster." },
  { who: 'skorn', mood: 'angry', line: 'This the worst day of my life, and I set a map on fire yesterday.' },
  { who: 'xylo', line: 'Lykor. The metocy will not find itself.' },
  { who: 'lykor', line: "Aight, aight. My people! It's been real, but your king gotta dip." },
  { do: 'goblinsBlock' },
  { who: 'chief', line: 'Dip? DIP?! The Shiny One stays FOREVER.' },
  { who: 'goblins', line: 'FOREVER! FOREVER! FOREVER!' },
  { who: 'narrator', line: 'How does Lykor get out of this?' },
  {
    choice: [
      {
        text: 'Give a royal speech',
        steps: [
          { who: 'lykor', line: 'My people. My loyal, crusty people.' },
          { who: 'lykor', mood: 'smug', line: 'A king is like a hair flip. You gotta let it go… so it can come back even harder.' },
          { who: 'goblins', line: '…' },
          { who: 'chief', line: "…That's the most beautiful thing I've ever heard." },
          ...OUTRO,
        ],
      },
      {
        text: 'Sneak out',
        steps: [
          { do: 'sneak' },
          { who: 'lykor', thought: true, line: "Slow… quiet… they ain't even notice—" },
          { do: 'sneakCaught' },
          { who: 'lykor', mood: 'shocked', line: "WHY Y'ALL RIGHT BEHIND ME." },
          { who: 'goblin', line: 'We go where the Shiny One goes.' },
          { who: 'chief', line: '…Fine. A king needs his quests. But you WILL come back.' },
          { do: 'sneakReturn' },
          ...OUTRO,
        ],
      },
      {
        text: 'Let Skorn "negotiate"',
        steps: [
          { who: 'skorn', mood: 'smug', line: 'Step aside, pretty boy. Let a professional negotiate.' },
          { who: 'lykor', mood: 'shocked', line: 'Skorn, do NOT—' },
          { do: 'skornSlap' },
          { who: 'narrator', line: 'Skorn Diddy Slaps the nearest goblin.' },
          { do: 'fightGoblins' },
          { who: 'chief', line: '…The purple one hits so hard. So beautifully.' },
          { who: 'goblins', line: 'WE WORSHIP THE PURPLE ONE TOO!' },
          { do: 'skornRespect' },
          { who: 'skorn', mood: 'smug', line: 'Finally. Somebody in this forest got taste.' },
          ...OUTRO,
        ],
      },
    ],
  },
];
