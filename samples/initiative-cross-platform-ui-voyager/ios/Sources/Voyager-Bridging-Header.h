// Voyager-Bridging-Header.h
// Exposes the Voyager Crystal C-ABI surface to Swift.
// See: samples/initiative-cross-platform-ui-voyager/ios/bridge.cr for implementations.

#ifndef Voyager_Bridging_Header_h
#define Voyager_Bridging_Header_h

#import <UIKit/UIKit.h>

void voyager_init(void);
void* voyager_render(const char* slug);
const char* voyager_current_slug(void);
void voyager_register_route_changed_callback(void (*cb)(const char*));

#endif
