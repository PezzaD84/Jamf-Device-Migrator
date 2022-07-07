#!/bin/bash
#
# Script to Migrate device from one Jamf instance to another Jamf instance
#
# Created by Perry Driscoll 17/6/2022
#
#########################################################################################

#########################################################################################
# Variables
#########################################################################################

ORG="COMPANY NAME"

DEP_NOTIFY_LOG="/var/tmp/depnotify.log"

DEP_NOTIFY_APP="/Applications/Utilities/DEPNotify.app"

enrollmentURL="ENROLLMENT URL OF NEW JAMF"

JCApp="/Applications/Jamf Connect.app/Contents/Info.plist"

authchng="/Library/Security/SecurityAgentPlugins/JamfConnectLogin.bundle/Contents/MacOS/authchanger"

user=$(ls -l /dev/console | awk '{ print $3 }')

CURRENT_USER_ID=$(id -u $user)

admins=$(dscl . read /Groups/admin GroupMembership | grep $user)

#########################################################################################
# Check for DEPNotify app
#########################################################################################

if [ -d $DEP_NOTIFY_APP ]; then
	echo "DEPNotify is installed. Continuing Migration....."
else
	echo "DEPNotify is not installed. App will be installed now....."
	sudo jamf policy -event installDEPNotify
fi

#########################################################################################
# Check Previous build and clean up
#########################################################################################

# Removing config files in /var/tmp
rm /var/tmp/depnotify*

# Removing bom files in /var/tmp
rm /var/tmp/com.depnotify.*

# Removing plists in local user folder

rm /Users/"$user"/Library/Preferences/menu.nomad.DEPNotify*

# Restarting cfprefsd due to plist changes
killall cfprefsd

#########################################################################################
# Initial message and Start App
#########################################################################################

echo "Command: WindowStyle: Activate" >> $DEP_NOTIFY_LOG
echo "Command: WindowTitle: $ORG Migration" >> $DEP_NOTIFY_LOG
echo "Command: Image: /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/Sync.icns" >> $DEP_NOTIFY_LOG
echo "Command: MainTitle: $ORG Migration" >> $DEP_NOTIFY_LOG
echo "Command: MainText: This mac will now be migrated to the new $ORG MDM server. \n \n Please do not log out or turn off this device during this process. \n \n The process will now begin." >> $DEP_NOTIFY_LOG
echo "Status: Device Migration in progress....." >> $DEP_NOTIFY_LOG

# Start DEPNotify app
launchctl asuser $CURRENT_USER_ID open -a "$DEP_NOTIFY_APP" --args -path "$DEP_NOTIFY_LOG"

Sleep 10

#########################################################################################
# Remove MDM Profile
#########################################################################################

echo "Status: Removing old MDM Profile....." >> $DEP_NOTIFY_LOG

jamf removeMdmProfile

sleep 10

#########################################################################################
# Remove Jamf Framework
#########################################################################################

echo "Status: Removing old Management Framework....." >> $DEP_NOTIFY_LOG

jamf removeFramework

sleep 10

#########################################################################################
# Open browser to enrol device in new Jamf instance
#########################################################################################

echo "Command: WindowStyle: Activate" >> $DEP_NOTIFY_LOG
echo "Command: WindowTitle: $ORG Migration" >> $DEP_NOTIFY_LOG
echo "Command: Image: /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/Sync.icns" >> $DEP_NOTIFY_LOG
echo "Command: MainTitle: $ORG Migration" >> $DEP_NOTIFY_LOG
echo "Command: MainText: **PLEASE READ THE FOLLOWING TO ENROLL YOUR DEVICE** \n You will now be taken to the new $ORG Enrollment page. Please make a note of the details below to enrol your device. \n \n Username: ENROLLMENT ACCOUNT \n Password: ENROLLMENT PASSWORD \n \n Once logged in please leave all the details as default and click on Enroll and then follow the onscreen prompts." >> $DEP_NOTIFY_LOG
echo "Status: Device Migration in progress....." >> $DEP_NOTIFY_LOG
echo "Command: ContinueButton: Enroll" >> $DEP_NOTIFY_LOG

# Pausing for user interaction

DEP_NOTIFY_PROCESS=$(pgrep -l "DEPNotify" | cut -d " " -f1)

until [ "$DEP_NOTIFY_PROCESS" == "" ]; do
	echo "DEPNotify is waiting for user interaction......"
	sleep 5
	DEP_NOTIFY_PROCESS=$(pgrep -l "DEPNotify" | cut -d " " -f1)
done

echo "Continuing Migration....."

# Open Browser to enrollment page
open -a "Safari" "$enrollmentURL"

sleep 2

# Check for downloaded enrollment profile
profile=$(ls ~/Downloads/ | grep -m1 -i enrollment)

while [[ $profile == "" ]]; do
	echo "Profile not downloaded yet...."
	sleep 5
	profile=$(ls ~/Downloads/ | grep -m1 -i enrollment)
done

echo "Profile Downloaded...."

open /System/Library/PreferencePanes/Profiles.prefPane
sleep 10

# Loop to check Mac has User Approved MDM

MDM_STATUS=$(profiles status -type enrollment | grep -o "User Approved")

while [[ "$MDM_STATUS" != "User Approved" ]]; do
	
	# Quit System Preferences	
	
	osascript -e 'quit app "System Preferences"'
	
	# Open System Preferences > Profiles
	
	echo "MDM Approval Status: Not user approved"
	
	open /System/Library/PreferencePanes/Profiles.prefPane 
	
	osascript -e 'display dialog "User Approved MDM Not Detected 

Go to System Preferences > Profiles > MDM and click on the [Approve...] button.

Once the MDM profile has been Approved you can click OK to continue the enrollment process.  

The process will not continue until the MDM has been Approved" buttons {"OK"} default button 1 with icon alias "System:Library:CoreServices:CoreTypes.bundle:Contents:Resources:Sync.icns"'
	sleep 15
	
	MDM_STATUS=$(profiles status -type enrollment | grep -o "User Approved")
done
echo "MDM Approval Status: MDM is user approved"

#########################################################################################
# Final Migration Checks
#########################################################################################

echo "Command: WindowStyle: Activate" > $DEP_NOTIFY_LOG
echo "Command: WindowTitle: $ORG Migration" >> $DEP_NOTIFY_LOG
echo "Command: Image: /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/Sync.icns" >> $DEP_NOTIFY_LOG
echo "Command: MainTitle: $ORG Migration" >> $DEP_NOTIFY_LOG
echo "Command: MainText: Final Migration checks in progress. \n \n Your device is nearly ready. \n \n Please sit tight while we do some final checks to get you up and running." >> $DEP_NOTIFY_LOG
echo "Status: Final Migration checks in progress....." >> $DEP_NOTIFY_LOG

# Start DEPNotify app
launchctl asuser $CURRENT_USER_ID open -a "$DEP_NOTIFY_APP" --args -path "$DEP_NOTIFY_LOG"

sleep 10

#########################################################################################
# Check for Jamf connect install
#########################################################################################

while [ ! -f "$JCApp" ]; do
	echo "Jamf connect not installed. Waiting for install to complete...."
	JCApp="/Applications/Jamf Connect.app/Contents/Info.plist"
	sleep 5
done
	echo "Jamf Connect Installed. Continuing migration...."

#########################################################################################
# Reset Login Sceen to Jamf Connect
#########################################################################################

$authchng -reset -JamfConnect -preAuth JamfConnectLogin:privileged

#########################################################################################
# Check If logged in user is admin and remove admin permissions 
#########################################################################################

if [[ $admins == "" ]]; then
	echo "$user is not local admin, continuing migration....." 
else
	echo "$user is a local admin, removing permissions....."
	dseditgroup -o edit -d $user -t user admin
	sleep 5
	user=$(ls -l /dev/console | awk '{ print $3 }')
	admins=$(dscl . read /Groups/admin GroupMembership | grep $user)
	if [[ $admins == "" ]]; then
		echo "$user has been removed from the local admins group. continuing migration....."
	else
		echo "$user is still local admin. Continuing migration to avoid failure loop."
	fi
fi

#########################################################################################
# Completion Message
#########################################################################################

echo "Command: WindowStyle: Activate" >> $DEP_NOTIFY_LOG
echo "Command: WindowTitle: $ORG Migration" >> $DEP_NOTIFY_LOG
echo "Command: Image: /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/Sync.icns" >> $DEP_NOTIFY_LOG
echo "Command: MainTitle: Migration Complete!!" >> $DEP_NOTIFY_LOG
echo "Command: MainText: This mac has been successfully migrated to the new $ORG MDM server. \n \n Please save and close any open work and then click 'Finish'. \n \n You will be logged out and taken to the new next15 login screen. \n \n Please log in with your next15 email address and follow the on screen prompts." >> $DEP_NOTIFY_LOG
echo "Status: MIGRATION COMPLETE!" >> $DEP_NOTIFY_LOG
echo "Command: ContinueButtonLogout: Finish" >> $DEP_NOTIFY_LOG
