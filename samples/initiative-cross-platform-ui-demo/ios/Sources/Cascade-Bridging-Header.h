// Cascade-Bridging-Header.h
// Exposes the Crystal C-ABI surface to Swift.
// See: samples/initiative-cross-platform-ui-demo/ios/bridge.cr for implementations.

#ifndef Cascade_Bridging_Header_h
#define Cascade_Bridging_Header_h

#import <UIKit/UIKit.h>

void cascade_init(void);
void* cascade_render(const char* slug);

#endif
