#!/bin/bash

REPO_DIR=/home/xpp/pynq_git
PYNQ_DIR=/usr/local/lib/python3.4/dist-packages/pynq
BACKUP_DIR=/home/xpp/pynq_backup

FINAL_DOCS_DIR=/home/xpp/docs
FINAL_NOTEBOOKS_DIR=/home/xpp/jupyter_notebooks
FINAL_SCRIPTS_DIR=/home/xpp/scripts

GS_NOTEBOOK_IMAGES="edit_mode.png
dashboard_running_tab.png
python_logo.svg
dashboard_files_tab_run.png
zybo_io_opt.jpeg
command_mode.png
zybo_io.jpeg
dashboard_files_tab_new.png
dashboard_files_tab.png
menubar_toolbar.png
dashboard_files_tab_btns.png
zyboaudiovideo.jpg
Pmods_opt.png
pmod_closeup_opt.jpeg
pmod_pins_opt.png
Pmod_Grove_Adapter_opt.jpeg
tmp2_8pin_opt.jpeg
iop.jpg
zybopmods_opt.jpeg
pmodio_overlay_1_opt.png
als_oled_Demo_opt.jpeg
adc_dac_demo_opt.jpeg"


if ! [ $(id -u) = 0 ]; then
   echo "to be run with sudo"
   exit 1
fi
 
if [ -d $REPO_DIR ] || [ -d $BACKUP_DIR ] ; then
   echo ""
   echo "please manually remove git backup folders before running this script."
   echo "rm -rf ${REPO_DIR} ${BACKUP_DIR}"
   echo ""
   exit 1
fi

echo "1. Backing up files into ${BACKUP_DIR}"
mkdir $BACKUP_DIR
cp -r $FINAL_DOCS_DIR $FINAL_NOTEBOOKS_DIR $FINAL_SCRIPTS_DIR $BACKUP_DIR

echo "2. Build docs"
git clone https://github.com/Xilinx/PYNQ $REPO_DIR
cd $REPO_DIR/docs
sphinx-apidoc -f -o ./source $PYNQ_DIR
python3 ipynb_post_processor.py
make clean ; make html

echo "3. Transfer Git files into final filesystem with correct ownership"
rm -rf $FINAL_DOCS_DIR/* $FINAL_NOTEBOOKS_DIR/* 
cp -r $REPO_DIR/docs/build/html/* $FINAL_DOCS_DIR
cp -r $REPO_DIR/$BOARD/notebooks/* $FINAL_NOTEBOOKS_DIR
cp -r $REPO_DIR/ubuntu/scripts/hostname.sh $FINAL_SCRIPTS_DIR
cp -r $REPO_DIR/ubuntu/scripts/*.py $FINAL_SCRIPTS_DIR
pushd $FINAL_NOTEBOOKS_DIR ; ln -s $FINAL_DOCS_DIR ; popd
pushd $REPO_DIR/docs/source/temp
for f in *.tmp
do 
    mv -- "$f" "$REPO_DIR/docs/source/${f%.tmp}.ipynb"
done
popd
rm -rf $REPO_DIR/docs/source/temp
mkdir $FINAL_NOTEBOOKS_DIR/Getting_Started
cp $REPO_DIR/docs/source/3_jupyter_notebook.ipynb \
    $FINAL_NOTEBOOKS_DIR/Getting_Started/1_jupyter_notebook.ipynb
cp $REPO_DIR/docs/source/4_programming_in_python.ipynb \
    $FINAL_NOTEBOOKS_DIR/Getting_Started/2_programming_in_python.ipynb
cp $REPO_DIR/docs/source/5_programming_onboard_peripherals.ipynb \
    $FINAL_NOTEBOOKS_DIR/Getting_Started/3_programming_onboard_peripherals.ipynb
cp $REPO_DIR/docs/source/6_pmodio_overlay.ipynb \
    $FINAL_NOTEBOOKS_DIR/Getting_Started/4_pmodio_overlay.ipynb
cp $REPO_DIR/docs/source/7_audio_video_overlay.ipynb \
    $FINAL_NOTEBOOKS_DIR/Getting_Started/5_audio_video_overlay.ipynb

mkdir $FINAL_NOTEBOOKS_DIR/Getting_Started/images
for f in $GS_NOTEBOOK_IMAGES
do
    cp $REPO_DIR/docs/source/images/$f $FINAL_NOTEBOOKS_DIR/Getting_Started/images/
done


chmod -R a+rw $FINAL_NOTEBOOKS_DIR $FINAL_DOCS_DIR $PYNQ_DIR
chmod -R a+x $FINAL_SCRIPTS_DIR/*
chown -R xpp:xpp $REPO_DIR $BACKUP_DIR
chown -R xpp:xpp $FINAL_NOTEBOOKS_DIR $FINAL_DOCS_DIR $FINAL_SCRIPTS_DIR $PYNQ_DIR 

echo ""
echo "Completed build."
echo "Documentation folder is at: $FINAL_DOCS_DIR"
echo ""
echo "To update this file, manually replace it from local git:"
echo "cp -r $REPO_DIR/ubuntu/scripts/$SCRIPT_NAME $FINAL_SCRIPTS_DIR"
echo ""