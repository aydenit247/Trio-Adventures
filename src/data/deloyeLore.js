// DELOYE LORE — used by the Lore Session minigame (Scene 4, choice C).
//
// Each passage is a page from a different chapter. It tells a short story in a mystical, epic tone and
// stops mid-sentence. The player picks how the story continues: `right` is the continuation that stays
// true to the lore (the details in the passage point to it); `wrong` are continuations that break it.
// Diddy Chud Giant is secretly a lore nerd — true lore soothes him, wrong lore wakes him up.
//
// Edit, add or replace passages freely. Five are played per session, in order.

export const LORE_PASSAGES = [
  {
    where: 'Chapter 8,784 · Section B12 · Page 3',
    title: 'The First Metocy',
    text:
      'In the age before ages, when Caelid was still mostly soup, the first metocy fell from the sky like a tear '
      + 'from a bored star. It was small. It was oval. It glowed a blue so holy that three kingdoms went to war just to '
      + 'look at it. The sages who first held it wrote that its shell was dry as desert bone and warm as a '
      + "grandmother's hand, and that whoever held it saw the whole universe at once — and the universe, for the first "
      + 'time, saw them back. And so it was written, for all the ages to come, that true metocy shall forever be…',
    right: '…dry as bone, blue as heaven, and never, ever moist.',
    wrong: ['…soft, damp, and lightly moist to the touch.', '…purple, cracked, and sold at a discount.'],
  },
  {
    where: 'Chapter 112 · Section A7 · Page 9',
    title: 'The Sneeze of the Dragon Mama',
    text:
      'Long before scales had names, the Dragon Mama slept atop the highest mountain in Caelid, curled around the moon '
      + 'to keep it warm. For a thousand years she did not move. Then one winter, a single grain of cosmic pepper drifted '
      + 'into her nostril. The mountain trembled. The moon held its breath. And with a sneeze so mighty it cracked the sky '
      + 'into seven pieces, out flew the very first dragon — small, red, and already offended. This is why, to this day, '
      + 'every dragon who swears a true oath says…',
    right: '…"On my Dragon Mama," and the sky remembers.',
    wrong: ['…"By the moon," for the moon was their mother.', '…nothing at all, for dragons do not make oaths.'],
  },
  {
    where: 'Chapter 6,006 · Section Z1 · Page 44',
    title: 'The Throne Beyond the Smoke',
    text:
      'There is a god who does not live in Caelid, nor in any heaven, but in a dimension folded behind the smoke. His name '
      + 'is Dulbmeethus. No temple can reach him and no prayer can find him. There is only one way: a traveler must light a '
      + "Dulber's Frint Pack and breathe deep, until their spirit slips free of their body and drifts upward through the "
      + 'purple fog. Many who tried were never the same. Those who arrived found him lounging upon a throne of clouds, eyes '
      + 'like twin galaxies, already waiting. He leaned forward, and spoke the ancient greeting:',
    right: '"Y\'all could hear me doe?"',
    wrong: ['"Welcome, mortal, to my eternal realm."', '"Who dares disturb the great Dulbmeethus?"'],
  },
  {
    where: 'Chapter 4,040 · Section C3 · Page 12',
    title: 'The Spoon That Became',
    text:
      'When Dulbmeethus grew bored — which was often — he would reach down through the smoke and make things. Mountains. '
      + 'Rivers. A frog with opinions. One afternoon he found nothing on his table but a single silver spoon. He breathed on '
      + 'it. He named it. And the spoon stood up, blinked twice, and asked for a snack. That was the first goblin. Its children '
      + 'were born small, hungry and loyal, and they never forgot where they came from. That is why, in every goblin village, '
      + 'the most sacred treasures are always…',
    right: '…spoons, piled high on altars and polished every morning.',
    wrong: ["…golden swords, taken from the first goblin's grave.", '…mushrooms, for the first goblin grew from the dirt.'],
  },
  {
    where: 'Chapter 9,999 · Section Q2 · Page 1',
    title: 'The Prophecy of the Three',
    text:
      'And on the last page of the first volume is written the oldest prophecy of all: three shall rise from Caelid to seek '
      + 'the metocy. One purple and full of fury, who cannot read. One golden-haired, whose beauty shall bend whole kingdoms. '
      + 'And one red, who sees what others cannot — and speaks of it far too often. On the night before their journey, the '
      + 'one who cannot read shall find the only map, and he shall…',
    right: '…feed it to the fire, and call it fire starter.',
    wrong: ['…read it aloud, and lead them true.', '…guard it with his life, and never let it go.'],
  },
];
