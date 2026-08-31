class_name TrialGate
extends StaticBody3D
## The sealed gate east of camp. Interacting stows ordinary goods (the sim's
## TrialSession deposits them) and starts a run; the TrialController owns
## everything after that.


func interact(player: WroughtwildPlayer) -> void:
	if player.trial.active():
		player.trial.reopen()
		return
	if not player.trial.begin_run():
		player.hud.notify("The gate does not open.")
