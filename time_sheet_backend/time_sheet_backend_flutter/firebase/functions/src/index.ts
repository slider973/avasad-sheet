import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { createClient } from '@supabase/supabase-js';

// Initialize Firebase Admin
admin.initializeApp();

// Initialize Supabase client
const supabaseUrl = functions.config().supabase.url;
const supabaseServiceKey = functions.config().supabase.service_key;
const supabase = createClient(supabaseUrl, supabaseServiceKey);

// Types
interface ValidationRequest {
  id: string;
  employee_id: string;
  manager_id: string;
  period_start: string;
  period_end: string;
  status: 'pending' | 'approved' | 'rejected';
}

interface NotificationPayload {
  title: string;
  body: string;
  data: Record<string, string>;
}

// Cloud Function: Send notification on new validation request
export const onValidationRequestCreated = functions
  .region('europe-west1')
  .firestore
  .document('validation_requests/{requestId}')
  .onCreate(async (snap, context) => {
    const validationData = snap.data() as ValidationRequest;
    
    try {
      // Get manager's FCM token from Supabase
      const { data: manager, error } = await supabase
        .from('users')
        .select('fcm_token, email')
        .eq('id', validationData.manager_id)
        .single();
      
      if (error || !manager?.fcm_token) {
        console.error('Manager FCM token not found:', error);
        return;
      }
      
      // Get employee info
      const { data: employee } = await supabase
        .from('users')
        .select('email')
        .eq('id', validationData.employee_id)
        .single();
      
      // Prepare notification
      const notification: NotificationPayload = {
        title: 'Nouvelle demande de validation',
        body: `${employee?.email || 'Un employé'} demande la validation de sa timesheet`,
        data: {
          type: 'validation_request',
          validation_id: validationData.id,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
      };
      
      // Send FCM notification
      const message = {
        token: manager.fcm_token,
        notification: {
          title: notification.title,
          body: notification.body,
        },
        data: notification.data,
        apns: {
          payload: {
            aps: {
              badge: 1,
              sound: 'default',
            },
          },
        },
        android: {
          priority: 'high' as const,
          notification: {
            channelId: 'validations',
            priority: 'high' as const,
          },
        },
      };
      
      await admin.messaging().send(message);
      
      // Save notification in Supabase
      await supabase.from('notifications').insert({
        user_id: validationData.manager_id,
        validation_request_id: validationData.id,
        type: 'validation_request',
        title: notification.title,
        body: notification.body,
        data: notification.data,
      });
      
      console.log('Notification sent successfully');
    } catch (error) {
      console.error('Error sending notification:', error);
    }
  });

// Cloud Function: Send notification on validation status change
export const onValidationStatusChanged = functions
  .region('europe-west1')
  .firestore
  .document('validation_requests/{requestId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data() as ValidationRequest;
    const after = change.after.data() as ValidationRequest;
    
    // Check if status changed
    if (before.status === after.status) {
      return;
    }
    
    try {
      // Get employee's FCM token
      const { data: employee, error } = await supabase
        .from('users')
        .select('fcm_token, email')
        .eq('id', after.employee_id)
        .single();
      
      if (error || !employee?.fcm_token) {
        console.error('Employee FCM token not found:', error);
        return;
      }
      
      // Prepare notification based on status
      let notification: NotificationPayload;
      
      if (after.status === 'approved') {
        notification = {
          title: 'Timesheet approuvée',
          body: 'Votre timesheet a été approuvée par votre manager',
          data: {
            type: 'validation_feedback',
            validation_id: after.id,
            status: 'approved',
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
          },
        };
      } else if (after.status === 'rejected') {
        notification = {
          title: 'Timesheet rejetée',
          body: 'Votre timesheet nécessite des corrections',
          data: {
            type: 'validation_feedback',
            validation_id: after.id,
            status: 'rejected',
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
          },
        };
      } else {
        return; // Unknown status
      }
      
      // Send FCM notification
      const message = {
        token: employee.fcm_token,
        notification: {
          title: notification.title,
          body: notification.body,
        },
        data: notification.data,
        apns: {
          payload: {
            aps: {
              badge: 1,
              sound: 'default',
            },
          },
        },
        android: {
          priority: 'high' as const,
          notification: {
            channelId: 'feedback',
            priority: 'high' as const,
          },
        },
      };
      
      await admin.messaging().send(message);
      
      // Save notification in Supabase
      await supabase.from('notifications').insert({
        user_id: after.employee_id,
        validation_request_id: after.id,
        type: 'validation_feedback',
        title: notification.title,
        body: notification.body,
        data: notification.data,
      });
      
      console.log('Feedback notification sent successfully');
    } catch (error) {
      console.error('Error sending feedback notification:', error);
    }
  });

// Cloud Function: Send reminder notifications
export const sendValidationReminders = functions
  .region('europe-west1')
  .pubsub
  .schedule('every day 09:00')
  .timeZone('Europe/Zurich')
  .onRun(async (context) => {
    try {
      // Get pending validations older than 2 days
      const twoDaysAgo = new Date();
      twoDaysAgo.setDate(twoDaysAgo.getDate() - 2);
      
      const { data: pendingValidations, error } = await supabase
        .from('validation_requests')
        .select('id, manager_id, employee_id, created_at')
        .eq('status', 'pending')
        .lte('created_at', twoDaysAgo.toISOString());
      
      if (error) {
        console.error('Error fetching pending validations:', error);
        return;
      }
      
      // Send reminders to managers
      for (const validation of pendingValidations || []) {
        const { data: manager } = await supabase
          .from('users')
          .select('fcm_token')
          .eq('id', validation.manager_id)
          .single();
        
        if (manager?.fcm_token) {
          const message = {
            token: manager.fcm_token,
            notification: {
              title: 'Rappel: Validation en attente',
              body: 'Vous avez une timesheet en attente de validation',
            },
            data: {
              type: 'reminder',
              validation_id: validation.id,
              click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
          };
          
          try {
            await admin.messaging().send(message);
          } catch (error) {
            console.error('Error sending reminder:', error);
          }
        }
      }
      
      console.log(`Sent ${pendingValidations?.length || 0} reminders`);
    } catch (error) {
      console.error('Error in reminder function:', error);
    }
  });

// Cloud Function: Clean expired validations
export const cleanExpiredValidations = functions
  .region('europe-west1')
  .pubsub
  .schedule('every day 02:00')
  .timeZone('Europe/Zurich')
  .onRun(async (context) => {
    try {
      const { error } = await supabase.rpc('clean_expired_validations');
      
      if (error) {
        console.error('Error cleaning expired validations:', error);
      } else {
        console.log('Expired validations cleaned successfully');
      }
    } catch (error) {
      console.error('Error in cleanup function:', error);
    }
  });

// Cloud Function: Sync validation to Firestore (for real-time updates)
export const syncValidationToFirestore = functions
  .region('europe-west1')
  .https
  .onCall(async (data, context) => {
    // Verify authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }
    
    const { validationId } = data;
    if (!validationId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Validation ID is required'
      );
    }
    
    try {
      // Get validation from Supabase
      const { data: validation, error } = await supabase
        .from('validation_requests')
        .select('*')
        .eq('id', validationId)
        .single();
      
      if (error) {
        throw new functions.https.HttpsError(
          'not-found',
          'Validation not found'
        );
      }
      
      // Verify user has access
      if (validation.employee_id !== context.auth.uid && 
          validation.manager_id !== context.auth.uid) {
        throw new functions.https.HttpsError(
          'permission-denied',
          'User does not have access to this validation'
        );
      }
      
      // Sync to Firestore
      await admin.firestore()
        .collection('validation_requests')
        .doc(validationId)
        .set(validation, { merge: true });
      
      return { success: true };
    } catch (error) {
      console.error('Error syncing validation:', error);
      throw new functions.https.HttpsError(
        'internal',
        'Error syncing validation'
      );
    }
  });