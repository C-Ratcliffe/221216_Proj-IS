#set up the env
import gl
gl.resetdefaults()
gl.backcolor(0,0,0)
gl.colorbarcolor(0,0,0,0)
gl.colorbarvisible(0)
gl.colorbarposition(4)
gl.orientcubevisible(0)
rdir = f'/Users/coreyratcliffe/Documents/WD_code/rstats/221216_Proj-IS/output/'
sfdir = f'/Applications/Surfice/221216_Proj-IS/fs/'
mods = ['aniso_fs', 'aniso_fsc', 'dldir_fs', 'dliso_fs', 'dlsyn_fs', 'iso_fsc', 'res_fs', 'res_fsc', 'synth_fs']

# cortex
mesh = f'{sfdir}mni-cort.lh.mz3'
mets = ['cortdsc', 'cortthi', 'cortvol']

gl.meshloadbilateral(mesh)
gl.shadername('sheen')
gl.shaderforbackgroundonly(1)
gl.shaderambientocclusion(.35)
gl.overlaycloseall()

for mod in mods:
	for met in mets:
		ovlfile = f'{rdir}{met}-{mod}.nii.gz'
		gl.overlayload(ovlfile)
		if (met == 'cortdsc'):
			gl.overlaycolorname(1, 'ACTC')
			gl.overlayminmax(1, 0.1, 1)
		elif (met == 'cortthi'):
			gl.overlaycolorname(1, 'viridis')
			gl.overlayminmax(1, -0.01, 1.01)
		elif (met == 'cortvol'):
			gl.overlaycolorname(1, 'viridis')
			gl.overlayminmax(1, -0.01, 1.01)
		gl.meshcurv()
		gl.azimuthelevation(180, 0)
		gl.hemispherepry(105)
		gl.hemispheredistance(0.85)
		ss1 = f'{sfdir}{mod}-{met}-lat.png'
		gl.cameradistance(0.53)
		gl.savebmpxy(ss1, 2194, 800)
		gl.azimuthelevation(180, 0)
		gl.hemispherepry(295)
		gl.hemispheredistance(1.05)
		ss2 = f'{sfdir}{mod}-{met}-med.png'
		gl.cameradistance(0.53)
		gl.savebmpxy(ss2, 2194, 800)
		gl.overlaycloseall()

#subcortical structures
mesh = f'{sfdir}mni-subcort.obj'
mets = ['asegdsc', 'asegvol']

gl.meshload(mesh)
gl.shadername('sheen')
gl.shaderforbackgroundonly(1)
gl.shaderambientocclusion(.35)
gl.overlaycloseall()

for mod in mods:
	for met in mets:
		ovlfile = f'{rdir}{met}-{mod}.nii.gz'
		gl.overlayload(ovlfile)
		if (met == 'asegdsc'):
			gl.overlaycolorname(1, 'ACTC')
			gl.overlayminmax(1, 0.1, 1)
		elif (met == 'asegvol'):
			gl.overlaycolorname(1, 'viridis')
			gl.overlayminmax(1, -0.01, 1.01)
		gl.meshcurv()
		gl.azimuthelevation(120, 0)
		gl.hemispherepry(0)
		gl.hemispheredistance(0)
		ss1 = f'{sfdir}{mod}-{met}-right.png'
		gl.cameradistance(0.68)
		gl.savebmpxy(ss1, 725, 800)
		gl.azimuthelevation(240, 0)
		gl.hemispherepry(0)
		gl.hemispheredistance(0)
		ss2 = f'{sfdir}{mod}-{met}-left.png'
		gl.cameradistance(0.68)
		gl.savebmpxy(ss2, 725, 800)
		gl.overlaycloseall()
		
gl.quit()