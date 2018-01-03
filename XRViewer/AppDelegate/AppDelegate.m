#import "AppDelegate.h"
#import "Constants.h"
#import "XRViewer-Swift.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self registerDefaultsFromSettingsBundle];
    
    [DDLog addLogger:[DDTTYLogger sharedInstance]]; // TTY = Xcode console
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];

    // If it's the first time we launch the app, wait until the user responds to the analytics usage question
    BOOL alreadyLaunched = [[NSUserDefaults standardUserDefaults] boolForKey:ALREADY_LAUNCHED_KEY];
    if (alreadyLaunched) {
        BOOL sendUsageData = [[NSUserDefaults standardUserDefaults] boolForKey:USE_ANALYTICS_KEY];
        [[AnalyticsManager sharedInstance] initializeWithSendUsageData:sendUsageData];
    }
    
    return YES;
}

- (void)registerDefaultsFromSettingsBundle {
    NSString *settingsBundle = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"];
    if(!settingsBundle) {
        NSLog(@"Could not find Settings.bundle");
        return;
    }

    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:@"Root.plist"]];
    NSArray *preferences = settings[@"PreferenceSpecifiers"];
    
    NSMutableDictionary *defaultsToRegister = [[NSMutableDictionary alloc] initWithCapacity:[preferences count]];
    for(NSDictionary *prefSpecification in preferences) {
        NSString *key = prefSpecification[@"Key"];
        if(key) {
            defaultsToRegister[key] = prefSpecification[@"DefaultValue"];
        }
    }
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsToRegister];
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    //Be ready to open URLs like "wxrv://ios-viewer.webxrexperiments.com/viewer.html"
    if ([[url scheme] isEqualToString:@"wxrv"]) {
        // Extract the scheme part of the URL
        NSString* urlString = [[url absoluteString] substringFromIndex:7];
        urlString = [NSString stringWithFormat:@"https://%@", urlString];
        
        DDLogDebug(@"WebXR-iOS viewer opened with URL: %@", urlString);
        
        [[NSUserDefaults standardUserDefaults] setObject:urlString forKey:REQUESTED_URL_KEY];

        return YES;
    }
    return NO;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [[AnalyticsManager sharedInstance] sendEventWithCategory:EventCategoryAction method:EventMethodForeground object:EventObjectApp];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [[AnalyticsManager sharedInstance] sendEventWithCategory:EventCategoryAction method:EventMethodBackground object:EventObjectApp];
}

@end
