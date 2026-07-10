// CrystalHIGHost-Bridging-Header.h
// Exposes the Crystal C-ABI surface to Swift.
// See: samples/cross_platform/ios_host/hig_bridge.cr for implementations.

#ifndef CrystalHIGHost_Bridging_Header_h
#define CrystalHIGHost_Bridging_Header_h

#import <UIKit/UIKit.h>

// Lifecycle
void crystal_init(void);

// Render a HIG component by slug. Returns a retained UIView* (Swift takes
// ownership via Unmanaged.fromOpaque(ptr).takeRetainedValue()).
void* crystal_render_slug(const char* slug);

#endif /* CrystalHIGHost_Bridging_Header_h */
