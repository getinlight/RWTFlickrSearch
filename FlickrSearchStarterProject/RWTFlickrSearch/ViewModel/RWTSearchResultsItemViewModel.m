//
//  RWTSearchResultsItemViewModel.m
//  RWTFlickrSearch
//
//  Created by z on 2018/4/17.
//  Copyright © 2018年 Colin Eberhardt. All rights reserved.
//

#import "RWTSearchResultsItemViewModel.h"
#import "RWTFlickrPhotoMetadata.h"

@interface RWTSearchResultsItemViewModel ()

@property (weak, nonatomic) id<RWTViewModelServices> services;
@property (strong, nonatomic) RWTFlickrPhoto *photo;

@end

@implementation RWTSearchResultsItemViewModel

- (instancetype)initWithPhoto:(RWTFlickrPhoto *)photo services:(id<RWTViewModelServices>)services {
    self = [super init];
    if (self) {
        _title = photo.title;
        _url = photo.url;
        _services = services;
        _photo = photo;
        
        [self initialize];
    }
    return  self;
}

- (void)initialize {
    RACSignal *fetchMetadata =
    [RACObserve(self, isVisible) filter:^BOOL(NSNumber *visible) {
         return [visible boolValue];
     }];
    
    @weakify(self)
    [fetchMetadata subscribeNext:^(id x) {
        @strongify(self)
        [[[self.services getFlickrSearchService] flickrImageMetadata:self.photo.identifier]
         subscribeNext:^(RWTFlickrPhotoMetadata *x) {
             self.favorites = @(x.favorites);
             self.comments = @(x.comments);
         }];
    }];
}

@end
