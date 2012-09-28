#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

// undefine Move macro, this is conflict to Mac OS X QuickDraw API.
#undef Move

#ifdef DEBUG
#  define LOG(...) NSLog(__VA_ARGS__)
#else
#  define LOG(...) ;
#endif

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#import "Skype.h"

static Class API;

@interface P5CocoaSkypeDelegate : NSObject<SkypeAPIDelegate> {
@public
    SV* perl_obj;
}
@end

@implementation P5CocoaSkypeDelegate

-(NSString*)clientApplicationName {
    HV* hv;
    SV* sv_name;
    STRLEN len;
    char* ptr;
    NSString* name;

    LOG(@"clientApplicationName");

    hv      = (HV*)SvRV(self->perl_obj);
    sv_name = *hv_fetch(hv, "name", 4, 0);

    ptr  = SvPV(sv_name, len);
    name = [NSString stringWithUTF8String:ptr];

    return name;
}

-(void)skypeAttachResponse:(unsigned)aAttachResponseCode {
    HV*  hv;
    SV** sv_cb;
    SV*  sv_code;
    dSP;

    LOG(@"skypeAttachResponse: %d", aAttachResponseCode);

    hv = (HV*)SvRV(self->perl_obj);
    sv_cb = hv_fetch(hv, "on_attach_response", 18, 0);

    if (sv_cb) {
        sv_code = sv_2mortal(newSViv(aAttachResponseCode));

        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_code);
        PUTBACK;

        call_sv(*sv_cb, G_SCALAR);

        SPAGAIN;
        PUTBACK;
        FREETMPS;
        LEAVE;
    }
}

-(void)skypeNotificationReceived:(NSString*)aNotificationString {
    HV*  hv;
    SV** sv_cb;
    SV*  sv_notification;
    dSP;

    LOG(@"skypeNotificationReceived: %@", aNotificationString);

    hv = (HV*)SvRV(self->perl_obj);
    sv_cb = hv_fetch(hv, "on_notification_received", 24, 0);

    if (sv_cb) {
        sv_notification = sv_2mortal(newSV(0));
        sv_setpv(sv_notification, [aNotificationString UTF8String]);

        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_notification);
        PUTBACK;

        call_sv(*sv_cb, G_SCALAR);

        SPAGAIN;
        PUTBACK;
        FREETMPS;
        LEAVE;
    }
}

-(void)skypeBecameAvailable:(NSNotification*)aNotification {
    HV*  hv;
    SV** sv_cb;
    dSP;

    LOG(@"skypeBecameAvailable");

    hv = (HV*)SvRV(self->perl_obj);
    sv_cb = hv_fetch(hv, "on_became_available", 19, 0);

    if (sv_cb) {
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        PUTBACK;

        call_sv(*sv_cb, G_SCALAR);

        SPAGAIN;
        PUTBACK;
        FREETMPS;
        LEAVE;
    }
}

-(void)skypeBecameUnavailable:(NSNotification*)aNotification {
    HV*  hv;
    SV** sv_cb;
    dSP;

    LOG(@"skypeBecameUnavailable");

    hv = (HV*)SvRV(self->perl_obj);
    sv_cb = hv_fetch(hv, "on_became_unavailable", 21, 0);

    if (sv_cb) {
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        PUTBACK;

        call_sv(*sv_cb, G_SCALAR);

        SPAGAIN;
        PUTBACK;
        FREETMPS;
        LEAVE;
    }
}

@end

XS(Cocoa__Skype__isSkypeRunning) {
    dXSARGS;
    SV* sv_running;

    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

    if ([API isSkypeRunning]) {
        sv_running = sv_2mortal(newSViv(1));
    }
    else {
        sv_running = sv_2mortal(newSViv(0));
    }

    [pool drain];

    ST(0) = sv_running;
    XSRETURN(1);
}

XS(Cocoa__Skype__isSkypeAvailable) {
    dXSARGS;
    SV* sv_available;

    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

    if ([API isSkypeAvailable]) {
        sv_available = sv_2mortal(newSViv(1));
    }
    else {
        sv_available = sv_2mortal(newSViv(0));
    }

    [pool drain];

    ST(0) = sv_available;
    XSRETURN(1);
}

XS(Cocoa__Skype__setup) {
    dXSARGS;
    HV* hv;

    if (items < 1) {
        Perl_croak(aTHX_ "invalid arguments\n");
    }

    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

    P5CocoaSkypeDelegate* delegate = [[P5CocoaSkypeDelegate alloc] init];
    delegate->perl_obj = ST(0);

    hv = (HV*)SvRV(delegate->perl_obj);
    sv_magic((SV*)hv, NULL, PERL_MAGIC_ext, NULL, 0);
    mg_find((SV*)hv, PERL_MAGIC_ext)->mg_obj = (SV*)delegate;

    [API setSkypeDelegate:delegate];

    [pool drain];

    XSRETURN(0);
}

XS(Cocoa__Skype__connect) {
    dXSARGS;

    if (items < 1) {
        Perl_croak(aTHX_ "invalid function call\n");
    }

    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    [API connect];
    [pool drain];

    XSRETURN(0);
}

XS(Cocoa__Skype__disconnect) {
    dXSARGS;

    if (items < 1) {
        Perl_croak(aTHX_ "invalid function call\n");
    }

    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    [API disconnect];
    [pool drain];

    XSRETURN(0);
}

XS(Cocoa__Skype__send) {
    dXSARGS;
    SV* sv_msg;
    char* ptr;
    STRLEN len;
    NSString* msg;
    NSString* res;
    SV* sv_res = NULL;

    if (items < 2) {
        Perl_croak(aTHX_ "Usage: $obj->send($msg)");
    }

    sv_msg = ST(1);

    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

    ptr = SvPV(sv_msg, len);
    msg = [NSString stringWithUTF8String:ptr];

    LOG(@"sendSkypeCommand: %@", msg);
    res = (NSString*)[API sendSkypeCommand:msg];
    LOG(@"response: %@", res);

    if (res) {
        sv_res = sv_2mortal(newSV(0));
        sv_setpv(sv_res, [res UTF8String]);
    }

    [pool drain];

    if (sv_res) {
        ST(0) = sv_res;
        XSRETURN(1);
    }
    else {
        XSRETURN(0);
    }
}

XS(Cocoa__Skype__DESTROY) {
    dXSARGS;
    SV* obj;

    if (items != 1) {
        Perl_croak(aTHX_ "invalid function call");
    }

    obj = ST(0);

    MAGIC* m = mg_find(SvRV(obj), PERL_MAGIC_ext);
    if (m) {
        P5CocoaSkypeDelegate* delegate = (P5CocoaSkypeDelegate*)m->mg_obj;
        if (delegate) {
            [delegate release];
            m->mg_obj = NULL;
        }
    }
}

XS(boot_Cocoa__Skype) {
    SV* dir = get_sv("Cocoa::Skype::FRAMEWORK_DIR", FALSE);

    STRLEN len;
    char* d = SvPV(dir, len);

    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

    NSBundle* framework = [NSBundle bundleWithPath:[NSString stringWithUTF8String:d]];
    NSError* e = nil;
    if (framework && [framework loadAndReturnError:&e]) {
        API = objc_getClass("SkypeAPI");
    }
    else {
        Perl_croak(aTHX_ "Couldn't load Skype.framework: %s\n", [[e localizedDescription] UTF8String]);
    }

    [pool drain];

    newXS("Cocoa::Skype::isRunning", Cocoa__Skype__isSkypeRunning, __FILE__);
    newXS("Cocoa::Skype::isAvailable", Cocoa__Skype__isSkypeAvailable, __FILE__);
    newXS("Cocoa::Skype::_setup", Cocoa__Skype__setup, __FILE__);
    newXS("Cocoa::Skype::connect", Cocoa__Skype__connect, __FILE__);
    newXS("Cocoa::Skype::disconnect", Cocoa__Skype__disconnect, __FILE__);
    newXS("Cocoa::Skype::send", Cocoa__Skype__send, __FILE__);
    newXS("Cocoa::Skype::DESTROY", Cocoa__Skype__DESTROY, __FILE__);
}
