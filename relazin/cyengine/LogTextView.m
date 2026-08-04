//
//  LogTextView.m (cyengine shim)
//  relazin
//

#import "LogTextView.h"
#import "relazin-Swift.h"
#import <stdarg.h>
#import <stdio.h>

static BOOL g_verbose = YES;

void log_user(const char *fmt, ...) {
    if (!fmt) return;
    va_list ap;
    va_start(ap, fmt);
    NSString *msg = [[NSString alloc] initWithFormat:[NSString stringWithUTF8String:fmt]
                                           arguments:ap];
    va_end(ap);
    [CyLogBridge log:msg];
}

void log_write(const char *msg) {
    if (msg) [CyLogBridge log:[NSString stringWithUTF8String:msg]];
}

void log_init(void) {}
void log_set_verbose(BOOL enabled) { g_verbose = enabled; }
BOOL log_verbose_enabled(void) { return g_verbose; }
