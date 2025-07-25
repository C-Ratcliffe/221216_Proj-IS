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
rdir=${derivdir}stats/
rdirfs=${rdir}measurements_fs/
rdirfsl=${rdir}measurements_fsl/
rdirdice=${rdir}measurements_dice/
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
	${derivdir}synth/ \
	${derivdir}aniso/ \
	${derivdir}iso/ \
	${derivdir}res/ \
	${rdirfs} \
	${rdirfsl} \
	${rdirdice}

for subpath in ${derivdir}iso/*
do
	subfile=${subpath##*/iso/}
	subname=${subfile%%_iso.nii.gz}
	sub=${rawdir}${subname}/anat/${subname}
	mri_synthsr \
		--i ${sub}_acq-2D_T1w.nii.gz \
		--o ${derivdir}synth \
		--threads 10
	source DL-DiReCT/bin/activate
	dl+direct \
		--model v7 \
		--subject $subname \
		--bet \
		${sub}_acq-2D_T1w.nii.gz \
		${derivdir}dldir/${subname} \
		--keep
	deactivate
	mv \
		${derivdir}synth/${subname}_acq-2D_T1w_synthsr.nii.gz \
		${derivdir}synth/${subname}_synth.nii.gz
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
			-openmp 24
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
			24 \
			${derivdir}${imgmod}_fsc/
	done
done

# Surface-based Morphometry with FreeSurfer

# Preparing the environment

mkdir \
	-p \
	${rdirfs}

# Aparcstats2table and Asegstats2table

for i in fs fsc
do
	if [ $i '==' 'fs' ]
	then
		declare -a imgmods=('aniso' 'iso' 'res' 'synth')
	elif [ $i '==' 'fsc' ]
	then
		declare -a imgmods=('aniso' 'iso' 'res')
	fi
	for imgmod in ${imgmods[@]}
	do
		for meas in volume thickness
		do
			for hemi in lh rh
			do
				aparcstats2table \
					--skip \
					--subjects ${derivdir}${imgmod}_fs/sub* \
					--parc aparc.a2009s \
					--hemi $hemi \
					--measure $meas \
					--delimiter tab \
					--tablefile ${rdirfs}${imgmod}-da_${hemi}_${meas}_uncut.tsv
				cut -f 2-75 -d, ${rdirfs}${imgmod}-da_${hemi}_${meas}_uncut.tsv > ${rdirfs}${imgmod}-da_${hemi}_${meas}.tsv
				rm ${rdirfs}${imgmod}-da_${hemi}_${meas}_uncut.tsv
			done
			paste \
				-d '\t' \
				${rdirfs}${imgmod}-da_*_${meas}.tsv > ${rdirfs}${imgmod}_${i}-cort_${meas}.tsv
			rm ${rdirfs}${imgmod}-da_lh_${meas}.tsv ${rdirfs}${imgmod}-da_rh_${meas}.tsv
		done
		for meas in ${measuressubcort[@]}
		do
			asegstats2table --skip \
				--subjects ${derivdir}${imgmod}_freesurfer/sub* \
				--meas $meas \
				--delimiter tab \
				--tablefile ${rdirfs}${imgmod}-aseg_${meas}_uncut.tsv
			cut -f 2-65 -d, ${rdirfs}${imgmod}-aseg_${meas}_uncut.tsv > ${rdirfs}${imgmod}-${i}-aseg_${meas}.tsv
			rm ${rdirfs}${imgmod}-aseg_${meas}_uncut.tsv
			if [ $meas '==' 'Area_mm2' ]
			then
				mv ${rdirfs}${imgmod}-aseg_${meas}.tsv ${rdirfs}${imgmod}-${i}-aseg_area_uncut.tsv
				#cut -f 2-65 -d, ${rdirfs}${imgmod}-aseg_area_uncut.tsv > ${rdirfs}${imgmod}-aseg_area.tsv
				rm ${rdirfs}${imgmod}-aseg_area_uncut.tsv
			fi
		done
	done
done

awk '(NR == 1) || (FNR > 1)' ${derivdir}dldir/sub*/result-thick.tsv > ${rdirfs}dldirect-da_bi_thick.tsv
awk '(NR == 1) || (FNR > 1)' ${derivdir}dldir/sub*/result-vol.tsv > ${rdirfs}dldirect-da_bi_vol.tsv
cut -f 2-32 -d, ${rdirfs}dldirect-da_bi_vol.tsv > ${rdirfs}dldirect-aseg_volume.tsv
cut -f 33-180 -d, ${rdirfs}dldirect-da_bi_vol.tsv > ${rdirfs}dldirect-da_bi_volume.tsv
cut -f 2-149 -d, ${rdirfs}dldirect-da_bi_thick.tsv > ${rdirfs}dldirect-da_bi_thickness.tsv
rm ${rdirfs}dldirect-da_bi_vol.tsv ${rdirfs}dldirect-da_bi_thick.tsv

# Subcortical Surface Shape with FSL

# Preprocessing

for imgmod in aniso iso res synth
	do
	fsldir=$(printf "${derivdir}${imgmod}_fslanat/")	#subject directory
	res=1																							#resolution of the reference image
	preproc=yes																				#carry out preprocessing and segmentation
	concat=yes																				#carry out concatenation of the bvars
	group=yes																					#carry out group level comparisons with randomise
	test=fstat1																				#carry out t- or f- tests
	testno=1																					#label for the hypothesis testing
	design=design1.mat																#name of the design matrix
	contrast=contrast1.con														#name of the contrast file
	ftest=ftest1.fts																	#name of the f-test file

	mkdir \
		-p \
		${fsldir}design/Extras/Display_Volumes/${testno} \
		${fsldir}design/Extras/Screenshots \
		${fsldir}processed \
		${fsldir}design/Extras/Volumes

## Segmentation

	if [[ ! -e ${fsldir}design/mni-bet.nii.gz ]]
	then
		cp \
			${FSLDIR}/data/standard/MNI152_T1_${res}mm.nii.gz \
			${fsldir}design/mni.nii.gz
		bet \
			${fsldir}design/mni.nii.gz \
			${fsldir}design/mni-bet.nii.gz
	fi

	for subj in ${fsldir}input/*.nii.gz
	do
		subname=$(grep -E -o 'sub-[0-9][0-9][0-9]' <<< $subj)
		subpre=${fsldir}${subname}/${subname}
		mkdir \
			-p \
			${fsldir}${subname}
		echo $subname
		N4BiasFieldCorrection \
			-i $subj \
			-o ${subpre}_biascorr.nii.gz
		bet \
			${subpre}_biascorr.nii.gz \
			${subpre}_biascorr-bet.nii.gz
		flirt \
			-omat ${subpre}_biascorr-bet2std.mat \
			-in ${subpre}_biascorr-bet.nii.gz \
			-ref ${fsldir}design/mni-bet.nii.gz \
			-out ${subpre}_biascorr-bet2std.nii.gz
		run_first_all -a ${subpre}_biascorr-bet2std.mat \
			-s L_Accu,L_Amyg,L_Caud,L_Hipp,L_Pall,L_Puta,L_Thal,R_Accu,R_Amyg,R_Caud,R_Hipp,R_Pall,R_Puta,R_Thal \
			-b \
			-i ${subpre}_biascorr-bet.nii.gz \
			-o ${subpre}_first
		mv $subj ${fsldir}processed/
	done
	first_roi_slicesdir ${fsldir}sub*/sub*biascorr.nii.gz ${fsldir}sub*/sub*firstseg.nii.gz
	mv slicesdir ${fsldir}slicesdir_seg
	${FSLDIR}/bin/slicesdir -p ${fsldir}design/mni.nii.gz ${fsldir}sub*/sub*biascorr-bet2std.nii.gz
	mv slicesdir ${fsldir}slicesdir_reg

## Concatenation, weighting, and randomise

	for region in L_Accu L_Amyg L_Caud L_Hipp L_Pall L_Puta L_Thal R_Accu R_Amyg R_Caud R_Hipp R_Pall R_Puta R_Thal
	do
		rm ${fsldir}design/${region}.bvars
		mkdir -p ${fsldir}design/${region}
		concat_bvars ${fsldir}design/${region}.bvars ${fsldir}sub*/sub*first-${region}_first.bvars
		first_utils --vertexAnalysis \
			--usebvars \
			-i ${fsldir}design/${region}.bvars \
			-d ${fsldir}design/$design \
			-o ${fsldir}design/${region}/${design%%.*}_${region} \
			--useReconMNI \
			-v >& ${fsldir}design/${region}/log_${design%%.*}_${region}.txt
		randomise -i ${fsldir}design/${region}/${design%%.*}_${region}.nii.gz \
			-m ${fsldir}design/${region}/${design%%.*}_${region}_mask.nii.gz \
			-o ${fsldir}design/${region}/${design%%.*}_${region} \
			-d ${fsldir}design/${design} \
			-t ${fsldir}design/${contrast} \
			-T 
		cp ${fsldir}design/${region}/*mask.nii.gz ${surfdirfsl}/${imgmod}_${region}_base.nii.gz
		cp ${fsldir}design/${region}/*tfce*1.nii.gz ${surfdirfsl}/${imgmod}_${region}_hc-ptc.nii.gz
		cp ${fsldir}design/${region}/*tfce*1.nii.gz ${fsldir}design/Extras/Display_Volumes/${testno}/${imgmod}_${region}_hc-ptc.nii.gz
		cp ${fsldir}design/${region}/*tfce*2.nii.gz ${surfdirfsl}/${imgmod}_${region}_ptc-hc.nii.gz
		cp ${fsldir}design/${region}/*tfce*2.nii.gz ${fsldir}design/Extras/Display_Volumes/${testno}/${imgmod}_${region}_ptc-hc.nii.gz
	done

# Volume estimation

	rm ${fsldir}design/Extras/Volumes/voxels_volumes.csv
	for subj in ${fsldir}sub*
	do
		subname=${subj#*fslanat/} 
		echo ${subname}_vox ${subname}_vols NA > ${fsldir}design/Extras/Volumes/${subname}_vols.csv
		fslstats -t ${subj}/sub*_origsegs.nii.gz -V >> ${fsldir}design/Extras/Volumes/${subname}_vols.csv
	done
	paste -d ' ' ${fsldir}design/Extras/Volumes/*vols.csv > ${fsldir}design/Extras/Volumes/voxels_volumes.csv
	rm ${fsldir}design/Extras/Volumes/*_vols.csv
	cp ${fsldir}design/Extras/Volumes/voxels_volumes.csv ${rdirfsl}${imgmod}_volumes.csv
	
	rm ${fsldir}design/Extras/Volumes/shapemin_shapemax.csv
	for scan in ${fsldir}design/Extras/Display_Volumes/${testno}/*ptc*
	do
		scanname=${scan#*/}
		scanlabel=${scanname%%.nii.gz}
		echo ${scanlabel}_min ${scanlabel}_max NA > ${fsldir}design/Extras/Volumes/${scanlabel}_shapesigs.csv
		fslstats $scan -R >> ${fsldir}design/Extras/Volumes/${scanlabel}_shapesigs.csv
	done
	paste -d ' ' ${fsldir}design/Extras/Volumes/*sigs.csv > ${fsldir}design/Extras/Volumes/shapemin_shapemax.csv
	rm ${fsldir}design/Extras/Volumes/*sigs.csv
	cp ${fsldir}design/Extras/Volumes/shapemin_shapemax.csv ${rdirfsl}${imgmod}_shapes.csv
done

# Calculating Dice Coefficients 

# Preparing the environment - RUN AS A DISCRETE BLOCK
# Thresholding, binarising, and creating overlap volumes

if [[ ! -e ${rdir}ints.txt ]]
then
	mrdump \
		${SUBJECTS_DIR}/bert/mri/aparc.a2009s+aseg.mgz \
		-mask ${SUBJECTS_DIR}/bert/mri/aparc.a2009s+aseg.mgz \
		${rdir}ints.txt
fi
if [[ ! -e ${rdir}ints_dl.txt ]]
then
	mrdump \
		${derivdir}dldir/sub-001/T1w_norm_seg.nii.gz \
		-mask ${derivdir}dldir/sub-001/T1w_norm_seg.nii.gz \
		${rdir}ints_dl.txt
fi
if [[ ! -e ${rdir}ints_all.txt ]]
then
	cat \
		${rdir}ints.txt \
		${rdir}ints_dl.txt > ${rdir}ints_all.txt
fi
ints=(${(u)$(<${rdir}ints_all.txt)})
for i in fs fsc
do
	if [ $i '==' 'fs' ]
	then
		declare -a imgmods=('iso' 'aniso' 'res' 'synth' 'dldir')
	elif [ $i '==' 'fsc' ]
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
			if [ ! $imgmod == dldir ]
			then
				startvol=${derivdir}${imgmod}_${i}/${ptc}_${imgmod}/mri/aparc.a2009s+aseg.nii.gz
				mri_convert \
					${derivdir}${imgmod}_${i}/${ptc}_${imgmod}/mri/aparc.a2009s+aseg.mgz \
					${startvol}
				if [ ! $imgmod == iso ] || [ ! $i == fs ]
				then
					flirtvol=${derivdir}${imgmod}_${i}/${ptc}_${imgmod}/mri/aparc.a2009s+aseg-affine.nii.gz
					flirt \
						-in ${startvol} \
						-ref ${derivdir}iso_fs/${ptc}_iso/mri/aparc.a2009s+aseg.nii.gz \
						-interp nearestneighbour \
						-dof 6 \
						-o ${flirtvol}
				else
					flirtvol=${derivdir}${imgmod}_${i}/${ptc}_${imgmod}/mri/aparc.a2009s+aseg.nii.gz
				fi
			else
				startvol=${derivdir}dldir/${ptc}/T1w_norm_seg.nii.gz
				flirtvol=${derivdir}dldir/${ptc}/T1w_norm_reg.nii.gz
				flirt \
					-in ${startvol} \
					-ref ${derivdir}iso_fs/${ptc}_iso/mri/aparc.a2009s+aseg.nii.gz \
					-interp nearestneighbour \
					-dof 6 \
					-o ${flirtvol}
			fi
			for parc in ${ints[@]}
			do
				fslmaths \
					$flirtvol \
					-thr ${parc} \
					-uthr ${parc} \
					-bin ${sub}_${parc}_bin.nii.gz
			done
			if [ ! $imgmod == dldir ]
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
				if [ ! $imgmod == iso ] || [ ! $i == fs ]
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

# Recording the overlap volumes as csv files, and collating them

ints=(${(u)$(<${rdir}ints_dl.txt)})

for imgmod in aniso_fs aniso_fsc dldir_fs iso_fs iso_fsc res_fs res_fsc synth_fs
do
	for subpath in ${derivdir}iso/*
	do
		subfile=${subpath##*/iso/}
		ptc=${subfile%%_iso.nii.gz}
		sub=${derivdir}dice_fs/${imgmod}/${ptc}/${ptc}
		echo ${ptc} > ${derivdir}dice_fs/${imgmod}/${ptc}/vol.tsv
		for parc in ${ints[@]}
		do
			binvol=$(fslstats ${sub}_${parc}_bin.nii.gz -V | awk '{print $2}')
			echo $binvol >> ${derivdir}dice_fs/${imgmod}/${ptc}/vol.tsv
		done
		if [ ! $imgmod == iso_fs ]
		then
			echo ${ptc} > ${derivdir}dice_fs/${imgmod}/${ptc}/ovl.tsv
			for parc in ${ints[@]}
			do
				ovlvol=$(fslstats ${sub}_${parc}_ovl.nii.gz -V | awk '{print $2}')
				echo $ovlvol >> ${derivdir}dice_fs/${imgmod}/${ptc}/ovl.tsv
			done
		fi
	done
	paste -d '\t' ${derivdir}dice_fs/${imgmod}/*/vol.tsv > ${derivdir}dice_fs/${imgmod}-vol.tsv
	if [ ! $imgmod == iso ]
	then
		paste -d '\t' ${derivdir}dice_fs/${imgmod}/*/ovl.tsv > ${derivdir}dice_fs/${imgmod}-ovl.tsv
	fi
done

# Copying the volume csv files to the r directory

for i in ${derivdir}dice_fs/*l.tsv
do
	cp $i ${rdirdice}
done

# Visualising alignment

for subpath in ${derivdir}iso/*019*
do
	subfile=${subpath##*/iso/}
	ptc=${subfile%%_iso.nii.gz}
	sub=${derivdir}iso_fs/${ptc}_iso/mri/aparc.a2009s+aseg.nii.gz
	mrview \
		$sub \
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
		-overlay.load ${derivdir}aniso_fsc/${ptc}_aniso/mri/aparc.a2009s+aseg-affine.nii.gz \
		-overlay.colour 145,30,180 \
		-overlay.threshold_min 200 \
		-overlay.interpolation 0 \
		-overlay.load ${derivdir}res_fsc/${ptc}_res/mri/aparc.a2009s+aseg-affine.nii.gz \
		-overlay.colour 70,240,240 \
		-overlay.threshold_min 200 \
		-overlay.interpolation 0 \
		-overlay.load ${derivdir}synth_fsc/${ptc}_synth/mri/aparc.a2009s+aseg-affine.nii.gz \
		-overlay.colour 255,225,25 \
		-overlay.threshold_min 200 \
		-overlay.interpolation 0
done

