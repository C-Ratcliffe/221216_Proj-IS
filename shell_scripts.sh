# Preprocessing with DL+DiReCT and SynthSR

# Environment creation and package installation

pyenv install 3.10
pyenv local 3.10
pyenv exec python3.10 -m venv DL-DiReCT
source DL-DiReCT/bin/activate
pip install --upgrade pip
cd ~/DL-DiReCT
git clone https://github.com/SCAN-NRAD/DL-DiReCT.git
cd DL-DiReCT
pip install numpy && pip install -e .
deactivate

pyenv exec python3.10 -m venv nibabel
source nibabel/bin/activate
pip install --upgrade pip
cd ~/nibabel
pip install git+https://github.com/nipy/nibabel
deactivate

# Preparing the environment

studydir=~/Documents/is/
rawdir=${studydir}rawdata/
derivdir=${studydir}derivatives/
statsdir=${derivdir}stats/
statsdirfs=${statsdir}measurements_fs/
statsdirfsl=${statsdir}measurements_fsl/
statsdirdice=${statsdir}measurements_dice/
surfdir=/Applications/Surfice

export FREESURFER_HOME=/usr/local/freesurfer/8.0.0
source $FREESURFER_HOME/SetUpFreeSurfer.sh
conda activate

# Rename files to encourage homogeneity

find . -name "*acq-3D_T1w.nii.gz" -exec rename 's/acq-3D_T1w/iso/' {} ";"
find . -name "*acq-2D_T1w.nii.gz" -exec rename 's/acq-2D_T1w/aniso/' {} ";"

# Preprocessing

mkdir \
	-p \
	${derivdir}dldir/ \
	${derivdir}dliso/ \
	${derivdir}dlsyn/ \
	${derivdir}synth/ \
	${derivdir}aniso/ \
	${derivdir}iso/ \
	${derivdir}res/ \
	${statsdirfs} \
	${statsdirfsl} \
	${statsdirdice}

for subpath in ${derivdir}iso/*
do
	subfile=${subpath##*/iso/}
	subname=${subfile%%_iso.nii.gz}
	sub=${rawdir}${subname}/anat/${subname}
	mri_synthsr \
		--i ${sub}_acq-2D_T1w.nii.gz \
		--o ${derivdir}synth \
		--threads 10
	mv \
		${derivdir}synth/${subname}_acq-2D_T1w_synthsr.nii.gz \
		${derivdir}synth/${subname}_synth.nii.gz
	source DL-DiReCT/bin/activate
	dl+direct \
		--model v7 \
		--subject ${subname} \
		--bet \
		${sub}_acq-2D_T1w.nii.gz \
		${derivdir}dldir/${subname} \
		--keep
	dl+direct \
		--model v7 \
		--subject ${subname} \
		--bet \
		${sub}_acq-3D_T1w.nii.gz \
		${derivdir}dliso/${subname} 
	dl+direct \
		--model v7 \
		--subject ${subname} \
		--bet \
		${derivdir}synth/${subname}_synth.nii.gz \
		${derivdir}dlsyn/${subname} 
	deactivate
	mv \
		${derivdir}dldir/${subname}/T1w_norm.nii.gz \
		${derivdir}res/${subname}_res.nii.gz
	cp \
		${sub}_acq-2D_T1w.nii.gz \
		${derivdir}aniso/${subname}_aniso.nii.gz
	cp \
		${sub}_acq-3D_T1w.nii.gz \
		${derivdir}iso/${subname}_iso.nii.gz
	for imgmod in aniso iso res synth
	do
		SUBJECTS_DIR=${derivdir}${imgmod}_fs
		mkdir \
			-p \
			$SUBJECTS_DIR
		export FS_ALLOW_DEEP=1
		recon-all \
			-s ${subname}_${imgmod} \
			-i ${derivdir}${imgmod}/${subname}_${imgmod}.nii.gz \
			-all \
			-qcache \
			-3T \
			-openmp 10
	done
	for imgmod in aniso iso res
  do
		SUBJECTS_DIR=${derivdir}${imgmod}_fsc
		mkdir \
			-p \
			$SUBJECTS_DIR
		export FS_ALLOW_DEEP=1
		recon-all-clinical.sh \
			${derivdir}${imgmod}/${subname}_${imgmod}.nii.gz \
			${subname}_${imgmod} \
			10 \
			${derivdir}${imgmod}_fsc/
	done
done

# Surface-based Morphometry with FreeSurfer

# Preparing the environment

mkdir \
	-p \
	${statsdirfs}

# Aparcstats2table and Asegstats2table

for i in fs fsc
do
	if [[ $i '==' 'fs' ]]
	then
		declare -a imgmods=('aniso' 'iso' 'res' 'synth')
	elif [[ $i '==' 'fsc' ]]
	then
		declare -a imgmods=('aniso' 'iso' 'res')
		for imgmod in ${imgmods[@]}
		do
			for subpath in ${derivdir}iso/sub-001_iso.nii.gz
			do
				subfile=${subpath##*/iso/}
				subname=${subfile%%_iso.nii.gz}
				sub=${derivdir}${imgmod}_${i}/${subname}_${imgmod}/
				mri_segstats \
					--seg ${sub}mri/aseg.mgz \
					--ctab ${FREESURFER_HOME}/FreeSurferColorLUT.txt \
					--excludeid 0 \
					--sum ${sub}stats/aseg.stats
			done
		done
	fi
	for imgmod in ${imgmods[@]}
	do
		asegstats2table \
			--skip \
			--subjects ${derivdir}${imgmod}_${i}/sub* \
			--meas volume \
			--delimiter tab \
			--tablefile ${statsdirfs}${imgmod}_${i}-aseg_volume_uncut.tsv
		cut -f 2-65 -d, ${statsdirfs}${imgmod}_${i}-aseg_volume_uncut.tsv > ${statsdirfs}${imgmod}_${i}-aseg_volume.tsv
		rm ${statsdirfs}${imgmod}_${i}-aseg_volume_uncut.tsv
		for meas in volume thickness
		do
			for hemi in lh rh
			do
				aparcstats2table \
					--skip \
					--subjects ${derivdir}${imgmod}_${i}/sub* \
					--parc aparc.a2009s \
					--hemi $hemi \
					--measure $meas \
					--delimiter tab \
					--tablefile ${statsdirfs}${imgmod}_${i}-da_${hemi}_${meas}_uncut.tsv
				cut -f 2-75 -d, ${statsdirfs}${imgmod}_${i}-da_${hemi}_${meas}_uncut.tsv > ${statsdirfs}${imgmod}_${i}-da_${hemi}_${meas}.tsv
				rm ${statsdirfs}${imgmod}_${i}-da_${hemi}_${meas}_uncut.tsv
			done
			paste \
				-d '\t' \
				${statsdirfs}${imgmod}_${i}-da_*_${meas}.tsv > ${statsdirfs}${imgmod}_${i}-cort_${meas}.tsv
			rm ${statsdirfs}${imgmod}_${i}-da_lh_${meas}.tsv ${statsdirfs}${imgmod}_${i}-da_rh_${meas}.tsv
		done
	done
done

for i in dldir dliso dlsyn
do
	awk '(NR == 1) || (FNR > 1)' ${derivdir}${i}/sub*/result-thick.csv > ${statsdirfs}${i}_thick.tsv
	awk '(NR == 1) || (FNR > 1)' ${derivdir}${i}/sub*/result-vol.csv > ${statsdirfs}${i}_vol.tsv
	cut -f 2-32 -d, ${statsdirfs}${i}_vol.tsv > ${statsdirfs}${i}_fs-aseg_volume.tsv
	cut -f 33-180 -d, ${statsdirfs}${i}_vol.tsv > ${statsdirfs}${i}_fs-cort_volume.tsv
	cut -f 2-149 -d, ${statsdirfs}${i}_thick.tsv > ${statsdirfs}${i}_fs-cort_thickness.tsv
	rm \
		${statsdirfs}${i}_vol.tsv \
		${statsdirfs}${i}_thick.tsv
done

# Subcortical Surface Shape with FSL

# Preprocessing

for imgmod in aniso iso res synth
	do
	fsldir=$(printf "${derivdir}${imgmod}_fslanat/")	#subject directory
	mkdir \
		-p \
		${fsldir}design/volumes/
	rm \
		-f \
		${fsldir}design/volumes/significances.tsv \
		${fsldir}design/volumes/volumes.tsv
	echo region > ${fsldir}design/volumes/meta_vols.tsv
	echo contrast > ${fsldir}design/volumes/meta_sigs.tsv
	for contrast in fstat1 tstat1 tstat2 tstat3 tstat4 tstat5 tstat6
	do
		echo ${contrast} >> ${fsldir}design/volumes/meta_sigs.tsv
	done

## Segmentation

	if [[ ! -e ${fsldir}design/mni-bet.nii.gz ]]
	then
		mri_synthstrip \
			-i ${FSLDIR}/data/standard/MNI152_T1_1mm.nii.gz \
			-o ${fsldir}design/mni-bet.nii.gz
	fi

	for subpath in ${derivdir}iso/*
	do
		subfile=${subpath##*/iso/}
		ptc=${subfile%%_iso.nii.gz}
		subout=${fsldir}${ptc}/${ptc}
		mkdir \
			-p \
			${fsldir}${ptc}
		echo $subj
		N4BiasFieldCorrection \
			-i ${derivdir}${imgmod}/${ptc}_${imgmod}.nii.gz \
			-o ${subout}_biascorr.nii.gz
		mri_synthstrip \
			-i ${subout}_biascorr.nii.gz \
			-o ${subout}_biascorr-bet.nii.gz
		flirt \
			-in ${subout}_biascorr-bet.nii.gz \
			-ref ${fsldir}design/mni-bet.nii.gz \
			-omat ${subout}_biascorr-bet2std.mat \
			-out ${subout}_biascorr-bet2std.nii.gz
		run_first_all \
			-a ${subout}_biascorr-bet2std.mat \
			-s L_Accu,L_Amyg,L_Caud,L_Hipp,L_Pall,L_Puta,L_Thal,R_Accu,R_Amyg,R_Caud,R_Hipp,R_Pall,R_Puta,R_Thal \
			-b \
			-i ${subout}_biascorr-bet.nii.gz \
			-o ${subout}_first
		echo ${ptc}_vols > ${fsldir}design/volumes/${ptc}_vols.tsv
		ptcvol=$(fslstats -t ${subout}_first_all_none_origsegs.nii.gz -V | awk '{for (i=2; i<=NF; i+=2) print $i}')
		echo $ptcvol >> ${fsldir}design/volumes/${ptc}_vols.tsv
	done
	first_roi_slicesdir \
		${fsldir}sub*/sub*biascorr.nii.gz \
		${fsldir}sub*/sub*firstseg.nii.gz
	mv \
		slicesdir \
		${fsldir}slicesdir_seg
	${FSLDIR}/bin/slicesdir \
		-p ${fsldir}design/mni-bet.nii.gz \
		${fsldir}sub*/sub*biascorr-bet2std.nii.gz
	mv \
		slicesdir \
		${fsldir}slicesdir_reg

## Concatenation, weighting, and randomise

	for hemi in L R
	do
		for struct in Accu Amyg Caud Hipp Pall Puta Thal
		do
			region=${hemi}_${struct}
			rm \
				-f \
				${fsldir}design/${region}.bvars
			echo ${region} >> ${fsldir}design/volumes/meta_vols.tsv
			echo ${region}_sigs > ${fsldir}design/volumes/roi_${region}_sigs.tsv
			mkdir \
				-p \
				${fsldir}design/${region}
			concat_bvars \
				${fsldir}design/${region}.bvars \
				${fsldir}sub*/sub*first-${region}_first.bvars
			first_utils \
				--vertexAnalysis \
				--usebvars \
				-i ${fsldir}design/${region}.bvars \
				-d ${derivdir}stats/design.mat \
				-o ${fsldir}design/${region}_concat \
				--useReconMNI \
				-v >& ${fsldir}design/${region}_log.txt
			randomise_parallel \
				-i ${fsldir}design/${region}_concat.nii.gz \
				-m ${fsldir}design/${region}_concat_mask.nii.gz \
				-o ${fsldir}design/${region}/${region}_rand \
				-d ${derivdir}stats/design.mat \
				-t ${derivdir}stats/design.con \
				-f ${derivdir}stats/design.fts \
				-T
			for contrast in fstat1 tstat1 tstat2 tstat3 tstat4 tstat5 tstat6
			do
				filesig=${fsldir}design/${region}/${region}_rand_tfce_corrp_${contrast}.nii.gz
				roicrit=$(fslstats -t ${filesig} -R | awk '{print $2}')
				roisig=$(( 1 - $roicrit ))
				echo $roisig >> ${fsldir}design/volumes/roi_${region}_sigs.tsv
			done
		done
	done
	
	paste -d '\t' ${fsldir}design/volumes/*vols.tsv > ${fsldir}design/volumes/volumes.tsv
	paste -d '\t' ${fsldir}design/volumes/*sigs.tsv > ${fsldir}design/volumes/significances.tsv
	rm \
		${fsldir}design/volumes/*_vols.tsv \
		${fsldir}design/volumes/*_sigs.tsv
	cp \
		${fsldir}design/volumes/volumes.tsv \
		${statsdirfsl}${imgmod}_volumes.tsv
	cp \
		${fsldir}design/volumes/significances.tsv \
		${statsdirfsl}${imgmod}_significances.tsv
done

# Calculating Dice Coefficients 

# Preparing the environment - RUN AS A DISCRETE BLOCK
# Thresholding, binarising, and creating overlap volumes

if [[ ! -e ${statsdir}ints.txt ]]
then
	mrdump \
		${SUBJECTS_DIR}/bert/mri/aparc.a2009s+aseg.mgz \
		-mask ${SUBJECTS_DIR}/bert/mri/aparc.a2009s+aseg.mgz \
		${statsdir}ints.txt
fi
if [[ ! -e ${statsdir}ints_dl.txt ]]
then
	mrdump \
		${derivdir}dldir/sub-001/T1w_norm_seg.nii.gz \
		-mask ${derivdir}dldir/sub-001/T1w_norm_seg.nii.gz \
		${statsdir}ints_dl.txt
fi
if [[ ! -e ${statsdir}ints_all.txt ]]
then
	cat \
		${statsdir}ints.txt \
		${statsdir}ints_dl.txt > ${statsdir}ints_all.txt
fi

ints=(${(u)$(<${statsdir}ints_all.txt)})

for i in fs fsc
do
	if [[ $i '==' 'fs' ]]
	then
		declare -a imgmods=('iso' 'aniso' 'res' 'synth' 'dldir' 'dliso' 'dlsyn')
	elif [[ $i '==' 'fsc' ]]
	then
		declare -a imgmods=('iso' 'aniso' 'res')
	fi
	for subpath in ${derivdir}iso/*
	do
		subfile=${subpath##*/iso/}
		ptc=${subfile%%_iso.nii.gz}
		for imgmod in ${imgmods[@]}
		do
			sub=${derivdir}dice_fs/${imgmod}_${i}/${ptc}/${ptc}
			mkdir \
				-p \
				${derivdir}dice_fs/${imgmod}_${i}/${ptc}/
			if [[ ! $imgmod == dldir && ! $imgmod == dliso && ! $imgmod == dlsyn ]]
			then
				startvol=${derivdir}${imgmod}_${i}/${ptc}_${imgmod}/mri/aparc.a2009s+aseg.nii.gz
				mri_convert \
					${derivdir}${imgmod}_${i}/${ptc}_${imgmod}/mri/aparc.a2009s+aseg.mgz \
					${startvol}
				if [[ ! ${imgmod}_${i} == iso_fs ]]
				then
					regvol=${derivdir}${imgmod}_${i}/${ptc}_${imgmod}/mri/aparc.a2009s+aseg-affine.nii.gz
					flirt \
						-in ${startvol} \
						-ref ${derivdir}iso_fs/${ptc}_iso/mri/aparc.a2009s+aseg.nii.gz \
						-interp nearestneighbour \
						-dof 6 \
						-o ${regvol}
				else
					regvol=${derivdir}${imgmod}_${i}/${ptc}_${imgmod}/mri/aparc.a2009s+aseg.nii.gz
				fi
			else
				startvol=${derivdir}${imgmod}/${ptc}/T1w_norm_seg.nii.gz
				regvol=${derivdir}${imgmod}/${ptc}/T1w_norm_reg.nii.gz
				flirt \
					-in ${startvol} \
					-ref ${derivdir}iso_fs/${ptc}_iso/mri/aparc.a2009s+aseg.nii.gz \
					-interp nearestneighbour \
					-dof 6 \
					-o ${regvol}
			fi
			for parc in ${ints[@]}
			do
				fslmaths \
					$regvol \
					-thr ${parc} \
					-uthr ${parc} \
					-bin ${sub}_${parc}_bin.nii.gz
			done
			if [[ ! $imgmod == dldir && ! $imgmod == dliso && ! $imgmod == dlsyn ]]
			then
				fslmaths \
					${sub}_7_bin.nii.gz \
					-add ${sub}_8_bin.nii.gz \
					${sub}_104_bin.nii.gz
				fslmaths \
					${sub}_46_bin.nii.gz \
					-add ${sub}_47_bin.nii.gz \
					${sub}_117_bin.nii.gz
				fslmaths \
					${sub}_251_bin.nii.gz \
					-add ${sub}_252_bin.nii.gz \
					-add ${sub}_253_bin.nii.gz \
					-add ${sub}_254_bin.nii.gz \
					-add ${sub}_255_bin.nii.gz \
					${sub}_130_bin.nii.gz
			fi
			for parc in ${ints[@]}
			do
				if [[ ! ${imgmod}_${i} == iso_fs ]]
				then
					fslmaths \
						${sub}_${parc}_bin.nii.gz \
						-mul ${derivdir}dice_fs/iso_fs/${ptc}/${ptc}_${parc}_bin.nii.gz \
						${sub}_${parc}_ovl.nii.gz
				fi
			done
		done
	done
done

# Recording the overlap volumes as tsv files, and collating them
# regional

ints=(${(u)$(<${statsdir}ints_dl.txt)})

for imgmod in aniso_fs aniso_fsc dldir_fs dliso_fs dlsyn_fs iso_fs iso_fsc res_fs res_fsc synth_fs
do
	for subpath in ${derivdir}iso/*
	do
		subfile=${subpath##*/iso/}
		ptc=${subfile%%_iso.nii.gz}
		sub=${derivdir}dice_fs/${imgmod}/${ptc}/${ptc}
		iso=${derivdir}dice_fs/iso_fs/${ptc}/${ptc}
		echo ${ptc} > ${derivdir}dice_fs/${imgmod}/${ptc}/vol.tsv
		if [[ ${imgmod} == iso_fs ]]
		then
			for parc in ${ints[@]}
			do
				binvol=$(fslstats ${sub}_${parc}_bin.nii.gz -V | awk '{print $2}')
				echo $binvol >> ${derivdir}dice_fs/${imgmod}/${ptc}/vol.tsv
			done
		elif [[ ! ${imgmod} == iso_fs ]]
		then
			echo ${ptc} > ${derivdir}dice_fs/${imgmod}/${ptc}/ovl.tsv
			echo ${ptc} > ${derivdir}dice_fs/${imgmod}/${ptc}/dsc.tsv
			for parc in ${ints[@]}
			do
				ovlvol=$(fslstats ${sub}_${parc}_ovl.nii.gz -V | awk '{print $2}')
				binvol=$(fslstats ${sub}_${parc}_bin.nii.gz -V | awk '{print $2}')
				isovol=$(fslstats ${iso}_${parc}_bin.nii.gz -V | awk '{print $2}')
				dscvol=$(( 2 * ${ovlvol} / ( ${binvol} + ${isovol} ) ))
				echo $binvol >> ${derivdir}dice_fs/${imgmod}/${ptc}/vol.tsv
				echo $ovlvol >> ${derivdir}dice_fs/${imgmod}/${ptc}/ovl.tsv
				echo $dscvol >> ${derivdir}dice_fs/${imgmod}/${ptc}/dsc.tsv
			done
		fi
	done
	paste -d '\t' ${derivdir}dice_fs/${imgmod}/*/vol.tsv > ${derivdir}dice_fs/${imgmod}-vol.tsv
	if [[ ! $imgmod == iso ]]
	then
		paste -d '\t' ${derivdir}dice_fs/${imgmod}/*/ovl.tsv > ${derivdir}dice_fs/${imgmod}-ovl.tsv
		paste -d '\t' ${derivdir}dice_fs/${imgmod}/*/dsc.tsv > ${derivdir}dice_fs/${imgmod}-dsc.tsv
	fi
done

# wholebrain

for i in fs fsc
do
	if [[ ${i} == 'fs' ]]
	then
		declare -a imgmods=('iso' 'aniso' 'res' 'synth' 'dldir' 'dliso' 'dlsyn')
	elif [[ ${i} == 'fsc' ]]
	then
		declare -a imgmods=('iso' 'aniso' 'res')
	fi
	for imgmod in ${imgmods[@]}
	do
		echo ${imgmod}_${i} > ${derivdir}/dice_fs/${imgmod}_${i}/wholebrain_vol.tsv
		echo ${imgmod}_${i} > ${derivdir}/dice_fs/${imgmod}_${i}/wholebrain_ovl.tsv
		echo ${imgmod}_${i} > ${derivdir}/dice_fs/${imgmod}_${i}/wholebrain_dsc.tsv
		for subpath in ${derivdir}iso/*
		do
			subfile=${subpath##*/iso/}
			ptc=${subfile%%_iso.nii.gz}
			iso=${derivdir}iso_fs/${ptc}_iso/mri/aparc.a2009s+aseg.nii.gz
			if [[ ${imgmod}_${i} == 'iso_fs' ]]
			then
				sub=${derivdir}${imgmod}_${i}/${ptc}_${imgmod}/mri/aparc.a2009s+aseg.nii.gz
				ovl=${derivdir}${imgmod}_${i}/${ptc}_${imgmod}/mri/aparc.a2009s+aseg-ovl.nii.gz
			elif [[ ${imgmod}_${i} == 'dldir_fs' || ${imgmod}_${i} == 'dliso_fs' || ${imgmod}_${i} == 'dlsyn_fs' ]]
			then
				sub=${derivdir}${imgmod}/${ptc}/T1w_norm_reg.nii.gz
				ovl=${derivdir}${imgmod}/${ptc}/T1w_norm_ovl.nii.gz
			elif [[ ${imgmod}_${i} != 'iso_fs' && ${imgmod}_${i} != 'dldir_fs'  && ${imgmod}_${i} != 'dliso_fs'  && ${imgmod}_${i} != 'dlsyn_fs' ]]
			then
				sub=${derivdir}${imgmod}_${i}/${ptc}_${imgmod}/mri/aparc.a2009s+aseg-affine.nii.gz
				ovl=${derivdir}${imgmod}_${i}/${ptc}_${imgmod}/mri/aparc.a2009s+aseg-ovl.nii.gz
			fi
			fslmaths \
				${sub} \
				-mul ${iso} \
				${ovl}
			ovlvol=$(fslstats ${ovl} -V | awk '{print $2}')
			binvol=$(fslstats ${sub} -V | awk '{print $2}')
			isovol=$(fslstats ${iso} -V | awk '{print $2}')
			dscvol=$(( 2 * ${ovlvol} / ( ${binvol} + ${isovol} ) ))
			echo $binvol >> ${derivdir}/dice_fs/${imgmod}_${i}/wholebrain_vol.tsv
			echo $ovlvol >> ${derivdir}/dice_fs/${imgmod}_${i}/wholebrain_ovl.tsv
			echo $dscvol >> ${derivdir}/dice_fs/${imgmod}_${i}/wholebrain_dsc.tsv
		done
	done
done
echo sub > ${derivdir}/dice_fs/wholebrain_meta.tsv
for subpath in ${derivdir}iso/*
do
	subfile=${subpath##*/iso/}
	ptc=${subfile%%_iso.nii.gz}
	echo ${ptc} >> ${derivdir}/dice_fs/wholebrain_meta.tsv
done
paste -d '\t' ${derivdir}dice_fs/*/wholebrain_dsc.tsv > ${derivdir}dice_fs/wholebrain_dice.tsv
paste -d '\t' ${derivdir}dice_fs/*/wholebrain_vol.tsv > ${derivdir}dice_fs/wholebrain_vols.tsv

# Copying the volume tsv files to the r directory

for i in ${derivdir}dice_fs/*.tsv
do
	cp \
		$i \
		${statsdirdice}
done

# Visualising alignment

for subpath in ${derivdir}iso/*001*
do
	subfile=${subpath##*/iso/}
	ptc=${subfile%%_iso.nii.gz}
	mrview \
		${derivdir}iso_fs/${ptc}_iso/mri/brain.mgz \
		-overlay.load ${derivdir}iso_fs/${ptc}_iso/mri/aparc.a2009s+aseg.nii.gz \
		-overlay.colour 255,255,255 \
		-overlay.threshold_min 200 \
		-overlay.interpolation 0 \
		-overlay.load ${derivdir}aniso_fs/${ptc}_aniso/mri/aparc.a2009s+aseg-affine.nii.gz \
		-overlay.colour 230,25,75 \
		-overlay.threshold_min 200 \
		-overlay.interpolation 0 \
		-overlay.load ${derivdir}res_fs/${ptc}_res/mri/aparc.a2009s+aseg-affine.nii.gz \
		-overlay.colour 60,180,75 \
		-overlay.threshold_min 200 \
		-overlay.interpolation 0 \
		-overlay.load ${derivdir}synth_fs/${ptc}_synth/mri/aparc.a2009s+aseg-affine.nii.gz \
		-overlay.colour 0,130,200 \
		-overlay.threshold_min 200 \
		-overlay.interpolation 0 \
		-overlay.load ${derivdir}dldir/${ptc}/T1w_norm_reg.nii.gz \
		-overlay.colour 245,130,48 \
		-overlay.threshold_min 200 \
		-overlay.interpolation 0 \
		-overlay.load ${derivdir}iso_fsc/${ptc}_iso/mri/aparc.a2009s+aseg-affine.nii.gz \
		-overlay.colour 145,30,180 \
		-overlay.threshold_min 200 \
		-overlay.interpolation 0 \
		-overlay.load ${derivdir}aniso_fsc/${ptc}_aniso/mri/aparc.a2009s+aseg-affine.nii.gz \
		-overlay.colour 70,240,240 \
		-overlay.threshold_min 200 \
		-overlay.interpolation 0 \
		-overlay.load ${derivdir}res_fsc/${ptc}_res/mri/aparc.a2009s+aseg-affine.nii.gz \
		-overlay.colour 255,225,25 \
		-overlay.threshold_min 200 \
		-overlay.interpolation 0
done

