# Volta

Volta is an iOS app for timesheet management. With it, employees can submit their work times for the week and managers can approve or deny their timesheets. Also, admin users can have an eagle-eye view of the organization and see the status of the timesheets of the employees.

All of this in real time as it leverages Firebase's realtime database.

You can easily implement it in your company (and for free!) by changing the Firebase instance it's pointing to.

##Getting Started

### Prerequisites

To have your own Volta, you will need:
- A Firebase account (free)
- Carthage (for building EPSignature)
- Cocoapods (for the rest of the frameworks)

### Setup

1. After creating a Firebase account and setting up the app in the Firebase console, create a user from there.
2. Copy the generated User UID.
3. Replace "TqCUTiAGCaSu3dghrkSsCqSkl2I3" in the "Firebase initial DB" JSON for your generated User ID.
4. Import the "Firebase initial DB" JSON into the Database section of the Firebase console.
5. Run the app and login with your user to create managers and employees.

## Features

### Employees
- Enter their timesheets, specify projects worked on the day and send to submission.
- Upload a picture of a paper or screen timesheet if required by attaching to the timesheet week.

### Managers
- Approve or don't approve the week timesheet entered by employees.

### Admins
- Manage managers and employees in the company.
- Manage projects and assign them to employees.
- Export timesheet week report to PDF.

### Everyone
- See an overview of the approval status of the timesheets. 
- Receive notifications for timesheet submission (Manager), submission reminders (Employee) and project overtime (Admin). (Requires Apple Push Notification Service certificates)

## Built with
- [Firebase][1] - Realtime database, authentication, storage and notifications.
- [LGSideMenuController][2] - Side menu.
- [ActionSheetPicker][3] - Picker modal for choosing options.
- [iOS-htmltopdf][4] - For exporting the timesheets to PDF
- [MBProgressHUD][5] - Progress indicator.
- [NYTPhotoViewer][6] - Image viewer for timesheets photos.
- [EPSignature][7] - For the first time managers login, to record their signature.

[1]: https://firebase.google.com
[2]: https://github.com/Friend-LGA/LGSideMenuController
[3]: https://github.com/skywinder/ActionSheetPicker-3.0
[4]: https://github.com/iclems/iOS-htmltopdf
[5]: https://www.github.com/jdg/MBProgressHUD
[6]: https://github.com/NYTimes/NYTPhotoViewer
[7]: https://github.com/ipraba/EPSignature

## Known issues
- Incorrect appearance of the navigation bar in iPhone X.
- For admin users, progress indicator not disappearing if there are no employees on the database. Create at least one employee to avoid this.
- At startup, the selected week is the week before and not the current one.

## Author

* **Jonathan Cabrera** - [LinkedIn](https://www.linkedin.com/in/jcabreram/en)
            
## License

This project is licensed under the Apache License - see the [LICENSE.md](LICENSE.md) file for details
