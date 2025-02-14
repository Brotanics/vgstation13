//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:31

/obj/machinery/computer/prisoner
	name = "Prisoner Management"
	icon = 'icons/obj/computer.dmi'
	icon_state = "explosive"
	req_access = list(access_armory)
	circuit = "/obj/item/weapon/circuitboard/prisoner"
	var/id = 0.0
	var/temp = null
	var/status = 0
	var/timeleft = 60
	var/stop = 0.0
	var/screen = 0 // 0 - No Access Denied, 1 - Access allowed

	light_color = LIGHT_COLOR_RED

/obj/machinery/computer/prisoner/attack_ai(var/mob/user as mob)
	src.add_hiddenprint(user)
	return src.attack_hand(user)

/obj/machinery/computer/prisoner/attack_paw(var/mob/user as mob)
	return

/obj/machinery/computer/prisoner/attack_hand(var/mob/user as mob)
	if(..())
		return
	user.set_machine(src)
	var/dat = list()
	if(screen == 0)
		dat += "<A href='?src=\ref[src];lock=1'>Unlock Console</A>"
	else if(screen == 1)
		dat += "Chemical Implants<BR>"
		var/turf/Tr = null
		for(var/obj/item/weapon/implant/chem/C in chemical_implants)
			Tr = get_turf(C)
			if((Tr) && (Tr.z != src.z))
				continue//Out of range
			if(!C.imp_in)
				continue

			dat += {"[C.imp_in.name] | Remaining Units: [C.reagents.total_volume] | Inject:
				<A href='?src=\ref[src];inject1=\ref[C]'>(<font color=red>(1)</font>)</A>
				<A href='?src=\ref[src];inject5=\ref[C]'>(<font color=red>(5)</font>)</A>
				<A href='?src=\ref[src];inject10=\ref[C]'>(<font color=red>(10)</font>)</A><BR>
				********************************<BR>"}
		for(var/obj/item/weapon/implant/explosive/remote/R in remote_implants)
			Tr = get_turf(R)
			if((Tr) && (Tr.z != src.z))
				continue//Out of range
			if(!R.imp_in)
				continue

			dat += {"[R.imp_in.name] | <A href='?src=\ref[src];explode=\ref[R]'><font color=red>Activate explosion</font></A>"}
		dat += "<HR>Tracking Implants<BR>"
		for(var/obj/item/weapon/implant/tracking/T in tracking_implants)
			Tr = get_turf(T)
			if((Tr) && (Tr.z != src.z))
				continue//Out of range
			if(!T.imp_in)
				continue
			var/loc_display = "Unknown"
			var/mob/living/carbon/M = T.imp_in
			if(!M)
				continue //Changeling monkeys break the console, bad monkeys.
			if(M.z == map.zMainStation && !istype(M.loc, /turf/space))
				var/turf/mob_loc = get_turf(M)
				loc_display = mob_loc.loc
			if(T.malfunction)
				loc_display = pick(teleportlocs)

			dat += {"ID: [T.id] | Location: [loc_display]<BR>
				<A href='?src=\ref[src];warn=\ref[T]'>(<font color=red><i>Message Holder</i></font>)</A> |<BR>
				********************************<BR>"}
		dat += "<HR><A href='?src=\ref[src];lock=1'>Lock Console</A>"
	dat = jointext(dat,"")
	var/datum/browser/popup = new(user, "prisoner_implants", "Prisoner Implant Manager System", 400, 500, src)
	popup.set_content(dat)
	popup.open()
	onclose(user, "prisoner_implants")

/obj/machinery/computer/prisoner/process()
	if(!..())
		src.updateDialog()
	return


/obj/machinery/computer/prisoner/Topic(href, href_list)
	if(..())
		return 1
	else
		usr.set_machine(src)

		if(href_list["inject1"])
			var/obj/item/weapon/implant/I = locate(href_list["inject1"])
			if(istype(I))
				I.activate(1)

		else if(href_list["inject5"])
			var/obj/item/weapon/implant/I = locate(href_list["inject5"])
			if(istype(I))
				I.activate(5)

		else if(href_list["inject10"])
			var/obj/item/weapon/implant/I = locate(href_list["inject10"])
			if(istype(I))
				I.activate(10)

		else if(href_list["lock"])
			if(src.allowed(usr))
				screen = !screen
			else
				to_chat(usr, "Unauthorized Access.")

		else if(href_list["warn"])
			var/obj/item/weapon/implant/tracking/I = locate(href_list["warn"])
			if(!istype(I) || !I.imp_in)
				return
			var/warning = copytext(sanitize(input(usr,"Message:","Enter your message here!","")),1,MAX_MESSAGE_LEN)
			if(!warning)
				return

			var/mob/living/carbon/R = I.imp_in
			to_chat(R, "<span class='good'>You hear a voice in your head saying: '[warning]'</span>")

		else if(href_list["explode"])
			var/obj/item/weapon/implant/I = locate(href_list["explode"])
			if(istype(I))
				I.activate()

		src.add_fingerprint(usr)
	src.updateUsrDialog()
	return
