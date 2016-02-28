//
//  CFGFeature.h
//  Pods
//
//  Created by Natan Abramov on 2/28/16.
//
//

#import "NNJSONObject.h"

@interface CFGFeature : NNJSONObject

@property (nonatomic, readonly) BOOL enabled;
@property (nonatomic, readonly) NSString *key;

@end
