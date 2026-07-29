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

#ifdef __cplusplus
}
#endif

#endif // TOUCHCONTROLLER_LAUNCHER_H