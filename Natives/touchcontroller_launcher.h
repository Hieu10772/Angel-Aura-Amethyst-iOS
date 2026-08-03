/*
 * TouchController iOS Launcher Native Interface
 */

#ifndef TOUCHCONTROLLER_LAUNCHER_H
#define TOUCHCONTROLLER_LAUNCHER_H

#ifdef __cplusplus
extern "C" {
#endif

void touchcontroller_vibrate(int type);
void touchcontroller_showKeyboard();
void touchcontroller_hideKeyboard();

// C API for the shared in-process queue (same semantics as the mod's
// touchcontroller_ios_send/receive):
//   send:   launcher -> game (read by the mod's Transport.receive)
//   receive: game -> launcher (written by the mod's Transport.send)
// Returns 0 on success, -1 if the queue is unavailable, 1 on enqueue failure.
// touchcontroller_ios_receive returns the message length, 0 when empty.
int touchcontroller_ios_send(const void* buf, int len);
int touchcontroller_ios_receive(void* buf);

#ifdef __cplusplus
}
#endif

#endif // TOUCHCONTROLLER_LAUNCHER_H