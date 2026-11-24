# Trio Adventures — Freeze Report

**What happened:** The game stopped responding: no frame has been drawn for 12 seconds.  
**Report written:** 2026-11-23 19:38:17  

## What probably caused it
- It happened **while loading an area**. If it recovered, it was just slow (first launch compiles shaders). If not, the scene being loaded is the suspect.

## What the player was doing
- **Area:** res://main.tscn
- **Controlling:** Skorn at (0.087696,0.000845,-21.89293)
- **Player input locked (cutscene/menu/dialogue):** true
- **Dialogue on screen:** no
- **In a fight:** no
- **Menu open:** no
- **Party:** level 1, 0 XP, 0 gold
- **Bags:** {  }
- **Equipped:** {  }
- **Story flags on:** campLit, campSlept, campDone
- **Settings:** voices on · graphics High · difficulty 1
- **FPS:** 240 · **objects:** 4263 · **memory used:** 0 MB · **triangles drawn:** 454646
- **Time since the game started:** 39:15

## Last things that happened (newest at the bottom)
```
[29:59.9] Fight — Xylo uses Dragon Breath on Dulbers Frint! (-23)
[30:00.7] Fight — Dulbers Frint is COOKED. On fire for a few turns.
[30:02.2] Fight — Dulbers Frint is Cooked. The fire is still going. (-6)
[30:03.2] Fight — Dulbers SHAPESHIFTS… into Xylo?! (Bootleg version)
[30:15.9] Fight — Skorn rolls the d6… (on some dice shi)
[30:17.9] Fight — Skorn crashes out on Dulbers Frint! (rolled a 5) (-36)
[30:21.7] Fight — Metocin Mattias uses Metocy Bolt on Dulbers Frint! (-32)
[30:29.2] Fight — Lykor uses Mog on Dulbers Frint! (-36)
[30:30.0] Fight — Dulbers Frint is MOGGED. Insecure now. Takes 25% more damage.
[30:32.0] Fight — Dulbers Frint is Cooked. The fire is still going. (-8)
[30:32.8] Fight — Dulbers: "I'm not losing, I'm just… restocking." (COPIUM: heals each turn. Hit him hard to break it.)
[30:45.9] Fight — Xylo uses Citation Needed on Dulbers Frint! (-27)
[30:46.4] Fight — That broke his Copium.
[30:47.1] Fight — Dulbers Frint is HUMBLED.
[30:56.0] Fight — Skorn uses Diddy Slap on Dulbers Frint! (-25)
[31:00.8] Fight — Metocin Mattias uses Wizard Drip on Dulbers Frint! (-59)
[31:01.5] Fight — Dulbers Frint is down!
[31:05.9] Dialogue — Dulbers Frint: "*sniffling* Y'all gon' hear from Dulbmeethus about this…"
[31:05.9] Fight ended
[31:08.9] Dialogue closed
[31:10.7] Dialogue — Dulbers Frint: "*sniffling* Y'all gon' hear from Dulbmeethus about this…"
[31:11.2] Dialogue closed
[31:27.8] Menu open: pause
[31:33.4] Menu closed
[32:14.7] Dialogue — Metocin Mattias: "Welcome to da crib folk, you had said you was looking for metocy? You have earned it. I had heard that y'all made Dulbers cry on a mountain. T
[32:27.9] Dialogue — Lykor: "You fight like you mog."
[32:30.1] Dialogue — Metocin Mattias: "Thank you folk."
[32:32.2] Dialogue closed
[32:32.9] Dialogue — Metocin Mattias: "Here yall go folk, have at it."
[32:35.7] Dialogue — Choice on screen (5 options)
[32:58.2] Dialogue — Metocin Mattias: "Bet."
[33:01.0] Dialogue closed
[33:03.2] Dialogue — Skorn: "Mattias you was fuckin wit one this whole time?"
[33:07.0] Dialogue — Metocin Mattias: "Bet."
[33:09.0] Dialogue — Metocin Mattias: "Now peep this, folk. What if we gave every goblin some metocy?"
[33:15.6] Dialogue — Choice on screen (2 options)
[33:23.2] Dialogue closed
[33:40.5] Loading a new area…
[33:40.8] Scene: res://title.tscn
[36:18.4] Loading a new area…
[36:18.7] Scene: res://main.tscn
[36:23.4] Dialogue — "Caelid. Night. The night before the greatest quest of their lives."
[36:25.7] Dialogue — "The quest for the metocy."
[36:26.9] Dialogue — Lykor: "Dat metocy gon be gah tomorrow, on the absolute."
[36:30.2] Dialogue — Skorn: "Man, it's about cold as a motherfucker. We could get the fire going, though."
[36:31.9] Dialogue — Lykor: "Aight bet. But don't touch my bag, though."
[36:36.2] Dialogue — Skorn: "Why would I touch yo bag, mud?"
[36:41.2] Dialogue — Skorn  (thinking): "Alright, where the fuck is some fire starter? I'm tryna get this bitch going."
[36:45.2] Dialogue — Skorn  (thinking): "Man, fuck this jit Lykor. He probably got some gas fire starter in his bag."
[36:49.7] Dialogue — "(WASD to walk, E to interact. Get the fire going.)"
[36:56.6] Dialogue closed
[36:59.9] Dialogue — "(WASD to walk, E to interact. Get the fire going.)"
[37:00.6] Dialogue — "Skorn got: Important-Looking Paper."
[37:02.2] Dialogue — "It reads: "M̷Ꭺ̵Ꮲ̶ ̸Ƭ̷Ө̴ ̵Ƭ̶Ң̸Ɛ̷ ̴M̵Ɛ̶Ƭ̸Ө̷C̴Ɏ̵" (Skorn cannot read)"
[37:08.5] Dialogue — Skorn  (thinking): "Bunch of squiggly ass lines. Yeah, that's fire starter."
[37:11.5] Dialogue closed
[37:14.0] Dialogue — Skorn  (thinking): "Bunch of squiggly ass lines. Yeah, that's fire starter."
[37:15.8] Dialogue — Lykor: "Damn, you started that up quick. Good shit, dude."
[37:19.5] Dialogue — Skorn: "Yeah, I just used the paper that was in your bag. I don't know why you said I couldn't use your bag."
[37:27.0] Dialogue — Lykor: "Say you swear to the absolute."
[37:29.8] Dialogue — Skorn: "What? What are you talking about, mud?"
[37:33.3] Dialogue — Lykor: "BRO. THAT WAS THE MAP TO THE METOCY. THE ONLY MAP."
[37:38.5] Dialogue — Xylo: "On my Dragon Mama... I seen this in a vision. I just ain't think it'd be this dumb."
[37:45.8] Dialogue — Skorn: "Then why the fuck you leave it in a bag?! Bags is for fire starter!"
[37:50.3] Dialogue — Lykor: "Bags is for MAPS, Skorn!"
[37:54.0] Dialogue — Skorn: "Not no more."
[37:55.1] Dialogue — Xylo: "Chill. Them goblins up north know every road in Caelid. We just ask them."
[38:01.6] Dialogue — Lykor: "Bet. We leave at sunrise. And nobody touch NUN."
[38:07.3] Dialogue — "(Explore the camp. Q switches who you control. Tab opens your inventory.)"
[38:26.6] Dialogue closed
[38:29.6] Dialogue — Skorn: "I'm not tired. I'm finna stay up and guard the fire."
[38:33.4] Dialogue — Xylo: "Guard it from what."
[38:36.4] Dialogue — Skorn: "From… other fires."
[38:47.7] Loading a new area…
[38:47.7] Dialogue closed
[38:49.0] Dialogue — "The next morning…"
[38:52.6] Dialogue — Lykor: "Aight, new rule: Skorn don't hold nothing. I'm leading."
[38:59.9] Dialogue — Skorn: "Bet, my fault. I'm dumb as hell."
[39:05.4] Dialogue closed
[39:15.6] Loading a new area…
```

## Engine / script errors this session
None logged.

## PC
- **OS:** Windows 10.0.26200
- **CPU:** 12th Gen Intel(R) Core(TM) i9-12900 (24 threads)
- **RAM:** 31.7 GB total, 20.0 GB free at startup
- **GPU:** NVIDIA GeForce RTX 3070 (NVIDIA) · 12_0
- **Renderer:** forward_plus
- **Screen:** (2560, 1440) · window (1280, 720)
- **Godot:** 4.7.2-stable (official)
- **Game data (.pck) built:** 2026-11-24 02:47:01

---
_For the Claude reading this: check TIPS.md (known gotchas like the Windows TTS deadlock) and COLLAB.md, then log what you find._
## Update: it never came back
The game was closed without quitting normally after this freeze (probably Task Manager), so it was a **hard freeze**.

## End of Godot's log from that session
```

```
