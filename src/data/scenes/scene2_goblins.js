// Scene 2 — Goblin Village. Play as Lykor.
// Every line here is a Claude DRAFT in Ebain's style — keep, edit or replace any of them.
// Format notes are at the top of scene1_the_map.js.

const OUTRO = [
  { who: 'chief', line: '…Fine. The metocy is sold at the Metocy Mart, east of here.' },
  { who: 'xylo', mood: 'unimpressed', line: 'They… sell it?' },
  { who: 'chief', line: 'For all yo metocy needs.' },
  { do: 'goblinsCry' },
  { who: 'goblins', line: '*sobbing* BYE MOGGING ELF!! COME BACK HARDER!!' },
  { who: 'xylo', mood: 'smug', line: "On my Dragon Mama, I'm leading from here. Lykor too famous now." },
  { do: 'leave' },
];

export const SCENE2 = [
  { who: 'narrator', line: 'Later that morning…' },
  { do: 'enterParty' },
  { who: 'skorn', mood: 'angry', line: "Man, I can't believe this jit got the lead now." },
  { who: 'lykor', mood: 'smug', line: "Map-burners don't get a vote, Skorn." },
  { who: 'xylo', mood: 'vision', line: "Wait a second… sum don't feel right, folk." }, // Ebain

  { do: 'goblinsAppear' },
  { who: 'goblin', line: '…' },
  { who: 'goblin', line: "Yay.. you are allowed to mog that hard, right? Cool dude, that's fucking fair." }, // Ebain
  { who: 'goblins', line: 'THE MOGGING ELF!!' }, // Ebain
  { do: 'goblinsKneel' },
  { who: 'lykor', mood: 'flattered', line: 'Hell yup… this looksmaxxin shi payin off.' }, // Ebain
  { who: 'skorn', mood: 'angry', line: "Hell nah. Why they ain't bowing to ME? I'm the one with armor." },
  { who: 'xylo', mood: 'unimpressed', line: 'Prophecies be weird like that.' },

  { do: 'chiefAppears' },
  { who: 'chief', line: 'For a thousand years we have waited for the Mogging Elf. Golden hair. Pointy ears. Smells like expensive conditioner.' },
  { who: 'lykor', mood: 'smug', line: "Aight, if I'm y'all's god or whatever, then answer me this: where the metocy at?" },
  { who: 'chief', line: '*gasp* The Mogging Elf seeks the metocy… We know where it is.' },
  { who: 'skorn', mood: 'smug', line: 'Then run it, short stuff.' },
  { who: 'chief', line: 'We will tell the Mogging Elf… once he is crowned. Come. Your throne awaits.' },

  { do: 'toThrone' },
  { who: 'narrator', line: 'The goblins seat Lykor on a throne made of spoons, bones, and one (1) wagon wheel.' },
  { do: 'crown' },
  { who: 'lykor', mood: 'flattered', line: "Y'all had said you got some beezy or some shi?" }, // Ebain
  { do: 'beezy' },
  { who: 'narrator', line: 'The goblins hand the Mogging Elf a mug of goblin beezy.' },
  { who: 'lykor', mood: 'flattered', line: 'Ayy. Now THIS a kingdom.' },
  { who: 'xylo', mood: 'unimpressed', line: 'Lykor. Focus. Ask him.' },
  { who: 'lykor', line: "Aight, I'm crowned. Where the metocy at?" },
  { do: 'goblinsBlock' },
  { who: 'chief', line: "Oh, we'll tell you… as long as you stay our king. FOREVER." },
  { who: 'goblins', line: 'FOREVER! FOREVER! FOREVER!' },
  { who: 'lykor', mood: 'angry', line: 'Bro, I just wanted directions.' },
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
          { who: 'goblin', line: 'We go where the Mogging Elf goes.' },
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
