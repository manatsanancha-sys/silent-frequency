extends CollectibleItem

func on_collect():
	Inventory.update_power_cells.emit()
	
static func use_item():
	Inventory.player.get_flashlight().try_to_recharge()
