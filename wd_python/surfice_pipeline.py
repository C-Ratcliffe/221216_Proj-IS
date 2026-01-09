#indir=/Applications/Surfice/221216_Proj-IS/fsl/pipeline/
#
#for i in aniso iso res synth
#do
#	j=${indir}${i}
#	mrthreshold \
#		-comp gt \
#		-abs 0 \
#		${j}-001.nii.gz \
#		${j}.bi.nii.gz
#	mrthreshold \
#		-abs 30 \
#		${j}-001.nii.gz \
#		${j}.rh.nii.gz
#	mrcalc \
#		${j}.bi.nii.gz \
#		${j}.rh.nii.gz \
#		-sub \
#		${j}.lh.nii.gz
#	for k in 001 002 112
#	do
#		mrthreshold \
#			-comp lt \
#			-abs 18 \
#			${j}-${k}.nii.gz \
#			${j}.temp1.nii.gz \
#			-force
#		mrthreshold \
#			-comp lt \
#			-abs 17 \
#			${j}-${k}.nii.gz \
#			${j}.temp2.nii.gz \
#			-force
#		mrcalc \
#			${j}.temp1.nii.gz \
#			${j}.temp2.nii.gz \
#			-sub \
#			${j}-${k}.hipp.nii.gz \
#			-force
#	done
#	rm \
#		${j}.bi.nii.gz \
#		${j}.temp1.nii.gz \
#		${j}.temp2.nii.gz
#done

# set up the env
import gl
gl.resetdefaults()
gl.backcolor(0,0,0)
gl.colorbarvisible(1)
gl.colorbarposition(4)

# define the environmental variables
indir = f'/Applications/Surfice/221216_Proj-IS/pipeline/'

# define the loop

mods = ['aniso', 'iso', 'res', 'synth']
hemis = ['lh', 'rh']
subs = ['001', '002', '112']

for mod in mods:
	# subcortical structures
	for hemi in hemis:
		nifti = f'{indir}{mod}.{hemi}.nii.gz'
		mesh = f'{indir}{mod}.{hemi}.obj'
		gl.meshcreate(nifti, mesh, 0.2, 1, 1, 2)
	gl.meshloadbilateral(mesh)
	gl.shadername('sheen')
	gl.shaderforbackgroundonly(1)
	gl.shaderambientocclusion(.35)
	gl.orientcubevisible(0)
	gl.colorbarvisible(0)
	gl.overlaycloseall()
	ovl = f'{indir}{mod}.nii.gz'
	gl.overlayload(ovl)
	gl.overlaycolorname(1, 'Random')
	gl.overlayminmax(1, 0, 60)
	gl.meshcurv()
	ss1 = f'{indir}{mod}_lat.png'
	gl.azimuthelevation(180, 0)
	gl.cameradistance(1)
	gl.hemispherepry(105)
	if (mod == 'aniso'):
		gl.hemispheredistance(1.45)
	elif (mod == 'iso'):
		gl.hemispheredistance(1.4)
	elif (mod == 'res'):
		gl.hemispheredistance(0.75)
	elif (mod == 'synth'):
		gl.hemispheredistance(0.75)
	gl.cameradistance(0.61)
	gl.savebmpxy(ss1, 2213, 915)
	gl.overlaycloseall()
	# hippocampal significance testing
	nifti = f'{indir}{mod}.mask.nii.gz'
	mesh = f'{indir}{mod}.mask.obj'
	gl.meshcreate(nifti, mesh, 0.2, 1, 1, 2)
	gl.meshload(mesh)
	gl.shadername('sheen')
	gl.shaderforbackgroundonly(1)
	gl.shaderambientocclusion(.35)
	gl.orientcubevisible(0)
	gl.colorbarvisible(0)
	gl.overlaycloseall()
	ovl = f'{indir}{mod}_hipp_fstat1.nii.gz'
	gl.overlayload(ovl)
	gl.overlaycolorname(1, 'ACTC')
	gl.overlayminmax(1, 0, 1)
	gl.meshcurv()
	ss2 = f'{indir}{mod}_sig.png'
	gl.azimuthelevation(220, 45)
	gl.hemispheredistance(0)
	gl.hemispherepry(0)
	gl.cameradistance(1)
	gl.savebmpxy(ss2, 1000, 1000)
	gl.overlaycloseall()
	# subject-specific hippcocampi
	for sub in subs:
		nifti = f'{indir}{mod}-{sub}.hipp.nii.gz'
		mesh = f'{indir}{mod}-{sub}.hipp.obj'
		gl.meshcreate(nifti, mesh, 0.2, 1, 1, 2)
		gl.meshload(mesh)
		gl.shadername('sheen')
		gl.shaderforbackgroundonly(1)
		gl.shaderambientocclusion(.35)
		gl.orientcubevisible(0)
		gl.colorbarvisible(0)
		gl.overlaycloseall()
		gl.overlayload(nifti)
		gl.overlaycolorname(1, 'Random')
		gl.overlayminmax(1, 0, 60)
		gl.meshcurv()
		ss3 = f'{indir}{mod}-{sub}_hipp.png'
		if (mod == 'res' and sub == '112'):
			gl.azimuthelevation(220, 135)
		else:
			gl.azimuthelevation(220, 45)
		gl.hemispheredistance(0)
		gl.hemispherepry(0)
		gl.cameradistance(1)
		gl.savebmpxy(ss3, 1000, 1000)
		gl.overlaycloseall()

gl.quit()