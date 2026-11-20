// Scene 2 — Goblin Village. Play as Lykor.
// Every line here is a Claude DRAFT in Ebain's style — keep, edit or replace any of them.
// Format notes are at the top of scene1_the_map.js.

// Shared goodbye (choices A, B-win and E)
const GOODBYE = [
  { who: 'xylo', mood: 'unimpressed', line: 'They… sell it?' },
  { who: 'chief', line: 'For all yo metocy needs.' },
  { do: 'goblinsCry' },
  { who: 'goblins', line: '*sobbing* BYE!! COME BACK HARDER!!' },
  { who: 'xylo', mood: 'smug', line: "On my Dragon Mama, I'm leading from here." },
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
      // A — royal speech → directions + beezy for the road (healing item)
      {
        text: 'Give a royal speech',
        steps: [
          { who: 'lykor', mood: 'smug', line: 'My chopped goblins. My loyal chopped goblins.' }, // Ebain
          { who: 'lykor', mood: 'smug', line: "Y'all need to quit being OD and let me dip on a mf, and that's on some type shi. I'll spin the block on y'all and bring u some metocy n shi, trust. Y'all type coo." }, // Ebain
          { who: 'chief', line: 'Bet dat.' }, // Ebain
          { who: 'chief', line: "Aight, so if you could keep walking doe, over there, on some east shit. As far as I know, that's the best metocy a goblin like me could get his hands on." }, // Ebain
          { who: 'chief', line: 'Here go some beezy, folk. Take it for the road.' }, // Ebain
          { do: 'giftBeezy' },
          { who: 'narrator', line: 'Lykor got: Beezy ×3 (heals)' },
          { who: 'lykor', mood: 'flattered', line: "Y'all real for this. Real ones." },
          { who: 'skorn', mood: 'angry', line: 'Why HE get the beezy?' },
          ...GOODBYE,
        ],
      },
      // B — chugging contest (button-mash minigame)
      {
        text: 'Challenge the chief to a chugging contest',
        steps: [
          { who: 'lykor', mood: 'smug', line: "I bet your ass can't beat me in a beezy contest." }, // Ebain
          { who: 'chief', line: '*gasp* Nobody has out-drunk Bogdrinker in 400 years.' },
          { who: 'skorn', mood: 'unimpressed', line: "Bro literally chugs bogs and swamps. It's in his NAME, dumbass." }, // Ebain's idea
          { do: 'chugGame' },
          {
            if: 'chugWon',
            steps: [
              { who: 'chief', line: '…The Mogging Elf… out-drank… BOGDRINKER?' },
              { who: 'goblins', line: 'LEGEND! LEGEND! LEGEND!' },
              { who: 'chief', line: '*hic* The Metocy Mart. East. Go before I cry.' },
              ...GOODBYE,
            ],
          },
          {
            ifNot: 'chugWon',
            steps: [
              { do: 'passOut' },
              { who: 'narrator', line: 'Lykor passes out.' },
              { do: 'wakeOutside' },
              { who: 'narrator', line: 'Lykor wakes up outside the village. Something is written on his forehead.' },
              { who: 'xylo', mood: 'unimpressed', line: 'On my Dragon Mama… it says "METOCY MART, EAST. LOSER."' },
              { who: 'lykor', mood: 'angry', line: "…They ain't have to add the last part." },
              { who: 'xylo', mood: 'smug', line: "I'm leading from here." },
              { do: 'leave' },
            ],
          },
        ],
      },
      // C — offer Skorn as king → Skorn gets left behind (bursts into Metocy Mart later)
      {
        text: 'Offer Skorn as the new king',
        steps: [
          { who: 'lykor', mood: 'smug', line: "Aight, real talk. Take HIM instead. He's purple. That's basically royal." },
          { who: 'skorn', mood: 'confused', line: 'Say what now?' },
          { who: 'chief', line: '…A purple king…' },
          { who: 'goblins', line: 'PURPLE KING! PURPLE KING!' },
          { do: 'crownSkorn' },
          { who: 'narrator', line: 'The goblins crown Skorn.' },
          { who: 'skorn', mood: 'smug', line: 'Wait, dis bih tuff lowkey. I could fw this.' }, // Ebain
          { who: 'chief', line: 'The Metocy Mart is east. Now leave, Mogging Elf. We have a new god.' },
          { who: 'lykor', line: 'Damn. That was easy. Too easy.' },
          { who: 'xylo', mood: 'unimpressed', line: "We are leaving him here, aren't we." },
          { who: 'lykor', mood: 'smug', line: 'Yup.' },
          { do: 'leave' },
        ],
      },
      // D — sneak out → the goblins tag along to Metocy Mart
      {
        text: 'Sneak out',
        steps: [
          { do: 'sneak' },
          { who: 'lykor', thought: true, line: 'Slow… quiet…' }, // Ebain
          { do: 'sneakCaught' },
          { who: 'lykor', mood: 'shocked', line: "What the fuck is y'all doing?" }, // Ebain
          { who: 'goblin', line: 'We go where the Mogging Elf goes.' },
          { who: 'chief', line: 'The Mogging Elf seeks the metocy? Then the goblins will take him there OURSELVES. To the Metocy Mart!' },
          { who: 'goblins', line: 'FIELD TRIP! FIELD TRIP! FIELD TRIP!' },
          { who: 'skorn', mood: 'angry', line: 'Hell nah.' },
          { do: 'goblinsJoin' },
          { who: 'xylo', mood: 'unimpressed', line: 'On my Dragon Mama… we got an entourage now.' },
          { do: 'leave' },
        ],
      },
      // E — Skorn "negotiates" → real fight → the goblins worship Skorn, Lykor gets dethroned
      {
        text: 'Let Skorn "negotiate"',
        steps: [
          { who: 'skorn', mood: 'smug', line: 'Step aside, pretty boy. Let a professional negotiate.' },
          { who: 'lykor', mood: 'shocked', line: 'Skorn, do NOT—' },
          { do: 'skornSlap' },
          { who: 'narrator', line: 'Skorn Diddy Slaps the nearest goblin.' },
          { do: 'fightGoblins' },
          { who: 'chief', line: '…The purple one hits so hard. So beautifully.' },
          { who: 'goblins', line: 'WE WORSHIP THE PURPLE ONE NOW!' },
          { who: 'chief', line: 'The Mogging Elf is… dethroned. Give the beezy to the purple one.' },
          { do: 'dethrone' },
          { who: 'lykor', mood: 'angry', line: "Y'all DEADASS?" },
          { who: 'skorn', mood: 'smug', line: 'Finally. Somebody in this forest got taste.' },
          { who: 'chief', line: "The Metocy Mart is east. Purple one, come back anytime. Elf… don't." },
          ...GOODBYE,
        ],
      },
    ],
  },
];
