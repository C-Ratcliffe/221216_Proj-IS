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
declare -a subs=('sub-001' ... 'sub-070')
declare -a imgmods=('raw' 'aniso' 'dldirect' 'synthsr')

#### Preprocessing

export FREESURFER_HOME=~/freesurfer
source $FREESURFER_HOME/SetUpFreeSurfer.sh
    
for sub in ${subs[@]}
    do
    conda activate DL_DiReCT
    dl+direct --model v7 --subject $sub --bet ${derivdir}dldirect/input/${sub}* \
        ${derivdir}dldirect/${sub} --lowmem --keep --no-cth
    mv ${derivdir}dldirect/input/${sub}* ${derivdir}dldirect/processed/
    cp ${derivdir}dldirect/${sub}/T1w_norm.nii.gz ${derivdir}dldirect_freesurfer/input/${sub}_dldirect.nii.gz
    cp ${derivdir}dldirect/${sub}/T1w_norm.nii.gz ${derivdir}dldirect_fslanat/input/${sub}_dldirect.nii.gz
    cp ${derivdir}dldirect/${sub}/T1w_norm_noskull.nii.gz ${derivdir}dldirect_dlseg/input/${sub}_dldirect.nii.gz
    dl+direct --model v7 --subject $sub ${derivdir}dldirect_dlseg/input/${sub}* \
        ${derivdir}dldirect_dlseg/${sub} --lowmem --keep
    mv ${derivdir}dldirect_dlseg/input/${sub}* ${derivdir}dldirect_dlseg/processed/
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

### Surface-based Morphometry with FreeSurfer

#### Preparing the environment

rdir=~/rstats_directory/
declare -a measurescort=('volume' 'thickness')
declare -a measuressubcort=('volume' 'Area_mm2' 'nvoxels' 'nvertices' 'mean' 'std' 'snr' 'max')
declare -a hemis=('lh' 'rh')

mkdir -p $rdir

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
                --tablefile ${rdir}synth_fs${imgmod}-da_${hemi}_${meas}_uncut.csv
            cut -f 2-75 -d, ${rdir}synth_fs${imgmod}-da_${hemi}_${meas}_uncut.csv > ${rdir}synth_fs${imgmod}-da_${hemi}_${meas}.csv
            rm ${rdir}synth_fs${imgmod}-da_${hemi}_${meas}_uncut.csv
        done
        paste -d ' ,' ${rdir}synth_fs${imgmod}-da_*_${meas}.csv > ${rdir}synth_fs${imgmod}-da_bi_${meas}.csv
        rm ${rdir}synth_fs${imgmod}-da_lh_${meas}.csv ${rdir}synth_fs${imgmod}-da_rh_${meas}.csv
    done
    for meas in ${measuressubcort[@]}
        do
        asegstats2table --skip \
            --subjects ${derivdir}${imgmod}_freesurfer/sub* \
            --meas $meas \
            --delimiter comma \
            --tablefile ${rdir}synth_fs${imgmod}-aseg_bi_${meas}_uncut.csv
        cut -f 2-65 -d, ${rdir}synth_fs${imgmod}-aseg_bi_${meas}_uncut.csv > ${rdir}synth_fs${imgmod}-aseg_bi_${meas}.csv
        rm ${rdir}synth_fs${imgmod}-aseg_bi_${meas}_uncut.csv
        if [ $meas '==' 'Area_mm2' ]
            then
            mv ${rdir}synth_fs${imgmod}-aseg_bi_${meas}.txt ${rdir}synth_fs${imgmod}-aseg_bi_area_uncut.csv
            #cut -f 2-65 -d, ${rdir}synth_fs${imgmod}-aseg_bi_area_uncut.csv > ${rdir}synth_fs${imgmod}-aseg_bi_area.csv
            rm ${rdir}synth_fs${imgmod}-aseg_bi_area_uncut.csv
        fi
    done
done

awk '(NR == 1) || (FNR > 1)' ${derivdir}dldirect_dlseg/sub*/result-thick.csv > ${rdir}synth_fsdlseg-da_bi_thick.csv
awk '(NR == 1) || (FNR > 1)' ${derivdir}dldirect_dlseg/sub*/result-thickstd.csv > ${rdir}synth_fsdlseg-da_bi_thickstd.csv
awk '(NR == 1) || (FNR > 1)' ${derivdir}dldirect_dlseg/sub*/result-vol.csv > ${rdir}synth_fsdlseg-da_bi_vol.csv
cut -f 2-32 -d, ${rdir}synth_fsdlseg-da_bi_vol.csv > ${rdir}synth_fsdlseg-aseg_bi_volume.csv
cut -f 33-180 -d, ${rdir}synth_fsdlseg-da_bi_vol.csv > ${rdir}synth_fsdlseg-da_bi_volume.csv
cut -f 2-149 -d, ${rdir}synth_fsdlseg-da_bi_thick.csv > ${rdir}synth_fsdlseg-da_bi_thickness.csv
cut -f 2-149 -d, ${rdir}synth_fsdlseg-da_bi_thickstd.csv > ${rdir}synth_fsdlseg-da_bi_thicknessstd.csv
rm ${rdir}synth_fsdlseg-da_bi_vol.csv ${rdir}synth_fsdlseg-da_bi_thick.csv ${rdir}synth_fsdlseg-da_bi_thickstd.csv

### Subcortical Surface Shape with FSL

#### Preparing the environment

for imgmod in ${imgmods[@]}
    do
    SUBJECT_DIR=$(printf "/studydir/derivatives/${imgmod}_fslanat/")
    RES=1
    TYPE=ANAT_FIRST
    CONCAT=YES
    TEST=tstat1
    TESTNO=1
    DESIGN=design/design.mat
    CONTRAST=design/contrast.con
    FTEST=design/ftest.fts
    GROUP=YES

    cd $SUBJECT_DIR
    mkdir -p design/Extras/Display_Volumes/${TESTNO} design/Extras/Screenshots processed design/Extras/Volumes

    #### Segmentation

    if [ $TYPE == 'ANAT' ] || [ $TYPE == 'ANAT_FIRST' ]
        then
        for NAME in ${subs[@]}
            do 
            sub=$(grep -E -o 'sub-[0-9][0-9][0-9]' <<< $NAME) 
            fsl_anat -i input/${sub}* \
                -o ${sub}
            mv input/${sub}* processed
        done
        if [ $TYPE == 'ANAT_FIRST' ]
            then
            for DIRECTORY in sub* 
                do 
                cd $DIRECTORY 
                rm -rf first_results 
                flirt -omat T1_biascorr_to_std_sub.mat \
                    -in T1_biascorr.nii.gz \
                    -ref ${FSLDIR}/data/standard/MNI152_T1_${RES}mm \
                    -out T1_biascorr_to_std_sub.nii.gz 
                mkdir -p first_results 
                run_first_all -a T1_biascorr_to_std_sub.mat \
                    -s L_Accu,L_Amyg,L_Caud,L_Hipp,L_Pall,L_Puta,L_Thal,R_Accu,R_Amyg,R_Caud,R_Hipp,R_Pall,R_Puta,R_Thal \
                    -i T1_biascorr.nii.gz \
                    -o first_results/T1_first 
                cd $SUBJECT_DIR
            done
            first_roi_slicesdir *.anat/T1_biascorr.nii.gz *.anat/first_results/*firstseg.nii.gz
            mv slicesdir slicesdir_seg
            ${FSLDIR}/bin/slicesdir -p ${FSLDIR}/data/standard/MNI152_T1_0.5mm.nii.gz */*_to_std_sub.nii.gz
            mv slicesdir slicesdir_reg
        else
            echo "ANAT segmentations used"
        fi
    else
        echo "Registration skipped"
    fi

    #### Concatenation and weighting

    if [ $CONCAT == 'YES' ]
        then
        for hemi in L R;
            do 
            for REGION in Accu Amyg Caud Hipp Pall Puta Thal
                do
                rm design/${hemi}_${REGION}.bvars
                concat_bvars design/${hemi}_${REGION}.bvars *.anat/first_results/T1_first-${hemi}_${REGION}_first.bvars
            done
        done
        for REGION in design/*.bvars;
            do 
            mkdir -p ${REGION%.*};
        done
        for REGION in design/*.bvars;	
            do 
            first_utils --vertexAnalysis \
                --usebvars \
                -i $REGION \
                -d $DESIGN \
                -o ${REGION%.*}/$(basename $DESIGN .mat)_$(basename $REGION .bvars) \
                --useReconNative \
                --useRigidAlign \
                -v >& ${REGION%.*}/$(basename $DESIGN .mat)_$(basename $REGION .bvars)_log.txt;
        done
    else
        echo 'Concatenation and weighting skipped'
    fi

    #### Randomise and volume creation

    #Group level analyses are run, according to the specified TEST

    if [ $GROUP == 'YES' ]
        then for hemi in L R;
            do 
            for SUBJECT in design/${hemi}_*/;
                do 
                SUB_DESIGN=${SUBJECT}$(basename $DESIGN .mat)_$(basename $SUBJECT /)
                SUB_CONTRAST=${SUBJECT}$(basename $CONTRAST .con)_$(basename $SUBJECT /)
                END_VOL=design/Extras/Display_Volumes/${TESTNO}/$(basename $SUBJECT /)_$(basename $CONTRAST .con)
                if [ $TEST == 'tstat1' ]
                    then randomise -i ${SUB_DESIGN}.nii.gz \
                        -m ${SUB_DESIGN}_mask.nii.gz \
                        -o ${SUB_CONTRAST}_rand \
                        -d $DESIGN \
                        -t $CONTRAST \
                        -c 3 \
                        -D ;
                elif [ $TEST == 'fstat1' ]
                    then randomise -i ${SUB_DESIGN}.nii.gz \
                        -m ${SUB_DESIGN}_mask.nii.gz \
                        -o ${SUB_CONTRAST}_rand \
                        -d $DESIGN \
                        -t $CONTRAST \
                        -f $FTEST \
                        --fonly \
                        -F 3 \
                        -D ;
                else
                    echo 'Randomise skipped'
                fi
                first3Dview ${SUB_DESIGN}_mask.nii.gz \
                    ${SUB_CONTRAST}_rand_clustere_corrp_${TEST}.nii.gz 
                cp ${SUB_CONTRAST}_rand_clustere_corrp_${TEST}.nii.gz \
                    ${END_VOL}_sig.nii.gz
                cp ${SUB_CONTRAST}_rand_clustere_corrp_${TEST}_basestruct.nii.gz \
                    ${END_VOL}_base.nii.gz
                cp ${SUB_CONTRAST}_rand_clustere_corrp_${TEST}_filledstruct.nii.gz \
                    ${END_VOL}_wholevol.nii.gz
            done
        done
    else
        echo 'Group analysis skipped'
    fi

    #### Volume estimation
    
    SUBJECT_DIR=$(printf "~/studydir/derivatives/${imgmod}_fslanat/")
    cd $SUBJECT_DIR
    rm ${SUBJECT_DIR}design/Extras/Volumes/voxels_volumes.csv
    for SUBJECT in *.anat
        do 
        echo ${SUBJECT%.*}_vox ${SUBJECT%.*}_vols NA > ${SUBJECT_DIR}design/Extras/Volumes/${SUBJECT%.*}_vols.csv
        fslstats -t ${SUBJECT}/first_results/T1*_origsegs.nii.gz -V >> ${SUBJECT_DIR}design/Extras/Volumes/${SUBJECT%.*}_vols.csv
    done
    paste -d ' ' ${SUBJECT_DIR}design/Extras/Volumes/*vols.csv > ${SUBJECT_DIR}design/Extras/Volumes/voxels_volumes.csv
    rm ${SUBJECT_DIR}design/Extras/Volumes/*_vols.csv
    cp ${SUBJECT_DIR}design/Extras/Volumes/voxels_volumes.csv ${rdir}${imgmod}_volumes.csv
    rm ${SUBJECT_DIR}design/Extras/Volumes/shapemin_shapemax.csv
    for scan in design/Extras/Display_Volumes/${TESTNO}/*sig*
        do
        scanname=${scan##*/}
        scanlabel=${scanname%%_contrast*}
        echo ${scanlabel}_min ${scanlabel}_max NA > ${SUBJECT_DIR}design/Extras/Volumes/${scanlabel}_shapesigs.csv
        fslstats $scan -R >> ${SUBJECT_DIR}design/Extras/Volumes/${scanlabel}_shapesigs.csv
    done
    paste -d ' ' ${SUBJECT_DIR}design/Extras/Volumes/*sigs.csv > ${SUBJECT_DIR}design/Extras/Volumes/shapemin_shapemax.csv
    rm ${SUBJECT_DIR}design/Extras/Volumes/*sigs.csv
    cp ${SUBJECT_DIR}design/Extras/Volumes/shapemin_shapemax.csv ${rdir}${imgmod}_shapes.csv
done

### Calculating Dice Coefficients

#### Preparing the environment
    
dicedir=~${rdir}measurements_dice/
declare -a imgmods=('raw' 'aniso' 'dldirect' 'dlseg' 'synthsr')
declare -a metas=('subs' 'ints' 'labels')

for meta in ${metas[@]}
    do
    #cp ~/rstats_directory/resources/dice_${meta}.csv ${derivdir}dice_fs/
    readarray -t $meta < <(tail -n +2 ${derivdir}dice_fs/dice_${meta}.csv)
done

declare -a ints=('2' ... '12175') #All of the FreeSurfer integer labels

mkdir -p $dicedir

#### Thresholding, binarising, and creating overlap volumes

for ptc in ${subs[@]}
    do
    for imgmod in ${imgmods[@]}
        do
        mkdir -p ${derivdir}dice_fs/${imgmod}/${ptc}/
        if [ ! $imgmod == dlseg ]
            then
            startmgz=${derivdir}${imgmod}_freesurfer/${ptc}_${imgmod}/mri/aparc.a2009s+aseg.mgz
            startvol=${derivdir}${imgmod}_freesurfer/${ptc}_${imgmod}/mri/aparc.a2009s+aseg.nii.gz
            mri_convert $startmgz $startvol
        elif
            startvol=${derivdir}dldirect_dlseg/${ptc}/T1w_norm_seg.nii.gz
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
        if [ ! $imgmod == dlseg ]
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
            if [ ! $imgmod == raw ]
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
        if [ ! $imgmod == raw ]
            then
            echo ${ptc}_vox ${ptc}_vols NA > ${derivdir}dice_fs/${imgmod}/${ptc}/ovl.csv
            for parc in ${ints[@]}
                do
                fslstats ${derivdir}dice_fs/${imgmod}/${ptc}/${ptc}_${parc}_ovl.nii.gz -V >> ${derivdir}dice_fs/${imgmod}/${ptc}/ovl.csv
            done
        fi
    done
    paste -d ' ' ${derivdir}dice_fs/${imgmod}/*/vol.csv > ${derivdir}dice_fs/synth_${imgmod}-da_bi_vol.csv
    if [ ! $imgmod == raw ]
        then
        paste -d ' ' ${derivdir}dice_fs/${imgmod}/*/ovl.csv > ${derivdir}dice_fs/synth_${imgmod}-da_bi_ovl.csv
    fi
done

#### Copying the volume csv files to the r directory

for i in ${derivdir}dice_fs/synth*.csv
    do
    cp $i $dicedir
done