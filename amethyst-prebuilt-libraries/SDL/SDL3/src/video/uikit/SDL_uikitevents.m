/*
  Simple DirectMedia Layer
  Copyright (C) 1997-2026 Sam Lantinga <slouken@libsdl.org>

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.
*/
#include "SDL_internal.h"
#include <dlfcn.h>

#ifdef SDL_VIDEO_DRIVER_UIKIT

#include "../../events/SDL_events_c.h"
#include "../../main/SDL_main_callbacks.h"

#include "SDL_uikitevents.h"
#include "SDL_uikitopengles.h"
#include "SDL_uikitvideo.h"
#include "SDL_uikitwindow.h"

#import <Foundation/Foundation.h>
#import <GameController/GameController.h>

static BOOL UIKit_EventPumpEnabled = YES;

@interface SDL_LifecycleObserver : NSObject
@property(nonatomic, assign) BOOL isObservingNotifications;
@end

@implementation SDL_LifecycleObserver

- (void)update
{
    NSNotificationCenter *notificationCenter = NSNotificationCenter.defaultCenter;
    bool wants_observation = (UIKit_EventPumpEnabled || SDL_HasMainCallbacks());
    if (!wants_observation) {
        // Make sure no windows have active animation callbacks
        int num_windows = 0;
        SDL_free(SDL_GetWindows(&num_windows));
        if (num_windows > 0) {
            wants_observation = true;
        }
    }
    if (wants_observation && !self.isObservingNotifications) {
        self.isObservingNotifications = YES;
        [notificationCenter addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
        [notificationCenter addObserver:self selector:@selector(applicationWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
        [notificationCenter addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [notificationCenter addObserver:self selector:@selector(applicationWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
        [notificationCenter addObserver:self selector:@selector(applicationWillTerminate) name:UIApplicationWillTerminateNotification object:nil];
        [notificationCenter addObserver:self selector:@selector(applicationDidReceiveMemoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
#if !defined(SDL_PLATFORM_TVOS) && !defined(SDL_PLATFORM_VISIONOS)
        [notificationCenter addObserver:self
                               selector:@selector(applicationDidChangeStatusBarOrientation)
                                   name:UIApplicationDidChangeStatusBarOrientationNotification
                                 object:nil];
#endif
    } else if (!wants_observation && self.isObservingNotifications) {
        self.isObservingNotifications = NO;
        [notificationCenter removeObserver:self];
    }
}

- (void)applicationDidBecomeActive
{
    SDL_OnApplicationDidEnterForeground();
}

- (void)applicationWillResignActive
{
    SDL_OnApplicationWillEnterBackground();
}

- (void)applicationDidEnterBackground
{
    SDL_OnApplicationDidEnterBackground();
}

- (void)applicationWillEnterForeground
{
    SDL_OnApplicationWillEnterForeground();
}

- (void)applicationWillTerminate
{
    SDL_OnApplicationWillTerminate();
}

- (void)applicationDidReceiveMemoryWarning
{
    SDL_OnApplicationDidReceiveMemoryWarning();
}

#if !defined(SDL_PLATFORM_TVOS) && !defined(SDL_PLATFORM_VISIONOS)
- (void)applicationDidChangeStatusBarOrientation
{
    SDL_OnApplicationDidChangeStatusBarOrientation();
}
#endif

@end

void SDL_UpdateLifecycleObserver(void)
{
    static SDL_LifecycleObserver *lifecycleObserver;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      lifecycleObserver = [SDL_LifecycleObserver new];
    });
    [lifecycleObserver update];
}

void SDL_SetiOSEventPump(bool enabled)
{
    UIKit_EventPumpEnabled = enabled;

    SDL_UpdateLifecycleObserver();
}

Uint64 UIKit_GetEventTimestamp(NSTimeInterval nsTimestamp)
{
    static Uint64 timestamp_offset;
    Uint64 timestamp = (Uint64)(nsTimestamp * SDL_NS_PER_SECOND);
    Uint64 now = SDL_GetTicksNS();

    if (!timestamp_offset) {
        timestamp_offset = (now - timestamp);
    }
    timestamp += timestamp_offset;

    if (timestamp > now) {
        timestamp_offset -= (timestamp - now);
        timestamp = now;
    }
    return timestamp;
}

void UIKit_PumpEvents(SDL_VideoDevice *_this)
{
    if (!UIKit_EventPumpEnabled) {
        return;
    }

    /* Let the run loop run for a short amount of time: long enough for
       touch events to get processed (which is important to get certain
       elements of Game Center's GKLeaderboardViewController to respond
       to touch input), but not long enough to introduce a significant
       delay in the rest of the app.
    */
    const CFTimeInterval seconds = 0.000002;

    // Pump most event types.
    SInt32 result;
    do {
        result = CFRunLoopRunInMode(kCFRunLoopDefaultMode, seconds, TRUE);
    } while (result == kCFRunLoopRunHandledSource);

    // Make sure UIScrollView objects scroll properly.
    do {
        result = CFRunLoopRunInMode((CFStringRef)UITrackingRunLoopMode, seconds, TRUE);
    } while (result == kCFRunLoopRunHandledSource);

    // See the comment in the function definition.
#if defined(SDL_VIDEO_OPENGL_ES) || defined(SDL_VIDEO_OPENGL_ES2)
    UIKit_GL_RestoreCurrentContext();
#endif
}

static id keyboard_connect_observer = nil;
static id keyboard_disconnect_observer = nil;

static void OnGCKeyboardConnected(GCKeyboard *keyboard) API_AVAILABLE(macos(11.0), ios(14.0), tvos(14.0))
{
    SDL_KeyboardID keyboardID = (SDL_KeyboardID)(uintptr_t)keyboard;

    SDL_AddKeyboard(keyboardID, NULL);

    // Local modification: the host launcher already handles the hardware
    // keyboard itself (UIKey events -> GLFW/SDL key injection). GCKeyboard
    // only keeps the last registered keyChangedHandler, so SDL must NOT
    // register its own here or every physical key press would be delivered
    // twice to the game (once via this handler, once via the launcher).
}

static void OnGCKeyboardDisconnected(GCKeyboard *keyboard) API_AVAILABLE(macos(11.0), ios(14.0), tvos(14.0))
{
    SDL_KeyboardID keyboardID = (SDL_KeyboardID)(uintptr_t)keyboard;

    SDL_RemoveKeyboard(keyboardID);

    // Local modification: do not clear keyChangedHandler here; it belongs to
    // the host launcher.
}

void SDL_InitGCKeyboard(void)
{
    @autoreleasepool {
        if (@available(iOS 14.0, tvOS 14.0, *)) {
            NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

            keyboard_connect_observer = [center addObserverForName:GCKeyboardDidConnectNotification
                                                            object:nil
                                                             queue:nil
                                                        usingBlock:^(NSNotification *note) {
                                                          GCKeyboard *keyboard = note.object;
                                                          OnGCKeyboardConnected(keyboard);
                                                        }];

            keyboard_disconnect_observer = [center addObserverForName:GCKeyboardDidDisconnectNotification
                                                               object:nil
                                                                queue:nil
                                                           usingBlock:^(NSNotification *note) {
                                                             GCKeyboard *keyboard = note.object;
                                                             OnGCKeyboardDisconnected(keyboard);
                                                           }];

            if (GCKeyboard.coalescedKeyboard != nil) {
                OnGCKeyboardConnected(GCKeyboard.coalescedKeyboard);
            }
        }
    }
}

void SDL_QuitGCKeyboard(void)
{
    @autoreleasepool {
        if (@available(iOS 14.0, tvOS 14.0, *)) {
            NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

            if (keyboard_connect_observer) {
                [center removeObserver:keyboard_connect_observer name:GCKeyboardDidConnectNotification object:nil];
                keyboard_connect_observer = nil;
            }

            if (keyboard_disconnect_observer) {
                [center removeObserver:keyboard_disconnect_observer name:GCKeyboardDidDisconnectNotification object:nil];
                keyboard_disconnect_observer = nil;
            }

            if (GCKeyboard.coalescedKeyboard != nil) {
                OnGCKeyboardDisconnected(GCKeyboard.coalescedKeyboard);
            }
        }
    }
}

static id mouse_connect_observer = nil;
static id mouse_disconnect_observer = nil;
static bool mouse_relative_mode = false;

static void UpdatePointerLock(void)
{
    SDL_VideoDevice *_this = SDL_GetVideoDevice();
    SDL_Window *window;

    for (window = _this->windows; window != NULL; window = window->next) {
        UIKit_UpdatePointerLock(_this, window);
    }
}

static bool SetGCMouseRelativeMode(bool enabled)
{
    mouse_relative_mode = enabled;

    // Local modification: this can be called from the game thread (the app
    // calls SDL_SetRelativeMouseMode from its own thread), so the UIKit calls
    // in UpdatePointerLock must run on the main thread.
    dispatch_async(dispatch_get_main_queue(), ^{
        UpdatePointerLock();
    });

    // Local modification: the host launcher needs to know the moment the game
    // grabs the mouse (relative mode) so it can switch touch translation to
    // relative deltas and hide its own cursor. Resolve the bridge via dlsym so
    // this SDL copy stays usable outside the launcher.
    static void (*NoteGrab)(bool);
    if (!NoteGrab) {
        NoteGrab = (void (*)(bool))dlsym(RTLD_DEFAULT, "AASDL_NoteGrab");
    }
    if (NoteGrab) {
        NoteGrab(enabled);
    }
    return true;
}

static void OnGCMouseButtonChanged(SDL_MouseID mouseID, Uint8 button, BOOL pressed)
{
    Uint64 timestamp = SDL_GetTicksNS();
    SDL_SendMouseButton(timestamp, SDL_GetMouseFocus(), mouseID, button, pressed);
}

static void OnGCMouseConnected(GCMouse *mouse) API_AVAILABLE(macos(11.0), ios(14.0), tvos(14.0))
{
    SDL_MouseID mouseID = (SDL_MouseID)(uintptr_t)mouse;

    SDL_AddMouse(mouseID, NULL);

    // Local modification: the host launcher already registered its own
    // GCMouse handlers (mouseMovedHandler, button and scroll handlers) before
    // the game started. GCMouse only keeps the last registered handler per
    // event, so SDL must NOT register its own here or the launcher would lose
    // the mouse entirely. Relative mode is still tracked via
    // SetRelativeMouseMode -> SetGCMouseRelativeMode.

    UpdatePointerLock();
}

static void OnGCMouseDisconnected(GCMouse *mouse) API_AVAILABLE(macos(11.0), ios(14.0), tvos(14.0))
{
    SDL_MouseID mouseID = (SDL_MouseID)(uintptr_t)mouse;

    // Local modification: do not clear the GCMouse handlers here either; they
    // belong to the host launcher (GCMouse keeps only the last registered
    // handler).

    UpdatePointerLock();

    SDL_RemoveMouse(mouseID);
}

void SDL_InitGCMouse(void)
{
    @autoreleasepool {
        // There is a bug where mouse accumulates duplicate deltas over time in iOS 14.0
        if (@available(iOS 14.1, tvOS 14.1, *)) {
            /* iOS will not send the new pointer touch events if you don't have this key,
             * and we need them to differentiate between mouse events and real touch events.
             */
            BOOL indirect_input_available = [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"UIApplicationSupportsIndirectInputEvents"] boolValue];
            if (indirect_input_available) {
                NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

                mouse_connect_observer = [center addObserverForName:GCMouseDidConnectNotification
                                                             object:nil
                                                              queue:nil
                                                         usingBlock:^(NSNotification *note) {
                                                           GCMouse *mouse = note.object;
                                                           OnGCMouseConnected(mouse);
                                                         }];

                mouse_disconnect_observer = [center addObserverForName:GCMouseDidDisconnectNotification
                                                                object:nil
                                                                 queue:nil
                                                            usingBlock:^(NSNotification *note) {
                                                              GCMouse *mouse = note.object;
                                                              OnGCMouseDisconnected(mouse);
                                                            }];

                for (GCMouse *mouse in [GCMouse mice]) {
                    OnGCMouseConnected(mouse);
                }
            } else {
                NSLog(@"You need UIApplicationSupportsIndirectInputEvents in your Info.plist for mouse support");
            }
        }
    }

    // Local modification: always wire up relative mode, even without a
    // connected GCMouse or indirect input events, so games can grab the mouse.
    // SetGCMouseRelativeMode notifies the host launcher in that case.
    SDL_GetMouse()->SetRelativeMouseMode = SetGCMouseRelativeMode;
}

bool SDL_GCMouseRelativeMode(void)
{
    return mouse_relative_mode;
}

void SDL_QuitGCMouse(void)
{
    @autoreleasepool {
        if (@available(iOS 14.1, tvOS 14.1, *)) {
            NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

            if (mouse_connect_observer) {
                [center removeObserver:mouse_connect_observer name:GCMouseDidConnectNotification object:nil];
                mouse_connect_observer = nil;
            }

            if (mouse_disconnect_observer) {
                [center removeObserver:mouse_disconnect_observer name:GCMouseDidDisconnectNotification object:nil];
                mouse_disconnect_observer = nil;
            }

            for (GCMouse *mouse in [GCMouse mice]) {
                OnGCMouseDisconnected(mouse);
            }

            SDL_GetMouse()->SetRelativeMouseMode = NULL;
        }
    }
}

#endif // SDL_VIDEO_DRIVER_UIKIT
