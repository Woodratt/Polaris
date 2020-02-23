// The lighting system
//
// consists of light fixtures (/obj/machinery/light) and light tube/bulb items (/obj/item/weapon/light)


// status values shared between lighting fixtures and items
#define LIGHT_OK 0
#define LIGHT_EMPTY 1
#define LIGHT_BROKEN 2
#define LIGHT_BURNED 3
#define LIGHT_BULB_TEMPERATURE 400 //K - used value for a 60W bulb
#define LIGHTING_POWER_FACTOR 5		//5W per luminosity * range
#define LIGHT_EMERGENCY_POWER_USE 0.2 //How much power emergency lights will consume per tick

var/global/list/light_type_cache = list()
/proc/get_light_type_instance(var/light_type)
	. = light_type_cache[light_type]
	if(!.)
		. = new light_type
		light_type_cache[light_type] = .

/obj/machinery/light_construct
	name = "light fixture frame"
	desc = "A light fixture under construction."
	icon = 'icons/obj/lighting.dmi'
	icon_state = "tube-construct-stage1"
	anchored = 1
	plane = MOB_PLANE
	layer = ABOVE_MOB_LAYER
	var/stage = 1
	var/fixture_type = /obj/machinery/light
	var/sheets_refunded = 2
	var/obj/machinery/light/newlight = null
	var/obj/item/weapon/cell/cell = null

	var/cell_connectors = TRUE

/obj/machinery/light_construct/New(var/atom/newloc, var/newdir, var/building = 0, var/datum/frame/frame_types/frame_type, var/obj/machinery/light/fixture = null)
	..(newloc)
	if(fixture)
		fixture_type = fixture.type
		fixture.transfer_fingerprints_to(src)
		set_dir(fixture.dir)
		stage = 2
	else if(newdir)
		set_dir(newdir)
	update_icon()

/obj/machinery/light_construct/update_icon()
	switch(stage)
		if(1)
			icon_state = "tube-construct-stage1"
		if(2)
			icon_state = "tube-construct-stage2"
		if(3)
			icon_state = "tube-empty"

/obj/machinery/light_construct/examine(mob/user)
	if(!..(user, 2))
		return

	switch(src.stage)
		if(1)
			to_chat(user, "It's an empty frame.")
		if(2)
			to_chat(user, "It's wired.")
		if(3)
			to_chat(user, "The casing is closed.")
	if(cell_connectors)
		if(cell)
			to_chat(user, "You see [cell] inside the casing.")
		else
			to_chat(user, "The casing has no power cell for backup power.")
	else
		to_chat(user, "<span class='danger'>This casing doesn't support power cells for backup power.</span>")

/obj/machinery/light_construct/attack_hand(mob/user)
	if(cell)
		user.visible_message("[user] removes [cell] from [src]!","<span class='notice'>You remove [cell].</span>")
		user.put_in_hands(cell)
		cell.update_icon()
		cell = null
		add_fingerprint(user)

/obj/machinery/light_construct/attackby(obj/item/weapon/W as obj, mob/user as mob)
	src.add_fingerprint(user)
	if(istype(W, /obj/item/weapon/cell/emergency_light))
		if(!cell_connectors)
			to_chat(user, "<span class='warning'>This [name] can't support a power cell!</span>")
			return
		if(!user.unEquip(W))
			to_chat(user, "<span class='warning'>[W] is stuck to your hand!</span>")
			return
		if(cell)
			to_chat(user, "<span class='warning'>There is a power cell already installed!</span>")
		else if(user.drop_from_inventory(W))
			user.visible_message("<span class='notice'>[user] hooks up [W] to [src].</span>", \
			"<span class='notice'>You add [W] to [src].</span>")
			playsound(src, 'sound/machines/click.ogg', 50, TRUE)
			W.forceMove(src)
			cell = W
			add_fingerprint(user)
		return

	if (W.is_wrench())
		if (src.stage == 1)
			playsound(src, W.usesound, 75, 1)
			to_chat(usr, "You begin deconstructing [src].")
			if (!do_after(usr, 30 * W.toolspeed))
				return
			new /obj/item/stack/material/steel( get_turf(src.loc), sheets_refunded )
			user.visible_message("[user.name] deconstructs [src].", \
				"You deconstruct [src].", "You hear a noise.")
			playsound(src.loc, 'sound/items/Deconstruct.ogg', 75, 1)
			qdel(src)
		if (src.stage == 2)
			to_chat(usr, "You have to remove the wires first.")
			return

		if (src.stage == 3)
			to_chat(usr, "You have to unscrew the case first.")
			return

	if(W.is_wirecutter())
		if (src.stage != 2) return
		src.stage = 1
		src.update_icon()
		new /obj/item/stack/cable_coil(get_turf(src.loc), 1, "red")
		user.visible_message("[user.name] removes the wiring from [src].", \
			"You remove the wiring from [src].", "You hear a noise.")
		playsound(src.loc, W.usesound, 50, 1)
		return

	if(istype(W, /obj/item/stack/cable_coil))
		if (src.stage != 1) return
		var/obj/item/stack/cable_coil/coil = W
		if (coil.use(1))
			src.stage = 2
			src.update_icon()
			user.visible_message("[user.name] adds wires to [src].", \
				"You add wires to [src].")
		return

	if(W.is_screwdriver())
		if (src.stage == 2)
			src.stage = 3
			src.update_icon()
			user.visible_message("[user.name] closes [src]'s casing.", \
				"You close [src]'s casing.", "You hear a noise.")
			playsound(src, W.usesound, 75, 1)

			var/obj/machinery/light/newlight = new fixture_type(src.loc, src)
			newlight.set_dir(src.dir)
			src.transfer_fingerprints_to(newlight)
			if(cell)
				newlight.cell = cell
				cell.forceMove(newlight)
				cell = null
			qdel(src)
			return
	..()

/obj/machinery/light_construct/small
	name = "small light fixture frame"
	desc = "A small light fixture under construction."
	icon = 'icons/obj/lighting.dmi'
	icon_state = "bulb-construct-stage1"
	anchored = 1
	stage = 1
	fixture_type = /obj/machinery/light/small
	sheets_refunded = 1

/obj/machinery/light_construct/small/update_icon()
	switch(stage)
		if(1)
			icon_state = "bulb-construct-stage1"
		if(2)
			icon_state = "bulb-construct-stage2"
		if(3)
			icon_state = "bulb-empty"

/obj/machinery/light_construct/flamp
	name = "floor light fixture frame"
	desc = "A floor light fixture under construction."
	icon = 'icons/obj/lighting.dmi'
	icon_state = "flamp-construct-stage1"
	anchored = 0
	plane = OBJ_PLANE
	layer = OBJ_LAYER
	stage = 1
	fixture_type = /obj/machinery/light/flamp
	sheets_refunded = 2

/obj/machinery/light_construct/flamp/update_icon()
	switch(stage)
		if(1)
			icon_state = "flamp-construct-stage1"
		if(2)
			icon_state = "flamp-construct-stage2"
		if(3)
			icon_state = "flamp-empty"

// the standard tube light fixture
/obj/machinery/light
	name = "light fixture"
	icon = 'icons/obj/lighting.dmi'
	var/base_state = "tube"		// base description and icon_state
	icon_state = "tube1"
	desc = "A lighting fixture."
	anchored = 1
	plane = MOB_PLANE
	layer = ABOVE_MOB_LAYER
	use_power = 2
	idle_power_usage = 2
	active_power_usage = 10		// Previously 20.
	power_channel = LIGHT //Lights are calc'd via area so they dont need to be in the machine list
	var/on = 0					// 1 if on, 0 if off
	var/brightness_range
	var/brightness_power
	var/brightness_color
	var/status = LIGHT_OK		// LIGHT_OK, _EMPTY, _BURNED or _BROKEN
	var/flickering = 0
	var/light_type = /obj/item/weapon/light/tube		// the type of light item
	var/construct_type = /obj/machinery/light_construct
	var/switchcount = 0			// count of number of times switched on/off
								// this is used to calc the probability the light burns out

	var/rigged = 0				// true if rigged to explode

	var/auto_flicker = FALSE // If true, will constantly flicker, so long as someone is around to see it (otherwise its a waste of CPU).

	var/obj/item/weapon/cell/emergency_light/cell
	var/start_with_cell = TRUE	// if true, this fixture generates a very weak cell at roundstart

	var/emergency_mode = FALSE	// if true, the light is in emergency mode
	var/no_emergency = FALSE	// if true, this light cannot ever have an emergency mode
	var/bulb_emergency_brightness_mul = 0.25	// multiplier for this light's base brightness in emergency power mode
	var/bulb_emergency_colour = "#FF3232"	// determines the colour of the light while it's in emergency mode
	var/bulb_emergency_pow_mul = 0.75	// the multiplier for determining the light's power in emergency mode
	var/bulb_emergency_pow_min = 0.5	// the minimum value for the light's power in emergency mode

/obj/machinery/light/flicker
	auto_flicker = TRUE

// the smaller bulb light fixture

/obj/machinery/light/small
	icon_state = "bulb1"
	base_state = "bulb"
	desc = "A small lighting fixture."
	light_type = /obj/item/weapon/light/bulb
	construct_type = /obj/machinery/light_construct/small

/obj/machinery/light/small/flicker
	auto_flicker = TRUE

/obj/machinery/light/poi
	start_with_cell = FALSE

/obj/machinery/light/small/poi
	start_with_cell = FALSE

/obj/machinery/light/flamp
	icon_state = "flamp1"
	base_state = "flamp"
	plane = OBJ_PLANE
	layer = OBJ_LAYER
	desc = "A floor lamp."
	light_type = /obj/item/weapon/light/bulb
	construct_type = /obj/machinery/light_construct/flamp
	var/lamp_shade = 1

/obj/machinery/light/flamp/New(atom/newloc, obj/machinery/light_construct/construct = null)
	..(newloc, construct)
	if(construct)
		start_with_cell = FALSE
		lamp_shade = 0
		update_icon()
	else	
		if(start_with_cell && !no_emergency)
			cell = new/obj/item/weapon/cell/emergency_light(src)
	

/obj/machinery/light/flamp/flicker
	auto_flicker = TRUE


/obj/machinery/light/small/emergency
	light_type = /obj/item/weapon/light/bulb/red

/obj/machinery/light/small/emergency/flicker
	auto_flicker = TRUE


/obj/machinery/light/spot
	name = "spotlight"
	light_type = /obj/item/weapon/light/tube/large

/obj/machinery/light/spot/flicker
	auto_flicker = TRUE

// create a new lighting fixture
/obj/machinery/light/New(atom/newloc, obj/machinery/light_construct/construct = null)
	..(newloc)

	if(construct)
		start_with_cell = FALSE
		status = LIGHT_EMPTY
		construct_type = construct.type
		construct.transfer_fingerprints_to(src)
		set_dir(construct.dir)
	else
		if(start_with_cell && !no_emergency)
			cell = new/obj/item/weapon/cell/emergency_light(src)
		var/obj/item/weapon/light/L = get_light_type_instance(light_type)
		update_from_bulb(L)
		if(prob(L.broken_chance))
			broken(1)

	on = powered()
	update(0)

/obj/machinery/light/Destroy()
	var/area/A = get_area(src)
	if(A)
		on = 0
//		A.update_lights()
	QDEL_NULL(cell)
	return ..()

/obj/machinery/light/update_icon()

	switch(status)		// set icon_states
		if(LIGHT_OK)
			icon_state = "[base_state][on]"
		if(LIGHT_EMPTY)
			icon_state = "[base_state]-empty"
			on = 0
		if(LIGHT_BURNED)
			icon_state = "[base_state]-burned"
			on = 0
		if(LIGHT_BROKEN)
			icon_state = "[base_state]-broken"
			on = 0
	return

/obj/machinery/light/flamp/update_icon()
	if(lamp_shade)
		base_state = "flampshade"
		switch(status)		// set icon_states
			if(LIGHT_OK)
				icon_state = "[base_state][on]"
			if(LIGHT_EMPTY)
				on = 0
				icon_state = "[base_state][on]"
			if(LIGHT_BURNED)
				on = 0
				icon_state = "[base_state][on]"
			if(LIGHT_BROKEN)
				on = 0
				icon_state = "[base_state][on]"
		return
	else
		base_state = "flamp"
		..()


// update lighting
/obj/machinery/light/proc/update(var/trigger = 1)
	update_icon()
	if(on)
		if(light_range != brightness_range || light_power != brightness_power || light_color != brightness_color)
			if(!auto_flicker)
				switchcount++
			if(rigged)
				if(status == LIGHT_OK && trigger)

					log_admin("LOG: Rigged light explosion, last touched by [fingerprintslast]")
					message_admins("LOG: Rigged light explosion, last touched by [fingerprintslast]")

					explode()
			else if( prob( min(60, switchcount*switchcount*0.01) ) )
				if(status == LIGHT_OK && trigger)
					status = LIGHT_BURNED
					update_icon()
					on = 0
					set_light(0)
			else
				use_power = 2
				set_light(brightness_range, brightness_power, brightness_color)
	else if(has_emergency_power(LIGHT_EMERGENCY_POWER_USE) && !turned_off())
		use_power = 1
		emergency_mode = TRUE
		START_PROCESSING(SSobj, src)
	else
		use_power = 1
		set_light(0)

	active_power_usage = ((light_range * light_power) * LIGHTING_POWER_FACTOR)


/obj/machinery/light/attack_generic(var/mob/user, var/damage)
	if(!damage)
		return
	if(status == LIGHT_EMPTY||status == LIGHT_BROKEN)
		to_chat(user, "That object is useless to you.")
		return
	if(!(status == LIGHT_OK||status == LIGHT_BURNED))
		return
	visible_message("<span class='danger'>[user] smashes the light!</span>")
	user.do_attack_animation(src)
	broken()
	return 1

/obj/machinery/light/take_damage(var/damage)
	if(!damage)
		return
	if(status == LIGHT_EMPTY||status == LIGHT_BROKEN)
		return
	if(!(status == LIGHT_OK||status == LIGHT_BURNED))
		return
	broken()
	return 1

/obj/machinery/light/blob_act()
	broken()

// attempt to set the light's on/off status
// will not switch on if broken/burned/empty
/obj/machinery/light/proc/seton(var/s)
	on = (s && status == LIGHT_OK)
	update()

/obj/machinery/light/get_cell()
	return cell

// examine verb
/obj/machinery/light/examine(mob/user)
	var/fitting = get_fitting_name()
	switch(status)
		if(LIGHT_OK)
			to_chat(user, "[desc] It is turned [on? "on" : "off"].")
		if(LIGHT_EMPTY)
			to_chat(user, "[desc] The [fitting] has been removed.")
		if(LIGHT_BURNED)
			to_chat(user, "[desc] The [fitting] is burnt out.")
		if(LIGHT_BROKEN)
			to_chat(user, "[desc] The [fitting] has been smashed.")
	if(cell)
		to_chat(user, "Its backup power charge meter reads [round((cell.charge / cell.maxcharge) * 100, 0.1)]%.")

/obj/machinery/light/proc/get_fitting_name()
	var/obj/item/weapon/light/L = light_type
	return initial(L.name)

/obj/machinery/light/proc/update_from_bulb(obj/item/weapon/light/L)
	status = L.status
	switchcount = L.switchcount
	rigged = L.rigged
	brightness_range = L.brightness_range
	brightness_power = L.brightness_power
	brightness_color = L.brightness_color

// attack with item - insert light (if right type), otherwise try to break the light

/obj/machinery/light/proc/insert_bulb(obj/item/weapon/light/L)
	update_from_bulb(L)
	qdel(L)

	on = powered()
	update()

	if(on && rigged)

		log_admin("LOG: Rigged light explosion, last touched by [fingerprintslast]")
		message_admins("LOG: Rigged light explosion, last touched by [fingerprintslast]")

		explode()

/obj/machinery/light/proc/remove_bulb()
	. = new light_type(src.loc, src)

	switchcount = 0
	status = LIGHT_EMPTY
	update()

/obj/machinery/light/attackby(obj/item/W, mob/user)

	//Light replacer code
	if(istype(W, /obj/item/device/lightreplacer))
		var/obj/item/device/lightreplacer/LR = W
		if(isliving(user))
			var/mob/living/U = user
			LR.ReplaceLight(src, U)
			return

	// attempt to insert light
	if(istype(W, /obj/item/weapon/light))
		if(status != LIGHT_EMPTY)
			to_chat(user, "There is a [get_fitting_name()] already inserted.")
			return
		if(!istype(W, light_type))
			to_chat(user, "This type of light requires a [get_fitting_name()].")
			return

		to_chat(user, "You insert [W].")
		insert_bulb(W)
		src.add_fingerprint(user)

		// attempt to break the light
		//If xenos decide they want to smash a light bulb with a toolbox, who am I to stop them? /N

	else if(status != LIGHT_BROKEN && status != LIGHT_EMPTY)


		if(prob(1+W.force * 5))

			to_chat(user, "You hit the light, and it smashes!")
			for(var/mob/M in viewers(src))
				if(M == user)
					continue
				M.show_message("[user.name] smashed the light!", 3, "You hear a tinkle of breaking glass", 2)
			if(on && !(W.flags & NOCONDUCT))
				//if(!user.mutations & COLD_RESISTANCE)
				if (prob(12))
					electrocute_mob(user, get_area(src), src, 0.3)
			broken()

		else
			to_chat(user, "You hit the light!")

	// attempt to stick weapon into light socket
	else if(status == LIGHT_EMPTY)
		if(W.is_screwdriver()) //If it's a screwdriver open it.
			playsound(src, W.usesound, 75, 1)
			user.visible_message("[user.name] opens [src]'s casing.", \
				"You open [src]'s casing.", "You hear a noise.")
			new construct_type(src.loc, fixture = src)
			qdel(src)
			return

		to_chat(user, "You stick \the [W] into the light socket!")
		if(has_power() && !(W.flags & NOCONDUCT))
			var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
			s.set_up(3, 1, src)
			s.start()
			//if(!user.mutations & COLD_RESISTANCE)
			if (prob(75))
				electrocute_mob(user, get_area(src), src, rand(0.7,1.0))

/obj/machinery/light/flamp/attackby(obj/item/W, mob/user)
	if(W.is_wrench())
		anchored = !anchored
		playsound(src, W.usesound, 50, 1)
		to_chat(user, "<span class='notice'>You [anchored ? "wrench" : "unwrench"] \the [src].</span>")

	if(!lamp_shade)
		if(istype(W, /obj/item/weapon/lampshade))
			lamp_shade = 1
			qdel(W)
			update_icon()
			return

	else
		if(W.is_screwdriver())
			playsound(src, W.usesound, 75, 1)
			user.visible_message("[user.name] removes [src]'s lamp shade.", \
				"You remove [src]'s lamp shade.", "You hear a noise.")
			lamp_shade = 0
			new /obj/item/weapon/lampshade(src.loc)
			update_icon()
			return

	..()

// returns if the light has power /but/ is manually turned off
// if a light is turned off, it won't activate emergency power
/obj/machinery/light/proc/turned_off()
	var/area/A = get_area(src)
	return !A.lightswitch && A.power_light || flickering

// returns whether this light has power
// true if area has power and lightswitch is on
/obj/machinery/light/proc/has_power()
	var/area/A = get_area(src)
	return A && A.lightswitch && (!A.requires_power || A.power_light)

/obj/machinery/light/flamp/has_power()
	var/area/A = get_area(src)
	if(lamp_shade)
		return A && (!A.requires_power || A.power_light)
	else
		return A && A.lightswitch && (!A.requires_power || A.power_light)

// returns whether this light has emergency power
// can also return if it has access to a certain amount of that power
/obj/machinery/light/proc/has_emergency_power(pwr)
	if(no_emergency || !cell)
		return FALSE
	if(pwr ? cell.charge >= pwr : cell.charge)
		return status == LIGHT_OK

// attempts to use power from the installed emergency cell, returns true if it does and false if it doesn't
/obj/machinery/light/proc/use_emergency_power(pwr = LIGHT_EMERGENCY_POWER_USE)
	if(turned_off())
		return FALSE
	if(!has_emergency_power(pwr))
		return FALSE
	if(cell.charge > 300) //it's meant to handle 120 W, ya doofus
		visible_message("<span class='warning'>[src] short-circuits from too powerful of a power cell!</span>")
		status = LIGHT_BURNED
		return FALSE
	cell.use(pwr)
	set_light(brightness_range * bulb_emergency_brightness_mul, max(bulb_emergency_pow_min, bulb_emergency_pow_mul * (cell.charge / cell.maxcharge)), bulb_emergency_colour)
	return TRUE

/obj/machinery/light/proc/flicker(var/amount = rand(10, 20))
	if(flickering) return
	flickering = 1
	spawn(0)
		if(on && status == LIGHT_OK)
			for(var/i = 0; i < amount; i++)
				if(status != LIGHT_OK) break
				on = !on
				update(0)
				sleep(rand(5, 15))
			on = (status == LIGHT_OK)
			update(0)
		flickering = 0

// ai attack - turn on/off emergency lighting for a specific fixture

/obj/machinery/light/attack_ai(mob/user)
	no_emergency = !no_emergency
	to_chat(user, "<span class='notice'>Emergency lights for this fixture have been [no_emergency ? "disabled" : "enabled"].</span>")
	update(FALSE)
	return

/obj/machinery/light/flamp/attack_ai(mob/user)
	attack_hand()
	return

// attack with hand - remove tube/bulb
// if hands aren't protected and the light is on, burn the player
/obj/machinery/light/attack_hand(mob/user)

	add_fingerprint(user)

	if(status == LIGHT_EMPTY)
		to_chat(user, "There is no [get_fitting_name()] in this light.")
		return

	if(istype(user,/mob/living/carbon/human))
		var/mob/living/carbon/human/H = user
		if(H.species.can_shred(H))
			user.setClickCooldown(user.get_attack_speed())
			for(var/mob/M in viewers(src))
				M.show_message("<font color='red'>[user.name] smashed the light!</font>", 3, "You hear a tinkle of breaking glass", 2)
			broken()
			return

	// make it burn hands if not wearing fire-insulated gloves
	if(on)
		var/prot = 0
		var/mob/living/carbon/human/H = user

		if(istype(H))
			if(H.species.heat_level_1 > LIGHT_BULB_TEMPERATURE)
				prot = 1
			else if(H.gloves)
				var/obj/item/clothing/gloves/G = H.gloves
				if(G.max_heat_protection_temperature)
					if(G.max_heat_protection_temperature > LIGHT_BULB_TEMPERATURE)
						prot = 1
		else
			prot = 1

		if(prot > 0 || (COLD_RESISTANCE in user.mutations))
			to_chat(user, "You remove the light [get_fitting_name()]")
		else if(TK in user.mutations)
			to_chat(user, "You telekinetically remove the light [get_fitting_name()].")
		else
			to_chat(user, "You try to remove the light [get_fitting_name()], but it's too hot and you don't want to burn your hand.")
			return				// if burned, don't remove the light
	else
		to_chat(user, "You remove the light [get_fitting_name()].")

	// create a light tube/bulb item and put it in the user's hand
	user.put_in_active_hand(remove_bulb())	//puts it in our active hand

/obj/machinery/light/flamp/attack_hand(mob/user)
	if(lamp_shade)
		if(status == LIGHT_EMPTY)
			to_chat(user, "There is no [get_fitting_name()] in this light.")
			return

		if(on)
			on = 0
			update()
		else
			on = has_power()
			update()
	else
		..()


/obj/machinery/light/attack_tk(mob/user)
	if(status == LIGHT_EMPTY)
		to_chat(user, "There is no [get_fitting_name()] in this light.")
		return

	to_chat(user, "You telekinetically remove the light [get_fitting_name()].")
	remove_bulb()

// break the light and make sparks if was on

/obj/machinery/light/proc/broken(var/skip_sound_and_sparks = 0)
	if(status == LIGHT_EMPTY)
		return

	if(!skip_sound_and_sparks)
		if(status == LIGHT_OK || status == LIGHT_BURNED)
			playsound(src.loc, 'sound/effects/Glasshit.ogg', 75, 1)
		if(on)
			var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
			s.set_up(3, 1, src)
			s.start()
	status = LIGHT_BROKEN
	update()

/obj/machinery/light/proc/fix()
	if(status == LIGHT_OK)
		return
	status = LIGHT_OK
	on = 1
	update()

// explosion effect
// destroy the whole light fixture or just shatter it

/obj/machinery/light/ex_act(severity)
	switch(severity)
		if(1.0)
			qdel(src)
			return
		if(2.0)
			if (prob(75))
				broken()
		if(3.0)
			if (prob(50))
				broken()
	return

//blob effect


// timed process
// use power

/obj/machinery/light/process()
	if(!cell)
		return PROCESS_KILL
	if(has_power())
		emergency_mode = FALSE
		update(FALSE)
		if(cell.charge == cell.maxcharge)
			return PROCESS_KILL
		cell.charge = min(cell.maxcharge, cell.charge + LIGHT_EMERGENCY_POWER_USE*2) //Recharge emergency power automatically while not using it
	if(emergency_mode && !use_emergency_power(LIGHT_EMERGENCY_POWER_USE))
		update(FALSE) //Disables emergency mode and sets the color to normal

	if(auto_flicker && !flickering)
		if(check_for_player_proximity(src, radius = 12, ignore_ghosts = FALSE, ignore_afk = TRUE))
			seton(TRUE) // Lights must be on to flicker.
			flicker(5)
		else
			seton(FALSE) // Otherwise keep it dark and spooky for when someone shows up.

// called when area power state changes
/obj/machinery/light/power_change()
	spawn(10)
		seton(has_power())

// called when on fire

/obj/machinery/light/fire_act(datum/gas_mixture/air, exposed_temperature, exposed_volume)
	if(prob(max(0, exposed_temperature - 673)))   //0% at <400C, 100% at >500C
		broken()

// explode the light

/obj/machinery/light/proc/explode()
	var/turf/T = get_turf(src.loc)
	spawn(0)
		broken()	// break it first to give a warning
		sleep(2)
		explosion(T, 0, 0, 2, 2)
		sleep(1)
		qdel(src)

// the light item
// can be tube or bulb subtypes
// will fit into empty /obj/machinery/light of the corresponding type

/obj/item/weapon/light
	icon = 'icons/obj/lighting.dmi'
	force = 2
	throwforce = 5
	w_class = ITEMSIZE_TINY
	var/status = 0		// LIGHT_OK, LIGHT_BURNED or LIGHT_BROKEN
	var/base_state
	var/switchcount = 0	// number of times switched
	matter = list(DEFAULT_WALL_MATERIAL = 60)
	var/rigged = 0		// true if rigged to explode
	var/broken_chance = 2

	var/brightness_range = 2 //how much light it gives off
	var/brightness_power = 1
	var/brightness_color = LIGHT_COLOR_INCANDESCENT_TUBE

/obj/item/weapon/light/tube
	name = "light tube"
	desc = "A replacement light tube."
	icon_state = "ltube"
	base_state = "ltube"
	item_state = "c_tube"
	matter = list("glass" = 100)
	brightness_range = 7	// luminosity when on, also used in power calculation
	brightness_power = 6

/obj/item/weapon/light/tube/large
	w_class = ITEMSIZE_SMALL
	name = "large light tube"
	brightness_range = 15
	brightness_power = 9

/obj/item/weapon/light/bulb
	name = "light bulb"
	desc = "A replacement light bulb."
	icon_state = "lbulb"
	base_state = "lbulb"
	item_state = "contvapour"
	matter = list("glass" = 100)
	brightness_range = 5
	brightness_power = 4
	brightness_color = LIGHT_COLOR_INCANDESCENT_BULB

/obj/item/weapon/light/throw_impact(atom/hit_atom)
	..()
	shatter()

/obj/item/weapon/light/bulb/red
	brightness_range = 4
	color = "#da0205"
	brightness_color = "#da0205"

/obj/item/weapon/light/bulb/fire
	name = "fire bulb"
	desc = "A replacement fire bulb."
	icon_state = "fbulb"
	base_state = "fbulb"
	item_state = "egg4"
	matter = list("glass" = 100)

// update the icon state and description of the light
/obj/item/weapon/light/update_icon()
	switch(status)
		if(LIGHT_OK)
			icon_state = base_state
			desc = "A replacement [name]."
		if(LIGHT_BURNED)
			icon_state = "[base_state]-burned"
			desc = "A burnt-out [name]."
		if(LIGHT_BROKEN)
			icon_state = "[base_state]-broken"
			desc = "A broken [name]."


/obj/item/weapon/light/New(atom/newloc, obj/machinery/light/fixture = null)
	..()
	if(fixture)
		status = fixture.status
		rigged = fixture.rigged
		switchcount = fixture.switchcount
		fixture.transfer_fingerprints_to(src)

		//shouldn't be necessary to copy these unless someone varedits stuff, but just in case
		brightness_range = fixture.brightness_range
		brightness_power = fixture.brightness_power
		brightness_color = fixture.brightness_color
	update_icon()


// attack bulb/tube with object
// if a syringe, can inject phoron to make it explode
/obj/item/weapon/light/attackby(var/obj/item/I, var/mob/user)
	..()
	if(istype(I, /obj/item/weapon/reagent_containers/syringe))
		var/obj/item/weapon/reagent_containers/syringe/S = I

		to_chat(user, "You inject the solution into the [src].")

		if(S.reagents.has_reagent("phoron", 5))

			log_admin("LOG: [user.name] ([user.ckey]) injected a light with phoron, rigging it to explode.")
			message_admins("LOG: [user.name] ([user.ckey]) injected a light with phoron, rigging it to explode.")

			rigged = 1

		S.reagents.clear_reagents()
	else
		..()
	return

// called after an attack with a light item
// shatter light, unless it was an attempt to put it in a light socket
// now only shatter if the intent was harm

/obj/item/weapon/light/afterattack(atom/target, mob/user, proximity)
	if(!proximity) return
	if(istype(target, /obj/machinery/light))
		return
	if(user.a_intent != I_HURT)
		return

	shatter()

/obj/item/weapon/light/proc/shatter()
	if(status == LIGHT_OK || status == LIGHT_BURNED)
		src.visible_message("<font color='red'>[name] shatters.</font>","<font color='red'> You hear a small glass object shatter.</font>")
		status = LIGHT_BROKEN
		force = 5
		sharp = 1
		playsound(src.loc, 'sound/effects/Glasshit.ogg', 75, 1)
		update_icon()

//Lamp Shade
/obj/item/weapon/lampshade
	name = "lamp shade"
	desc = "A lamp shade for a lamp."
	icon = 'icons/obj/lighting.dmi'
	icon_state = "lampshade"
	w_class = ITEMSIZE_TINY
