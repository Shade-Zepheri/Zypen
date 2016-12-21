#import "ZYTheme.h"

@interface ZYThemeLoader : NSObject
+(ZYTheme*)loadFromFile:(NSString*)baseName;

+(ZYTheme*) themeFromDictionary:(NSDictionary*)dict;
@end
