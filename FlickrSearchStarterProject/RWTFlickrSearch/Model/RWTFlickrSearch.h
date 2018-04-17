//
//  RWTFlickrSearch.h
//  RWTFlickrSearch
//
//  Created by z on 2018/4/17.
//  Copyright © 2018年 Colin Eberhardt. All rights reserved.

//  Model的Services的作用是用来放置业务逻辑的

#import <Foundation/Foundation.h>

@protocol RWTFlickrSearch <NSObject>

- (RACSignal *)flickrSearchSignal:(NSString *)searchString;

- (RACSignal *)flickrImageMetadata:(NSString *)photoId;

@end
