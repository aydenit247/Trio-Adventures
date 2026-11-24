# Trio Adventures — Freeze Report

**What happened:** The game stopped responding: no frame has been drawn for 12 seconds.  
**Report written:** 2026-11-23 18:57:52  

## What probably caused it
- It happened **while loading an area**. If it recovered, it was just slow (first launch compiles shaders). If not, the scene being loaded is the suspect.

## What the player was doing
- **Area:** res://main.tscn
- **Controlling:** Skorn at (5.44086,-0.001538,-1.923729)
- **Player input locked (cutscene/menu/dialogue):** false
- **Dialogue on screen:** no
- **In a fight:** no
- **Menu open:** no
- **Party:** level 1, 0 XP, 0 gold
- **Bags:** { "skorn": {  }, "lykor": {  }, "xylo": {  } }
- **Equipped:** { "skorn": {  }, "lykor": {  }, "xylo": {  } }
- **Story flags on:** campLit, bag_checked, campSlept
- **Settings:** voices on · graphics High · difficulty 1
- **FPS:** 240 · **objects:** 3407 · **memory used:** 0 MB · **triangles drawn:** 1008513
- **Time since the game started:** 9:53

## Last things that happened (newest at the bottom)
```
[00:00.0] Game started (2026-11-23 18:47:46)
[00:01.6] Scene: res://title.tscn
[03:22.8] Loading a new area…
[03:23.3] Scene: res://main.tscn
[03:28.1] Dialogue — "Caelid. Night. The night before the greatest quest of their lives."
[03:42.1] Dialogue — "The quest for the metocy."
[03:47.9] Dialogue — Lykor: "Dat metocy gon be gah tomorrow, on the absolute."
[03:53.8] Dialogue — Skorn: "Man, it's about cold as a motherfucker. We could get the fire going, though."
[04:01.3] Dialogue — Lykor: "Aight bet. But don't touch my bag, though."
[04:06.1] Dialogue — Skorn: "Why would I touch yo bag, mud?"
[04:18.4] Dialogue — Lykor: "Aight bet. But don't touch my bag, though."
[04:21.3] Dialogue — Skorn: "Why would I touch yo bag, mud?"
[04:29.9] Dialogue — Lykor: "Aight bet. But don't touch my bag, though."
[04:32.1] Dialogue — Skorn: "Why would I touch yo bag, mud?"
[04:57.9] Dialogue — Skorn  (thinking): "Alright, where the fuck is some fire starter? I'm tryna get this bitch going."
[05:09.4] Dialogue — Skorn: "Why would I touch yo bag, mud?"
[05:12.1] Dialogue — Skorn  (thinking): "Alright, where the fuck is some fire starter? I'm tryna get this bitch going."
[05:17.9] Dialogue — Skorn  (thinking): "Man, fuck this jit Lykor. He probably got some gas fire starter in his bag."
[05:23.1] Dialogue — "(WASD to walk, E to interact. Get the fire going.)"
[05:30.9] Dialogue closed
[05:36.7] Dialogue — Skorn  (thinking): "…He don't got no fire starter. He got a book."
[05:42.0] Dialogue closed
[05:44.0] Dialogue — Lykor: "Aight bet. But don't touch my bag, though."
[05:48.3] Dialogue closed
[05:55.1] Dialogue — Skorn  (thinking): "Can't start a fire with nothing. Need some fire starter."
[05:57.6] Dialogue closed
[06:07.1] Dialogue — Skorn  (thinking): "Ain't no fire starter in the tent. Just Xylo's lore books. Too heavy to burn."
[06:09.9] Dialogue closed
[06:22.6] Dialogue — Skorn  (thinking): "Can't start a fire with nothing. Need some fire starter."
[06:23.6] Dialogue closed
[06:24.9] Dialogue — Skorn  (thinking): "Can't start a fire with nothing. Need some fire starter."
[06:25.4] Dialogue — "Skorn got: Important-Looking Paper."
[06:29.6] Dialogue — "It reads: "M̷Ꭺ̵Ꮲ̶ ̸Ƭ̷Ө̴ ̵Ƭ̶Ң̸Ɛ̷ ̴M̵Ɛ̶Ƭ̸Ө̷C̴Ɏ̵" (Skorn cannot read)"
[06:37.9] Dialogue — Skorn  (thinking): "Bunch of squiggly ass lines. Yeah, that's fire starter."
[06:41.4] Dialogue closed
[06:48.1] Dialogue — Goblin: "Ayo. Y'all got a light?"
[06:52.1] Dialogue — Skorn: "Do it LOOK like we got a light?"
[06:54.6] Dialogue closed
[07:00.6] Menu open: party
[07:33.9] Menu closed
[07:36.7] Menu open: party
[07:48.0] Menu closed
[07:51.8] Dialogue — Skorn: "Do it LOOK like we got a light?"
[07:53.5] Dialogue — Lykor: "Damn, you started that up quick. Good shit, dude."
[07:58.5] Dialogue — Skorn: "Yeah, I just used the paper that was in your bag. I don't know why you said I couldn't use your bag."
[08:06.3] Dialogue — Lykor: "Say you swear to the absolute."
[08:09.8] Dialogue — Skorn: "What? What are you talking about, mud?"
[08:15.5] Dialogue — Lykor: "BRO. THAT WAS THE MAP TO THE METOCY. THE ONLY MAP."
[08:21.3] Dialogue — Xylo: "On my Dragon Mama... I seen this in a vision. I just ain't think it'd be this dumb."
[08:30.3] Dialogue — Skorn: "Then why the fuck you leave it in a bag?! Bags is for fire starter!"
[08:36.3] Dialogue — Xylo: "On my Dragon Mama... I seen this in a vision. I just ain't think it'd be this dumb."
[08:40.8] Dialogue — Skorn: "Then why the fuck you leave it in a bag?! Bags is for fire starter!"
[08:46.8] Dialogue — Lykor: "Bags is for MAPS, Skorn!"
[08:51.0] Dialogue — Skorn: "Not no more."
[08:53.3] Dialogue — Xylo: "Chill. Them goblins up north know every road in Caelid. We just ask them."
[08:59.8] Dialogue — Lykor: "Bet. We leave at sunrise. And nobody touch NUN."
[09:06.6] Dialogue — "(Explore the camp. Q switches who you control. Tab opens your inventory.)"
[09:14.3] Dialogue closed
[09:22.1] Dialogue — Choice on screen (2 options)
[09:23.8] Dialogue — Lykor: "Don't touch my bag, doe!"
[09:26.8] Dialogue closed
[09:27.6] Dialogue — Choice on screen (2 options)
[09:28.3] Dialogue — Lykor: "Don't touch my bag, doe!"
[09:29.6] Dialogue closed
[09:33.2] Dialogue — Skorn: "I'm not tired. I'm finna stay up and guard the fire."
[09:37.7] Dialogue — Xylo: "Guard it from what."
[09:40.8] Dialogue — Skorn: "From… other fires."
[09:53.0] Loading a new area…
[09:53.0] Dialogue closed
```

## Engine / script errors this session
None logged.

## PC
- **OS:** Windows 10.0.26200
- **CPU:** 12th Gen Intel(R) Core(TM) i9-12900 (24 threads)
- **RAM:** 31.7 GB total, 19.7 GB free at startup
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
