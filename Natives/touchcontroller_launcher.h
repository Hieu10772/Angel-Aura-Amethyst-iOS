/*
 * TouchController iOS Launcher Native Interface
 */

#ifndef TOUCHCONTROLLER_LAUNCHER_H
#define TOUCHCONTROLLER_LAUNCHER_H

#include <stddef.h>

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
int touchcontroller_queue_ensure(void);
int touchcontroller_ios_send(const void* buf, int len);
int touchcontroller_ios_receive(void* buf, size_t max_len);
int touchcontroller_launcher_send(const void* buf, int len);
size_t touchcontroller_launcher_game_drain_marker(void);
int touchcontroller_launcher_game_drained_past(size_t marker);
int touchcontroller_launcher_mod_active(void);

#ifdef __cplusplus
}
#endif

#endif // TOUCH