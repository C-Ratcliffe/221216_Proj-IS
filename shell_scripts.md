### Preprocessing with DL+DiReCT and SynthSR

#### Environment creation and package installation

conda create -y -n DL_DiReCT python=3.10
conda activate DL_DiReCT
cd ${HOME}
git clone https://github.com/SCAN-NRAD/DL-DiReCT.git
cd DL-DiReCT
pip install numpy && pip install -e

conda create -n synthsr python=3.6
conda activate synthsr
cd ~/anaconda3/envs/synthsr/lib/synthsr/
pip install -r requirements.txt
pip install tensorflow-directml

#### Preparing the environment

derivdir=~/studydir/derivatives/
rdir=~/rstatsdir/
surfdir=~/surficedir/
declare -a subs=('sub-001' ... 'sub-070')
declare -a imgmods=('iso' 'aniso' 'res' 'synthsr')

#### Rename files to encourage homogeneity

find . -name "*acq-3D_T1w.nii.gz" -exec rename 's/acq-3D_T1w/iso/' {} ";"
find . -name "*acq-2D_T1w.nii.gz" -exec rename 's/acq-2D_T1w/aniso/' {} ";"

#### Preprocessing

export FREESURFER_HOME=~/freesurfer
source $FREESURFER_HOME/SetUpFreeSurfer.sh
    
for sub in ${subs[@]}
    do
    conda activate DL_DiReCT
    dl+direct --model v7 --subject $sub --bet ${derivdir}res/input/${sub}* \
        ${derivdir}res/${sub} --lowmem --keep --no-cth
    mv ${derivdir}res/input/${sub}* ${derivdir}res/processed/
    cp ${derivdir}res/${sub}/T1w_norm.nii.gz ${derivdir}res_freesurfer/input/${sub}_res.nii.gz
    cp ${derivdir}res/${sub}/T1w_norm.nii.gz ${derivdir}res_fslanat/input/${sub}_res.nii.gz
    cp ${derivdir}res/${sub}/T1w_norm_noskull.nii.gz ${derivdir}res_dldirect/input/${sub}_res.nii.gz
    dl+direct --model v7 --subject $sub ${derivdir}res_dldirect/input/${sub}* \
        ${derivdir}res_dldirect/${sub} --lowmem --keep
    mv ${derivdir}res_dldirect/input/${sub}* ${derivdir}res_dldirect/processed/
    conda deactivate
    conda activate synthsr
    mkdir -p ${derivdir}synthsr/${sub}/
    python ~/anaconda3/envs/synthsr/lib/synthsr/scripts/predict_command_line.py \
        ${derivdir}synthsr/input/${sub}* \
        ${derivdir}synthsr/${sub}/${sub}_synthsr --cpu
    mv ${derivdir}synthsr/input/${sub}* ${derivdir}synthsr/processed/
    cp ${derivdir}synthsr/${sub}/${sub}_synthsr.nii ${derivdir}synthsr_freesurfer/input/
    cp ${derivdir}synthsr/${sub}/${sub}_synthsr.nii ${derivdir}synthsr_fslanat/input/
    conda deactivate
done

for imgmod in ${imgmods[@]}
	do
	fsldir=$(printf "${derivdir}${imgmod}_fslanat/")
	for nifti in ${fsldir}input/*.nii
		do
		gzip $nifti
	done
done

### Surface-based Morphometry with FreeSurfer

#### Preparing the environment

rdirfs=${rdir}measurements_fs/
declare -a measurescort=('volume' 'thickness')
declare -a measuressubcort=('volume')
declare -a hemis=('lh' 'rh')

mkdir -p ${rdirfs}

#### Reconstructing with FreeSurfer

for sub in ${subs[@]}
    do
    for imgmod in ${imgmods[@]}
        do
        recon-all -s ${sub}_${imgmod} -i ${derivdir}${imgmod}_freesurfer/input/${sub}* -all -qcache -3T -openmp 2
        mv ${derivdir}${imgmod}_freesurfer/input/${sub}* ${derivdir}${imgmod}_freesurfer/processed
        mv -r ${SUBJECTS_DIR}/${sub}_${imgmod} ${derivdir}${imgmod}_freesurfer/
    done
done

#### Aparcstats2table and Asegstats2table    

for imgmod in ${imgmods[@]}
    do
    for meas in ${measurescort[@]}
        do
        for hemi in ${hemis[@]}
            do
            aparcstats2table --skip \
                --subjects ${derivdir}${imgmod}_freesurfer/sub* \
                --parc aparc.a2009s \
                --hemi $hemi \
                --measure $meas \
                --delimiter comma \
                --tablefile ${rdirfs}${imgmod}-da_${hemi}_${meas}_uncut.csv
            cut -f 2-75 -d, ${rdirfs}${imgmod}-da_${hemi}_${meas}_uncut.csv > ${rdirfs}${imgmod}-da_${hemi}_${meas}.csv
            rm ${rdirfs}${imgmod}-da_${hemi}_${meas}_uncut.csv
        done
        paste -d ' ,' ${rdirfs}${imgmod}-da_*_${meas}.csv > ${rdirfs}${imgmod}-cort_${meas}.csv
        rm ${rdirfs}${imgmod}-da_lh_${meas}.csv ${rdirfs}${imgmod}-da_rh_${meas}.csv
    done
    for meas in ${measuressubcort[@]}
        do
        asegstats2table --skip \
            --subjects ${derivdir}${imgmod}_freesurfer/sub* \
            --meas $meas \
            --delimiter comma \
            --tablefile ${rdirfs}${imgmod}-aseg_${meas}_uncut.csv
        cut -f 2-65 -d, ${rdirfs}${imgmod}-aseg_${meas}_uncut.csv > ${rdirfs}${imgmod}-aseg_${meas}.csv
        rm ${rdirfs}${imgmod}-aseg_${meas}_uncut.csv
        if [ $meas '==' 'Area_mm2' ]
            then
            mv ${rdirfs}${imgmod}-aseg_${meas}.csv ${rdirfs}${imgmod}-aseg_area_uncut.csv
            #cut -f 2-65 -d, ${rdirfs}${imgmod}-aseg_area_uncut.csv > ${rdirfs}${imgmod}-aseg_area.csv
            rm ${rdirfs}${imgmod}-aseg_area_uncut.csv
        fi
    done
done

awk '(NR == 1) || (FNR > 1)' ${derivdir}res_dldirect/sub*/result-thick.csv > ${rdirfs}dldirect-da_bi_thick.csv
awk '(NR == 1) || (FNR > 1)' ${derivdir}res_dldirect/sub*/result-thickstd.csv > ${rdirfs}dldirect-da_bi_thickstd.csv
awk '(NR == 1) || (FNR > 1)' ${derivdir}res_dldirect/sub*/result-vol.csv > ${rdirfs}dldirect-da_bi_vol.csv
cut -f 2-32 -d, ${rdirfs}dldirect-da_bi_vol.csv > ${rdirfs}dldirect-aseg_volume.csv
cut -f 33-180 -d, ${rdirfs}dldirect-da_bi_vol.csv > ${rdirfs}dldirect-da_bi_volume.csv
cut -f 2-149 -d, ${rdirfs}dldirect-da_bi_thick.csv > ${rdirfs}dldirect-da_bi_thickness.csv
cut -f 2-149 -d, ${rdirfs}dldirect-da_bi_thickstd.csv > ${rdirfs}dldirect-da_bi_thicknessstd.csv
rm ${rdirfs}dldirect-da_bi_vol.csv ${rdirfs}dldirect-da_bi_thick.csv ${rdirfs}dldirect-da_bi_thickstd.csv

### Subcortical Surface Shape with FSL

#### Preprocessing

rdirfsl=${rdir}measurements_fsl/
surfdirfsl=${surfdir}fsl/

for imgmod in ${imgmods[@]}
	do
	fsldir=$(printf "${derivdir}${imgmod}_fslanat/")	#subject directory
	res=1																							#resolution of the reference image
	preproc=yes																				#carry out preprocessing and segmentation
	concat=yes																				#carry out concatenation of the bvars
	group=yes																					#carry out group level comparisons with randomise
	test=tstat1																				#carry out t- or f- tests
	testno=9																					#label for the hypothesis testing
	design=design2.mat																#name of the design matrix
	contrast=contrast1.con														#name of the contrast file
	ftest=ftest1.fts																	#name of the f-test file

	mkdir -p ${fsldir}design/Extras/Display_Volumes/${testno} ${fsldir}design/Extras/Screenshots ${fsldir}processed ${fsldir}design/Extras/Volumes ${rdirfsl} ${surfdirfsl}

##### Segmentation

	cp ${FSLDIR}/data/standard/MNI152_T1_${res}mm.nii.gz ${fsldir}design/mni.nii.gz
	bet ${fsldir}design/mni.nii.gz ${fsldir}design/mni-bet.nii.gz

	for subj in ${fsldir}input/*.nii.gz
		do
		subname=$(grep -E -o 'sub-[0-9][0-9][0-9]' <<< $subj)
		subpre=${fsldir}${subname}/${subname}
		mkdir -p ${fsldir}${subname}
		echo $subname
		N4BiasFieldCorrection -i $subj -o ${subpre}_biascorr.nii.gz
		bet ${subpre}_biascorr.nii.gz ${subpre}_biascorr-bet.nii.gz
		flirt -omat ${subpre}_biascorr-bet2std.mat \
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

##### Concatenation, weighting, and randomise

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

#### Volume estimation

	rm ${fsldir}design/Extras/Volumes/voxels_volumes.csv
	for subj in ${fsldir}sub*
		do
		subname=${subj##*fslanat/} 
		echo ${subname}_vox ${subname}_vols NA > ${fsldir}design/Extras/Volumes/${subname}_vols.csv
		fslstats -t ${subj}/sub*_origsegs.nii.gz -V >> ${fsldir}design/Extras/Volumes/${subname}_vols.csv
	done
	paste -d ' ' ${fsldir}design/Extras/Volumes/*vols.csv > ${fsldir}design/Extras/Volumes/voxels_volumes.csv
	rm ${fsldir}design/Extras/Volumes/*_vols.csv
	cp ${fsldir}design/Extras/Volumes/voxels_volumes.csv ${rdirfsl}${imgmod}_volumes.csv
	
	rm ${fsldir}design/Extras/Volumes/shapemin_shapemax.csv
	for scan in ${fsldir}design/Extras/Display_Volumes/${testno}/*ptc*
		do
		scanname=${scan##*/}
		scanlabel=${scanname%%.nii.gz}
		echo ${scanlabel}_min ${scanlabel}_max NA > ${fsldir}design/Extras/Volumes/${scanlabel}_shapesigs.csv
		fslstats $scan -R >> ${fsldir}design/Extras/Volumes/${scanlabel}_shapesigs.csv
	done
	paste -d ' ' ${fsldir}design/Extras/Volumes/*sigs.csv > ${fsldir}design/Extras/Volumes/shapemin_shapemax.csv
	rm ${fsldir}design/Extras/Volumes/*sigs.csv
	cp ${fsldir}design/Extras/Volumes/shapemin_shapemax.csv ${rdirfsl}${imgmod}_shapes.csv
done

### Calculating Dice Coefficients

#### Preparing the environment
    
rdirdice=${rdir}measurements_dice/
declare -a imgmods=('iso' 'aniso' 'res' 'dldirect' 'synthsr')
declare -a metas=('subs' 'ints' 'labels')

for meta in ${metas[@]}
    do
    #cp ~/rstats_directory/resources/dice_${meta}.csv ${derivdir}dice_fs/
    readarray -t $meta < <(tail -n +2 ${derivdir}dice_fs/dice_${meta}.csv)
done

declare -a ints=('2' ... '12175') #All of the FreeSurfer integer labels

mkdir -p ${rdirdice}

#### Thresholding, binarising, and creating overlap volumes

for ptc in ${subs[@]}
    do
    for imgmod in ${imgmods[@]}
        do
        mkdir -p ${derivdir}dice_fs/${imgmod}/${ptc}/
        if [ ! $imgmod == dldirect ]
            then
            startmgz=${derivdir}${imgmod}_freesurfer/${ptc}_${imgmod}/mri/aparc.a2009s+aseg.mgz
            startvol=${derivdir}${imgmod}_freesurfer/${ptc}_${imgmod}/mri/aparc.a2009s+aseg.nii.gz
            mri_convert $startmgz $startvol
        elif
            startvol=${derivdir}res_dldirect/${ptc}/T1w_norm_seg.nii.gz
        fi
        for parc in ${ints[@]}
            do
            thlvol=${derivdir}dice_fs/${imgmod}/${ptc}/${ptc}_${parc}_thl.nii.gz
            thuvol=${derivdir}dice_fs/${imgmod}/${ptc}/${ptc}_${parc}_thu.nii.gz
            binvol=${derivdir}dice_fs/${imgmod}/${ptc}/${ptc}_${parc}_bin.nii.gz
            fslmaths $startvol -thr ${parc} $thlvol
            fslmaths $thlvol -uthr ${parc} $thuvol
            fslmaths $thuvol -bin $binvol
            rm $thlvol $thuvol
        done
        if [ ! $imgmod == dldirect ]
            then
            volcl=${derivdir}dice_fs/${imgmod}/${ptc}/${ptc}_104_bin.nii.gz
            volrl=${derivdir}dice_fs/${imgmod}/${ptc}/${ptc}_117_bin.nii.gz
            volcc=${derivdir}dice_fs/${imgmod}/${ptc}/${ptc}_130_bin.nii.gz
            fslmaths ${derivdir}dice_fs/${imgmod}/${ptc}/${ptc}_7_bin.nii.gz -add ${derivdir}dice_fs/${imgmod}/${ptc}/${ptc}_8_bin.nii.gz $volcl
            fslmaths ${derivdir}dice_fs/${imgmod}/${ptc}/${ptc}_46_bin.nii.gz -add ${derivdir}dice_fs/${imgmod}/${ptc}/${ptc}_47_bin.nii.gz $volrl
            fslmaths ${derivdir}dice_fs/${imgmod}/${ptc}/${ptc}_251_bin.nii.gz -add ${derivdir}dice_fs/${imgmod}/${ptc}/${ptc}_252_bin.nii.gz \
                -add ${derivdir}dice_fs/${imgmod}/${ptc}/${ptc}_253_bin.nii.gz -add ${derivdir}dice_fs/${imgmod}/${ptc}/${ptc}_254_bin.nii.gz \
                -add ${derivdir}dice_fs/${imgmod}/${ptc}/${ptc}_255_bin.nii.gz $volcc
        fi
        for parc in ${ints[@]}
            do            
            if [ ! $imgmod == iso ]
                then
                natvol=${derivdir}dice_fs/raw/${ptc}/${ptc}_${parc}_bin.nii.gz
                ovlvol=${derivdir}dice_fs/${imgmod}/${ptc}/${ptc}_${parc}_ovl.nii.gz
                fslmaths $binvol -mul $natvol $ovlvol
            fi
        done
    done
done

#### Recording the overlap volumes as csv files, and collating them

declare -a ints=('2' ... '12175') #All of the FreeSurfer integer labels that are common with the truncated DL+DiReCT output

for imgmod in ${imgmods[@]}
    do
    for ptc in ${subs[@]}
        do
        echo ${ptc}_vox ${ptc}_vols NA > ${derivdir}dice_fs/${imgmod}/${ptc}/vol.csv
        for parc in ${ints[@]}
            do
            fslstats ${derivdir}dice_fs/${imgmod}/${ptc}/${ptc}_${parc}_bin.nii.gz -V >> ${derivdir}dice_fs/${imgmod}/${ptc}/vol.csv
        done
        if [ ! $imgmod == iso ]
            then
            echo ${ptc}_vox ${ptc}_vols NA > ${derivdir}dice_fs/${imgmod}/${ptc}/ovl.csv
            for parc in ${ints[@]}
                do
                fslstats ${derivdir}dice_fs/${imgmod}/${ptc}/${ptc}_${parc}_ovl.nii.gz -V >> ${derivdir}dice_fs/${imgmod}/${ptc}/ovl.csv
            done
        fi
    done
    paste -d ' ' ${derivdir}dice_fs/${imgmod}/*/vol.csv > ${derivdir}dice_fs/${imgmod}-vol.csv
    if [ ! $imgmod == iso ]
        then
        paste -d ' ' ${derivdir}dice_fs/${imgmod}/*/ovl.csv > ${derivdir}dice_fs/${imgmod}-ovl.csv
    fi
done

#### Copying the volume csv files to the r directory

for i in ${derivdir}dice_fs/*l.csv
    do
    cp $i ${rdirdice}
done