//
//  RemoteCall.h (cyengine shim)
//  relazin
//
//  Declares the cyanide-style RemoteCall C API used by the ported tweaks.
//  Implemented in RemoteCallShim.m on top of lara's RemoteCall ObjC class,
//  so both engines share the same exploited session machinery.
//

#ifndef CYENGINE_TASKROP_REMOTECALL_H
#define CYENGINE_TASKROP_REMOTECALL_H

#import <mach/mach.h>
#ifdef __OBJC__
#import <Foundation/Foundation.h>
#endif
#include <stdbool.h>
#include <stdint.h>

// One-shot override consumed by the next init_remote_call (kept for API
// compatibility with cyanide; honored by the shim where possible).
extern uint64_t g_RC_targetProcOverride;

int      init_remote_call(const char *process, bool useMigFilterBypass);
int      init_remote_call_with_first_exception_timeout(const char *process, bool useMigFilterBypass, int firstExceptionTimeoutMS);
int      init_remote_call_original_thread_only_with_first_exception_timeout(const char *process, bool useMigFilterBypass, int firstExceptionTimeoutMS);

uint64_t do_remote_call_stable(int timeout, const char *name,
                               uint64_t x0, uint64_t x1, uint64_t x2, uint64_t x3,
                               uint64_t x4, uint64_t x5, uint64_t x6, uint64_t x7);
uint64_t do_remote_call_stable_addr(int timeout, uint64_t pcAddr, const char *name,
                                    uint64_t x0, uint64_t x1, uint64_t x2, uint64_t x3,
                                    uint64_t x4, uint64_t x5, uint64_t x6, uint64_t x7);

bool     remote_read(uint64_t src, void *dst, uint64_t size);
uint64_t remote_read64(uint64_t src);
bool     remote_write(uint64_t dst, const void *src, uint64_t size);
bool     remote_write64(uint64_t dst, uint64_t val);
bool     remote_writeStr(uint64_t dst, const char *str);

uint64_t remote_call_trojan_mem(void);
int      destroy_remote_call(void);
void     abandon_remote_call(void);
bool     remote_call_has_local_state(void);
int      remote_call_current_pid(void);
bool     remote_call_uses_vphone_bridge(void);

#ifdef __OBJC__

@class RemoteCall; // lara's engine class

// Wrapper matching cyanide's RemoteCallSession surface, backed by a
// lara RemoteCall instance.
@interface RemoteCallSession : NSObject

@property(nonatomic, readonly) uint64_t taskAddr;
@property(nonatomic, readonly) uint64_t trojanMem;
@property(nonatomic, readonly) int pid;
@property(nonatomic, strong, readonly) RemoteCall *laraRC;

- (instancetype)initWithProcess:(NSString *)process useMigFilterBypass:(BOOL)useMigFilterBypass;
- (instancetype)initWithProcess:(NSString *)process
              useMigFilterBypass:(BOOL)useMigFilterBypass
         firstExceptionTimeoutMS:(int)firstExceptionTimeoutMS;
- (instancetype)initWithProcess:(NSString *)process
              useMigFilterBypass:(BOOL)useMigFilterBypass
         firstExceptionTimeoutMS:(int)firstExceptionTimeoutMS
              originalThreadOnly:(BOOL)originalThreadOnly;

- (uint64_t)doRemoteCallStableWithTimeout:(int)timeout
                             functionName:(const char *)name
                                       x0:(uint64_t)x0 x1:(uint64_t)x1 x2:(uint64_t)x2 x3:(uint64_t)x3
                                       x4:(uint64_t)x4 x5:(uint64_t)x5 x6:(uint64_t)x6 x7:(uint64_t)x7;
- (uint64_t)doRemoteCallStableWithTimeout:(int)timeout
                          functionAddress:(uint64_t)pcAddr
                             functionName:(const char *)name
                                       x0:(uint64_t)x0 x1:(uint64_t)x1 x2:(uint64_t)x2 x3:(uint64_t)x3
                                       x4:(uint64_t)x4 x5:(uint64_t)x5 x6:(uint64_t)x6 x7:(uint64_t)x7;
- (BOOL)remoteRead:(uint64_t)src to:(void *)dst size:(uint64_t)size;
- (uint64_t)remoteRead64:(uint64_t)src;
- (BOOL)remoteWrite:(uint64_t)dst from:(const void *)src size:(uint64_t)size;
- (BOOL)remoteWrite64:(uint64_t)dst value:(uint64_t)val;
- (BOOL)remoteWriteString:(uint64_t)dst value:(const char *)str;
- (int)destroyRemoteCall;
- (void)abandonRemoteCall;
- (BOOL)hasLocalState;

@end

// Runs block with `session` installed as the current global session.
void remote_call_with_session(RemoteCallSession *session, void (^block)(void));

#endif // __OBJC__

#endif // CYENGINE_TASKROP_REMOTECALL_H
