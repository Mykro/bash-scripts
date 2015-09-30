#!/bin/bash
#===============================================================================
# Steam Key Activator for Linux
# v2.0
# Copyright (C) 2015 mykro76, licensed under GPLv3 for free use/modification.
#
# This script takes a Steam key (via parameter or prompt) and then activates
# it by controlling the Steam for Linux client.
#
# Prerequisites: steam, xte, imagemagick, tesseract
#
# Usage:
# - Make sure your Steam client is running and logged in.
# - At the commandline execute:
#     ./skafl.sh
#
# Notes:
# - Tested with Ubuntu 14.04
#===============================================================================

# Prompt user for a key if needed
if [ -z "$1" ]; then
  read -e -p "Enter a Steam Key: " STEAMKEY
else
  STEAMKEY=$1
fi

echo Activating Steam Key ${STEAMKEY}.

# Launches Steam if necessary, and opens the Activate Product dialog.
steam steam://open/activateproduct

# Intro page.  Next button is focused by default, send Return keypress.
xte 'usleep 500000' 'key Return'

# Licence page.  "I agree" button is focused by default, send Return keypress.
xte 'usleep 500000' 'key Return'

# Product code field is (normally) focused.  Send key.
xte 'usleep 500000' "str ${STEAMKEY}"

xte 'usleep 200000' 'key Return'

# There are five possible outcomes:
# OC1 : Successful and can be installed
#       To exit: RETURN (?)
# OC2 : Successful but nothing to install (eg DLC)
#       To exit: RETURN (?)
# OC3 : Product already owned and can be installed (or is already installed).  
#       To exit: RETURN, 2 x TAB, RETURN
# OC4 : Product already owned but nothing to install.
#       To exit: RETURN
# OC5 : Invalid Key.  
#       To exit: 2 x TAB, RETURN

# The Product Activation window is blank for a while.
# Wait for up to 10 seconds, checking each second for some content to appear.
COUNTER=0
while [ $COUNTER -lt 10 ]; do
  let COUNTER=COUNTER+1 

  xte 'sleep 1'

  # Use the imagemagick import tool to take a screenshot of the PA window. 
  # Adjust the depth and resize parameters for best OCR results.
  import -format tiff -depth 8 -resize 400% -window "Product Activation" _temp_pawindow.tiff

  # Use the tesseract tool to OCR the tiff.  The output file is given a .txt extension.
  tesseract -l eng _temp_pawindow.tiff _temp_pawindow

  # Count lines in the output file.  A blank (still processing) window is about 6 lines.
  TEMP_LINES=$(cat _temp_pawindow.txt | wc -l)

  # If there's more than 8 OCR'd lines we have our response.
  if [ $TEMP_LINES -gt 8 ]; then
    COUNTER=100;  # break out
  fi
done

# Check the output file for content
if egrep 'Invalid Product Code' _temp_pawindow.txt 
then
  echo "'Invalid Product Code' message detected."
  xte 'key Tab' 'usleep 200000'	'key Tab' 'usleep 200000' 'key Return'
else 
  if egrep 'Actlvatlon Successful|Activation Successful' _temp_pawindow.txt 
  then
    echo "'Activation Successful' message detected."
    PRODUCT_NAME=$(sed '10q;d' _temp_pawindow.txt)
    echo "Product name: " ${PRODUCT_NAME}
    # ESC doesn't work here, go to next screen first
    xte 'usleep 500000' 'key Return' 'key Escape'
  else
    if egrep 'Product Already Owned' _temp_pawindow.txt 
    then
      echo "'Product Already Owned' message detected."
      xte 'usleep 500000' 'key Return'
      xte 'usleep 200000' 'key Tab' 'usleep 200000' 'key Tab' 'usleep 200000' 'key Return'
    else
      echo "Message not recognised."
    fi
  fi
fi


