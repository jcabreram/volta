# Volta

Volta is an iOS app for timesheet management. With it, employees can submit their work times for the week and managers can approve or deny their timesheets. Also, admin users can have an eagle-eye view of the organization and see the status of the timesheets of the employees.

All of this in real time as it leverages Firebase's realtime database.

You can easily implement it in your company (and for free!) by changing the Firebase instance it's pointing to.

##Features

###Employees
People on the company working on a project with an internal or external manager.
- Enter their timesheets, specify projects worked on the day and send to submission.
- Upload a picture of a paper or screen timesheet if required by attaching to the timesheet week.

###Managers
Project or business managers that don't necessarily work for the company but manage the company's employees. They are responsible for approval of timesheets.
- Approve or don't approve the week timesheet entered by employees.

###Admins
The company's management and Human Relations people who have a need to manage the app information.
- Manage managers and employees in the company.
- Manage projects and assign them to employees.
- Export timesheet week report to PDF.

###Everyone
- See an overview of the approval status of the timesheets. 
- Receive notifications for timesheet submission (Manager), submission reminders (Employee) and project overtime (Admin). (Requires Apple Push Notification Service certificates)

##Built with
- [Firebase][1] - Realtime database, authentication, storage and notifications.
- [LGSideMenuController][2] - Side menu
- [ActionSheetPicker][3] - Picker modal for choosing options
- [iOS-htmltopdf][4]
- [MBProgressHUD][5]
- [NYTPhotoViewer][6]
- [EPSignature][7]

[1]: https://firebase.google.com
[2]: https://github.com/Friend-LGA/LGSideMenuController
[3]: https://github.com/skywinder/ActionSheetPicker-3.0
[4]: https://github.com/iclems/iOS-htmltopdf
[5]: https://www.github.com/jdg/MBProgressHUD
[6]: https://github.com/NYTimes/NYTPhotoViewer
[7]: https://github.com/ipraba/EPSignature
            
