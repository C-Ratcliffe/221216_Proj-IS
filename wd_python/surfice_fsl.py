# A snippet to concatenate all of the masks in each hemisphere

#for test in tstat fstat
#do
#	indir=/Applications/Surfice/221216_Proj-IS/fsl-${test}/
#	for i in ${indir}*/design/
#	do
#		for j in L R
#		do
#			mrmath \
#				${i}${j}_*_concat_mask.nii.gz \
#				sum \
#				${i}${j}h.mask.nii.gz
#			rm \
#				${i}${j}_*_concat_mask.nii.gz
#		done
#		mv \
#			${i}*/*_rand_tfce_corrp_tstat*.nii.gz \
#			${i}
#		for j in Accu Amyg Caud Hipp Pall Puta Thal
#		do
#			for k in p_fstat1 p_tstat1 p_tstat2 p_tstat3 p_tstat4 p_tstat5 p_tstat6
#			do
#				l=${k##*_}
#				mrmath \
#					${i}*_${j}_rand_tfce_corr${k}.nii.gz \
#					sum \
#					${i}${j}_${l}.nii.gz
#				rm \
#					${i}*_${j}_rand_tfce_corr${k}.nii.gz
#			done
#		done
#		rm \
#			-r \
#			${i}*/ \
#			${i}*concat.nii.gz \
#			${i}*log.txt \
#			${i}*.bvars \
#			${i}mni-bet.nii.gz \
#			${i}*rand_tfce_corr*.nii.gz
#	done
#done

##set up the env
import gl
gl.resetdefaults()
gl.backcolor(0,0,0)
gl.colorbarvisible(1)
gl.colorbarposition(4)

##define the loop

tests = ['fstat', 'tstat']
hemi_names = ['L', 'R']
imgmods = ['iso', 'aniso', 'res', 'synthsr']
contrasts = ['fstat1', 'tstat1', 'tstat2', 'tstat3']
ovl_names = ['Accu', 'Amyg', 'Caud', 'Hipp', 'Pall', 'Puta', 'Thal']

for test in tests:
	for imgmod in imgmods:
		indir=f'/Applications/Surfice/221216_Proj-IS/fsl-{test}/{imgmod}/'
		for hemi in hemi_names:
			##mesh setup
			nifti = f'{indir}{hemi}h.mask.nii.gz'
			mesh = f'{indir}{hemi}h.mask.obj'
			gl.meshcreate(nifti, mesh, 0.2, 1, 1, 2)
		mesh = f'{indir}Lh.mask.obj'
		gl.meshloadbilateral(mesh)
		gl.shadername('sheen')
		gl.shaderforbackgroundonly(1)
		gl.shaderambientocclusion(.35)
		gl.orientcubevisible(0)
		gl.colorbarvisible(0)
		gl.overlaycloseall()
		if (test == 'fstat'):
			for contrast in contrasts:
				ovl_num = 1
				for ovl_name in ovl_names:
					ovl_file = f'{indir}{ovl_name}_{contrast}.nii.gz'
					gl.overlayload(ovl_file)
					gl.overlaycolorname(ovl_num, 'red-yellow')
					gl.overlayminmax(ovl_num, .90, 1)
					ovl_num += 1
					if (contrast == 'fstat1'):
						continue
					else:
						if (contrast == 'tstat1'):
							rev = f'tstat4'
						elif (contrast == 'tstat2'):
							rev = f'tstat5'
						elif (contrast == 'tstat3'):
							rev = f'tstat6'
						rev_file = f'{indir}{ovl_name}_{rev}.nii.gz'
						gl.overlayload(rev_file)
						gl.overlaycolorname(ovl_num, 'blue-green')
						gl.overlayminmax(ovl_num, .90, 1)
						ovl_num += 1
				gl.meshcurv()
				ss1 = f'{indir}{imgmod}-{contrast}-lat.png'
				gl.azimuthelevation(180, 0)
				gl.hemispherepry(105)
				gl.hemispheredistance(0.8)
				gl.cameradistance(0.61)
				gl.savebmpxy(ss1, 2213, 915)
				ss2 = f'{indir}{imgmod}-{contrast}-med.png'
				gl.azimuthelevation(180, 0)
				gl.hemispherepry(295)
				gl.hemispheredistance(0.9)
				gl.cameradistance(0.61)
				gl.savebmpxy(ss2, 2213, 915)
				gl.overlaycloseall()
		elif (test == 'tstat'):
			ovl_num = 1
			for ovl_name in ovl_names:
				ovl_file = f'{indir}{ovl_name}_tstat1.nii.gz'
				rev_file = f'{indir}{ovl_name}_tstat2.nii.gz'
				gl.overlayload(ovl_file)
				gl.overlaycolorname(ovl_num, 'red-yellow')
				gl.overlayminmax(ovl_num, .90, 1)
				ovl_num += 1
				gl.overlayload(rev_file)
				gl.overlaycolorname(ovl_num, 'blue-green')
				gl.overlayminmax(ovl_num, .90, 1)
				ovl_num += 1
			gl.meshcurv()
			ss1 = f'{indir}{imgmod}-lat.png'
			gl.azimuthelevation(180, 0)
			gl.hemispherepry(105)
			gl.hemispheredistance(0.8)
			gl.cameradistance(0.61)
			gl.savebmpxy(ss1, 2213, 915)
			ss2 = f'{indir}{imgmod}-med.png'
			gl.azimuthelevation(180, 0)
			gl.hemispherepry(295)
			gl.hemispheredistance(0.9)
			gl.cameradistance(0.61)
			gl.savebmpxy(ss2, 2213, 915)
			gl.overlaycloseall()
		
gl.quit()