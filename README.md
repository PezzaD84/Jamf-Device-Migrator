# Jamf Device Migrator

This script will help to Enrol devices into a new Jamf instance without the need of wiping the device.

It was created for the purpose of migrating on-prem Jamf instances to JamfCloud instances. It can be used to go from cloud to on-prem, on-prem to on-prem or cloud to cloud. It is not limited to one way.

> **<sub>This script could easily be modified to remove MDM profiles from other solutions other than Jamf if needed. Look at lines 102 and 112 which are the commands to remove Jamf. These could be replaced to remove another solutions MDM and local client.</sub>**

## Setup

You will need DEPNotify installed on devices for this script to work. Set up a policy to do this before the script is run. You can download it here https://files.nomad.menu/DEPNotify.pkg

There is a check in the script to install DEPNotify from Jamf if it is not installed. It needs a policy created with a custom trigger of **installDEPNotify**.

you will need to install a PPPC Profile to allow terminal to send finder and system event requests. You can download the profile here https://github.com/PezzaD84/PPPC-Terminal upload it to your old existing Jamf instance and scope to all devices.

This process needs an account setup in the new Jamf instance with **only _Enrollment_ access**. This needs to be added to the custom variables in the script.

Upload the script to your old existing Jamf instance and set the custom variables in the script for your Company **(Between Lines 10-28)**.

## Migration Flow

The Migration goes through a few steps as follows.

- Remove Old MDM Profile
- Remove Old Jamf Framework
- Enroll in new Jamf Instance
- Check for Jamf Connect (Optional)
- Remove Local admin rights (Optional)
- Log user out
  
The user will see the following screens while the migration is happening.

**Start Screen**

![Screenshot 2022-07-11 at 09 38 55](https://user-images.githubusercontent.com/89595349/178234574-6188efce-45bc-4df8-9bec-0fcb6d61fc76.png)

**MDM Removal**

![Screenshot 2022-07-11 at 09 40 40](https://user-images.githubusercontent.com/89595349/178234636-5f8f1ffe-64b6-4323-a0fe-628ee91cbd25.png)

**JAMF Framework Removal**

![Screenshot 2022-07-11 at 09 40 50](https://user-images.githubusercontent.com/89595349/178234679-f820c14a-8864-4570-a82c-4486ab20be05.png)

**Enrollment Details Screen**

![Screenshot 2022-07-11 at 09 41 02](https://user-images.githubusercontent.com/89595349/178234724-bd15c8ad-8260-4053-9241-9d8543c466ec.png)

**Enrollment Website in Safari**

![Screenshot 2022-07-11 at 09 46 48](https://user-images.githubusercontent.com/89595349/178235062-06d4418a-98a9-4880-8f75-f9e196273c78.png)

**MDM Approval notification**

![Screenshot 2022-07-11 at 09 56 07](https://user-images.githubusercontent.com/89595349/178235097-8eed6b93-ddcc-4036-8c19-8d4e0f6cf20c.png)

**Final Migration Checks**

![Screenshot 2022-07-11 at 09 41 31](https://user-images.githubusercontent.com/89595349/178237839-bf885ead-0125-4224-a2f6-f815151d3777.png)

**Completion Screen**

![Screenshot 2022-07-11 at 09 47 06](https://user-images.githubusercontent.com/89595349/178235179-cb486e37-0d94-4567-9fc5-152049dbb40a.png)




