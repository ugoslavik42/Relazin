//
//  LogTextView.h (cyengine shim)
//  relazin
//
//  Ported cyanide code logs through log_user(); the shim forwards it to
//  relazin's globallogger (see CyLogBridge.swift).
//

#ifndef CYENGINE_LOGTEXTVIEW_H
#define CYENGINE_LOGTEXTVIEW_H

#import <Foundation/Foundation.h>

void log_user(const char *fmt, ...) __attribute__((format(printf, 1, 2)));
void log_write(const char *msg);
void log_init(void);
void log_set_verbose(BOOL enabled);
BOOL log_verbose_enabled(void);

#endif // CYENGINE_LOGTEXTVIEW_H
