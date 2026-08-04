//
//  PAC.h (cyengine shim)
//  relazin
//
//  Maps cyanide's PAC helper names onto lara's TaskRop/pac.h.
//

#ifndef CYENGINE_TASKROP_PAC_H
#define CYENGINE_TASKROP_PAC_H

#import "../../kexploit/TaskRop/pac.h"

#define native_strip                          nativestrip
#define ptrauth_blend_discriminator_wrapper   ptrauthblend
#define ptrauth_string_discriminator_special  ptrauthstrdisc
#define find_pacia_gadget                     findpacia
#define pac_cleanup                           paccleanup
#define remote_pac                            remotepac

#endif // CYENGINE_TASKROP_PAC_H
