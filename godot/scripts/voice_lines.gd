# Voice lines: a line in the scripts with a voice file plays it instead of the robot TTS.
# Lines are matched by their text (case, punctuation and spacing ignored), so the same file works
# wherever that line is used. If someone rewords a line, it falls back to TTS until it's regenerated.
#
# AI voices from the Emberstage studio are listed in voice_index.gd (made by tools/import_voices.py).
# For a one-off file by hand: drop it in res://assets/voices/<group>/ and add  "line text": "<group>/<file>"  below
# (no extension = .mp3). How voices get made: VOICE_LINES.md (repo root).
class_name VoiceLines

const DIR := "res://assets/voices/"

# Voice lines generated with the Emberstage studio (github.com/aydenit247/Voice-actor-generation) go here.
# Asar's 37 goblin/Chief recordings were removed on 2026-11-21 (Ebain's call: every voice will be AI-generated).
# Narrator, Lykor and Xylo: Asar's own recordings (2026-11-22). Their lines without a recording were removed (his call).
const LINES := {
	"Caelid. Night. The night before the greatest quest of their lives.": "narrator/caelid_night_the_night_before",
	"The quest for the metocy.": "narrator/the_quest_for",
	"(WASD to walk, E to interact. Get the fire going.)": "narrator/wasd_to_walk",
	"Skorn got: Important-Looking Paper.": "narrator/skorngotimportant",
	"It reads: \"M̷Ꭺ̵Ꮲ̶ ̸Ƭ̷Ө̴ ̵Ƭ̶Ң̸Ɛ̷ ̴M̵Ɛ̶Ƭ̸Ө̷C̴Ɏ̵\" (Skorn cannot read)": "narrator/it_reads_skorn_can_not_read",
	"(Explore the camp. Q switches who you control. Tab opens your inventory.)": "narrator/explorethecampqswitches",
	"The campfire. Burning bright. Suspiciously bright.": "narrator/thecampfireburningbright",
	"The next morning…": "narrator/thenextmorning",
	"Later that morning…": "narrator/laterthatmorning",
	"(You're playing as Lykor now. Folk, head into that village over there.)": "narrator/you_are_playing_as_lykor_now_folk_head_into_that_village_over_there",
	"The goblins seat Lykor on a throne made of spoons, bones, and one (1) wagon wheel.": "narrator/thegoblinsseatlykoronathrone",
	"How does Lykor get out of this?": "narrator/howdoeslykorgetoutofthis",
	"Lykor got: Beezy ×3 (heals)": "narrator/lykorgot3beezys",
	"Lykor passes out.": "narrator/lykorpassesout",
	"Skorn Diddy Slaps the nearest goblin.": "narrator/skorndiddyslaps",
	"East of the goblin village…": "narrator/eastofthegoblin",
	"(You're playing as Xylo now.)": "narrator/you_are_playing_as_xylo_now",
	"The trio takes the metocy.": "narrator/thetriotakes",
	"Got: Midtocy (throwable)": "narrator/got_midtocy_throwable",
	"Dulbers Frint was never seen again.": "narrator/dulbers_frint_was_never_seen_again",
	"Past the giant, the path climbs higher. Somewhere up ahead… the metocy.": "narrator/past_the_giant_the_path_climbs_higher_somewhere_up_ahead_the_metocy",
	"The mountain pass. Hot. Ashy. And OD as a mufucka.": "narrator/the_mountain_pass_hot_ashy_and_od_as_a_mufucka",
	"How do you get past Diddy Chud Giant?": "narrator/how_do_you_get_past_diddy_chud_giant",
	"The trio makes it across. Diddy Chud never wakes up.": "narrator/the_trio_makes_it_across_diddy_chud_never_wakes_up",
	"Diddy Chud Giant smiles in his sleep… and rolls over. The path is clear.": "narrator/diddy_chud_giant_smiles_in_his_sleep",
	"Skorn Diddy Slaps the giant across the face.": "narrator/skorn_diddy_slaps_the_giant_across",
	# Lykor: Asar's recordings (2026-11-22). Lykor lines without a recording were removed (his call).
	"A store in the middle of nowhere. Totally normal.": "lykor/a_store_in_the_middle_of_nowhere",
	"Aight bet. But don't touch my bag, though.": "lykor/aight_bet_but_dont_touch_my_bag",
	"Aight, if I'm y'all's god or whatever, then answer me this: where the metocy at?": "lykor/aight_if_im_yalls_god_or_whatever_then_answer_me_this",
	"Aight, I'm crowned. Where the metocy at?": "lykor/aight_im_crowned_where_the",
	"Aight, new rule: Skorn don't hold nothing. I'm leading.": "lykor/aight_new_rule_skorn_dont_hold",
	"Aight, real talk. Take HIM instead. He's purple. That's basically royal.": "lykor/aight_real_talk_take_him_instead",
	"Aight, so what the word? What we owe ya for some metocy, mud?": "lykor/aight_so_what_the_word_what_we_owe_ya",
	"Already??": "lykor/already",
	"Ayy. Now THIS a kingdom.": "lykor/ayy_now_this_a_kingdom",
	"Bags is for MAPS, Skorn!": "lykor/bags_is_for_maps_skorn",
	"Behold. Perfection.": "lykor/behold_perfection",
	"Bet. We leave at sunrise. And nobody touch NUN.": "lykor/bet_we_leave_at_sunrise_and_nobody_touch_nun",
	"Bogdrinker. Y'all try it first.": "lykor/bogdrinker_yall_try_it_first",
	"Bro deadahh sleep right where a mf gotta go.. like, yep.": "lykor/bro_deadahh_sleep_right_where_a_mf_gotta_go",
	"Bro, I just wanted directions.": "lykor/bro_i_just_wanted_directions",
	"Bro, not everything is solved by Deloye Lore.": "lykor/bro_not_everything_is_solved_by_deloy_lore",
	"BRO. THAT WAS THE MAP TO THE METOCY. THE ONLY MAP.": "lykor/bro_that_was_the_map_to_the_metocy",
	"Damn. That was easy. Too easy.": "lykor/damn_that_was_easy_too_easy",
	"Damn, you started that up quick. Good shit, dude.": "lykor/damn_you_started_that_up_quick",
	"Dat metocy gon be gah tomorrow, on the absolute.": "lykor/dat_metocy_gon_be_gah",
	"Don't look directly at me, folk.": "lykor/dont_look_directly_at_me_folk",
	"Don't touch my bag, doe!": "lykor/dont_touch_my_bag_doe",
	"Dulbers. What did you give us?": "lykor/dulbers_what_did_you_give_us",
	"Dulbers. What did you just give my guy?": "lykor/dulbers_what_did_you_just_give_my_guy",
	"Dulbmeethus fw my ahh, I ain't trippin' bout him.": "lykor/dulbmeethus_fw_my_ahh_i_aint_trippin",
	"Effortless.": "lykor/effortless",
	"Foolish..": "lykor/foolish",
	"He knows the lore?!": "lykor/he_knows_the_lore",
	"Hell yup… this looksmaxxin shit payin off.": "lykor/hell_yup_this_looksmaxxin_shit_payin_off",
	"I bet your ass can't beat me in a beezy contest, doe.": "lykor/i_bet_your_ass_cant_beat_me_in_a_beezy_contest_doe",
	"…I don't feel nothing.": "lykor/i_dont_feel_nothing",
	"I know. The conditioner is doing numbers tonight.": "lykor/i_know_the_conditioner",
	"It's weird without Skorn. …Peaceful, but weird.": "lykor/its_weird_without_skorn_peaceful_but_weird",
	"Map-burners don't get a vote, Skorn.": "lykor/map_burners_dont_get_a_vote_skorn",
	"Mate, get up, you are making us look bad.": "lykor/mate_get_up_you_are_making_us_look_bad",
	"Mogged.": "lykor/mogged",
	"Mountain pass it is.": "lykor/mountain_pass_it_is",
	"My chopped goblins. My loyal chopped goblins.": "lykor/my_chopped_goblins",
	"My hair cannot survive these OD ahh conditions. Pray for my ahh.": "lykor/my_hair_cannot_survive_these_od_ahh_conditions_pray_for_my_a",
	"My hair is RUINED.": "lykor/my_hair_is_ruined",
	"My WHAT?": "lykor/my_what",
	"Nah, I'm real life tweaking.": "lykor/nah_im_real_life_tweaking",
	"Nah, we good. Sum off about you, folk.": "lykor/nah_we_good_sum_off_about_you_folk",
	"Not the face!": "lykor/not_the_face",
	"Oh, he geeked now.": "lykor/oh_geeked_now",
	"On some type shit.": "lykor/on_some_type_shit",
	"Say you swear to the absolute.": "lykor/say_you_swear_to_the_absolute",
	"Skorn, do NOT—": "lykor/skorn_do_not",
	"Skorn. You first.": "lykor/skorn_you_first",
	"Slow… quiet…": "lykor/slow_quiet",
	"Somebody fix my hair, I'm dying.": "lykor/somebody_fix_my_hair_im_dying",
	"Tell my conditioner… I loved it…": "lykor/tell_my_conditioner_i_loved_it",
	"The ash is getting in my hair. I can feel it judging me.": "lykor/the_ash_is_getting_in_my_hair",
	"…They ain't have to add that last part.": "lykor/they_aint_have_to_add_that_last_part",
	"Ugh. Fine. I'll carry.": "lykor/ugh_fine_ill_carry",
	"Watch the hair!": "lykor/watch_the_hair",
	"We just gotta tiptoe across. Quiet as hell.": "lykor/we_just_gotta_tiptoe_across_quiet_as_hell",
	"What the fuck is y'all doing, folk?": "lykor/what_the_fuck_is_yall_doing_folk",
	"Why does that look like… nah. Nah.": "lykor/why_does_that_look_like",
	"Why is my bag opened?": "lykor/why_is_my_bag_opened",
	"Witness the aura.": "lykor/witness_the_aura",
	"Y'all are COUSINS?": "lykor/yall_are_cousins",
	"Y'all DEADASS?": "lykor/yall_deadass",
	"Y'all had said you got some beezy or some shit?": "lykor/yall_had_said_you_got_some_beezy_or_some_shit",
	"Y'all need to quit being OD and let me dip on a mf, and that's on some type shi. I'll spin the block on y'all and bring u some metocy n shi, trust. Y'all type coo.": "lykor/yall_need_to_quit_being_od_and_let_me_dip_on_a_mf",
	"Y'all real for this.": "lykor/yall_real_for_this",   # the recording never had "Real ones."
	"You robbed a sleeping giant?": "lykor/you_robbed_a_sleeping_giant",
	"You was a god for five minutes, bro. Pipe down.": "lykor/you_was_a_god_for_five_minutes_bro",
	"You was finna lace us with MIDTOCY?": "lykor/you_was_finna_lace_us_with_midtocy",
	"Yup.": "lykor/yup",
	# Xylo: Asar's recordings (2026-11-22). Xylo lines without a recording were removed (his call).
	"A tragic chapter.": "xylo/a_tragic_chapter",
	"And we still do not know where the metocy is.": "xylo/and_we_still_do_not_know_where_the_metocy_is",
	"As foretold in volume nine.": "xylo/as_foretold_in_volume_nine",
	"Ay you good bruh, he snoring loud as hell.": "xylo/ay_you_good_bruh_he_snoring_loud_as_hell",
	"Behold. My chud form.": "xylo/behold_my_chud_form",
	"But this one… is moist.": "xylo/but_this_one_is_moist",
	"CHUD. OUT.": "xylo/chud_out",
	"Cause they think he sexy as hell… like, yep.": "xylo/cause_they_think_he_sexy_as_hell_like_yep",
	"Chill. Them goblins up north know every road in Caelid. We just ask them.": "xylo/chill_them_goblins_up_north_know_every_road_in_caelid_we_jus",
	"Deloye Lore, Volume 4, says the night before a quest is sacred.": "xylo/deloye_lore_volume_4_says_the_night_before_a_quest_is_sacred",
	"Deloye was right.": "xylo/deloye_was_right",
	"Guard it from what.": "xylo/guard_it_from_what",
	"I did not see ts coming. Ts was not in the Deloye Lore scripture.": "xylo/i_did_not_see_ts_coming_ts_was_not_in_the_deloye_lore_script",
	"I'm leading from here.": "xylo/i_m_leading_from_here",
	"I'm running low on Lore Points.": "xylo/im_running_low_on_lore_points",
	"It is PERFECTLY canon.": "xylo/it_is_perfectly_canon",
	"It is written, in chapter 8,784, section B12, that true metocy glows from within — its shell dry as desert bone, smooth as a sage's forehead. True metocy is NEVER moist.": "xylo/it_is_written_in_chapter_8_784_section_b12_that_true_metocy_",
	"Just watch, folk.": "xylo/just_watch_folk",
	"Lykor. Focus. Ask him.": "xylo/lykor_focus_ask_him",
	"Maaaan, it's cause yo ass geekin off that midtocy.": "xylo/maaaan_it_s_cause_yo_ass_geekin_off_that_midtocey",
	"Maaan, this one is cracked, purple, and growing a small civilization.": "xylo/maaan_this_one_is_cracked_purple_and_growing_a_small_civiliz",
	"Nothing. There is no lore.": "xylo/nothing_there_is_no_lore",
	"On my Dragon Grandpa… our entourage has left us.": "xylo/on_my_dragon_grandpa_our_entourage_has_left_us",
	"On my Dragon Mama… it says \"METOCY MART, EAST. LOSER.\"": "xylo/on_my_dragon_mama_it_says_metocy_mart_east_loser",
	"On my Dragon Mama… we got an entourage now.": "xylo/on_my_dragon_mama_we_got_an_entourage_now",
	"On my Dragon Mama, I'm leading from here.": "xylo/on_my_dragon_mama_i_m_leading_from_here",
	"On my Dragon Mama... I seen this in a vision. I just ain't think it'd be this dumb.": "xylo/on_my_dragon_mama_i_seen_this_in_a_vision_i_just_ain_t_think",
	"On my Dragon Mama.": "xylo/on_my_dragon_mama",
	"On my Unborn dragon egg… I can see sounds. The sounds is purple.": "xylo/on_my_unborn_dragon_egg_i_can_see_sounds_the_sounds_is_purpl",
	"Prophecies be weird like that.": "xylo/prophecies_be_weird_like_that",
	"Rude.": "xylo/rude",
	"Stand back! He requires… lore.": "xylo/stand_back_he_requires_lore",
	"Sum don't feel right, folk.": "xylo/sum_don_t_feel_right_folk",
	"That was un-lore-like.": "xylo/that_was_un_lore_like",
	"The lore did not prepare me for this.": "xylo/the_lore_did_not_prepare_me_for_this",
	"The lore… has finally served its purpose.": "xylo/the_lore_has_finally_served_its_purpose",
	"There. I can feel it. The metocy is near.": "xylo/there_i_can_feel_it_the_metocy_is_near",
	"They… sell it?": "xylo/they_sell_it",
	"This was… not in the scripture…": "xylo/this_was_not_in_the_scripture",
	"Wait a second… sum don't feel right, folk.": "xylo/wait_a_second_sum_don_t_feel_right_folk",
	"We aren't leaving him here, are we?": "xylo/we_aren_t_leaving_him_here_are_we",
	# Dulbers Frint: Asar's recordings (2026-11-22), dialogue + combat taunts.
	"Hey guys, it's your boy Dulbers Frint!": "dulbers/hey_guys_its_your_boy",
	"Y'all could pull up before the Diddy Chud Giant smells you?": "dulbers/yall_could_pull_up_before_the_diddy_chud_giant",
	"Come on in, come on in! Store's open, folk!": "dulbers/come_on_in_come_on_in_stores_open_folk",
	"Heh… yeah, so that's actually midtocy. Off-brand. Similar vibes doe.": "dulbers/heh_yeah_so_that_s_actually_midtocy_off_brand_similar_vibes_",
	"…And now that you know…": "dulbers/and_now_that_you_know",
	"Finest metocy in Caelid. This shit'll have u geekin, folk. Hand-made. On some type shit.": "dulbers/finest_metocy_in_caelid_this_shit_ll_have_u_geekin_folk_hand",
	"For y'all ahh? First one's free.": "dulbers/for_yall_ahh_first_ones_free",
	"…Sum OFF? About ME? Your boy Dulbers?": "dulbers/sum_off_about_me_your_boy_dulbers",
	"Aight, y'all could get the fuck out my store doe? Fo' I call up Dulbmeethus.": "dulbers/aight_yall_get_the_fuck_out_my_store_doe",
	"*muffled, from inside* You'll regret this, trio…": "dulbers/youll_regret_this",
	"It's NOT moist—": "dulbers/its_not_moist",
	"Aight aight aight, keep your voice down! Let's make a deal.": "dulbers/aight_aight_keep_your_voice_down",
	"The real metocy is past the mountain pass. Past the giant. Here — take some midtocy on the house. Don't tell nobody.": "dulbers/the_real_metocy_is_past_the_mountain_pass_past_the_giant_her",
	"Pleasure doing business!": "dulbers/pleasure_doing_business",
	"…Uh oh.": "dulbers/uh_oh",
	"All sales final!": "dulbers/all_sales_final",
	"Thank you for shopping!": "dulbers/thank_you_for_shoping",
	"Let me try something on real quick…": "dulbers/let_me_try_something_on_real_quick",
	"hey guys its your boy dulbers frint": "dulbers/hey_guys_its_your_boy",
	# Goblins, Chief Bogdrinker, Big Thumbs, Wuzzle, Haggle: Asar's recordings (2026-11-22). These win over the studio goblin voices.
	"Three hundred spoons. Plus tip. We put it on the crown. The crown was on YOUR head.": "goblins_asar/300_tips_plus_tip",
	"FOREVER! FOREVER! FOREVER!": "goblins_asar/forever_forever_forever",
	"GET HIMMMM!": "goblins_asar/get_himmmm",
	"I NEED THIS JOB!": "goblins_asar/i_need_this_job",
	"THE MOGGING ELF!!": "goblins_asar/the_mogging_elf",
	"Welcome to Haggle's! Everything's for sale. No haggling. It's ironic.": "goblins_asar/welcome_to_haggle_s_everything_s_for_sale_no_haggling_it_s_i",
	"BIG THUMBS.": "goblins_asar/big_thumbs",
	"Bonk o'clock!": "goblins_asar/bonk_o_clock",
	"*sobbing* BYE!! YOU BETTER COME BACK ONE DAY!!": "goblins_asar/bye_you_better_come_back_one_day_instead_of_come_back_harder",
	"Oh. OH. It's the king. Your coronation party ran a tab, your majesty.": "goblins_asar/coronation_party_ran_a_tab",
	"East road! The patrol! My spoon misses me, I can feel it!": "goblins_asar/east_road_the_patrol",
	"FIELD TRIP! FIELD TRIP! FIELD TRIP!": "goblins_asar/field_trip_field_trip_field_tirp",
	"Here. I won this with my lucky spoon in a dice game. You keep it. It's weighted. Don't tell nobody.": "goblins_asar/here_i_won_this_with_my_lucky",
	"LEGEND! LEGEND! LEGEND!": "goblins_asar/legend_legend_legend",
	"LET'S GOOOOO!": "goblins_asar/lets_gooo",
	"Me and my spoon are going on a little vacation. Just us.": "goblins_asar/me_and_my_spoon_are_going_on_a_little_vacation",
	"Me? I got a liver of STEEL. Chug me. Right now. Winner gets two beezy. Loser gets… embarrassed.": "goblins_asar/me_i_got_a_liver_of_steel",
	"Me liver… it betrayed me… after all we've been through…": "goblins_asar/me_liver_it_betrayed_me",
	"MY SPOON! My beautiful lucky spoon! It's got patrol grease on it but I don't care!": "goblins_asar/my_spoon_my_beautiful_lucky_spoon",
	"No… my liver… it's never lost… it's crying…": "goblins_asar/no_my_liver_its_never_lost_its_crying",
	"OCCUPIED.": "goblins_asar/occupied",
	"Oh. OH. It's the ex-king. Your coronation party ran a tab before the purple one knocked you off the throne.": "goblins_asar/oh_its_the_ex_king",
	"Oh. OH. It's the OLD king. The purple king says your coronation party is on you.": "goblins_asar/oh_its_the_old_king",
	"On some field trip shiiiiii.": "goblins_asar/on_some_field_trip_shiii",
	"PURPLE KING! PURPLE KING!": "goblins_asar/purple_king_purple_kig",
	"Scared. I get it. Me liver scares me too.": "goblins_asar/scared_i_get_it_me_liver_scares_me_too",
	"So YOU'RE the elf who out-drank the Chief. Lemme tell you something. The Chief is washed.": "goblins_asar/so_you_are_the_elf_who_out_drank_the_chief_chief_is_washed",
	"So YOU'RE the elf who passed out chugging with the Chief. It's still on your forehead, bro. LOSER.": "goblins_asar/so_you_are_the_elf_who_passed_out_chugging",
	"Spoon time!": "goblins_asar/spoon_time",
	"STEEL. LIVER. Night night, pretty boy.": "goblins_asar/steel_liver_night_night_pretty_boy",
	"Take a number.": "goblins_asar/take_a_number",
	"The Goblin Patrol on the east road jacked it. Said it was a \"spoon tax.\" There's no spoon tax! I checked!": "goblins_asar/the_goblin_patrol_on_the_east_road",
	"WE WORSHIP THE PURPLE ONE NOW!": "goblins_asar/we_worship_the_purple_one_now",
	"*from inside* WE'RE NAPPING.": "goblins_asar/we_re_napping",
	"Welcome to the Unemployment Office & Bar. Fill out a form, have a drink. Or have a drink, forget the form.": "goblins_asar/welcome_to_the_unemployment",
	"You asked for it. BIG THUMBS!": "goblins_asar/you_asked_for_it_big_thumbs",
	"Y-you read my posting?! Finally! My lucky spoon got took!": "goblins_asar/you_read_my_posting_my_lucky_spoon_got_took",
	"I'm cancelling my gym membership. Shi did not work.": "goblins_asar/i_m_cancelling_my_gym_membership_shi_did_not_work",
	"No trouble in here. I do NOT get paid enough for trouble. I get paid zero.": "goblins_asar/no_trouble_in_here_i_do_not_get_paid_enough_for_trouble_i_ge",
	"…the tab is… paid… in full…": "goblins_asar/the_tab_is_paid_in_full",
	"…A purple king…": "goblins_asar/a_purple_king",
	"Aight, so if you could keep walking doe, over there, on some east shit. As far as I know, that's the best metocy a goblin like me could get his hands on.": "goblins_asar/aight_so_if_you_could_keep_walking_doe_over_there_on_some_ea",
	"An honor.": "goblins_asar/an_honor",
	"Bet dat.": "goblins_asar/bet_dat",
	"Bogdrinker handled it. Do not ask questions.": "goblins_asar/bogdrinker_handled_it_do_not_ask_questions",
	"Bogdrinker has heard of this place. Very legit.": "goblins_asar/bogdrinker_has_heard_of_this_place_very_legit",
	"…Cousin Chud?": "goblins_asar/cousin_chud",
	"East, Mogging Elf. On some east shit.": "goblins_asar/east_mogging_elf_on_some_east_shit",
	"For a thousand years we have waited for the Mogging Elf. Golden hair. Pointy ears. Smells like expensive conditioner.": "goblins_asar/for_a_thousand_years_we_have_waited_for_the_mogging_elf_gold",
	"For all yo metocy needs.": "goblins_asar/for_all_yo_metocy_needs",
	"Goblins: one. Demon: zero.": "goblins_asar/goblins_one_demon_zero",
	"Here go some beezy, folk. Take it for the road.": "goblins_asar/here_go_some_beezy_folk_take_it_for_the_road",
	"Hey! I'm royalty!": "goblins_asar/hey_i_m_royalty",
	"*gasp* Nobody has out-drunk Bogdrinker in 400 years.": "goblins_asar/nobody_has_out_drunk_bogdrinker_in_400_years",
	"Not on my watch!": "goblins_asar/not_on_my_watch",
	"Oh, we'll tell you… as long as you stay our king. FOREVER.": "goblins_asar/oh_we_ll_tell_you_as_long_as_you_stay_our_king_forever",
	"On my mama's side. Chud, MOVE. These my people.": "goblins_asar/on_my_mama_s_side_chud_move_these_my_people",
	"ROYAL BONK!": "goblins_asar/royal_bonk",
	"Somebody pour me one…": "goblins_asar/somebody_pour_me_one",
	"THIS AIN'T METOCY. THIS MIDTOCY. BOGDRINKER KNOWS HIS DRUGS.": "goblins_asar/this_ain_t_metocy_this_midtocy_bogdrinker_knows_his_drugs",
	"Tell the village… open bar…": "goblins_asar/tell_the_village_open_bar",
	"The Metocy Mart is east. Now leave, Mogging Elf. We have a new god.": "goblins_asar/the_metocy_mart_is_east_now_leave_mogging_elf_we_have_a_new_",
	"The Metocy Mart is east. Purple one, come back anytime. Elf… don't.": "goblins_asar/the_metocy_mart_is_east_purple_one_come_back_anytime_elf_don",
	"*hic* The Metocy Mart. East. Go before I cry.": "goblins_asar/the_metocy_mart_east_go_before_i_cry",
	"The Mogging Elf is… dethroned. Give the beezy to the purple one.": "goblins_asar/the_mogging_elf_is_dethroned_give_the_beezy_to_the_purple_on",
	"The Mogging Elf seeks the metocy? Then we will take him there OURSELVES. To the Metocy Mart!": "goblins_asar/the_mogging_elf_seeks_the_metocy_then_we_will_take_him_there",
	"*gasp* The Mogging Elf seeks the metocy… We know where it is.": "goblins_asar/the_mogging_elf_seeks_the_metocy_we_know_where_it_is",
	"…The Mogging Elf… out-drank… BOGDRINKER?": "goblins_asar/the_mogging_elf_out_drank_bogdrinker",
	"…The purple one hits so hard. So beautifully.": "goblins_asar/the_purple_one_hits_so_hard_so_beautifully",
	"The real metocy is past the giant. Field trip is over. Goblins — HOME.": "goblins_asar/the_real_metocy_is_past_the_giant_field_trip_is_over_goblins",
	"UNEMPLOYED, UNITE!": "goblins_asar/unemployed_unite",
	"We will tell the Mogging Elf… once he is crowned. Come. Your throne awaits.": "goblins_asar/we_will_tell_the_mogging_elf_once_he_is_crowned_come_your_th",
	"Your throne awaits, Mogging Elf. Sit. SIT.": "goblins_asar/your_throne_awaits_mogging_elf_sit_sit",
	"On some smelly shiiii!": "goblins_asar/on_some_smelly_shiiii_perfect_hit",
	"Ahhh. I saw you coming. In a vision. Also through the tent flap.": "goblins_asar/ahhh_i_saw_you_coming_in_a_vision_also_through_the_tent_flap",
	"Final prophecy! \"The Great Goblin in the sky HAS SPOKEN!\"": "goblins_asar/final_prophecy_the_great_goblin_in_the_sky_has_spoken",
	"Go away, lore dragon. I'm writing new prophecies. They're about how you cheated.": "goblins_asar/go_away_lore_dragon_i_m_writing_new_prophecies_they_re_about",
	"HA! The spirits laugh at you, dragon! Come back when your lore has lore.": "goblins_asar/ha_the_spirits_laugh_at_you_dragon_come_back_when_your_lore_",
	"Here. Now. A LORE-OFF. Answer three prophecies. Beat me, and I give you something… signed.": "goblins_asar/here_now_a_lore_off_answer_three_prophecies_beat_me_and_i_gi",
	"I knew you'd say that.": "goblins_asar/i_knew_you_d_say_that",
	"No… NO… the spirits… they're clapping for HIM…": "goblins_asar/no_no_the_spirits_they_re_clapping_for_him",
	"Prophecy one! The Scroll of Glorb says: \"The spoon shall rise!\"": "goblins_asar/prophecy_one_the_scroll_of_glorb_says_the_spoon_shall_rise",
	"Prophecy two! \"A golden-haired elf shall come… and mog the land!\"": "goblins_asar/prophecy_two_a_golden_haired_elf_shall_come_and_mog_the_land",
	"Take it. Deloye Lore, Volume 9. Signed. I don't know who signed it. It was like that when I stole it.": "goblins_asar/take_it_deloye_lore_volume_9_signed_i_don_t_know_who_signed_",
	"The dragon. You carry the book of… Deloye, yes? Bah. Goblin prophecy is ten times the lore.": "goblins_asar/the_dragon_you_carry_the_book_of_deloye_yes_bah_goblin_proph",
	"The spirits are listening. Mostly. One of them is on break.": "goblins_asar/the_spirits_are_listening_mostly_one_of_them_is_on_break",
}

static var _index: Dictionary = {}

static func key(line: String) -> String:
	var re := RegEx.create_from_string("[^a-z0-9]")
	return re.sub(line.to_lower(), "", true)

# Returns the AudioStream for this line, or null if it has no recording.
static func stream_for(line: String) -> AudioStream:
	if _index.is_empty():
		for k in VoiceIndex.LINES:
			_index[k] = DIR + VoiceIndex.LINES[k]
		for l in LINES:   # hand-added lines win
			var f: String = LINES[l]
			_index[key(l)] = DIR + (f if f.get_extension() != "" else f + ".mp3")
	var p: String = _index.get(key(line), "")
	if p == "" or not ResourceLoader.exists(p):
		return null
	return load(p)

# A page's plain text (BBCode tags out), so a book page finds its voice file (the key ignores punctuation, not tags).
static func plain(t: String) -> String:
	return RegEx.create_from_string("\\[/?[a-z]+[^\\]]*\\]").sub(t, "", true)

# The narrator reads a page aloud (Deloye library books, the Pass Lore Session; Ebain 11/25). Returns the player, or
# null if the page has no recording. The player frees itself when done; call stop_reading() to cut it off.
static func read_aloud(parent: Node, text: String) -> AudioStreamPlayer:
	var s := stream_for(plain(text))
	if s == null or Game.voice_vol <= 0.01:
		return null
	var p := AudioStreamPlayer.new()
	p.stream = s
	p.volume_db = linear_to_db(Game.voice_vol)
	parent.add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
	return p

static func stop_reading(p: AudioStreamPlayer) -> void:
	if p != null and is_instance_valid(p):
		p.queue_free()
