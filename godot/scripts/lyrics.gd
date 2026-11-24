# Song lyrics for the Library (library_ui.gd). Key = the song id in LibraryUI.SONGS.
# Ebain sends these: paste them in as-is between the triple quotes (# Ebain, never reworded).
# A song with no entry (or "") shows "Lyrics coming soon" on its page.
class_name Lyrics
extends RefCounted

const TEXT := {
	"prophecy_of_metocy": "",
	"the_mogging_elf": "",
	"the_hymn_of_metocin_mattias": "",
}
