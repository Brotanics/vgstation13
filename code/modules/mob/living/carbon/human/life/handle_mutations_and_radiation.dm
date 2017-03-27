//Refer to life.dm for caller

/mob/living/carbon/human/proc/handle_mutations_and_radiation()
	if(flags & INVULNERABLE)
		return
	if(getFireLoss())
		if((M_RESIST_HEAT in mutations))
			heal_organ_damage(0,1)

	for(var/gene_type in active_genes)
		var/datum/dna/gene/gene = dna_genes[gene_type]
		if(!gene.block)
			continue
		gene.OnMobLife(src)

	if(radiation)
		rad_tick++
		//Whoever wrote those next two blocks of code obviously never heard of mathematical helpers
		//Whoever wrote this next block needs shoved into supermatter
		/*if(radiation > 100)
			radiation = 100
			Knockdown(10)
			to_chat(src, "<span class='warning'>You feel weak.</span>")
			emote("collapse")*/

		if(radiation < 0)
			radiation = 0

		else
			if(species.flags & RAD_ABSORB)
				var/rads = radiation/25
				radiation -= rads
				nutrition += rads
				adjustBruteLoss(-(rads))
				adjustOxyLoss(-(rads))
				adjustToxLoss(-(rads))
				updatehealth()
				rad_tick = 0
				return

			var/damage = 0
			switch(radiation)
				if(1 to 49)
					radiation--
					rad_tick++
					if(!(radiation % 5)) //Damage every 5 ticks. Previously prob(25)
						adjustToxLoss(1)
						damage = 1
						updatehealth()

				if(50 to 74)
					radiation -= 2
					rad_tick += 2
					damage = 1
					adjustToxLoss(1)
					if(prob(5))
						radiation -= 5
						Knockdown(3)
						to_chat(src, "<span class='warning'>You feel weak.</span>")
						emote("collapse")
					updatehealth()

				if(75 to INFINITY)
					radiation -= 3
					rad_tick += 3
					adjustToxLoss(3)
					damage = 1
					/*
					if(prob(1))
						to_chat(src, "<span class='warning'>You mutate!</span>")
						randmutb(src)
						domutcheck(src,null)
						emote("gasp")
					*/
					updatehealth()

			if(damage && organs.len)
				var/datum/organ/external/O = pick(organs)
				if(istype(O))
					O.add_autopsy_data("Radiation Poisoning", damage)
	else
		rad_tick = max(rad_tick-1,0)

	if(rad_tick)
		/*
		A list of events that are more likely to occur based on time exposed and amount of exposure

		6 'gates'
		100
			Vomiting - Early on symptom, if rad_tick and radiation is above a certain level
			Nosebeeds - Early onset of the blood vessels breaking down
		200
			Internal hemorrhaging - Lower rad tick has lower probability, but this ramps up as it goes along
		300
			Organ Damage - A little later on, again lower rad tick has lower prob
		400
			Minor limb mutation - We're talking a decently large exposure causing this, somewhat rare
			Blindness - About the same chance as limb mutation
			Clone damage - To emulate DNA breakdown
		500
			Necrosis - After Limb mutation
			Glowing slightly green - Extremely rare, practically terminal, glowing increases with radiation level
		600
			Ghoulification if extremely lucky - We're talking 1 in 1000

		For anything affecting internal or external organs, if it's robotic, exempt them.
		*/

		//For symptoms that you want to scale off of a minimum radiation amount
		var/minor_rad_multiplier = max(1, radiation/20)
		var/rad_multiplier = max(1, radiation/50)
		var/major_rad_multiplier = max(1, radiation/70)
		var/extreme_rad_multiplier = max(1, radiation/100)

		if(rad_tick > 100)
			if(prob(5*rad_multiplier))
				//Vomit
				vomit()
			if(prob(5*minor_rad_multiplier))
				//Nosebleed
				if(prob(15))
					to_chat(src, "<span class = 'danger'>Your nose starts bleeding!</span>")
				drip(1*minor_rad_multiplier)
			if(prob(5*major_rad_multiplier))
				//Hallucination
				hallucination += rand(1,5)*minor_rad_multiplier
		if(rad_tick > 200)
			if(prob(5*rad_multiplier))
				//Internal hemorrhaging
				var/list/limbs_to_bleed = list()
				for(var/datum/organ/external/E in organs)
					if(E.is_robotic())
						continue
					limbs_to_bleed.Add(E)
				if(limbs_to_bleed.len)
					var/datum/organ/external/victim = pick(limbs_to_bleed)
					if(prob(35))
						to_chat(src, "<span class = 'danger'>You feel something tear in your [victim.display_name]</span>")
					var/datum/wound/internal_bleeding/I = new (1*minor_rad_multiplier)
					victim.wounds += I
		if(rad_tick > 300)
			if(prob(5*rad_multiplier))
				//Organ damage
				var/list/organ_to_damage = list()
				for(var/datum/organ/internal/I in internal_organs)
					if(I.robotic)
						continue
					organ_to_damage.Add(I)
				if(organ_to_damage.len)
					var/datum/organ/internal/victim = pick(organ_to_damage)
					victim.damage += rand(1,5)*rad_multiplier
		if(rad_tick > 400)
			if(prob(2*major_rad_multiplier))
				//Minor limb mutation
				var/list/datum/organ/external/candidates = list()
				for (var/datum/organ/external/O in organs)
					if(!(O.status & ORGAN_MUTATED|ORGAN_ROBOT))
						candidates.Add(O)
				if (candidates.len)
					var/datum/organ/external/O = pick(candidates)
					O.mutate()
					to_chat(src, "<span class = 'notice'>Something is not right with your [O.display_name].</span>")
			if(prob(5*rad_multiplier))
				//Minor clone damage
				adjustCloneLoss(rand(1,5))
				to_chat(src, "<span class='warning'>[pick("You can feel your body becoming weak!</span>", \
				"You feel like you're about to die!", \
				"You feel every part of your body screaming in agony!", \
				"A low, rolling pain passes through your body!", \
				"Your body feels as if it's falling apart!", \
				"You feel extremely weak!", \
				"A sharp, deep pain bathes every inch of your body!")]")
			if(prob(10)*minor_rad_multiplier)
				//Blindness
				var/datum/organ/internal/eyes/E = internal_organs_by_name["eyes"]
				if(!E.robotic)
					to_chat(src, "<span class = 'danger'>[pick("Your eyesight starts to fade!","Your eyes go cloudy!","Are you going blind?")]</span>")
					E.damage += 2.5
					eye_blurry = min(eye_blurry+1.5,50)
					if (E.damage >= E.min_broken_damage && !(sdisabilities & BLIND))
						simple_message("<span class='warning'>You go blind!</span>","<span class='warning'>Somebody turns the lights off.</span>")
						sdisabilities |= BLIND
					else if (E.damage >= E.min_bruised_damage && !(disabilities & NEARSIGHTED))
						simple_message("<span class='warning'>You go blind!</span>","<span class='warning'>Somebody turns the lights off.</span>")
						eye_blind = 5
						eye_blurry = 5
						disabilities |= NEARSIGHTED
						spawn(100)
						disabilities &= ~NEARSIGHTED
		if(rad_tick > 500)
			if(prob(2.5*major_rad_multiplier))
				//Necrosis Have sloughs of meat fall off the subject, maybe a limb fall off or become skeletal. Look at frankenstein limb code
				var/inst = pick(1, 2, 3)
				switch(inst)

					if(1)
						//Drop some meat
						to_chat(src, "<span class='warning'>A chunk of meat falls off of you!</span>")
						var/totalslabs = 1
						var/obj/item/weapon/reagent_containers/food/snacks/meat/allmeat[totalslabs]
						var/sourcename = real_name
						var/sourcejob = job
						var/sourcenutriment = nutrition / 15
						//var/sourcetotalreagents = mob.reagents.total_volume

						for(var/i = 1 to totalslabs)
							var/obj/item/weapon/reagent_containers/food/snacks/meat/human/newmeat = new
							newmeat.name = sourcename + " " + newmeat.name
							newmeat.subjectname = sourcename
							newmeat.subjectjob = sourcejob
							newmeat.reagents.add_reagent(NUTRIMENT, sourcenutriment / totalslabs) //Thehehe. Fat guys go first
							//src.occupant.reagents.trans_to(newmeat, round (sourcetotalreagents / totalslabs, 1)) // Transfer all the reagents from the
							allmeat[i] = newmeat

							var/obj/item/meatslab = allmeat[i]
							var/turf/Tx = get_turf(src)
							meatslab.forceMove(get_turf(src))
							meatslab.throw_at(Tx, i, 3)

							if(!Tx.density)
								var/obj/effect/decal/cleanable/blood/gibs/D = getFromPool(/obj/effect/decal/cleanable/blood/gibs, Tx)
								D.New(Tx,i)

					if(2)
						//Drop a limb
						var/list/datum/organ/external/candidates = list()
						for (var/datum/organ/external/O in organs)
							if(O.status & ORGAN_ROBOT)
								continue
							if(O.vital)
								continue
							if(O.amputated)
								continue
							candidates.Add(O)
						if (candidates.len)
							var/datum/organ/external/victim = pick(candidates)
							victim.droplimb(1)
					if(3)
						//Skeletonify a limb
						var/list/datum/organ/external/candidates = list()
						for (var/datum/organ/external/O in organs)
							if(O.status & ORGAN_ROBOT)
								continue
							if(O.amputated)
								continue
							if(O.species == "Skeletal Vox" || O.species == "Skellington")
								continue
							candidates.Add(O)
						if(candidates.len)
							var/datum/organ/external/victim = pick(candidates)
							to_chat(src, "<span class = 'warning'>The flesh is falling off of your [victim.display_name]!</span>")
							var/new_species_name
							if(isvox(src))
								new_species_name = "Skeletal Vox"
							else
								new_species_name = "Skellington"
							var/datum/species/S = all_species[new_species_name]
							victim.species = new S.type
							update_body()
			if(prob(1*major_rad_multiplier))
				//Rad glow
				to_chat(src, "<span class = 'blob'>You start glowing!</span>")
		if(rad_tick > 600)
			if(prob(0.01*extreme_rad_multiplier))
				//Ghoulification
				to_chat(src, "<span class = 'notice'>You feel strangely at peace.</span>")
				if(set_species("Ghoul"))
					regenerate_icons()
					visible_message("<span class='danger'>\The [src]'s form loses bulk as they collapse to the ground.</span>")
					Knockdown(3)