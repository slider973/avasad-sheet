/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;
import '../endpoints/manager_endpoint.dart' as _i2;
import '../endpoints/notification_endpoint.dart' as _i3;
import '../endpoints/pdf_processor_endpoint.dart' as _i4;
import '../endpoints/timesheet_endpoint.dart' as _i5;
import '../endpoints/validation_endpoint.dart' as _i6;
import '../greeting_endpoint.dart' as _i7;
import 'package:time_sheet_backend_server/src/generated/notification_type.dart'
    as _i8;
import 'package:time_sheet_backend_server/src/generated/timesheet_entry.dart'
    as _i9;

class Endpoints extends _i1.EndpointDispatch {
  @override
  void initializeEndpoints(_i1.Server server) {
    var endpoints = <String, _i1.Endpoint>{
      'manager': _i2.ManagerEndpoint()
        ..initialize(
          server,
          'manager',
          null,
        ),
      'notification': _i3.NotificationEndpoint()
        ..initialize(
          server,
          'notification',
          null,
        ),
      'pdfProcessor': _i4.PdfProcessorEndpoint()
        ..initialize(
          server,
          'pdfProcessor',
          null,
        ),
      'timesheet': _i5.TimesheetEndpoint()
        ..initialize(
          server,
          'timesheet',
          null,
        ),
      'validation': _i6.ValidationEndpoint()
        ..initialize(
          server,
          'validation',
          null,
        ),
      'greeting': _i7.GreetingEndpoint()
        ..initialize(
          server,
          'greeting',
          null,
        ),
    };
    connectors['manager'] = _i1.EndpointConnector(
      name: 'manager',
      endpoint: endpoints['manager']!,
      methodConnectors: {
        'createManager': _i1.MethodConnector(
          name: 'createManager',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'firstName': _i1.ParameterDescription(
              name: 'firstName',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'lastName': _i1.ParameterDescription(
              name: 'lastName',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'company': _i1.ParameterDescription(
              name: 'company',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'signature': _i1.ParameterDescription(
              name: 'signature',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['manager'] as _i2.ManagerEndpoint).createManager(
            session,
            params['email'],
            params['firstName'],
            params['lastName'],
            params['company'],
            params['signature'],
          ),
        ),
        'updateManager': _i1.MethodConnector(
          name: 'updateManager',
          params: {
            'managerId': _i1.ParameterDescription(
              name: 'managerId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'firstName': _i1.ParameterDescription(
              name: 'firstName',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'lastName': _i1.ParameterDescription(
              name: 'lastName',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'company': _i1.ParameterDescription(
              name: 'company',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'signature': _i1.ParameterDescription(
              name: 'signature',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'isActive': _i1.ParameterDescription(
              name: 'isActive',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['manager'] as _i2.ManagerEndpoint).updateManager(
            session,
            params['managerId'],
            params['firstName'],
            params['lastName'],
            params['company'],
            params['signature'],
            params['isActive'],
          ),
        ),
        'getActiveManagers': _i1.MethodConnector(
          name: 'getActiveManagers',
          params: {},
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['manager'] as _i2.ManagerEndpoint)
                  .getActiveManagers(session),
        ),
        'getManagerById': _i1.MethodConnector(
          name: 'getManagerById',
          params: {
            'managerId': _i1.ParameterDescription(
              name: 'managerId',
              type: _i1.getType<int>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['manager'] as _i2.ManagerEndpoint).getManagerById(
            session,
            params['managerId'],
          ),
        ),
        'getManagerByEmail': _i1.MethodConnector(
          name: 'getManagerByEmail',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['manager'] as _i2.ManagerEndpoint).getManagerByEmail(
            session,
            params['email'],
          ),
        ),
        'deactivateManager': _i1.MethodConnector(
          name: 'deactivateManager',
          params: {
            'managerId': _i1.ParameterDescription(
              name: 'managerId',
              type: _i1.getType<int>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['manager'] as _i2.ManagerEndpoint).deactivateManager(
            session,
            params['managerId'],
          ),
        ),
        'activateManager': _i1.MethodConnector(
          name: 'activateManager',
          params: {
            'managerId': _i1.ParameterDescription(
              name: 'managerId',
              type: _i1.getType<int>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['manager'] as _i2.ManagerEndpoint).activateManager(
            session,
            params['managerId'],
          ),
        ),
        'createOrActivateManager': _i1.MethodConnector(
          name: 'createOrActivateManager',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'firstName': _i1.ParameterDescription(
              name: 'firstName',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'lastName': _i1.ParameterDescription(
              name: 'lastName',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'company': _i1.ParameterDescription(
              name: 'company',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'signature': _i1.ParameterDescription(
              name: 'signature',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['manager'] as _i2.ManagerEndpoint)
                  .createOrActivateManager(
            session,
            params['email'],
            params['firstName'],
            params['lastName'],
            params['company'],
            params['signature'],
          ),
        ),
        'getManagerStatistics': _i1.MethodConnector(
          name: 'getManagerStatistics',
          params: {
            'managerId': _i1.ParameterDescription(
              name: 'managerId',
              type: _i1.getType<int>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['manager'] as _i2.ManagerEndpoint)
                  .getManagerStatistics(
            session,
            params['managerId'],
          ),
        ),
        'searchManagers': _i1.MethodConnector(
          name: 'searchManagers',
          params: {
            'query': _i1.ParameterDescription(
              name: 'query',
              type: _i1.getType<String>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['manager'] as _i2.ManagerEndpoint).searchManagers(
            session,
            params['query'],
          ),
        ),
        'importManagers': _i1.MethodConnector(
          name: 'importManagers',
          params: {
            'managersData': _i1.ParameterDescription(
              name: 'managersData',
              type: _i1.getType<List<Map<String, dynamic>>>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['manager'] as _i2.ManagerEndpoint).importManagers(
            session,
            params['managersData'],
          ),
        ),
      },
    );
    connectors['notification'] = _i1.EndpointConnector(
      name: 'notification',
      endpoint: endpoints['notification']!,
      methodConnectors: {
        'getUserNotifications': _i1.MethodConnector(
          name: 'getUserNotifications',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'unreadOnly': _i1.ParameterDescription(
              name: 'unreadOnly',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['notification'] as _i3.NotificationEndpoint)
                  .getUserNotifications(
            session,
            params['userId'],
            unreadOnly: params['unreadOnly'],
          ),
        ),
        'markAsRead': _i1.MethodConnector(
          name: 'markAsRead',
          params: {
            'notificationId': _i1.ParameterDescription(
              name: 'notificationId',
              type: _i1.getType<int>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['notification'] as _i3.NotificationEndpoint)
                  .markAsRead(
            session,
            params['notificationId'],
          ),
        ),
        'markAllAsRead': _i1.MethodConnector(
          name: 'markAllAsRead',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['notification'] as _i3.NotificationEndpoint)
                  .markAllAsRead(
            session,
            params['userId'],
          ),
        ),
        'deleteNotification': _i1.MethodConnector(
          name: 'deleteNotification',
          params: {
            'notificationId': _i1.ParameterDescription(
              name: 'notificationId',
              type: _i1.getType<int>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['notification'] as _i3.NotificationEndpoint)
                  .deleteNotification(
            session,
            params['notificationId'],
          ),
        ),
        'deleteReadNotifications': _i1.MethodConnector(
          name: 'deleteReadNotifications',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['notification'] as _i3.NotificationEndpoint)
                  .deleteReadNotifications(
            session,
            params['userId'],
          ),
        ),
        'getUnreadCount': _i1.MethodConnector(
          name: 'getUnreadCount',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['notification'] as _i3.NotificationEndpoint)
                  .getUnreadCount(
            session,
            params['userId'],
          ),
        ),
        'createNotification': _i1.MethodConnector(
          name: 'createNotification',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'type': _i1.ParameterDescription(
              name: 'type',
              type: _i1.getType<_i8.NotificationType>(),
              nullable: false,
            ),
            'title': _i1.ParameterDescription(
              name: 'title',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'message': _i1.ParameterDescription(
              name: 'message',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'data': _i1.ParameterDescription(
              name: 'data',
              type: _i1.getType<Map<String, dynamic>?>(),
              nullable: true,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['notification'] as _i3.NotificationEndpoint)
                  .createNotification(
            session,
            params['userId'],
            params['type'],
            params['title'],
            params['message'],
            params['data'],
          ),
        ),
        'createBulkNotifications': _i1.MethodConnector(
          name: 'createBulkNotifications',
          params: {
            'userIds': _i1.ParameterDescription(
              name: 'userIds',
              type: _i1.getType<List<String>>(),
              nullable: false,
            ),
            'type': _i1.ParameterDescription(
              name: 'type',
              type: _i1.getType<_i8.NotificationType>(),
              nullable: false,
            ),
            'title': _i1.ParameterDescription(
              name: 'title',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'message': _i1.ParameterDescription(
              name: 'message',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'data': _i1.ParameterDescription(
              name: 'data',
              type: _i1.getType<Map<String, dynamic>?>(),
              nullable: true,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['notification'] as _i3.NotificationEndpoint)
                  .createBulkNotifications(
            session,
            params['userIds'],
            params['type'],
            params['title'],
            params['message'],
            params['data'],
          ),
        ),
        'cleanupOldNotifications': _i1.MethodConnector(
          name: 'cleanupOldNotifications',
          params: {},
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['notification'] as _i3.NotificationEndpoint)
                  .cleanupOldNotifications(session),
        ),
        'getNotificationsByType': _i1.MethodConnector(
          name: 'getNotificationsByType',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['notification'] as _i3.NotificationEndpoint)
                  .getNotificationsByType(
            session,
            params['userId'],
          ),
        ),
        'sendValidationReminders': _i1.MethodConnector(
          name: 'sendValidationReminders',
          params: {},
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['notification'] as _i3.NotificationEndpoint)
                  .sendValidationReminders(session),
        ),
      },
    );
    connectors['pdfProcessor'] = _i1.EndpointConnector(
      name: 'pdfProcessor',
      endpoint: endpoints['pdfProcessor']!,
      methodConnectors: {
        'processPdfQueue': _i1.MethodConnector(
          name: 'processPdfQueue',
          params: {},
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['pdfProcessor'] as _i4.PdfProcessorEndpoint)
                  .processPdfQueue(session),
        ),
        'cleanupOldJobs': _i1.MethodConnector(
          name: 'cleanupOldJobs',
          params: {},
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['pdfProcessor'] as _i4.PdfProcessorEndpoint)
                  .cleanupOldJobs(session),
        ),
      },
    );
    connectors['timesheet'] = _i1.EndpointConnector(
      name: 'timesheet',
      endpoint: endpoints['timesheet']!,
      methodConnectors: {
        'processTimesheet': _i1.MethodConnector(
          name: 'processTimesheet',
          params: {
            'action': _i1.ParameterDescription(
              name: 'action',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'data': _i1.ParameterDescription(
              name: 'data',
              type: _i1.getType<Map<String, dynamic>>(),
              nullable: false,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['timesheet'] as _i5.TimesheetEndpoint)
                  .processTimesheet(
            session,
            params['action'],
            params['data'],
          ),
        ),
        'saveTimesheetData': _i1.MethodConnector(
          name: 'saveTimesheetData',
          params: {
            'validationRequestId': _i1.ParameterDescription(
              name: 'validationRequestId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'employeeId': _i1.ParameterDescription(
              name: 'employeeId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'employeeName': _i1.ParameterDescription(
              name: 'employeeName',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'employeeCompany': _i1.ParameterDescription(
              name: 'employeeCompany',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'month': _i1.ParameterDescription(
              name: 'month',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'year': _i1.ParameterDescription(
              name: 'year',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'entries': _i1.ParameterDescription(
              name: 'entries',
              type: _i1.getType<List<_i9.TimesheetEntry>>(),
              nullable: false,
            ),
            'totalDays': _i1.ParameterDescription(
              name: 'totalDays',
              type: _i1.getType<double>(),
              nullable: false,
            ),
            'totalHours': _i1.ParameterDescription(
              name: 'totalHours',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'totalOvertimeHours': _i1.ParameterDescription(
              name: 'totalOvertimeHours',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['timesheet'] as _i5.TimesheetEndpoint)
                  .saveTimesheetData(
            session,
            params['validationRequestId'],
            params['employeeId'],
            params['employeeName'],
            params['employeeCompany'],
            params['month'],
            params['year'],
            params['entries'],
            params['totalDays'],
            params['totalHours'],
            params['totalOvertimeHours'],
          ),
        ),
        'getTimesheetData': _i1.MethodConnector(
          name: 'getTimesheetData',
          params: {
            'validationRequestId': _i1.ParameterDescription(
              name: 'validationRequestId',
              type: _i1.getType<int>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['timesheet'] as _i5.TimesheetEndpoint)
                  .getTimesheetData(
            session,
            params['validationRequestId'],
          ),
        ),
        'generateSignedPdf': _i1.MethodConnector(
          name: 'generateSignedPdf',
          params: {
            'validationRequestId': _i1.ParameterDescription(
              name: 'validationRequestId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'employeeSignature': _i1.ParameterDescription(
              name: 'employeeSignature',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'managerSignature': _i1.ParameterDescription(
              name: 'managerSignature',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'managerName': _i1.ParameterDescription(
              name: 'managerName',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['timesheet'] as _i5.TimesheetEndpoint)
                  .generateSignedPdf(
            session,
            params['validationRequestId'],
            params['employeeSignature'],
            params['managerSignature'],
            params['managerName'],
          ),
        ),
      },
    );
    connectors['validation'] = _i1.EndpointConnector(
      name: 'validation',
      endpoint: endpoints['validation']!,
      methodConnectors: {
        'createValidation': _i1.MethodConnector(
          name: 'createValidation',
          params: {
            'employeeId': _i1.ParameterDescription(
              name: 'employeeId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'employeeName': _i1.ParameterDescription(
              name: 'employeeName',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'managerId': _i1.ParameterDescription(
              name: 'managerId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'managerEmail': _i1.ParameterDescription(
              name: 'managerEmail',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'periodStart': _i1.ParameterDescription(
              name: 'periodStart',
              type: _i1.getType<DateTime>(),
              nullable: false,
            ),
            'periodEnd': _i1.ParameterDescription(
              name: 'periodEnd',
              type: _i1.getType<DateTime>(),
              nullable: false,
            ),
            'pdfBytes': _i1.ParameterDescription(
              name: 'pdfBytes',
              type: _i1.getType<List<int>>(),
              nullable: false,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['validation'] as _i6.ValidationEndpoint)
                  .createValidation(
            session,
            params['employeeId'],
            params['employeeName'],
            params['managerId'],
            params['managerEmail'],
            params['periodStart'],
            params['periodEnd'],
            params['pdfBytes'],
          ),
        ),
        'approveValidation': _i1.MethodConnector(
          name: 'approveValidation',
          params: {
            'validationId': _i1.ParameterDescription(
              name: 'validationId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'managerName': _i1.ParameterDescription(
              name: 'managerName',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'comment': _i1.ParameterDescription(
              name: 'comment',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'signedPdfBytes': _i1.ParameterDescription(
              name: 'signedPdfBytes',
              type: _i1.getType<List<int>?>(),
              nullable: true,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['validation'] as _i6.ValidationEndpoint)
                  .approveValidation(
            session,
            params['validationId'],
            params['managerName'],
            params['comment'],
            params['signedPdfBytes'],
          ),
        ),
        'rejectValidation': _i1.MethodConnector(
          name: 'rejectValidation',
          params: {
            'validationId': _i1.ParameterDescription(
              name: 'validationId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'comment': _i1.ParameterDescription(
              name: 'comment',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'managerName': _i1.ParameterDescription(
              name: 'managerName',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['validation'] as _i6.ValidationEndpoint)
                  .rejectValidation(
            session,
            params['validationId'],
            params['comment'],
            params['managerName'],
          ),
        ),
        'getEmployeeValidations': _i1.MethodConnector(
          name: 'getEmployeeValidations',
          params: {
            'employeeId': _i1.ParameterDescription(
              name: 'employeeId',
              type: _i1.getType<String>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['validation'] as _i6.ValidationEndpoint)
                  .getEmployeeValidations(
            session,
            params['employeeId'],
          ),
        ),
        'getManagerValidations': _i1.MethodConnector(
          name: 'getManagerValidations',
          params: {
            'managerEmail': _i1.ParameterDescription(
              name: 'managerEmail',
              type: _i1.getType<String>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['validation'] as _i6.ValidationEndpoint)
                  .getManagerValidations(
            session,
            params['managerEmail'],
          ),
        ),
        'getValidation': _i1.MethodConnector(
          name: 'getValidation',
          params: {
            'validationId': _i1.ParameterDescription(
              name: 'validationId',
              type: _i1.getType<int>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['validation'] as _i6.ValidationEndpoint).getValidation(
            session,
            params['validationId'],
          ),
        ),
        'downloadValidationPdf': _i1.MethodConnector(
          name: 'downloadValidationPdf',
          params: {
            'validationId': _i1.ParameterDescription(
              name: 'validationId',
              type: _i1.getType<int>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['validation'] as _i6.ValidationEndpoint)
                  .downloadValidationPdf(
            session,
            params['validationId'],
          ),
        ),
        'getValidationTimesheetData': _i1.MethodConnector(
          name: 'getValidationTimesheetData',
          params: {
            'validationId': _i1.ParameterDescription(
              name: 'validationId',
              type: _i1.getType<int>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['validation'] as _i6.ValidationEndpoint)
                  .getValidationTimesheetData(
            session,
            params['validationId'],
          ),
        ),
        'checkExpiredValidations': _i1.MethodConnector(
          name: 'checkExpiredValidations',
          params: {},
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['validation'] as _i6.ValidationEndpoint)
                  .checkExpiredValidations(session),
        ),
      },
    );
    connectors['greeting'] = _i1.EndpointConnector(
      name: 'greeting',
      endpoint: endpoints['greeting']!,
      methodConnectors: {
        'hello': _i1.MethodConnector(
          name: 'hello',
          params: {
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['greeting'] as _i7.GreetingEndpoint).hello(
            session,
            params['name'],
          ),
        )
      },
    );
  }
}
