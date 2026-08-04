//
//  RemoteCallShim.m
//  relazin
//
//  Implements the cyanide RemoteCall C API on top of lara's RemoteCall
//  ObjC engine. Symbol resolution uses local dlsym(RTLD_DEFAULT) — valid
//  for the remote process too, since both share the same dyld shared cache.
//

#import "RemoteCall.h"                       // cyengine C API (this shim)
#import "../../kexploit/TaskRop/RemoteCall.h" // lara's engine
#import <dlfcn.h>
#import <pthread.h>

uint64_t g_RC_targetProcOverride = 0;

static RemoteCall *g_session = nil;
static pthread_mutex_t gSessionLock = PTHREAD_MUTEX_INITIALIZER;

static void *rc_sym(const char *name) {
    void *p = dlsym(RTLD_DEFAULT, name);
    return p;
}

int init_remote_call(const char *process, bool useMigFilterBypass) {
    if (!process) return -1;
    pthread_mutex_lock(&gSessionLock);
    g_session = [[RemoteCall alloc] initWithProcess:[NSString stringWithUTF8String:process]
                                 useMigFilterBypass:useMigFilterBypass];
    pthread_mutex_unlock(&gSessionLock);
    return g_session ? 0 : -1;
}

int init_remote_call_with_first_exception_timeout(const char *process, bool useMigFilterBypass, int firstExceptionTimeoutMS) {
    (void)firstExceptionTimeoutMS; // lara's engine manages its own timeouts
    return init_remote_call(process, useMigFilterBypass);
}

int init_remote_call_original_thread_only_with_first_exception_timeout(const char *process, bool useMigFilterBypass, int firstExceptionTimeoutMS) {
    (void)firstExceptionTimeoutMS;
    return init_remote_call(process, useMigFilterBypass);
}

static uint64_t rc_call(int timeout, void *ptr, const char *name,
                        uint64_t x0, uint64_t x1, uint64_t x2, uint64_t x3,
                        uint64_t x4, uint64_t x5, uint64_t x6, uint64_t x7) {
    pthread_mutex_lock(&gSessionLock);
    RemoteCall *s = g_session;
    pthread_mutex_unlock(&gSessionLock);
    if (!s) return 0;

    uint64_t args[8] = { x0, x1, x2, x3, x4, x5, x6, x7 };
    return [s doRemoteCallStableWithTimeout:timeout
                               functionName:(char *)(name ? name : "?")
                            functionPointer:ptr
                                       args:args
                                   argCount:8];
}

uint64_t do_remote_call_stable(int timeout, const char *name,
                               uint64_t x0, uint64_t x1, uint64_t x2, uint64_t x3,
                               uint64_t x4, uint64_t x5, uint64_t x6, uint64_t x7) {
    if (!name) return 0;
    return rc_call(timeout, rc_sym(name), name, x0, x1, x2, x3, x4, x5, x6, x7);
}

uint64_t do_remote_call_stable_addr(int timeout, uint64_t pcAddr, const char *name,
                                    uint64_t x0, uint64_t x1, uint64_t x2, uint64_t x3,
                                    uint64_t x4, uint64_t x5, uint64_t x6, uint64_t x7) {
    return rc_call(timeout, (void *)pcAddr, name, x0, x1, x2, x3, x4, x5, x6, x7);
}

bool remote_read(uint64_t src, void *dst, uint64_t size) {
    return [g_session remoteRead:src to:dst size:size];
}

uint64_t remote_read64(uint64_t src) {
    return [g_session remoteRead64From:src];
}

bool remote_write(uint64_t dst, const void *src, uint64_t size) {
    return [g_session remote_write:dst from:src size:size];
}

bool remote_write64(uint64_t dst, uint64_t val) {
    return [g_session remote_write64:dst value:val];
}

bool remote_writeStr(uint64_t dst, const char *str) {
    return [g_session remote_write:dst string:str];
}

uint64_t remote_call_trojan_mem(void) {
    return g_session.trojanMem;
}

int destroy_remote_call(void) {
    pthread_mutex_lock(&gSessionLock);
    RemoteCall *s = g_session;
    g_session = nil;
    pthread_mutex_unlock(&gSessionLock);
    return s ? [s destroyRemoteCall] : 0;
}

void abandon_remote_call(void) {
    pthread_mutex_lock(&gSessionLock);
    g_session = nil;
    pthread_mutex_unlock(&gSessionLock);
}

bool remote_call_has_local_state(void) {
    return g_session != nil;
}

int remote_call_current_pid(void) {
    return g_session ? (int)g_session.pid : -1;
}

bool remote_call_uses_vphone_bridge(void) {
    return false;
}

// MARK: - RemoteCallSession wrapper

@implementation RemoteCallSession

- (instancetype)initWithProcess:(NSString *)process useMigFilterBypass:(BOOL)useMigFilterBypass {
    self = [super init];
    if (self) {
        _laraRC = [[RemoteCall alloc] initWithProcess:process useMigFilterBypass:useMigFilterBypass];
        if (!_laraRC) return nil;
    }
    return self;
}

- (instancetype)initWithProcess:(NSString *)process
              useMigFilterBypass:(BOOL)useMigFilterBypass
         firstExceptionTimeoutMS:(int)firstExceptionTimeoutMS {
    (void)firstExceptionTimeoutMS;
    return [self initWithProcess:process useMigFilterBypass:useMigFilterBypass];
}

- (instancetype)initWithProcess:(NSString *)process
              useMigFilterBypass:(BOOL)useMigFilterBypass
         firstExceptionTimeoutMS:(int)firstExceptionTimeoutMS
              originalThreadOnly:(BOOL)originalThreadOnly {
    (void)firstExceptionTimeoutMS;
    (void)originalThreadOnly;
    return [self initWithProcess:process useMigFilterBypass:useMigFilterBypass];
}

- (uint64_t)taskAddr  { return 0; }
- (uint64_t)trojanMem { return self.laraRC.trojanMem; }
- (int)pid            { return (int)self.laraRC.pid; }

- (uint64_t)doRemoteCallStableWithTimeout:(int)timeout
                             functionName:(const char *)name
                                       x0:(uint64_t)x0 x1:(uint64_t)x1 x2:(uint64_t)x2 x3:(uint64_t)x3
                                       x4:(uint64_t)x4 x5:(uint64_t)x5 x6:(uint64_t)x6 x7:(uint64_t)x7 {
    uint64_t args[8] = { x0, x1, x2, x3, x4, x5, x6, x7 };
    return [self.laraRC doRemoteCallStableWithTimeout:timeout
                                         functionName:(char *)name
                                      functionPointer:rc_sym(name)
                                                 args:args
                                             argCount:8];
}

- (uint64_t)doRemoteCallStableWithTimeout:(int)timeout
                          functionAddress:(uint64_t)pcAddr
                             functionName:(const char *)name
                                       x0:(uint64_t)x0 x1:(uint64_t)x1 x2:(uint64_t)x2 x3:(uint64_t)x3
                                       x4:(uint64_t)x4 x5:(uint64_t)x5 x6:(uint64_t)x6 x7:(uint64_t)x7 {
    uint64_t args[8] = { x0, x1, x2, x3, x4, x5, x6, x7 };
    return [self.laraRC doRemoteCallStableWithTimeout:timeout
                                         functionName:(char *)name
                                      functionPointer:(void *)pcAddr
                                                 args:args
                                             argCount:8];
}

- (BOOL)remoteRead:(uint64_t)src to:(void *)dst size:(uint64_t)size {
    return [self.laraRC remoteRead:src to:dst size:size];
}
- (uint64_t)remoteRead64:(uint64_t)src { return [self.laraRC remoteRead64From:src]; }
- (BOOL)remoteWrite:(uint64_t)dst from:(const void *)src size:(uint64_t)size {
    return [self.laraRC remote_write:dst from:src size:size];
}
- (BOOL)remoteWrite64:(uint64_t)dst value:(uint64_t)val {
    return [self.laraRC remote_write64:dst value:val];
}
- (BOOL)remoteWriteString:(uint64_t)dst value:(const char *)str {
    return [self.laraRC remote_write:dst string:str];
}
- (int)destroyRemoteCall { return [self.laraRC destroyRemoteCall]; }
- (void)abandonRemoteCall { /* lara's engine cleans up on destroy */ }
- (BOOL)hasLocalState { return self.laraRC != nil; }

@end

void remote_call_with_session(RemoteCallSession *session, void (^block)(void)) {
    if (!session || !block) return;
    pthread_mutex_lock(&gSessionLock);
    RemoteCall *saved = g_session;
    g_session = session.laraRC;
    pthread_mutex_unlock(&gSessionLock);

    block();

    pthread_mutex_lock(&gSessionLock);
    g_session = saved;
    pthread_mutex_unlock(&gSessionLock);
}
