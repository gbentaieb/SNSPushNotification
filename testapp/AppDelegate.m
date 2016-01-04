#import <AWSCore/AWSCore.h>
#import <AWSSNS/AWSSNS.h>
#import <AWSCognito/AWSCognito.h>
#import "AppDelegate.h"

@implementation AppDelegate


-(NSString*)deviceTokenAsString:(NSData*)deviceTokenData
{
    NSString *rawDeviceTring = [NSString stringWithFormat:@"%@", deviceTokenData];
    NSString *noSpaces = [rawDeviceTring stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *tmp1 = [noSpaces stringByReplacingOccurrencesOfString:@"<" withString:@""];
    
    return [tmp1 stringByReplacingOccurrencesOfString:@">" withString:@""];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
    [AWSLogger defaultLogger].logLevel = AWSLogLevelVerbose;
    
    application.applicationIconBadgeNumber = 0;
    
    UIMutableUserNotificationAction *readAction = [[UIMutableUserNotificationAction alloc] init];
    readAction.identifier = @"READ_IDENTIFIER";
    readAction.title = @"Read";
    readAction.activationMode = UIUserNotificationActivationModeForeground;
    readAction.destructive = NO;
    readAction.authenticationRequired = YES;
    
    UIMutableUserNotificationAction *ignoreAction = [[UIMutableUserNotificationAction alloc] init];
    ignoreAction.identifier = @"IGNORE_IDENTIFIER";
    ignoreAction.title = @"Ignore";
    ignoreAction.activationMode = UIUserNotificationActivationModeBackground;
    ignoreAction.destructive = NO;
    ignoreAction.authenticationRequired = NO;
    
    UIMutableUserNotificationAction *deleteAction = [[UIMutableUserNotificationAction alloc] init];
    deleteAction.identifier = @"DELETE_IDENTIFIER";
    deleteAction.title = @"Delete";
    deleteAction.activationMode = UIUserNotificationActivationModeForeground;
    deleteAction.destructive = YES;
    deleteAction.authenticationRequired = YES;
    
    UIMutableUserNotificationCategory *messageCategory = [[UIMutableUserNotificationCategory alloc] init];
    messageCategory.identifier = @"MESSAGE_CATEGORY";
    [messageCategory setActions:@[readAction, ignoreAction, deleteAction] forContext:UIUserNotificationActionContextDefault];
    [messageCategory setActions:@[readAction, deleteAction] forContext:UIUserNotificationActionContextMinimal];
    
    NSSet *categories = [NSSet setWithObject:messageCategory];
    
    UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:categories];
    
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
    
    if(launchOptions!=nil){
        NSString *msg = [NSString stringWithFormat:@"%@", launchOptions];
        NSLog(@"%@",msg);
        [self createAlert:msg];
    }
    return YES;
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken{
    
    // Initialize the Amazon Cognito credentials provider
    
    AWSCognitoCredentialsProvider *credentialsProvider = [[AWSCognitoCredentialsProvider alloc]
                                                          initWithRegionType:AWSRegionEUWest1
                                                          identityPoolId:@"yourIdentityPoolId"];
    
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:credentialsProvider];
    
    [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = configuration;
    
    // Register the device with Amazon SNS
    
    NSString * myArn = @"yourAppARN";
    
    NSLog( @"Submit the device token [%@] to SNS to receive notifications.", deviceToken );
    
    AWSSNSCreatePlatformEndpointInput *platformEndpointRequest = [AWSSNSCreatePlatformEndpointInput new];
    platformEndpointRequest.token = [self deviceTokenAsString:deviceToken];
    platformEndpointRequest.platformApplicationArn = myArn;
    
    AWSSNS *snsManager = [AWSSNS defaultSNS];
    [snsManager createPlatformEndpoint:platformEndpointRequest];
    
    // text box with device token
    
    UITextField *tf = [[UITextField alloc] initWithFrame:CGRectMake(0,0,320,460)];
    tf.textColor = [UIColor colorWithRed:0/256.0 green:84/256.0 blue:129/256.0 alpha:1.0];
    tf.font = [UIFont fontWithName:@"Helvetica-Bold" size:25];
    tf.backgroundColor=[UIColor whiteColor];
    NSString *msg = [NSString stringWithFormat:@"deviceToken: %@", deviceToken];
    tf.text=msg;
    
    UITextView *myTextView = [[UITextView alloc] initWithFrame:CGRectMake(20,20,320,460)];
    myTextView.text = msg;
    [self.window.rootViewController.view addSubview:myTextView];
    [myTextView sizeToFit];
    
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error{
    NSLog(@"Failed to register with error : %@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    application.applicationIconBadgeNumber = 0;
    NSString *msg = [NSString stringWithFormat:@"%@", userInfo];
    NSLog(@"%@",msg);
    [self createAlert:msg];
}

- (void)createAlert:(NSString *)msg {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Message Received" message:[NSString stringWithFormat:@"%@", msg]delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
}

- (void)application:(UIApplication *) application handleActionWithIdentifier:(NSString *)identifier
forRemoteNotification:(NSDictionary *)notification completionHandler:(void (^)())completionHandler{
    if ([identifier isEqualToString:@"READ_IDENTIFIER"]){
        NSString *msg = [NSString stringWithFormat:@"%@", @"read"];
        [self createAlert:msg];
    }else if ([identifier isEqualToString:@"DELETE_IDENTIFIER"]){
        NSString *msg = [NSString stringWithFormat:@"%@", @"delete"];
        [self createAlert:msg];
    }
    
    completionHandler();
}

@end
